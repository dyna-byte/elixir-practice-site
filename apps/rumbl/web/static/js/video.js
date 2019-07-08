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

    msgContainer.addEventListener("click", e => {
      e.preventDefault();

      const seconds = e.target.getAttribute("data-seek")
        || e.target.parentNode.getAttribute("data-seek");

      if (!seconds) return;

      Player.seekTo(seconds);
    })
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
      videoChannel.params.last_seen_id = resp.id;
      this.renderAnnotation(msgContainer, resp);
    });

    videoChannel.join()
      .receive("ok", (resp) => {
        const { annotations } = resp;
        const ids = annotations.map(a => a.id);
        if (ids.length > 0) videoChannel.params.last_seen_id = Math.max(...ids);

        console.log(videoChannel.params);

        this.scheduleMessages(msgContainer, annotations);
        console.log("joined the channel");
      }).receive("error", reason => console.error("failed to join channel", reason))
  },

  renderAnnotation(msgcontainer, {user, body, at}) {
    const template = document.createElement("div");

    template.innerHTML = `
    <a href="#" data-seek="${escape(at)}">
      [${formatTime(at)}]
      <strong>${escape(user.username)}</strong>: ${escape(body)}
    </a>`;

    msgcontainer.appendChild(template);
    msgcontainer.scrollTop = msgcontainer.scrollHeight;
  },

  scheduleMessages(msgContainer, annotations) {
    setTimeout(() => {
      const ctime = Player.getCurrentTime();
      const remaining = this.renderAtTime(annotations, ctime, msgContainer)
      this.scheduleMessages(msgContainer, remaining);
    }, 1000);
  },

  renderAtTime(annotations, seconds, msgcontainer) {
    return annotations.filter(ann => 
      ann.at > seconds 
      ? true
      : (this.renderAnnotation(msgcontainer, ann) && false)
    );
  }
}

function escape(str) {
  const div = document.createElement("div");
  div.appendChild(document.createTextNode(str))
  return div.innerHTML;
}

function formatTime(at) {
  const date = new Date(null);
  date.setSeconds(at/ 1000);

  return date.toISOString().substr(14,5);
}

export default Video