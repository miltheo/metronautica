// Filter topics and reveal sections.
(() => {
    const input = document.getElementById("topic-filter");
    if (!input) return;
    const items = [...document.querySelectorAll("li.topic-item")];
    const groups = [...document.querySelectorAll(".topic-group")];
    const status = document.getElementById("topic-results");
    const searchable = new Map();
    const normalise = value => value.toLowerCase().replace(/[_-]+/g, " ").replace(/\s+/g, " ").trim();
    for (const item of items) {
        const heading = document.getElementById(item.dataset.topic);
        let text = item.textContent;
        for (let node = heading; node; node = node.nextElementSibling) {
            if (node !== heading && node.tagName === "H2") break;
            text += " " + node.textContent;
        }
        searchable.set(item, normalise(text));
    }
    const filter = () => {
        const query = normalise(input.value);
        let matches = 0;
        for (const item of items) {
            item.hidden = !searchable.get(item).includes(query);
            if (!item.hidden) matches++;
            if (query) {
                const sections = [...item.querySelectorAll(".topic-sections a")];
                item.querySelector("details").open = !item.hidden &&
                    sections.some(link => normalise(link.textContent).includes(query));
            }
        }
        for (const group of groups) {
            group.hidden = ![...group.querySelectorAll(".topic-item")].some(item => !item.hidden);
        }
        status.textContent = query ? `${matches} of ${items.length} topics` : "";
    };
    const reveal = () => {
        const hash = decodeURIComponent(location.hash.slice(1));
        let active;
        for (const item of items) {
            for (const link of item.querySelectorAll("a")) {
                const selected = link.getAttribute("href") === "#" + hash;
                if (selected) {
                    link.setAttribute("aria-current", "location");
                    active = item;
                } else link.removeAttribute("aria-current");
            }
        }
        if (active) active.querySelector("details").open = true;
    };
    input.addEventListener("input", filter);
    input.addEventListener("keydown", event => {
        if (event.key === "Escape") {
            input.value = "";
            filter();
            reveal();
        }
    });
    window.addEventListener("hashchange", reveal);
    filter();
    reveal();
})();
