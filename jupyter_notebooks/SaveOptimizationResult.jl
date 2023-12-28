function saveoptimizationresult(y::Matrix{Float64}, centroids::Matrix{Float64}, mic_positions::Matrix{Float64},
        name::String, save_dir::String; min_peak_thresh=35, maximum_melody_slope=5, melody_drop_thresh_db=20,
        melody_thresh_db_low=-20, moving_avg_size=10, melody_drop_thresh_db_start=35, find_highest_snr_in_first_ms=1,
        h_fft_thresh=0.1, data_fitting_weight=70, h_sparsity_weight=10, melody_weight=25, max_iter=10_000, melody_radius_start=8,
        melody_radius_end=1, pad_len=300, nfft=256, chirp_sequence_keyword_arguments...)
    chirp_sequences, vocalization_times = collectchirpsequences(y, centroids, mic_positions;
        min_peak_thresh=min_peak_thresh, chirp_sequence_keyword_arguments...);

    chirp_kwargs = Dict(
        :maximum_melody_slope => maximum_melody_slope,
        :melody_drop_thresh_db => melody_drop_thresh_db,
        :melody_thresh_db_low => melody_thresh_db_low,
        :moving_avg_size => moving_avg_size,
        :melody_drop_thresh_db_start => melody_drop_thresh_db_start,
        :find_highest_snr_in_first_ms => find_highest_snr_in_first_ms,
        :nfft => nfft
    );

    melody_kwargs, chirp_bound_kwargs, _ = separatechirpkwargs(;chirp_kwargs...);

    max_seq_len = 0;
    for chirp_seq_all_mics = chirp_sequences
        for seq=values(chirp_seq_all_mics)
            max_seq_len = max(max_seq_len, seq.length);
        end
    end
    max_seq_len += 2 * pad_len

    num_seqs = length(chirp_sequences);

    num_mics = size(y, 2);

    estimated_vocalizations = zeros(max_seq_len, num_seqs);
    estimated_vocalization_lengths = zeros(Int64, num_seqs);
    impulse_response_lengths = zeros(Int64, num_seqs);
        
    mic_k_impulse_response_per_chirp_seq = Vector(undef, num_mics);
    
    for k=1:num_mics
        mic_k_impulse_response_per_chirp_seq[k] = zeros(max_seq_len, num_seqs);
    end
    valid_mics = zeros(Bool, num_mics, num_seqs);

    for (i, chirp_seq_all_mics) = enumerate(chirp_sequences)
        @printf "Optimizing for chirp sequence %d...\n" i
        offsets = computemelodyoffsets(chirp_seq_all_mics, min_peak_thresh; chirp_kwargs...);
        Y, mics = getchirpsequenceY(chirp_seq_all_mics, offsets, pad_len);
        impulse_response_lengths[i] = size(Y, 1);
        
        X_init, H_init, longest_chirp = getinitialconditionsnr(Y, chirp_seq_all_mics, mics, min_peak_thresh, 
            h_fft_thresh=h_fft_thresh; chirp_kwargs...);
        stft_stride = Int64(ceil(longest_chirp / 50));

        ## Determine whether we're in buzz phase or not; if we're in buzz phase, we should change the
        ## melody_radius settings
        max_snr_mic = argmax(x -> maximum(chirp_seq_all_mics[x].snr_data), keys(chirp_seq_all_mics));
        melody = findmelody(chirp_seq_all_mics[max_snr_mic], min_peak_thresh; melody_kwargs...);
        melody_range = fftindextofrequency(maximum(melody) - minimum(melody), 256) / 1000;

        melody_radius_start_2 = melody_radius_start;
        melody_radius_end_2 = melody_radius_end;
        if melody_range < 12
            melody_radius_start_2 = melody_radius_start * 1.5;
            melody_radius_end_2 = melody_radius_start / 2;
        end
        
        X_opt, H_opt, max_chirp_len = optimizePALM(chirp_seq_all_mics, mics, Y, H_init, X_init, min_peak_thresh,
                        data_fitting_weight, h_sparsity_weight, melody_weight; num_debug=1,
                        melody_radius_start=melody_radius_start_2, melody_radius_end=melody_radius_end_2,
                        max_iter=max_iter, nfft=256, stft_stride=stft_stride, chirp_kwargs...);
        estimated_vocalization_lengths[i] = max_chirp_len - Int64(nfft/2) + 1;
        estimated_vocalizations[1:max_chirp_len - Int64(nfft/2) + 1, i] = X_opt[Int64(nfft/2):max_chirp_len];

        for (j, mic)=enumerate(mics)
            valid_mics[mic, i] = true;
            mic_k_impulse_response_per_chirp_seq[mic][1:size(Y, 1), i] = H_opt[:, j];
        end
    end

    save_filename = (@sprintf  "%s/%s_optimization_result.mat" SAVE_DIR DATASET_NAME);
    save_file = matopen(save_filename, "w");
    write(save_file, "valid_mics", valid_mics);
    write(save_file, "estimated_vocalizations", estimated_vocalizations);
    write(save_file, "estimated_vocalization_lengths", estimated_vocalization_lengths);
    write(save_file, "impulse_response_lengths", impulse_response_lengths);
    
    for k=1:num_mics
        write(save_file, (@sprintf "mic_%d_impulse_response_per_chirp_seq" k), mic_k_impulse_response_per_chirp_seq[k]);
    end
    close(save_file);
end