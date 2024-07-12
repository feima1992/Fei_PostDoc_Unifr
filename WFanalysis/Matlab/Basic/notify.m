function notify(title, content)
    % notification send through Bark (ios app)
    webread(['https://api.day.app/ysG3uSm555rYsXRfV7Ayr7/', title, '/', content]);
end
