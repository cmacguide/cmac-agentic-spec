# Performance & Optimization Guide

Guia abrangente para otimização de performance em UI/UX, focando em React rendering, bundle size, carregamento, Core Web Vitals e técnicas avançadas de otimização.

---

## ⚡ React Performance Optimization

### **Preventing Re-renders**

```jsx
// ✅ React.memo para componentes funcionais
const ExpensiveComponent = React.memo(
	({ data, onAction }) => {
		console.log("ExpensiveComponent rendered");

		return (
			<div className="expensive-component">
				{data.items.map((item) => (
					<div key={item.id}>
						{item.name} - {item.value}
					</div>
				))}
				<button onClick={() => onAction(data.id)}>Action</button>
			</div>
		);
	},
	(prevProps, nextProps) => {
		// Custom comparison function
		return (
			prevProps.data.id === nextProps.data.id &&
			prevProps.data.items.length === nextProps.data.items.length &&
			prevProps.onAction === nextProps.onAction
		);
	}
);

// ✅ useCallback para estabilizar referências de funções
function OptimizedParent({ items }) {
	const [selectedId, setSelectedId] = useState(null);

	// ❌ Função recriada a cada render
	// const handleSelect = (id) => setSelectedId(id);

	// ✅ Função estável com useCallback
	const handleSelect = useCallback((id) => {
		setSelectedId(id);
	}, []); // Dependências vazias pois setSelectedId é estável

	// ✅ Função estável com dependências
	const handleAction = useCallback(
		(itemId) => {
			console.log(`Action on item ${itemId}, selected: ${selectedId}`);
		},
		[selectedId]
	);

	return (
		<div className="optimized-parent">
			{items.map((item) => (
				<ItemComponent
					key={item.id}
					item={item}
					isSelected={item.id === selectedId}
					onSelect={handleSelect}
					onAction={handleAction}
				/>
			))}
		</div>
	);
}

// ✅ useMemo para cálculos caros
function DataAnalytics({ rawData, filters }) {
	const processedData = useMemo(() => {
		console.log("Processing data...");

		// Simulação de processamento caro
		return rawData
			.filter((item) => {
				return Object.entries(filters).every(([key, value]) => {
					return !value || item[key] === value;
				});
			})
			.map((item) => ({
				...item,
				score: calculateComplexScore(item),
				trend: calculateTrend(item.history),
			}))
			.sort((a, b) => b.score - a.score);
	}, [rawData, filters]);

	const stats = useMemo(
		() => ({
			total: processedData.length,
			average:
				processedData.reduce((sum, item) => sum + item.score, 0) /
				processedData.length,
			highest: Math.max(...processedData.map((item) => item.score)),
		}),
		[processedData]
	);

	return (
		<div className="analytics">
			<div className="stats">
				<div>Total: {stats.total}</div>
				<div>Average: {stats.average.toFixed(2)}</div>
				<div>Highest: {stats.highest}</div>
			</div>

			<div className="data-list">
				{processedData.map((item) => (
					<DataItem
						key={item.id}
						data={item}
					/>
				))}
			</div>
		</div>
	);
}
```

### **Virtualization for Large Lists**

