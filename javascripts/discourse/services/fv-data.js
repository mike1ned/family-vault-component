import Service from "@ember/service";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";

const MEMORIES_CATEGORY_ID = 53; // The Past
const CAPSULES_CATEGORY_ID = 55; // The Future
const TIMELINE_CATEGORY_ID = 54; // The Present
const CACHE_TTL = 5 * 60 * 1000; // 5 min

export default class FvDataService extends Service {
  @service currentUser;
  @service siteSettings;

  @tracked allEntries = [];
  @tracked myEntries = [];
  @tracked loading = false;

  _cache = null;
  _cacheTime = 0;

  get memoriesCategoryId() { return MEMORIES_CATEGORY_ID; }
  get capsulesCategoryId() { return CAPSULES_CATEGORY_ID; }
  get timelineCategoryId() { return TIMELINE_CATEGORY_ID; }

  get categoryIds() {
    return [MEMORIES_CATEGORY_ID, CAPSULES_CATEGORY_ID, TIMELINE_CATEGORY_ID];
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute("content") : "";
  }

  async fetchCategoryTopics(catId) {
    try {
      const res = await fetch(`/c/${catId}.json`, {
        headers: { "X-CSRF-Token": this.csrfToken() },
      });
      const data = await res.json();
      if (!data.topic_list?.topics) return [];
      return data.topic_list.topics
        .filter((t) => t.memory_date)
        .map((t) => ({
          id: t.id,
          slug: t.slug,
          title: t.title,
          categoryId: catId,
          excerpt: t.excerpt || "",
          memoryDate: t.memory_date,
          memoryType: t.memory_type || "other",
          userId: t.posters?.[0]?.user_id,
        }));
    } catch {
      return [];
    }
  }

  async loadEntries(force = false) {
    if (!force && this._cache && Date.now() - this._cacheTime < CACHE_TTL) {
      return this._cache;
    }

    this.loading = true;
    const results = await Promise.all(
      this.categoryIds.map((id) => this.fetchCategoryTopics(id))
    );
    const all = results.flat();
    all.sort((a, b) => new Date(a.memoryDate) - new Date(b.memoryDate));

    this.allEntries = all;
    this._cache = all;
    this._cacheTime = Date.now();

    if (this.currentUser) {
      this.myEntries = all.filter(
        (e) => e.userId === this.currentUser.id
      );
    }

    this.loading = false;
    return all;
  }

  typeIcon(type) {
    const icons = {
      story: "\uD83C\uDFE0",
      milestone: "\uD83C\uDFC6",
      photo: "\uD83D\uDCF7",
      letter: "\u2709\uFE0F",
      recipe: "\uD83C\uDF73",
      tradition: "\uD83C\uDF89",
    };
    return icons[type] || "\uD83D\uDCDD";
  }

  formatDateLong(d) {
    const days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
    const months = ["January","February","March","April","May","June","July","August","September","October","November","December"];
    return `${days[d.getDay()]}, ${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}`;
  }

  get monthNamesShort() {
    return ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
  }
}
