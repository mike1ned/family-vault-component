import Component from "@glimmer/component";
import { action } from "@ember/object";
import { on } from "@ember/modifier";

// The Memory Creator is a complex multi-step modal with calendar, upload, etc.
// For now it calls the existing global showModal() from the head_tag script.
// Full Glimmer migration planned for v2.
export default class FvMemoryCreator extends Component {
  @action
  openCreator() {
    if (typeof window.showFvMemoryCreator === "function") {
      window.showFvMemoryCreator();
    }
  }

  <template>
    <button class="fv-create-btn" type="button" {{on "click" this.openCreator}}>
      + Create Memory
    </button>
  </template>
}
