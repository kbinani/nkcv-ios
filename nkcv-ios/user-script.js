class NKCV {
    mute() {
        if (!Howler) {
            return;
        }
        Howler.mute(true);
    }

    unmute() {
        if (!Howler) {
            return;
        }
        Howler.mute(false);
    }

    injectApiHook() {
        axios.interceptors.response.use((response) => {
            const data = {
                url: response.config.url,
                response: response.data,
                request: response.config.data
            };
            this.onGameApiResponse(data);
            return response;
        }, (error) => {
            return Promise.reject(error);
        });
    }

    onGameApiResponse(data) {
        window.webkit.messageHandlers.onGameApiResponse.postMessage(data);
    }

    debug(data) {
        window.webkit.messageHandlers.debug.postMessage(data);
    }
}

window.nkcv = new NKCV();
