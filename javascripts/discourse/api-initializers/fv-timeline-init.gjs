import { apiInitializer } from "discourse/lib/api";
import FvTimeline from "../components/fv-timeline";

export default apiInitializer((api) => {
  api.renderInOutlet("above-main-container", FvTimeline);
});