```jsx
// ✅ Virtualização para listas grandes
import { FixedSizeList as List } from "react-window";

function VirtualizedList({ items, height = 400, itemHeight = 50 }) {
	const Row = ({ index, style }) => (
		<div
			style={style}
			className="list-item"
		>
			<div className="item-content">
				<h3>{items[index].title}</h3>
				<p>{items[index].description}</p>
				<span className="item-meta">
					{items[index].date} • {items[index].author}
				</span>
			</div>
		</div>
	);

	return (
		<List
			height={height}
			itemCount={items.length}
			itemSize={itemHeight}
			className="virtualized-list"
		>
			{Row}
		</List>
	);
}

// ✅ Virtualização dinâmica com react-window
import { VariableSizeList as DynamicList } from "react-window";

function DynamicVirtualizedList({ items }) {
	const [itemHeights, setItemHeights] = useState({});
	const listRef = useRef();

	const getItemSize = (index) => itemHeights[index] || 100;

	const setItemHeight = (index, height) => {
		setItemHeights((prev) => {
			if (prev[index] !== height) {
				const newHeights = { ...prev, [index]: height };

				// Reset cache when heights change
				if (listRef.current) {
					listRef.current.resetAfterIndex(index);
				}

				return newHeights;
			}
			return prev;
		});
	};

	const Row = ({ index, style }) => {
		const rowRef = useRef();

		useEffect(() => {
			if (rowRef.current) {
				const height = rowRef.current.offsetHeight;
				setItemHeight(index, height);
			}
		}, [index]);

		return (
			<div style={style}>
				<div
					ref={rowRef}
					className="dynamic-row"
				>
					<ItemContent item={items[index]} />
				</div>
			</div>
		);
	};

	return (
		<DynamicList
			ref={listRef}
			height={600}
			itemCount={items.length}
			itemSize={getItemSize}
			className="dynamic-virtualized-list"
		>
			{Row}
		</DynamicList>
	);
}
```

### **State Management Optimization**

```jsx
// ✅ Context otimizado para evitar re-renders desnecessários
const StateContext = createContext();
const DispatchContext = createContext();

function OptimizedProvider({ children }) {
	const [state, dispatch] = useReducer(appReducer, initialState);

	// Separar state e dispatch em contexts diferentes
	// Componentes que só precisam do dispatch não re-renderizam
	return (
		<StateContext.Provider value={state}>
			<DispatchContext.Provider value={dispatch}>
				{children}
			</DispatchContext.Provider>
		</StateContext.Provider>
	);
}

// Hooks específicos para consumir contexts
function useAppState() {
	const context = useContext(StateContext);
	if (!context) {
		throw new Error("useAppState must be used within OptimizedProvider");
	}
	return context;
}

function useAppDispatch() {
	const context = useContext(DispatchContext);
	if (!context) {
		throw new Error("useAppDispatch must be used within OptimizedProvider");
	}
	return context;
}

// ✅ Selector hooks para subscriptions específicas
function useAppSelector(selector) {
	const state = useAppState();
	return useMemo(() => selector(state), [state, selector]);
}

// Uso otimizado
function UserProfile() {
	// Só re-renderiza quando user data muda
	const user = useAppSelector((state) => state.user);
	const dispatch = useAppDispatch();

	const handleUpdate = useCallback(
		(updates) => {
			dispatch({ type: "UPDATE_USER", payload: updates });
		},
		[dispatch]
	);

	return (
		<div className="user-profile">
			<h1>{user.name}</h1>
			<p>{user.email}</p>
			<EditButton onUpdate={handleUpdate} />
		</div>
	);
}
```

---

## 📦 Bundle Size Optimization

### **Code Splitting**

