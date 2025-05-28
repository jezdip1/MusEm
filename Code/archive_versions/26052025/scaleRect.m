%% ====== pomocník – přepočítá recty z image‑coords do screen‑coords ====
function rectScr = scaleRect(imgRect, imgW, imgH, outW, outH, left, top)
scaleX = outW / imgW;
scaleY = outH / imgH;
rectScr = [ imgRect(1)*scaleX + left , imgRect(2)*scaleY + top , ...
            imgRect(3)*scaleX + left , imgRect(4)*scaleY + top ];
end
