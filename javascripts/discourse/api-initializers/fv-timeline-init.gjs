import { apiInitializer } from "discourse/lib/api";
import FvTimeline from "../components/fv-timeline";

export default apiInitializer("1.0", (api) => {
  api.renderInOutlet("above-main-container", FvTimeline);
});