```jsx
// ✅ Route-based code splitting
import { lazy, Suspense } from "react";
import { Routes, Route } from "react-router-dom";

// Lazy loading de páginas
const HomePage = lazy(() => import("./pages/HomePage"));
const ProductPage = lazy(() => import("./pages/ProductPage"));
const CheckoutPage = lazy(() => import("./pages/CheckoutPage"));
const AdminPanel = lazy(() => import("./pages/AdminPanel"));

function App() {
	return (
		<div className="app">
			<Header />

			<Suspense fallback={<PageLoadingSpinner />}>
				<Routes>
					<Route
						path="/"
						element={<HomePage />}
					/>
					<Route
						path="/product/:id"
						element={<ProductPage />}
					/>
					<Route
						path="/checkout"
						element={<CheckoutPage />}
					/>
					<Route
						path="/admin/*"
						element={<AdminPanel />}
					/>
				</Routes>
			</Suspense>
		</div>
	);
}

// ✅ Component-based code splitting
function AdvancedFeatures() {
	const [showChart, setShowChart] = useState(false);

	// Carregar componente apenas quando necessário
	const ChartComponent = lazy(() =>
		import("./Chart").then((module) => ({
			default: module.AdvancedChart,
		}))
	);

	return (
		<div className="advanced-features">
			<button onClick={() => setShowChart(true)}>Show Advanced Chart</button>

			{showChart && (
				<Suspense fallback={<div>Loading chart...</div>}>
					<ChartComponent />
				</Suspense>
			)}
		</div>
	);
}

// ✅ Dynamic imports para bibliotecas pesadas
function DataExport({ data }) {
	const [isExporting, setIsExporting] = useState(false);

	const handleExport = async () => {
		setIsExporting(true);

		try {
			// Carregar biblioteca apenas quando necessário
			const { utils, writeFile } = await import("xlsx");

			const worksheet = utils.json_to_sheet(data);
			const workbook = utils.book_new();
			utils.book_append_sheet(workbook, worksheet, "Data");

			writeFile(workbook, "export.xlsx");
		} catch (error) {
			console.error("Export failed:", error);
		} finally {
			setIsExporting(false);
		}
	};

	return (
		<button
			onClick={handleExport}
			disabled={isExporting}
			className="export-button"
		>
			{isExporting ? "Exporting..." : "Export to Excel"}
		</button>
	);
}
```

### **Tree Shaking & Dead Code Elimination**

```javascript
// ✅ Named imports para tree shaking
// ❌ Import completo da biblioteca
// import _ from 'lodash';

// ✅ Import específico
import { debounce, throttle } from "lodash";

// ✅ Ainda melhor: import específico do módulo
import debounce from "lodash/debounce";
import throttle from "lodash/throttle";

// ✅ Configuração webpack para tree shaking
module.exports = {
	mode: "production",
	optimization: {
		usedExports: true,
		sideEffects: false, // ou array com arquivos que têm side effects
		splitChunks: {
			chunks: "all",
			cacheGroups: {
				vendor: {
					test: /[\\/]node_modules[\\/]/,
					name: "vendors",
					chunks: "all",
				},
				common: {
					name: "common",
					minChunks: 2,
					chunks: "all",
					enforce: true,
				},
			},
		},
	},
};

// ✅ ESLint rules para detectar código não usado
// .eslintrc.js
module.exports = {
	extends: ["eslint:recommended"],
	rules: {
		"no-unused-vars": "error",
		"no-unreachable": "error",
		"no-dead-code": "error",
	},
};
```

### **Asset Optimization**

```jsx
// ✅ Image optimization
function OptimizedImage({
	src,
	alt,
	width,
	height,
	loading = "lazy",
	...props
}) {
	const [imageSrc, setImageSrc] = useState(null);
	const [isLoaded, setIsLoaded] = useState(false);

	useEffect(() => {
		// Generate responsive image URLs
		const createSrcSet = (baseSrc) => {
			const sizes = [320, 640, 768, 1024, 1280];
			return sizes
				.map((size) => `${baseSrc}?w=${size}&q=75 ${size}w`)
				.join(", ");
		};

		setImageSrc({
			src: `${src}?w=${width}&q=75`,
			srcSet: createSrcSet(src),
		});
	}, [src, width]);

	if (!imageSrc) {
		return (
			<div
				className="image-placeholder"
				style={{ width, height }}
			/>
		);
	}

	return (
		<picture>
			{/* WebP format for supported browsers */}
			<source
				srcSet={imageSrc.srcSet.replace(/\.(jpg|jpeg|png)/g, ".webp")}
				type="image/webp"
			/>

			<img
				src={imageSrc.src}
				srcSet={imageSrc.srcSet}
				sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 25vw"
				alt={alt}
				width={width}
				height={height}
				loading={loading}
				onLoad={() => setIsLoaded(true)}
				className={`optimized-image ${isLoaded ? "loaded" : "loading"}`}
				{...props}
			/>
		</picture>
	);
}

// ✅ Font optimization
function FontOptimizer() {
	useEffect(() => {
		// Preload critical fonts
		const fontPreloads = [
			{ href: "/fonts/inter-var.woff2", type: "font/woff2" },
			{ href: "/fonts/roboto-regular.woff2", type: "font/woff2" },
		];

		fontPreloads.forEach(({ href, type }) => {
			const link = document.createElement("link");
			link.rel = "preload";
			link.href = href;
			link.as = "font";
			link.type = type;
			link.crossOrigin = "anonymous";
			document.head.appendChild(link);
		});

		// Font display swap for better performance
		const fontFaceCSS = `
      @font-face {
        font-family: 'Inter';
        src: url('/fonts/inter-var.woff2') format('woff2');
        font-display: swap;
        font-weight: 100 900;
      }
    `;

		const style = document.createElement("style");
		style.textContent = fontFaceCSS;
		document.head.appendChild(style);
	}, []);

	return null;
}
```

