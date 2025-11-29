import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = {
    userId: Number
  }

  connect() {
    this.subscription = consumer.subscriptions.create(
      { channel: "UserChannel" },
      {
        connected: this.connected.bind(this),
        disconnected: this.disconnected.bind(this),
        received: this.received.bind(this)
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  connected() {
    // Channel connected
  }

  disconnected() {
    // Channel disconnected
  }

  received(data) {
    if (data.type === 'videos_ready' || data.type === 'feedback_ready') {
      this.showNotification(data)
    }
  }

  showNotification(data) {
    const event = new CustomEvent('show-toast', {
      detail: {
        type: 'success',
        title: data.title,
        message: data.message,
        link_url: data.link_url,
        link_text: data.link_text,
        icon: data.icon
      }
    })
    window.dispatchEvent(event)
  }
}
