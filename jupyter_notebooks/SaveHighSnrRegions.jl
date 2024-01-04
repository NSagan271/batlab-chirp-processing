function matreadsorted(filename)
    dict = matread(filename)
    sorted = SortedDict();
    for key=sort(collect(keys(dict)))
        sorted[key] = dict[key];
    end
    return sorted;
end

"""
Given the microphone data, `y`, return the SNR and the onset and offset indices of the high-snr regions.
"""
function collecthighsnrregions(y::AbstractArray; max_signal_length=MAX_SEQUENCE_LENGTH,
        signal_thresh=30, maxfilter_length=25, min_peak_thresh=35, snr_drop_thresh=20,
        peak_snr_thresh_radius=2000, tail_snr_thresh=20, tail_maxfilter_length=50,
        padding=0)
    
    noise_sample_idxs = getnoisesampleidxs(y);
    noise_sample = y[noise_sample_idxs, :];

    y = y .- mean(noise_sample; dims=1);
    noise_sample = noise_sample .- mean(noise_sample; dims=1);

    snr = estimatesnr(y, noise_sample, window_size=128);
    n_mics = size(y, 2);

    # Find the start and end indices of every high-SNR region
    rough_seq_idxs_per_mic = Array{Matrix{Int64}}(undef, n_mics, 1);
    for mic=1:n_mics
        rough_seq_idxs_per_mic[mic] = findhighsnrregionidxs(snr, mic, signal_thresh, min_peak_thresh, maxfilter_length;
                snr_drop_thresh=snr_drop_thresh, peak_snr_thresh_radius=peak_snr_thresh_radius);
    end

    chirp_seq_idxs_per_mic = Array{Matrix{Int64}}(undef, n_mics, 1);
    for mic=1:n_mics
        chirp_seq_idxs_per_mic[mic] = copy(rough_seq_idxs_per_mic[mic]);
    
        N_seqs = size(chirp_seq_idxs_per_mic[mic], 1);
        for row=1:N_seqs
            max_end_idx = (row == N_seqs) ? size(snr, 1) : chirp_seq_idxs_per_mic[mic][row+1, 1];
            chirp_seq_idxs_per_mic[mic][row, :] = 
                    adjusthighsnridxs(snr, mic, rough_seq_idxs_per_mic[mic][row, :],
                        max_end_idx, tail_snr_thresh, maxfilter_length=tail_maxfilter_length,
                        max_seq_len=max_signal_length);
        end
        chirp_seq_idxs_per_mic[mic][:, 1] = max.(chirp_seq_idxs_per_mic[mic][:, 1] .- padding, 1);
        chirp_seq_idxs_per_mic[mic][:, 2] = min.(chirp_seq_idxs_per_mic[mic][:, 2] .+ padding, size(y, 1));
        
    end

    return y, snr, chirp_seq_idxs_per_mic;
end

"""
For a filename like "../data/centroids/hello.mat", returns "hello"
"""
function getnamestem(filename::String, extension=".mat")
    last_slash = findlast(collect(filename) .== '/');
    last_slash = isnothing(last_slash) ? 0 : last_slash;
    return replace(filename[last_slash+1:end], extension => "")
end

"""
Saves high-snr regions to a MAT file, with the following variables:
- `mic_data_per_high_snr_region`: array where each column is a different high-
    SNR region. Zeros are added to the end of each column to make all columns
    the same length.
-`high_snr_region_lengths`: length, in audio samples, of each high-SNR region.
- `high_snr_region_onsets_ms`: time, in milliseconds since the beginning of
    the microphone data, that the high-SNR region starts.
- `snr_data_per_high_snr_region`: SNR of each high-SNR region, in the same
    format as `mic_data_per_high_snr_region`.
"""
function savehighsnrregions(y::AbstractArray, name::String, save_dir::String; keyword_arguments...)
    y, snr, chirp_seq_idxs_per_mic = collecthighsnrregions(y; keyword_arguments...);

    save_filename = (@sprintf  "%s/%s_high_snr_regions.mat" save_dir name);
    save_file = matopen(save_filename, "w");
    for mic=1:length(chirp_seq_idxs_per_mic)
        bounds = chirp_seq_idxs_per_mic[mic];
        if length(bounds) == 0
            continue;
        end
        max_seq_len = maximum(bounds[:, 2] .- bounds[:, 1] .+ 1);
        num_seqs = size(bounds, 1);
    
        chirp_array = zeros(max_seq_len, num_seqs);
        chirp_snrs = zeros(max_seq_len, num_seqs);
    
        for i=1:num_seqs
            len = bounds[i, 2] - bounds[i, 1] + 1;
            chirp_array[1:len, i] = y[bounds[i, 1]:bounds[i, 2], mic];
            chirp_snrs[1:len, i] = snr[bounds[i, 1]:bounds[i, 2], mic];
        end

        write(save_file, (@sprintf "mic_%d_data_per_high_snr_region" mic), chirp_array);
        write(save_file, (@sprintf "mic_%d_high_snr_region_lengths" mic), bounds[:, 2] .- bounds[:, 1] .+ 1);
        write(save_file, (@sprintf "mic_%d_high_snr_region_onsets_ms" mic), audioindextoms.(bounds[:, 1]));
        write(save_file, (@sprintf "mic_%d_snr_data_per_high_snr_region" mic), chirp_snrs);
    end
    close(save_file);
end