---

## 🚀 Loading Performance

### **Progressive Loading**

```jsx
// ✅ Progressive loading com Intersection Observer
function ProgressiveLoader({ children, threshold = 0.1 }) {
	const [isVisible, setIsVisible] = useState(false);
	const [isLoaded, setIsLoaded] = useState(false);
	const elementRef = useRef();

	useEffect(() => {
		const observer = new IntersectionObserver(
			([entry]) => {
				if (entry.isIntersecting) {
					setIsVisible(true);
					observer.unobserve(entry.target);
				}
			},
			{ threshold }
		);

		if (elementRef.current) {
			observer.observe(elementRef.current);
		}

		return () => observer.disconnect();
	}, [threshold]);

	useEffect(() => {
		if (isVisible && !isLoaded) {
			// Simulate async loading
			const timer = setTimeout(() => setIsLoaded(true), 100);
			return () => clearTimeout(timer);
		}
	}, [isVisible, isLoaded]);

	return (
		<div
			ref={elementRef}
			className="progressive-loader"
		>
			{isLoaded ? (
				children
			) : isVisible ? (
				<div className="loading-placeholder">Loading...</div>
			) : (
				<div className="intersection-placeholder" />
			)}
		</div>
	);
}

// ✅ Skeleton loading
function SkeletonLoader({
	lines = 3,
	width = "100%",
	height = "1rem",
	className = "",
}) {
	return (
		<div className={`skeleton-loader ${className}`}>
			{Array.from({ length: lines }, (_, index) => (
				<div
					key={index}
					className="skeleton-line"
					style={{
						width: index === lines - 1 ? "60%" : width,
						height: height,
						marginBottom: "0.5rem",
					}}
				/>
			))}
		</div>
	);
}

// Uso com Suspense
function ProductCard({ productId }) {
	return (
		<div className="product-card">
			<Suspense fallback={<SkeletonLoader lines={4} />}>
				<ProductDetails productId={productId} />
			</Suspense>
		</div>
	);
}
```

### **Preloading Strategies**

