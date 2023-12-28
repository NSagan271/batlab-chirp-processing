function collectchirpsequences(y::AbstractArray, centroids::Matrix, mic_positions::Matrix; 
        vocalization_start_tolerance_ms=1.5, single_mic_snr_thresh=75, any_mic_snr_thresh=45, high_snr_region_keyword_arguments...)
    y, snr, chirp_seq_idxs_per_mic = collecthighsnrregions(y; high_snr_region_keyword_arguments...);
    chirp_sequences, vocalization_times = 
        groupchirpsequencesbystarttime(chirp_seq_idxs_per_mic, snr, y, centroids,
            mic_positions, single_mic_snr_thresh=single_mic_snr_thresh,
            vocalization_start_tolerance_ms=vocalization_start_tolerance_ms,
            any_mic_snr_thresh=any_mic_snr_thresh);
    return chirp_sequences, vocalization_times;
end

function savechirpsequences(y::AbstractArray, centroids::Matrix, mic_positions::Matrix, name::String, save_dir::String; keyword_arguments...)
    chirp_sequences, vocalization_times = collectchirpsequences(y, centroids, mic_positions; keyword_arguments...);
    num_seqs = length(chirp_sequences);

    max_seq_len = 0;
    for chirp_seq_all_mics = chirp_sequences
        for seq=values(chirp_seq_all_mics)
            max_seq_len = max(max_seq_len, seq.length);
        end
    end

    num_mics = size(y, 2);
    mic_k_data_per_chirp_seq = Vector(undef, num_mics);
    mic_k_snr_data_per_chirp_seq = Vector(undef, num_mics);
    mic_k_chirp_seq_lengths = Vector(undef, num_mics);
    for k=1:num_mics
        mic_k_data_per_chirp_seq[k] = zeros(max_seq_len, num_seqs);
        mic_k_snr_data_per_chirp_seq[k] = zeros(max_seq_len, num_seqs);
        mic_k_chirp_seq_lengths[k] = zeros(Int64, num_seqs);
    end

    valid_mics = zeros(Bool, num_mics, num_seqs);

    for (i, chirp_seq_all_mics) = enumerate(chirp_sequences)
        for mic_seq_pair=chirp_seq_all_mics
            mic = mic_seq_pair.first;
            seq = mic_seq_pair.second;
            len = seq.length;

            valid_mics[mic, i] = true;
            mic_k_chirp_seq_lengths[mic][i] = len;
            mic_k_data_per_chirp_seq[mic][1:len, i] = seq.mic_data;
            mic_k_snr_data_per_chirp_seq[mic][1:len, i] = seq.snr_data;
        end
    end

    save_filename = (@sprintf  "%s/%s_chirp_sequences.mat" SAVE_DIR DATASET_NAME);
    save_file = matopen(save_filename, "w");
    write(save_file, "vocalization_times", vocalization_times);
    write(save_file, "valid_mics", valid_mics);
    for k=1:num_mics
        write(save_file, (@sprintf "mic_%d_data_per_chirp_seq" k), mic_k_data_per_chirp_seq[k]);
        write(save_file, (@sprintf "mic_%d_snr_data_per_chirp_seq" k), mic_k_snr_data_per_chirp_seq[k]);
        write(save_file, (@sprintf "mic_%d_chirp_seq_lengths" k), mic_k_chirp_seq_lengths[k]);
    end
    close(save_file);
end