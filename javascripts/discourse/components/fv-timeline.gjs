import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { htmlSafe } from "@ember/template";

export default class FvTimeline extends Component {
  @service fvData;

  @tracked entries = [];
  @tracked currentIndex = -1;
  @tracked previewEntry = null;
  @tracked loaded = false;

  constructor() {
    super(...arguments);
    this.loadData();
  }

  async loadData() {
    await this.fvData.loadEntries();
    this.entries = this.fvData.allEntries;
    this.loaded = true;
  }

  get hasEntries() {
    return this.entries.length > 0;
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

  get dateRange() {
    if (!this.hasEntries) return "";
    const s = this.fvData.monthNamesShort;
    return `${s[this.minDate.getMonth()]} ${this.minDate.getFullYear()}  —  ${s[this.maxDate.getMonth()]} ${this.maxDate.getFullYear()}`;
  }

  get todayStyle() {
    return htmlSafe(`left: ${this.pct(this.today)}%`);
  }

  get dots() {
    return this.entries.map((entry, idx) => ({
      entry,
      idx,
      style: htmlSafe(`left: ${this.pct(new Date(entry.memoryDate + "T12:00:00"))}%`),
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
      typeStyle: htmlSafe(`color: ${isCapsule ? "#7C6BC4" : "#E8A040"}`),
      title: e.title,
      date: this.fvData.formatDateLong(new Date(e.memoryDate + "T12:00:00")),
      url: `/t/${e.slug}/${e.id}`,
    };
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
    this.selectDot(this.currentIndex < 0 ? 0 : Math.min(this.currentIndex + 1, this.entries.length - 1));
  }

  <template>
    {{#if this.hasEntries}}
      <div class="fv-timeline-wrap">
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
              <div class="fv-tl-today" style={{this.todayStyle}}>
                <span class="fv-tl-today-label">TODAY</span>
              </div>
              {{#each this.dots as |dot|}}
                <div
                  class="fv-tl-dot {{if dot.isCapsule 'fv-tl-dot--capsule'}} {{if dot.isActive 'fv-tl-dot--active'}}"
                  style={{dot.style}}
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
                <span class="fv-tl-card-type" style={{this.previewCard.typeStyle}}>{{this.previewCard.type}}</span>
                <span class="fv-tl-card-title">{{this.previewCard.title}}</span>
                <span class="fv-tl-card-date">{{this.previewCard.date}}</span>
              </div>
              <a class="fv-tl-card-open" href={{this.previewCard.url}}>Open</a>
            </div>
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
