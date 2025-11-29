import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: String,
    type: String,
    duration: { type: Number, default: 5000 }
  }

  connect() {
    if (this.hasMessageValue && this.messageValue) {
      this.show()
    }

    this.boundShowCustomToast = this.showCustomToast.bind(this)
    window.addEventListener('show-toast', this.boundShowCustomToast)
  }

  disconnect() {
    window.removeEventListener('show-toast', this.boundShowCustomToast)
  }

  showCustomToast(event) {
    const { type, title, message, link_url, link_text, icon } = event.detail
    const toast = this.createCustomToast(title, message, link_url, link_text, type || 'notice', icon)
    this.element.appendChild(toast)

    setTimeout(() => {
      toast.classList.remove('translate-x-full', 'opacity-0')
      toast.classList.add('translate-x-0', 'opacity-100')
    }, 100)

    setTimeout(() => {
      this.dismiss(toast)
    }, 15000)
  }

  show() {
    const toast = this.createToast(this.messageValue, this.typeValue)
    this.element.appendChild(toast)

    // Trigger animation
    setTimeout(() => {
      toast.classList.remove('translate-x-full', 'opacity-0')
      toast.classList.add('translate-x-0', 'opacity-100')
    }, 100)

    // Auto dismiss
    setTimeout(() => {
      this.dismiss(toast)
    }, this.durationValue)
  }

  dismiss(toast) {
    toast.classList.remove('translate-x-0', 'opacity-100')
    toast.classList.add('translate-x-full', 'opacity-0')
    
    setTimeout(() => {
      toast.remove()
    }, 300)
  }

  createToast(message, type) {
    const toast = document.createElement('div')
    toast.className = 'transform transition-all duration-300 ease-in-out translate-x-full opacity-0 mb-4 max-w-md w-full'

    const config = this.getToastConfig(type)

    toast.innerHTML = `
      <div class="${config.bgClass} ${config.borderClass} border-l-4 rounded-lg shadow-lg p-4 flex items-start">
        <div class="flex-shrink-0">
          ${config.icon}
        </div>
        <div class="ml-3 flex-1">
          <p class="${config.textClass} font-medium">${message}</p>
        </div>
        <button
          type="button"
          class="ml-4 flex-shrink-0 inline-flex text-gray-400 hover:text-gray-600 focus:outline-none transition-colors"
          data-action="click->toast#dismissButton"
        >
          <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
          </svg>
        </button>
      </div>
    `

    return toast
  }

  createCustomToast(title, message, link_url, link_text, type, customIcon) {
    const toast = document.createElement('div')
    toast.className = 'transform transition-all duration-300 ease-in-out translate-x-full opacity-0 mb-4 max-w-md w-full'

    const config = this.getToastConfig(type)
    const iconSvg = customIcon ? this.getCustomIcon(customIcon) : config.icon

    const linkButton = link_url ? `
      <a href="${link_url}" class="mt-3 block w-full text-center bg-white hover:bg-gray-50 text-success-dark font-semibold px-4 py-2 rounded-lg transition-colors shadow-sm border border-success">
        ${link_text || 'View'}
      </a>
    ` : ''

    toast.innerHTML = `
      <div class="${config.bgClass} ${config.borderClass} border-l-4 rounded-lg shadow-lg p-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            ${iconSvg}
          </div>
          <div class="ml-3 flex-1">
            <p class="${config.textClass} font-bold text-base mb-1">${title}</p>
            ${message ? `<p class="${config.textClass} text-sm opacity-90 mb-2">${message}</p>` : ''}
            ${linkButton}
          </div>
          <button
            type="button"
            class="ml-4 flex-shrink-0 inline-flex text-gray-400 hover:text-gray-600 focus:outline-none transition-colors"
            data-action="click->toast#dismissButton"
          >
            <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
            </svg>
          </button>
        </div>
      </div>
    `

    return toast
  }

  dismissButton(event) {
    const toast = event.currentTarget.closest('.transform')
    this.dismiss(toast)
  }

  getToastConfig(type) {
    const configs = {
      success: {
        bgClass: 'bg-success-bg-light',
        borderClass: 'border-success',
        textClass: 'text-success-dark',
        icon: `
          <svg class="h-6 w-6 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        `
      },
      notice: {
        bgClass: 'bg-success-bg-light',
        borderClass: 'border-success',
        textClass: 'text-success-dark',
        icon: `
          <svg class="h-6 w-6 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        `
      },
      alert: {
        bgClass: 'bg-error-bg-light',
        borderClass: 'border-error',
        textClass: 'text-error-dark',
        icon: `
          <svg class="h-6 w-6 text-error" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        `
      },
      warning: {
        bgClass: 'bg-warning-bg-light',
        borderClass: 'border-warning',
        textClass: 'text-warning-dark',
        icon: `
          <svg class="h-6 w-6 text-warning" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
          </svg>
        `
      },
      info: {
        bgClass: 'bg-info-bg-light',
        borderClass: 'border-info',
        textClass: 'text-info-dark',
        icon: `
          <svg class="h-6 w-6 text-info" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
          </svg>
        `
      }
    }
    
    return configs[type] || configs.notice
  }

  getCustomIcon(iconName) {
    const icons = {
      video: `
        <svg class="h-6 w-6 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"/>
        </svg>
      `,
      star: `
        <svg class="h-6 w-6 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z"/>
        </svg>
      `,
      check: `
        <svg class="h-6 w-6 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
      `,
      'trending-up': `
        <svg class="h-6 w-6 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"/>
        </svg>
      `,
      book: `
        <svg class="h-6 w-6 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
        </svg>
      `
    }

    return icons[iconName] || icons.check
  }
}
