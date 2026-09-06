import * as THREE from 'https://cdn.jsdelivr.net/npm/three@0.180.0/build/three.module.js';

export function mount(element) {
  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0xf5f5f5);
  const camera = new THREE.PerspectiveCamera(40, 1, 0.1, 100);
  camera.position.z = 5;
  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  element.replaceChildren(renderer.domElement);
  const geometry = new THREE.TorusKnotGeometry(1, 0.28, 160, 24);
  const material = new THREE.MeshNormalMaterial();
  const knot = new THREE.Mesh(geometry, material);
  scene.add(knot);
  const resize = new ResizeObserver(() => {
    const { width, height } = element.getBoundingClientRect();
    renderer.setSize(width, height, false);
    camera.aspect = width / Math.max(height, 1);
    camera.updateProjectionMatrix();
    renderer.render(scene, camera);
  });
  resize.observe(element);
  const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)');
  let visible = true;
  const observer = new IntersectionObserver(entries => { visible = entries[0].isIntersecting; });
  observer.observe(element);
  renderer.setAnimationLoop(time => {
    if (!visible || document.hidden) return;
    if (!reduceMotion.matches) {
      knot.rotation.x = time * 0.00015;
      knot.rotation.y = time * 0.00025;
    }
    renderer.render(scene, camera);
  });
  window.addEventListener('pagehide', () => {
    renderer.setAnimationLoop(null);
    resize.disconnect(); observer.disconnect();
    geometry.dispose(); material.dispose(); renderer.dispose();
  }, { once: true });
}
