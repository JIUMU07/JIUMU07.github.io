/* ============================================================
   文章页增强（任务书 §4.4）—— 轻量、渐进增强
   1. TOC 滚动高亮：IntersectionObserver + rAF 兜底，无 JS 时 TOC 仍可点击
   2. 正文表格：外层 overflow-x: auto，手机不撑破 720 正文
   3. 移动端 TOC：默认折叠成「目录」按钮（details/summary）
   代码复制 / 图片放大 / 回到顶部：主题已实现（jijian footer +
   medium-zoom），不重复实现（任务书 §4.4.6）。
   ============================================================ */
(function () {
    'use strict';

    /* ---------- 1. TOC 滚动高亮 ---------- */
    function initScrollSpy() {
        var toc = document.querySelector('.toc .inner');
        if (!toc || !('IntersectionObserver' in window)) return;

        var links = Array.prototype.slice.call(toc.querySelectorAll('a[href^="#"]'));
        if (!links.length) return;

        var headings = [];
        links.forEach(function (a) {
            var href = a.getAttribute('href');
            if (!href || href === '#') return;
            var el = null;
            try {
                el = document.getElementById(decodeURIComponent(href.slice(1)));
            } catch (e) {
                el = document.getElementById(href.slice(1));
            }
            if (el) headings.push({ el: el, link: a });
        });
        if (!headings.length) return;

        var current = null;
        function setActive(item) {
            if (current === item) return;
            links.forEach(function (a) { a.classList.remove('active'); });
            if (item) item.link.classList.add('active');
            current = item;
        }

        /* 取视口顶部 offset 之上最近的一个标题；都在下方时高亮第一个 */
        function pick() {
            var offset = 120;
            var active = null;
            for (var i = 0; i < headings.length; i++) {
                if (headings[i].el.getBoundingClientRect().top <= offset) {
                    active = headings[i];
                } else {
                    break;
                }
            }
            setActive(active || headings[0]);
        }

        var io = new IntersectionObserver(function () { pick(); }, {
            rootMargin: '-72px 0px -60% 0px',
            threshold: 0
        });
        headings.forEach(function (h) { io.observe(h.el); });

        var ticking = false;
        window.addEventListener('scroll', function () {
            if (ticking) return;
            ticking = true;
            requestAnimationFrame(function () { pick(); ticking = false; });
        }, { passive: true });
        pick();
    }

    /* ---------- 2. 表格横向滚动 ---------- */
    function initTables() {
        var content = document.querySelector('.post-content');
        if (!content) return;
        content.querySelectorAll('table').forEach(function (t) {
            if (t.closest('.table-scroll') || t.closest('.highlight')) return;
            var wrap = document.createElement('div');
            wrap.className = 'table-scroll';
            t.parentNode.insertBefore(wrap, t);
            wrap.appendChild(t);
        });
    }

    /* ---------- 3. 中窄屏 TOC 默认折叠（≤1150px 时 TOC 转为文档流内面板） ---------- */
    function initMobileToc() {
        var details = document.querySelector('.toc details');
        if (!details) return;
        if (window.matchMedia('(max-width: 1150px)').matches) {
            details.removeAttribute('open');
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () {
            initScrollSpy();
            initTables();
            initMobileToc();
        });
    } else {
        initScrollSpy();
        initTables();
        initMobileToc();
    }
})();
