import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { on } from "@ember/modifier";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";

export default class FvTimeline extends Component {
  @service fvData;
  @service router;

  @tracked entries = [];
  @tracked currentIndex = -1;
  @tracked previewEntry = null;
  @tracked loaded = false;

  get hasEntries() {
    return this.entries.length > 0;
  }

  get dateRange() {
    if (!this.hasEntries) return "";
    const s = this.fvData.monthNamesShort;
    return `${s[this.minDate.getMonth()]} ${this.minDate.getFullYear()}  —  ${s[this.maxDate.getMonth()]} ${this.maxDate.getFullYear()}`;
  }

  get today() {
    const d = new Date();
    d.setHours(12, 0, 0, 0);
    return d;
  }

  get minDate() {
    const dates = this.entries.map((e) => new Date(e.memoryDate + "T12:00:00"));
    const min = new Date(Math.min(...dates, this.today));
    min.setDate(min.getDate() - 30);
    return min;
  }

  get maxDate() {
    const span = this.today.getTime() - this.minDate.getTime();
    return new Date(this.today.getTime() + Math.max(span * 0.11, 90 * 86400000));
  }

  get totalMs() {
    return this.maxDate.getTime() - this.minDate.getTime();
  }

  pct(d) {
    return ((d.getTime() - this.minDate.getTime()) / this.totalMs) * 100;
  }

  get todayPct() {
    return this.pct(this.today);
  }

  get dots() {
    return this.entries.map((entry, idx) => ({
      entry,
      idx,
      left: this.pct(new Date(entry.memoryDate + "T12:00:00")),
      isCapsule: entry.categoryId === this.fvData.capsulesCategoryId,
      isActive: idx === this.currentIndex,
    }));
  }

  get previewCard() {
    if (!this.previewEntry) return null;
    const e = this.previewEntry;
    const isCapsule = e.categoryId === this.fvData.capsulesCategoryId;
    return {
      type: isCapsule ? "\u23F3 Time Capsule" : this.fvData.typeIcon(e.memoryType) + " " + (e.memoryType || "Memory"),
      typeColor: isCapsule ? "#7C6BC4" : "#E8A040",
      title: e.title,
      date: this.fvData.formatDateLong(new Date(e.memoryDate + "T12:00:00")),
      url: `/t/${e.slug}/${e.id}`,
    };
  }

  @action
  async setup() {
    await this.fvData.loadEntries();
    this.entries = this.fvData.allEntries;
    this.loaded = true;
  }

  @action
  selectDot(idx) {
    if (idx < 0 || idx >= this.entries.length) return;
    this.currentIndex = idx;
    this.previewEntry = this.entries[idx];
  }

  @action
  prevDot() {
    this.selectDot(this.currentIndex <= 0 ? 0 : this.currentIndex - 1);
  }

  @action
  nextDot() {
    const next = this.currentIndex < 0 ? 0 : Math.min(this.currentIndex + 1, this.entries.length - 1);
    this.selectDot(next);
  }

  @action
  closePreview() {
    this.currentIndex = -1;
    this.previewEntry = null;
  }

  <template>
    <div class="fv-timeline-wrap" {{didInsert this.setup}} {{on "click" this.stopProp}}>
      {{#if this.hasEntries}}
        <div class="fv-tl-header">
          <span class="fv-tl-title">Timeline</span>
          <span class="fv-tl-range">{{this.dateRange}}</span>
        </div>
        <div class="fv-tl-body">
          <div class="fv-tl-nav">
            <button class="fv-tl-btn" type="button" {{on "click" this.nextDot}}>&#9650;</button>
            <button class="fv-tl-btn" type="button" {{on "click" this.prevDot}}>&#9660;</button>
          </div>
          <div class="fv-tl-line-wrap">
            <div class="fv-tl-line">
              <div class="fv-tl-today" style="left: {{this.todayPct}}%">
                <span class="fv-tl-today-label">TODAY</span>
              </div>
              {{#each this.dots as |dot|}}
                <div
                  class="fv-tl-dot {{if dot.isCapsule 'fv-tl-dot--capsule'}} {{if dot.isActive 'fv-tl-dot--active'}}"
                  style="left: {{dot.left}}%"
                  title={{dot.entry.title}}
                  role="button"
                  {{on "click" (fn this.selectDot dot.idx)}}
                ></div>
              {{/each}}
            </div>
          </div>
        </div>
        {{#if this.previewCard}}
          <div class="fv-tl-preview">
            <div class="fv-tl-card">
              <div class="fv-tl-card-info">
                <span class="fv-tl-card-type" style="color: {{this.previewCard.typeColor}}">{{this.previewCard.type}}</span>
                <span class="fv-tl-card-title">{{this.previewCard.title}}</span>
                <span class="fv-tl-card-date">{{this.previewCard.date}}</span>
              </div>
              <a class="fv-tl-card-open" href={{this.previewCard.url}}>Open</a>
            </div>
          </div>
        {{/if}}
      {{/if}}
    </div>
  </template>
}
