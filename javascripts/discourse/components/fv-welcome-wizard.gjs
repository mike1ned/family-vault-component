import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";

export default class FvWelcomeWizard extends Component {
  @service currentUser;

  @tracked show = false;
  @tracked dobValue = "";
  @tracked saving = false;
  @tracked step = 1; // 1 = welcome, 2 = DOB input

  DOB_FIELD_ID = 7;

  constructor() {
    super(...arguments);
    this.checkIfNeeded();
  }

  async checkIfNeeded() {
    if (!this.currentUser) return;

    try {
      const resp = await fetch(`/u/${this.currentUser.username}.json`);
      const data = await resp.json();
      const fields = data?.user?.user_fields || {};
      const dob = fields[this.DOB_FIELD_ID];

      if (!dob || dob.trim() === "") {
        // Small delay so page loads first
        setTimeout(() => { this.show = true; }, 1200);
      }
    } catch (e) {
      // Silently fail — don't block the user
    }
  }

  @action
  goToStep2() {
    this.step = 2;
  }

  @action
  updateDob(event) {
    this.dobValue = event.target.value;
  }

  @action
  async saveDob() {
    if (!this.dobValue) return;
    this.saving = true;

    try {
      const csrfEl = document.querySelector('meta[name="csrf-token"]');
      const csrf = csrfEl ? csrfEl.getAttribute("content") : "";

      const formData = new FormData();
      formData.append(`user_fields[${this.DOB_FIELD_ID}]`, this.dobValue);

      await fetch(`/u/${this.currentUser.username}.json`, {
        method: "PUT",
        headers: { "X-CSRF-Token": csrf },
        body: formData,
      });

      this.show = false;
    } catch (e) {
      // Allow dismiss even on error
      this.show = false;
    } finally {
      this.saving = false;
    }
  }

  @action
  dismiss() {
    this.show = false;
  }

  <template>
    {{#if this.show}}
      <div class="fv-wizard-overlay" {{on "click" this.dismiss}}>
        <div class="fv-wizard-modal" {{on "click" this.stopProp}}>
          {{#if (this.isStep1)}}
            <div class="fv-wizard-step">
              <div class="fv-wizard-icon">🏠</div>
              <h2 class="fv-wizard-title">Welcome to Family Vault</h2>
              <p class="fv-wizard-text">
                This is your family's private space — a place to collect memories,
                share stories, and build a timeline together.
              </p>
              <p class="fv-wizard-text">
                Before you start, we'd love to know your date of birth so we can
                celebrate with you!
              </p>
              <button class="fv-wizard-btn fv-wizard-btn--primary" type="button" {{on "click" this.goToStep2}}>
                Let's go
              </button>
              <button class="fv-wizard-btn fv-wizard-btn--skip" type="button" {{on "click" this.dismiss}}>
                Skip for now
              </button>
            </div>
          {{else}}
            <div class="fv-wizard-step">
              <div class="fv-wizard-icon">🎂</div>
              <h2 class="fv-wizard-title">When were you born?</h2>
              <p class="fv-wizard-text">
                This helps us place you on the family timeline and celebrate your birthday.
              </p>
              <input
                class="fv-wizard-date"
                type="date"
                value={{this.dobValue}}
                {{on "input" this.updateDob}}
                max="2025-12-31"
                min="1920-01-01"
              />
              <button
                class="fv-wizard-btn fv-wizard-btn--primary"
                type="button"
                disabled={{this.saving}}
                {{on "click" this.saveDob}}
              >
                {{if this.saving "Saving..." "Save & Continue"}}
              </button>
              <button class="fv-wizard-btn fv-wizard-btn--skip" type="button" {{on "click" this.dismiss}}>
                I'll do this later
              </button>
            </div>
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>

  get isStep1() {
    return this.step === 1;
  }

  @action
  stopProp(event) {
    event.stopPropagation();
  }
}
