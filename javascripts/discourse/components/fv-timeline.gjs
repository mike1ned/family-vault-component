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

  // Always read entries from the service — no stale copy
  get entries() {
    return this.fvData.allEntries;
  }

  get entryCount() {
    return this.entries.length;
  }

  get hasEntries() {
    return this.entryCount > 0;
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

  get todayPct() {
    return this.pct(this.today);
  }

  get todayStyle() {
    return htmlSafe(`left: ${this.todayPct}%`);
  }

  // Green selector dot position — on today or on the selected entry
  get selectorStyle() {
    const idx = this.selectedIndex;
    const count = this.entryCount;
    if (idx < 0 || idx >= count) {
      return htmlSafe(`left: ${this.todayPct}%`);
    }
    const d = new Date(this.entries[idx].memoryDate + "T12:00:00");
    return htmlSafe(`left: ${this.pct(d)}%`);
  }

  get isOnToday() {
    return this.selectedIndex < 0;
  }

  get dots() {
    return this.entries.map((entry, idx) => ({
      entry,
      idx,
      style: htmlSafe(`left: ${this.pct(new Date(entry.memoryDate + "T12:00:00"))}%`),
      isCapsule: entry.categoryId === this.fvData.capsulesCategoryId,
    }));
  }

  get previewCard() {
    const idx = this.selectedIndex;
    const count = this.entryCount;
    if (idx < 0 || idx >= count) return null;
    const e = this.entries[idx];
    const isCapsule = e.categoryId === this.fvData.capsulesCategoryId;
    return {
      type: isCapsule ? "\u23F3 Time Capsule" : this.fvData.typeIcon(e.memoryType) + " " + (e.memoryType || "Memory"),
      typeStyle: htmlSafe(`color: ${isCapsule ? "#7C6BC4" : "#E8A040"}`),
      title: e.title,
      date: this.fvData.formatDateLong(new Date(e.memoryDate + "T12:00:00")),
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
    const count = this.entryCount;
    if (count === 0) return;
    // Clamp idx to valid range
    const clamped = Math.max(0, Math.min(idx, count - 1));
    this.selectedIndex = clamped;
    this._startResetTimer();
  }

  @action
  prevDot() {
    if (this.selectedIndex <= 0) {
      // If on today (-1) or first entry (0), go to first entry
      this.selectDot(0);
    } else {
      this.selectDot(this.selectedIndex - 1);
    }
  }

  @action
  nextDot() {
    const count = this.entryCount;
    if (this.selectedIndex < 0) {
      // On today — go to first entry
      this.selectDot(0);
    } else if (this.selectedIndex < count - 1) {
      this.selectDot(this.selectedIndex + 1);
    }
    // If already at last entry, do nothing
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
              {{!-- Today marker line --}}
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
