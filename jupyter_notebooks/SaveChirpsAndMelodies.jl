function savechirpsandmelodies(y::AbstractArray, centroids::Matrix, mic_positions::Matrix,
        name::String, save_dir::String; min_peak_thresh=35, maximum_melody_slope=5, melody_drop_thresh_db=20,
        melody_thresh_db_low=-20, moving_avg_size=10, melody_drop_thresh_db_start=35, find_highest_snr_in_first_ms=1,
        chirp_sequence_keyword_arguments...)
    chirp_sequences, vocalization_times = collectchirpsequences(y, centroids, mic_positions;
        min_peak_thresh, chirp_sequence_keyword_arguments...);

    kwargs = Dict(
        :maximum_melody_slope => maximum_melody_slope,
        :melody_drop_thresh_db => melody_drop_thresh_db,
        :melody_thresh_db_low => melody_thresh_db_low,
        :moving_avg_size => moving_avg_size,
        :melody_drop_thresh_db_start => melody_drop_thresh_db_start,
        :find_highest_snr_in_first_ms => find_highest_snr_in_first_ms
    );

    melody_kwargs, chirp_bound_kwargs, _ = separatechirpkwargs(;kwargs...);

    max_seq_len = 0;
    for chirp_seq_all_mics = chirp_sequences
        for seq=values(chirp_seq_all_mics)
            max_seq_len = max(max_seq_len, seq.length);
        end
    end

    num_seqs = length(chirp_sequences);

    num_mics = size(y, 2);
    mic_k_melody_kHz_per_chirp_seq = Vector(undef, num_mics);
    mic_k_estimated_chirp_per_chirp_seq = Vector(undef, num_mics);
    mic_k_chirp_lengths = Vector(undef, num_mics);
    mic_k_samples_cut_off_from_beginning_per_chirp_seq = Vector(undef, num_mics);
    
    highest_snr_estimated_chirp_per_chirp_seq = zeros(max_seq_len, num_seqs);
    highest_snr_chirp_length_per_chirp_seq = zeros(Int64, num_seqs);
    highest_snr_melody_kHz_per_chirp_seq = zeros(max_seq_len, num_seqs);

    updated_vocalization_times = zeros(num_seqs);
    
    for k=1:num_mics
        mic_k_melody_kHz_per_chirp_seq[k] = zeros(max_seq_len, num_seqs);
        mic_k_estimated_chirp_per_chirp_seq[k] = zeros(max_seq_len, num_seqs);
        mic_k_chirp_lengths[k] = zeros(Int64, num_seqs);
        mic_k_samples_cut_off_from_beginning_per_chirp_seq[k] = zeros(Int64, num_seqs);
    end

    valid_mics = zeros(Bool, num_mics, num_seqs);

    for (i, chirp_seq_all_mics) = enumerate(chirp_sequences)
        offsets = computemelodyoffsets(chirp_seq_all_mics, min_peak_thresh; kwargs...);

        max_snr = -Inf;
        max_snr_mic = 0;

        n_mics_this_seq = length(chirp_seq_all_mics);
        vocalization_time = 0;
        
        for mic_seq_pair=chirp_seq_all_mics
            mic = mic_seq_pair.first;
            seq = mic_seq_pair.second;

            if maximum(seq.snr_data) > max_snr
                max_snr = maximum(seq.snr_data);
                max_snr_mic = mic;
            end

            valid_mics[mic, i] = true;
            mic_k_samples_cut_off_from_beginning_per_chirp_seq[mic][i] = max(offsets[mic], 0);

            melody = findmelody(seq, min_peak_thresh; melody_kwargs...);
            melody = smoothmelody(melody);
            melody_khz = fftindextofrequency.(melody, 256) ./ 1000;
            
            chirp_start, chirp_end = estimatechirpbounds(seq, melody, min_peak_thresh; chirp_bound_kwargs...);
            real_start_idx = seq.start_idx - offsets[mic];
            vocalization_time += getvocalizationtimems(real_start_idx, mic, centroids, mic_positions) / n_mics_this_seq;
            chirp_start -= min(0, offsets[mic]);
            
            
            len = chirp_end - chirp_start + 1;
            mic_k_melody_kHz_per_chirp_seq[mic][1:len, i] = melody_khz[chirp_start:chirp_end];
            mic_k_chirp_lengths[mic][i] = len;

            mic_k_estimated_chirp_per_chirp_seq[mic][1:len, i] = seq.mic_data[chirp_start:chirp_end];
        end
        highest_snr_estimated_chirp_per_chirp_seq[:, i] = mic_k_estimated_chirp_per_chirp_seq[max_snr_mic][:, i];
        highest_snr_chirp_length_per_chirp_seq[i] = mic_k_chirp_lengths[max_snr_mic][i];
        highest_snr_melody_kHz_per_chirp_seq[:, i] = mic_k_melody_kHz_per_chirp_seq[max_snr_mic][:, i];

        updated_vocalization_times[i] = vocalization_time;
    end

    save_filename = (@sprintf  "%s/%s_chirps_and_melodies.mat" SAVE_DIR DATASET_NAME);
    save_file = matopen(save_filename, "w");
    write(save_file, "valid_mics", valid_mics);
    write(save_file, "highest_snr_estimated_chirp_per_chirp_seq", highest_snr_estimated_chirp_per_chirp_seq);
    write(save_file, "highest_snr_chirp_length_per_chirp_seq", highest_snr_chirp_length_per_chirp_seq);
    write(save_file, "highest_snr_melody_kHz_per_chirp_seq", highest_snr_melody_kHz_per_chirp_seq);
    write(save_file, "updated_vocalization_times", updated_vocalization_times);
    
    for k=1:num_mics
        write(save_file, (@sprintf "mic_%d_melody_kHz_per_chirp_seq" k), mic_k_melody_kHz_per_chirp_seq[k]);
        write(save_file, (@sprintf "mic_%d_estimated_chirp_per_chirp_seq" k), mic_k_estimated_chirp_per_chirp_seq[k]);
        write(save_file, (@sprintf "mic_%d_chirp_lengths" k), mic_k_chirp_lengths[k]);
        write(save_file, (@sprintf "mic_%d_samples_cut_off_from_beginning_per_chirp_seq" k), mic_k_samples_cut_off_from_beginning_per_chirp_seq[k]);
    end
    close(save_file);
end