```jsx
// ✅ Preload de recursos críticos
function ResourcePreloader() {
	useEffect(() => {
		// Preload critical API data
		const criticalEndpoints = [
			"/api/user/profile",
			"/api/navigation/menu",
			"/api/config/app",
		];

		criticalEndpoints.forEach((endpoint) => {
			fetch(endpoint)
				.then((response) => response.json())
				.then((data) => {
					// Cache in memory or localStorage
					sessionStorage.setItem(`cache:${endpoint}`, JSON.stringify(data));
				})
				.catch(console.error);
		});

		// Preload next page routes
		const nextRoutes = ["/dashboard", "/profile", "/settings"];
		nextRoutes.forEach((route) => {
			import(`./pages${route}`);
		});
	}, []);

	return null;
}

// ✅ Hover preloading
function SmartLink({ href, children, ...props }) {
	const [isHovered, setIsHovered] = useState(false);
	const [isPreloaded, setIsPreloaded] = useState(false);

	useEffect(() => {
		if (isHovered && !isPreloaded) {
			// Preload route component on hover
			import(`./pages${href}`)
				.then(() => setIsPreloaded(true))
				.catch(console.error);
		}
	}, [isHovered, isPreloaded, href]);

	return (
		<Link
			to={href}
			onMouseEnter={() => setIsHovered(true)}
			{...props}
		>
			{children}
		</Link>
	);
}

// ✅ Service Worker para cache inteligente
function registerServiceWorker() {
	if ("serviceWorker" in navigator) {
		navigator.serviceWorker
			.register("/sw.js")
			.then((registration) => {
				console.log("SW registered:", registration);
			})
			.catch((error) => {
				console.log("SW registration failed:", error);
			});
	}
}

// sw.js - Service Worker
const CACHE_NAME = "app-cache-v1";
const urlsToCache = [
	"/",
	"/static/css/main.css",
	"/static/js/main.js",
	"/static/media/logo.svg",
];

self.addEventListener("install", (event) => {
	event.waitUntil(
		caches.open(CACHE_NAME).then((cache) => cache.addAll(urlsToCache))
	);
});

self.addEventListener("fetch", (event) => {
	event.respondWith(
		caches.match(event.request).then((response) => {
			// Return cached version or fetch from network
			return response || fetch(event.request);
		})
	);
});
```

---

## 📊 Core Web Vitals Optimization

### **Largest Contentful Paint (LCP)**

