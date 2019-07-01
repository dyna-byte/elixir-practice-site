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

    postButton.addEventListener("click", e => {
      const payload = {
        body: msgInput.value,
        at: Player.getCurrentTime()
      };

      videoChannel.push("new_annotation", payload)
      .receive("error", e => console.error(e));
      
      msgInput.value = "";
    });

    videoChannel.on("new_annotation", (resp) => {
      this.renderAnnotation(msgContainer, resp);
    });

    videoChannel.join()
      .receive("ok", ({annotations}) => {
        annotations && annotations.forEach(ann => this.renderAnnotation(msgContainer, ann))
        console.log("joined the channel");
      }).receive("error", reason => console.error("failed to join channel", reason))
  },

  renderAnnotation(msgcontainer, {user, body, at}) {
    const template = document.createElement("div");

    template.innerHTML = `
    <a href="#" data-seek="${escape(at)}">
      <strong>${escape(user.username)}</strong>: ${escape(body)}
    </a>`;

    msgcontainer.appendChild(template);
    msgcontainer.scrollTop = msgcontainer.scrollHeight;
  }
}

function escape(str) {
  const div = document.createElement("div");
  div.appendChild(document.createTextNode(str))
  return div.innerHTML;
}

export default Video