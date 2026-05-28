import Lenis from 'lenis';

export default defineNuxtPlugin({
  setup() {
    if (!import.meta.client) return;

    const lenis = new Lenis({
      duration: 0.6,
      easing: t => 1 - Math.pow(1 - t, 3),
    });

    function raf(time: number) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }

    requestAnimationFrame(raf);

    return { provide: { lenis } };
  },
});
