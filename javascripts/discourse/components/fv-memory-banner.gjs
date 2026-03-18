import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";

export default class FvMemoryBanner extends Component {
  @service fvData;
  @service router;

  @tracked memoryDate = null;
  @tracked memoryType = null;
  @tracked isPast = false;
  @tracked isFuture = false;

  get topicId() {
    const match = this.router.currentURL?.match(/\/t\/[^/]+\/(\d+)/);
    return match ? match[1] : null;
  }

  get hasBanner() {
    return !!this.memoryDate;
  }

  get formattedDate() {
    if (!this.memoryDate) return "";
    return this.fvData.formatDateLong(new Date(this.memoryDate + "T12:00:00"));
  }

  get icon() {
    return this.fvData.typeIcon(this.memoryType);
  }

  get label() {
    return this.memoryType || "Memory";
  }

  get bannerClass() {
    if (this.isFuture) return "fv-banner--future";
    if (this.isPast) return "fv-banner--past";
    return "fv-banner--today";
  }

  @action
  async setup() {
    if (!this.topicId) return;
    try {
      const res = await fetch(`/t/${this.topicId}.json`);
      const data = await res.json();
      if (!data.memory_date) return;
      this.memoryDate = data.memory_date;
      this.memoryType = data.memory_type || "other";
      const d = new Date(data.memory_date + "T12:00:00");
      const today = new Date();
      today.setHours(12, 0, 0, 0);
      this.isPast = d < today;
      this.isFuture = d > today;
    } catch { /* silent */ }
  }

  <template>
    <div {{didInsert this.setup}}>
      {{#if this.hasBanner}}
        <div class="fv-memory-banner {{this.bannerClass}}">
          <span class="fv-banner-icon">{{this.icon}}</span>
          <span class="fv-banner-label">{{this.label}}</span>
          <span class="fv-banner-date">{{this.formattedDate}}</span>
        </div>
      {{/if}}
    </div>
  </template>
}
