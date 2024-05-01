function imshowFrameRefBregma(frameData)
    pix2mm_X = 18;
    h = imshow(frameData,[], 'Colormap', fire(256));
    set(h, 'AlphaData', frameData > 0)
    set(gca,...
        'Visible', 'on',...
        'Box', 'off',...
        'TickDir', 'out',...
        'XTick', 256 - (4000:-500:0) / pix2mm_X,...
        'XTickLabel', -4:0.5:0, ...
        'YTick', 256 + (-3000:500:3000) / pix2mm_X,...
        'YTickLabel', 3:-0.5:-3,...
        'XLim', 256 - [4000 -500] / pix2mm_X,...
        'YLim', 256 + [-2000 2000] / pix2mm_X,...
        'XGrid', 'on',...
        'YGrid', 'on')
    hold on
    plot(256, 256, 'o', 'MarkerSize', 12, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'k')
    hold off
    xlabel('ML(mm)'); ylabel('AP(mm)')
end