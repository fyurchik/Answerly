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

  dismissButton(event) {
    const toast = event.currentTarget.closest('.transform')
    this.dismiss(toast)
  }

  getToastConfig(type) {
    const configs = {
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
}

