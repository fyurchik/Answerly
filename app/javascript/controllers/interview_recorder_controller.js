import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "questionVideo",
    "webcamPreview",
    "recordingIndicator",
    "statusMessage",
    "recordingTimer"
  ]

  static values = {
    questionId: Number,
    sessionId: Number,
    hasNext: Boolean,
    silenceDuration: { type: Number, default: 7000 },
    nextQuestionDelay: { type: Number, default: 3000 }
  }

  connect() {
    this.mediaRecorder = null
    this.recordedChunks = []
    this.stream = null
    this.silenceTimeout = null
    this.recordingStartTime = null
    this.timerInterval = null
    
    this.initializeWebcam()
  }

  disconnect() {
    this.cleanup()
  }

  async initializeWebcam() {
    try {
      this.stream = await navigator.mediaDevices.getUserMedia({
        video: true,
        audio: true
      })

      this.webcamPreviewTarget.srcObject = this.stream
      this.updateStatus('Ready! Watch the question video.')

      // Auto-play question video
      if (this.hasQuestionVideoTarget) {
        this.questionVideoTarget.play()
        this.questionVideoTarget.addEventListener('ended', () => this.startRecording())
      }
    } catch (error) {
      console.error('Error accessing webcam:', error)
      this.updateStatus('Error: Could not access webcam. Please allow camera permissions.')
    }
  }

  get hasQuestionVideoTarget() {
    return this.element.querySelector('[data-interview-recorder-target="questionVideo"]') !== null
  }

  get hasStatusMessageTarget() {
    return this.element.querySelector('[data-interview-recorder-target="statusMessage"]') !== null
  }

  startRecording() {
    try {
      this.recordedChunks = []
      this.mediaRecorder = new MediaRecorder(this.stream, {
        mimeType: 'video/webm;codecs=vp9'
      })

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.recordedChunks.push(event.data)
        }
      }

      this.mediaRecorder.onstop = () => this.handleRecordingStop()

      this.mediaRecorder.start()
      this.recordingStartTime = Date.now()
      this.showRecordingUI()
      this.startTimer()
      this.startSilenceDetection()

      this.updateStatus('Recording your answer...')
    } catch (error) {
      this.updateStatus('Error starting recording. Please try again.')
    }
  }

  stopRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      this.mediaRecorder.stop()
      this.clearSilenceTimeout()
      this.stopTimer()
    }
  }

  startSilenceDetection() {
    this.silenceTimeout = setTimeout(() => {
      this.stopRecording()
    }, this.silenceDurationValue)
  }

  clearSilenceTimeout() {
    if (this.silenceTimeout) {
      clearTimeout(this.silenceTimeout)
      this.silenceTimeout = null
    }
  }

  startTimer() {
    this.timerInterval = setInterval(() => {
      const elapsed = Math.floor((Date.now() - this.recordingStartTime) / 1000)
      const minutes = Math.floor(elapsed / 60)
      const seconds = elapsed % 60
      this.recordingTimerTarget.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`
    }, 1000)
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
      this.timerInterval = null
    }
  }

  showRecordingUI() {
    this.recordingIndicatorTarget.classList.remove('hidden')
  }

  hideRecordingUI() {
    this.recordingIndicatorTarget.classList.add('hidden')
  }

  async handleRecordingStop() {
    this.hideRecordingUI()
    this.updateStatus('Saving your answer...')

    const blob = new Blob(this.recordedChunks, { type: 'video/webm' })
    await this.uploadAnswer(blob)
  }

  async uploadAnswer(blob) {
    const formData = new FormData()
    formData.append('video', blob, 'answer.webm')
    formData.append('question_id', this.questionIdValue)

    try {
      const response = await fetch(`/interview_sessions/${this.sessionIdValue}/interview/save_answer`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: formData
      })

      const data = await response.json()

      if (data.success) {
        this.updateStatus('Answer saved! Moving to next question...')
        await this.moveToNextQuestion()
      } else {
        this.updateStatus('Error saving answer. Please try again.')
      }
    } catch (error) {
      this.updateStatus('Error uploading answer. Please try again.')
    }
  }

  async moveToNextQuestion() {
    this.updateStatus(`Answer saved! Moving to next question in ${this.nextQuestionDelayValue / 1000} seconds...`)

    await new Promise(resolve => setTimeout(resolve, this.nextQuestionDelayValue))

    try {
      const response = await fetch(`/interview_sessions/${this.sessionIdValue}/interview/next_question`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ question_id: this.questionIdValue })
      })

      const data = await response.json()

      if (data.has_next) {
        window.location.href = `/interview_sessions/${this.sessionIdValue}/interview?question_id=${data.next_question_id}`
      } else {
        window.location.href = data.redirect_url
      }
    } catch (error) {
      this.updateStatus('Error moving to next question. Please refresh the page.')
    }
  }

  updateStatus(message) {
    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.innerHTML = `<p class="text-body-color">${message}</p>`
    }
  }

  pauseAndExit() {
    if (confirm('Are you sure you want to pause the interview? You can resume later from where you left off.')) {
      this.cleanup()
      window.location.href = `/interview_sessions/${this.sessionIdValue}`
    }
  }

  cleanup() {
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
    }
    this.clearSilenceTimeout()
    this.stopTimer()
  }
}

