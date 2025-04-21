class LazyFadeIn extends HTMLElement {
  img = this.querySelector("img");
  placeholder = this.querySelector("[data-role=placeholder]");

  hidePlaceholder() {
    this.placeholder?.animate(
      { opacity: 0 },
      {
        duration: 100,
        delay: 100,
        fill: "forwards",
      }
    );
  }
  connectedCallback() {
    if (!this.img || this.img.complete) return this.hidePlaceholder();

    const animation = this.img.animate(
      [{ opacity: 0, "--tw-blur": "blur(8px)" }, { opacity: 1 }],
      {
        duration: 200,
      }
    );

    animation.pause();

    this.img.addEventListener("load", () => animation.play(), { once: true });
    animation.addEventListener("finish", this.hidePlaceholder);
  }
}

export default LazyFadeIn;
