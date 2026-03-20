import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { htmlSafe } from "@ember/template";

export default class FvTimeline extends Component {
  @service fvData;

  @tracked selectedIndex = -1; // -1 means "on today"
  @tracked loaded = false;
  _resetTimer = null;

  constructor() {
    super(...arguments);
    this.loadData();
  }

  willDestroy() {
    super.willDestroy(...arguments);
    if (this._resetTimer) clearTimeout(this._resetTimer);
  }

  async loadData() {
    await this.fvData.loadEntries();
    this.loaded = true;
  }

  get hasEntries() {
    return this.fvData.allEntries.length > 0;
  }

  get today() {
    const d = new Date();
    d.setHours(12, 0, 0, 0);
    return d;
  }

  get minDate() {
    const entries = this.fvData.allEntries;
    const dates = entries.map((e) => new Date(e.memoryDate + "T12:00:00"));
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

  get todayPct() {
    return this.pct(this.today);
  }

  get todayStyle() {
    return htmlSafe(`left: ${this.todayPct}%`);
  }

  get selectorStyle() {
    const idx = this.selectedIndex;
    const entries = this.fvData.allEntries;
    if (idx < 0 || idx >= entries.length) {
      return htmlSafe(`left: ${this.todayPct}%`);
    }
    const d = new Date(entries[idx].memoryDate + "T12:00:00");
    return htmlSafe(`left: ${this.pct(d)}%`);
  }

  get isOnToday() {
    return this.selectedIndex < 0;
  }

  get dots() {
    return this.fvData.allEntries.map((entry, idx) => ({
      entry,
      idx,
      style: htmlSafe(`left: ${this.pct(new Date(entry.memoryDate + "T12:00:00"))}%`),
      isCapsule: entry.categoryId === this.fvData.capsulesCategoryId,
    }));
  }

  get previewCard() {
    const idx = this.selectedIndex;
    const entries = this.fvData.allEntries;
    if (idx < 0 || idx >= entries.length) return null;
    const e = entries[idx];
    const isCapsule = e.categoryId === this.fvData.capsulesCategoryId;
    // Count how many entries share this date, and which position this one is
    const sameDate = entries.filter((x) => x.memoryDate === e.memoryDate);
    const posInGroup = sameDate.findIndex((x) => x.id === e.id) + 1;
    const groupLabel = sameDate.length > 1 ? ` (${posInGroup} of ${sameDate.length})` : "";
    return {
      type: isCapsule ? "\u23F3 Time Capsule" : this.fvData.typeIcon(e.memoryType) + " " + (e.memoryType || "Memory"),
      typeStyle: htmlSafe(`color: ${isCapsule ? "#7C6BC4" : "#E8A040"}`),
      title: e.title,
      date: this.fvData.formatDateLong(new Date(e.memoryDate + "T12:00:00")) + groupLabel,
      url: `/t/${e.slug}/${e.id}`,
    };
  }

  _startResetTimer() {
    if (this._resetTimer) clearTimeout(this._resetTimer);
    this._resetTimer = setTimeout(() => {
      this.selectedIndex = -1;
    }, 7000);
  }

  @action
  selectDot(idx) {
    const entries = this.fvData.allEntries;
    if (entries.length === 0) return;
    this.selectedIndex = Math.max(0, Math.min(idx, entries.length - 1));
    this._startResetTimer();
  }

  // Single button: TODAY → Date A (1 of 3) → Date A (2 of 3) → Date A (3 of 3) → Date B → ...
  @action
  advanceDot() {
    const entries = this.fvData.allEntries;
    const count = entries.length;
    if (count === 0) return;
    if (this.selectedIndex >= count - 1) {
      // At last entry — wrap back to today
      this.selectedIndex = -1;
      if (this._resetTimer) {
        clearTimeout(this._resetTimer);
        this._resetTimer = null;
      }
    } else {
      // Always advance by exactly one — every entry gets its turn
      this.selectedIndex = this.selectedIndex + 1;
      this._startResetTimer();
    }
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
            <button class="fv-tl-btn" type="button" {{on "click" this.advanceDot}}>&#9654;</button>
          </div>
          <div class="fv-tl-line-wrap">
            <div class="fv-tl-line">
              {{!-- Today marker --}}
              <div class="fv-tl-today" style={{this.todayStyle}}>
                <span class="fv-tl-today-label">TODAY</span>
              </div>
              {{!-- Entry dots (amber/purple) --}}
              {{#each this.dots as |dot|}}
                <div
                  class="fv-tl-dot {{if dot.isCapsule 'fv-tl-dot--capsule'}}"
                  style={{dot.style}}
                  title={{dot.entry.title}}
                  role="button"
                  {{on "click" (fn this.selectDot dot.idx)}}
                ></div>
              {{/each}}
              {{!-- Green selector dot --}}
              <div class="fv-tl-selector {{if this.isOnToday 'fv-tl-selector--today'}}" style={{this.selectorStyle}}></div>
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