```jsx
// ✅ Otimização para LCP
function LCPOptimizedHero({ imageUrl, title, description }) {
	useEffect(() => {
		// Preload hero image for faster LCP
		const link = document.createElement("link");
		link.rel = "preload";
		link.href = imageUrl;
		link.as = "image";
		document.head.appendChild(link);

		return () => {
			document.head.removeChild(link);
		};
	}, [imageUrl]);

	return (
		<section className="hero">
			{/* Critical above-the-fold content */}
			<img
				src={imageUrl}
				alt={title}
				className="hero-image"
				// Highest priority for LCP element
				fetchPriority="high"
				loading="eager"
			/>

			<div className="hero-content">
				<h1 className="hero-title">{title}</h1>
				<p className="hero-description">{description}</p>
				<button className="hero-cta">Get Started</button>
			</div>
		</section>
	);
}

// ✅ CSS optimization para LCP
const criticalCSS = `
  /* Inline critical CSS for above-the-fold content */
  .hero {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  
  .hero-image {
    width: 100%;
    max-width: 600px;
    height: auto;
    object-fit: cover;
  }
  
  .hero-title {
    font-size: 3rem;
    font-weight: 700;
    margin: 0 0 1rem 0;
    /* Use system fonts for faster rendering */
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
  }
`;
```

### **First Input Delay (FID)**

```jsx
// ✅ Otimização para FID
function OptimizedEventHandlers() {
	// Use debouncing for expensive operations
	const debouncedSearch = useMemo(
		() =>
			debounce((query) => {
				// Expensive search operation
				performSearch(query);
			}, 300),
		[]
	);

	// Break up long tasks
	const handleLargeDataset = useCallback(async (data) => {
		const chunks = chunkArray(data, 100);

		for (const chunk of chunks) {
			await new Promise((resolve) => {
				// Process chunk
				processChunk(chunk);

				// Yield to main thread
				setTimeout(resolve, 0);
			});
		}
	}, []);

	// Use requestIdleCallback for non-critical tasks
	const handleNonCriticalTask = useCallback(() => {
		if (window.requestIdleCallback) {
			requestIdleCallback(() => {
				performNonCriticalOperation();
			});
		} else {
			setTimeout(performNonCriticalOperation, 0);
		}
	}, []);

	return (
		<div className="optimized-handlers">
			<input
				onChange={(e) => debouncedSearch(e.target.value)}
				placeholder="Search..."
			/>

			<button onClick={() => handleLargeDataset(largeData)}>
				Process Large Dataset
			</button>

			<button onClick={handleNonCriticalTask}>Non-Critical Action</button>
		</div>
	);
}

// Utility function para chunking
function chunkArray(array, chunkSize) {
	const chunks = [];
	for (let i = 0; i < array.length; i += chunkSize) {
		chunks.push(array.slice(i, i + chunkSize));
	}
	return chunks;
}
```

### **Cumulative Layout Shift (CLS)**

```jsx
// ✅ Prevenção de CLS
function CLSOptimizedComponent() {
	const [imageLoaded, setImageLoaded] = useState(false);
	const [adLoaded, setAdLoaded] = useState(false);

	return (
		<div className="layout-stable">
			{/* Reserve space for images */}
			<div
				className="image-container"
				style={{
					width: "100%",
					aspectRatio: "16/9",
					backgroundColor: "#f0f0f0",
				}}
			>
				<img
					src="/hero-image.jpg"
					alt="Hero"
					className={`hero-image ${imageLoaded ? "loaded" : ""}`}
					onLoad={() => setImageLoaded(true)}
					style={{
						width: "100%",
						height: "100%",
						objectFit: "cover",
						opacity: imageLoaded ? 1 : 0,
						transition: "opacity 0.3s ease",
					}}
				/>
			</div>

			{/* Reserve space for ads */}
			<div
				className="ad-container"
				style={{
					width: "100%",
					height: "250px",
					backgroundColor: adLoaded ? "transparent" : "#f5f5f5",
					border: adLoaded ? "none" : "1px dashed #ccc",
					display: "flex",
					alignItems: "center",
					justifyContent: "center",
				}}
			>
				{adLoaded ? (
					<AdComponent />
				) : (
					<span style={{ color: "#999" }}>Advertisement</span>
				)}
			</div>

			{/* Content that won't shift */}
			<div className="main-content">
				<h1>Stable Content</h1>
				<p>This content won't cause layout shifts.</p>
			</div>
		</div>
	);
}

// ✅ CSS para prevenir CLS
const stableLayoutCSS = `
  /* Reserve space for dynamic content */
  .image-container {
    position: relative;
    overflow: hidden;
  }
  
  .image-container::before {
    content: '';
    display: block;
    width: 100%;
    padding-bottom: 56.25%; /* 16:9 aspect ratio */
  }
  
  .hero-image {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
  }
  
  /* Prevent font loading shifts */
  .text-content {
    font-display: swap;
    line-height: 1.5;
  }
  
  /* Stable button sizing */
  .stable-button {
    min-width: 120px;
    min-height: 44px;
    padding: 12px 24px;
  }
`;
```

---

## 🔧 Advanced Optimization Techniques

### **Memory Management**

```jsx
// ✅ Cleanup de event listeners e subscriptions
function MemoryOptimizedComponent() {
	const [data, setData] = useState([]);
	const intervalRef = useRef();
	const observerRef = useRef();

	useEffect(() => {
		// Setup interval
		intervalRef.current = setInterval(() => {
			fetchNewData().then(setData);
		}, 5000);

		// Setup intersection observer
		observerRef.current = new IntersectionObserver((entries) => {
			entries.forEach((entry) => {
				if (entry.isIntersecting) {
					trackVisibility(entry.target);
				}
			});
		});

		// Cleanup function
		return () => {
			if (intervalRef.current) {
				clearInterval(intervalRef.current);
			}

			if (observerRef.current) {
				observerRef.current.disconnect();
			}
		};
	}, []);

	// Cleanup large objects when component unmounts
	useEffect(() => {
		return () => {
			// Clear large data structures
			setData([]);

			// Cancel pending requests
			if (window.AbortController) {
				const controller = new AbortController();
				controller.abort();
			}
		};
	}, []);

	return (
		<div className="memory-optimized">
			{data.map((item) => (
				<DataItem
					key={item.id}
					data={item}
				/>
			))}
		</div>
	);
}

// ✅ Memoização com limite de cache
function createMemoizedFunction(fn, maxCacheSize = 100) {
	const cache = new Map();

	return (...args) => {
		const key = JSON.stringify(args);

		if (cache.has(key)) {
			return cache.get(key);
		}

		const result = fn(...args);

		// Limit cache size to prevent memory leaks
		if (cache.size >= maxCacheSize) {
			const firstKey = cache.keys().next().value;
			cache.delete(firstKey);
		}

		cache.set(key, result);
		return result;
	};
}

// Uso
const expensiveCalculation = createMemoizedFunction((a, b, c) => {
	// Expensive operation
	return complexMath(a, b, c);
}, 50);
```

### **Network Optimization**

```jsx
// ✅ Request deduplication
class RequestDeduplicator {
	constructor() {
		this.pendingRequests = new Map();
	}

	async fetch(url, options = {}) {
		const key = `${url}:${JSON.stringify(options)}`;

		// Return existing promise if request is already pending
		if (this.pendingRequests.has(key)) {
			return this.pendingRequests.get(key);
		}

		// Create new request
		const promise = fetch(url, options)
			.then((response) => response.json())
			.finally(() => {
				// Clean up after request completes
				this.pendingRequests.delete(key);
			});

		this.pendingRequests.set(key, promise);
		return promise;
	}
}

const requestDeduplicator = new RequestDeduplicator();

// ✅ Hook para requests otimizados
function useOptimizedFetch(url, options = {}) {
	const [data, setData] = useState(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState(null);

	useEffect(() => {
		let cancelled = false;

		setLoading(true);
		setError(null);

		requestDeduplicator
			.fetch(url, options)
			.then((result) => {
				if (!cancelled) {
					setData(result);
				}
			})
			.catch((err) => {
				if (!cancelled) {
					setError(err);
				}
			})
			.finally(() => {
				if (!cancelled) {
					setLoading(false);
				}
			});

		return () => {
			cancelled = true;
		};
	}, [url, JSON.stringify(options)]);

	return { data, loading, error };
}

// ✅ Batch de requests
function useBatchedRequests() {
	const [batchQueue, setBatchQueue] = useState([]);
	const timeoutRef = useRef();

	const addToBatch = useCallback(
		(request) => {
			setBatchQueue((prev) => [...prev, request]);

			// Clear existing timeout
			if (timeoutRef.current) {
				clearTimeout(timeoutRef.current);
			}

			// Batch requests after 100ms
			timeoutRef.current = setTimeout(() => {
				if (batchQueue.length > 0) {
					processBatch(batchQueue);
					setBatchQueue([]);
				}
			}, 100);
		},
		[batchQueue]
	);

	const processBatch = async (requests) => {
		try {
			// Combine multiple requests into single batch request
			const batchResponse = await fetch("/api/batch", {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ requests }),
			});

			const results = await batchResponse.json();

			// Resolve individual promises
			requests.forEach((request, index) => {
				request.resolve(results[index]);
			});
		} catch (error) {
			requests.forEach((request) => {
				request.reject(error);
			});
		}
	};

	return { addToBatch };
}
```

---

## 📈 Performance Monitoring

### **Performance Metrics**

```jsx
// ✅ Performance monitoring hook
function usePerformanceMonitoring() {
	const [metrics, setMetrics] = useState({});

	useEffect(() => {
		// Measure component render time
		const startTime = performance.now();

		return () => {
			const endTime = performance.now();
			const renderTime = endTime - startTime;

			setMetrics((prev) => ({
				...prev,
				renderTime,
				timestamp: Date.now(),
			}));
		};
	}, []);

	const measureAsyncOperation = useCallback(async (operation, name) => {
		const startTime = performance.now();

		try {
			const result = await operation();
			const endTime = performance.now();

			setMetrics((prev) => ({
				...prev,
				[name]: {
					duration: endTime - startTime,
					success: true,
					timestamp: Date.now(),
				},
			}));

			return result;
		} catch (error) {
			const endTime = performance.now();

			setMetrics((prev) => ({
				...prev,
				[name]: {
					duration: endTime - startTime,
					success: false,
					error: error.message,
					timestamp: Date.now(),
				},
			}));

			throw error;
		}
	}, []);

	return { metrics, measureAsyncOperation };
}

// ✅ Core Web Vitals monitoring
function useCoreWebVitals() {
	const [vitals, setVitals] = useState({});

	useEffect(() => {
		// Import web-vitals library dynamically
		import("web-vitals").then(({ getCLS, getFID, getFCP, getLCP, getTTFB }) => {
			getCLS((metric) => {
				setVitals((prev) => ({ ...prev, cls: metric.value }));
				sendToAnalytics("CLS", metric.value);
			});

			getFID((metric) => {
				setVitals((prev) => ({ ...prev, fid: metric.value }));
				sendToAnalytics("FID", metric.value);
			});

			getFCP((metric) => {
				setVitals((prev) => ({ ...prev, fcp: metric.value }));
				sendToAnalytics("FCP", metric.value);
			});

			getLCP((metric) => {
				setVitals((prev) => ({ ...prev, lcp: metric.value }));
				sendToAnalytics("LCP", metric.value);
			});

			getTTFB((metric) => {
				setVitals((prev) => ({ ...prev, ttfb: metric.value }));
				sendToAnalytics("TTFB", metric.value);
			});
		});
	}, []);

	return vitals;
}

function sendToAnalytics(metric, value) {
	// Send to your analytics service
	if (window.gtag) {
		window.gtag("event", metric, {
			custom_parameter_1: value,
			custom_parameter_2: "performance",
		});
	}
}
```

### **Bundle Analysis**

```javascript
// ✅ Webpack Bundle Analyzer configuration
const BundleAnalyzerPlugin =
	require("webpack-bundle-analyzer").BundleAnalyzerPlugin;

module.exports = {
	// ... other webpack config

	plugins: [
		// Add bundle analyzer in analyze mode
		process.env.ANALYZE &&
			new BundleAnalyzerPlugin({
				analyzerMode: "static",
				openAnalyzer: false,
				reportFilename: "bundle-report.html",
			}),
	].filter(Boolean),

	optimization: {
		splitChunks: {
			chunks: "all",
			cacheGroups: {
				vendor: {
					test: /[\\/]node_modules[\\/]/,
					name: "vendors",
					chunks: "all",
				},
				common: {
					name: "common",
					minChunks: 2,
					chunks: "all",
					enforce: true,
				},
			},
		},
	},
};

// Package.json script
// "analyze": "ANALYZE=true npm run build"
```

---

## ✅ Performance Checklist

### **React Optimization:**

- [ ] **React.memo** - Componentes memoizados apropriadamente
- [ ] **useCallback/useMemo** - Callbacks e cálculos otimizados
- [ ] **Code Splitting** - Lazy loading de componentes
- [ ] **Virtualization** - Listas grandes virtualizadas

### **Bundle Optimization:**

- [ ] **Tree Shaking** - Dead code elimination ativado
- [ ] **Dynamic Imports** - Bibliotecas carregadas sob demanda
- [ ] **Asset Optimization** - Imagens e fonts otimizados
- [ ] **Cache Strategy** - Service worker implementado

### **Core Web Vitals:**

- [ ] **LCP < 2.5s** - Largest Contentful Paint otimizado
- [ ] **FID < 100ms** - First Input Delay minimizado
- [ ] **CLS < 0.1** - Cumulative Layout Shift prevenido
- [ ] **TTFB < 600ms** - Time to First Byte otimizado

### **Monitoring:**

- [ ] **Performance Metrics** - Monitoramento implementado
- [ ] **Error Tracking** - Erros de performance rastreados
- [ ] **User Experience** - Métricas de UX coletadas
- [ ] **Bundle Analysis** - Análise regular do bundle

---

_Este guia foca em otimização de performance. Para patterns específicos de React, consulte frontend/react-patterns/_
