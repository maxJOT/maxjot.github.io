/**
 * dynamic_sidebar.js
 *
 * Purpose:
 *  Dynamically shifts the content iframe (.wm-article) when the sidebar
 *  (.wm-toc-pane) expands/collapses or is hidden/shown.
 *  Ensures content does not overlap sidebar and maintains alignment.
 *
 * Features:
 *  - Observes sidebar TOC expansion/collapse using MutationObserver
 *  - Reacts to TOC arrow clicks
 *  - Adjusts for existing padding of content pane
 *  - Works with hide/show sidebar button
 *  - Handles window resize
 *  - Compatible with default Windmill layout when JS is disabled
 *
 * Usage:
 *  Include this file in mkdocs.yml under extra_javascript:
 *    extra_javascript:
 *      - js/dynamic_sidebar.js
 *
 * Author: maxJOT
 * Version: 1.0
 * Date: 2025-12-12
 */

document.addEventListener("DOMContentLoaded", () => {
    const toc = document.querySelector(".wm-toc-pane");      // Sidebar
    const iframe = document.querySelector(".wm-article");    // Content iframe
    const body = document.body;

    if (!toc || !iframe) return;

    let resizeTimeout = null;

    // Main update function
    const updateLayout = () => {
        // If sidebar is hidden, reset margin so CSS handles default layout
        if (body.classList.contains("wm-toc-hidden")) {
            iframe.style.marginLeft = "";
            return;
        }

        // Get current sidebar width (including expanded subsections)
        const width = toc.getBoundingClientRect().width;

        // Get default padding-left of the content pane
        const contentPane = iframe.parentElement; // .wm-content-pane
        const style = window.getComputedStyle(contentPane);
        const defaultPadding = parseInt(style.paddingLeft) || 0;

        // Set margin-left = sidebar width minus default padding
        iframe.style.marginLeft = (width - defaultPadding) + "px";
    };

    // Schedule update with a small delay to avoid excessive recalculations
    const scheduleUpdate = (delay = 50) => {
        clearTimeout(resizeTimeout);
        resizeTimeout = setTimeout(updateLayout, delay);
    };

    // Initial layout
    scheduleUpdate();

    // Observe sidebar DOM changes (expanding/collapsing TOC items)
    const tocObserver = new MutationObserver(scheduleUpdate);
    tocObserver.observe(toc, { attributes: true, childList: true, subtree: true });

    // Listen for TOC arrow clicks
    document.addEventListener("click", (ev) => {
        if (ev.target.closest(".wm-toc-opener")) scheduleUpdate();
    });

    // Observe body class changes (hide/show sidebar button)
    const bodyObserver = new MutationObserver(scheduleUpdate);
    bodyObserver.observe(body, { attributes: true, attributeFilter: ["class"] });

    // Handle window resize
    window.addEventListener("resize", scheduleUpdate);
});

