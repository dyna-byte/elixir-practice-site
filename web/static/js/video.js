"use strict"

import Player from "./player";

const Video = {
  init(socket, element) {
    if (!element) return;

    let playerId = element.getAttribute("data-player-id");
    let videoId = element.getAttribute("data-id");

    socket.connect();
    Player.init(element.id, playerId, () => {
      this.onReady(videoId, socket);
    });

  },

  onReady(videoId, socket) {
    const msgContainer = document.getElementById("msg-container");
    const msgInput = document.getElementById("msg-input");
    const postButton = document.getElementById("msg-submit");
    const videoChannel = socket.channel(`videos:${videoId}`);

    videoChannel.join()
      .receive("ok", resp => {
        console.log("joined the channel", resp);
      }).receive("error", reason => console.error("failed to join channel", reason))
  }
}

export default Video