# Accessibility & Usability Guide

Guia abrangente para implementar acessibilidade e usabilidade em componentes UI, seguindo padrões WCAG 2.1, práticas de design inclusivo e otimizações para tecnologias assistivas.

---

## 🎯 Fundamentos da Acessibilidade

### **Princípios WCAG 2.1**

**1. Perceptível:**

```jsx
// ✅ Texto alternativo para imagens
function ProductImage({ src, productName, description }) {
	return (
		<img
			src={src}
			alt={`${productName} - ${description}`}
			role="img"
		/>
	);
}

// ✅ Contraste adequado
const accessibleColors = {
	// Ratio 4.5:1 para texto normal
	textOnBackground: {
		text: "#2d3748", // Dark gray
		background: "#ffffff", // White
	},

	// Ratio 3:1 para texto grande (18px+)
	largeTextOnBackground: {
		text: "#4a5568", // Medium gray
		background: "#ffffff", // White
	},

	// Estados de foco com contraste alto
	focusIndicator: {
		outline: "2px solid #0066cc",
		outlineOffset: "2px",
	},
};

// ✅ Suporte a modo de alto contraste
function Button({ children, variant = "primary", ...props }) {
	const styles = {
		"@media (prefers-contrast: high)": {
			border: "2px solid currentColor",
			backgroundColor: variant === "primary" ? "#000000" : "transparent",
			color: variant === "primary" ? "#ffffff" : "#000000",
		},
	};

	return (
		<button
			style={styles}
			{...props}
		>
			{children}
		</button>
	);
}
```

**2. Operável:**

```jsx
// ✅ Navegação por teclado
function Modal({ isOpen, onClose, title, children }) {
	const modalRef = useRef(null);
	const previousFocusRef = useRef(null);

	useEffect(() => {
		if (isOpen) {
			// Armazenar elemento com foco anterior
			previousFocusRef.current = document.activeElement;

			// Focar no modal
			modalRef.current?.focus();

			// Trap focus dentro do modal
			const handleKeyDown = (event) => {
				if (event.key === "Escape") {
					onClose();
				}

				if (event.key === "Tab") {
					trapFocus(event, modalRef.current);
				}
			};

			document.addEventListener("keydown", handleKeyDown);

			return () => {
				document.removeEventListener("keydown", handleKeyDown);
				// Restaurar foco anterior
				previousFocusRef.current?.focus();
			};
		}
	}, [isOpen, onClose]);

	if (!isOpen) return null;

	return (
		<div
			className="modal-overlay"
			onClick={onClose}
			role="dialog"
			aria-modal="true"
			aria-labelledby="modal-title"
		>
			<div
				ref={modalRef}
				className="modal-content"
				onClick={(e) => e.stopPropagation()}
				tabIndex={-1}
			>
				<header className="modal-header">
					<h2 id="modal-title">{title}</h2>
					<button
						className="modal-close"
						onClick={onClose}
						aria-label="Close modal"
					>
						×
					</button>
				</header>

				<div className="modal-body">{children}</div>
			</div>
		</div>
	);
}

// Função para trap focus
function trapFocus(event, container) {
	const focusableElements = container.querySelectorAll(
		'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
	);

	const firstElement = focusableElements[0];
	const lastElement = focusableElements[focusableElements.length - 1];

	if (event.shiftKey) {
		if (document.activeElement === firstElement) {
			lastElement.focus();
			event.preventDefault();
		}
	} else {
		if (document.activeElement === lastElement) {
			firstElement.focus();
			event.preventDefault();
		}
	}
}
```

**3. Compreensível:**

```jsx
// ✅ Formulários com labels e instruções claras
function FormField({
	id,
	label,
	type = "text",
	required,
	error,
	hint,
	value,
	onChange,
	...props
}) {
	const fieldId = id || `field-${Math.random().toString(36).substr(2, 9)}`;
	const errorId = `${fieldId}-error`;
	const hintId = `${fieldId}-hint`;

	return (
		<div className="form-field">
			<label
				htmlFor={fieldId}
				className="form-field__label"
			>
				{label}
				{required && (
					<span
						className="form-field__required"
						aria-label="required"
					>
						*
					</span>
				)}
			</label>

			{hint && (
				<div
					id={hintId}
					className="form-field__hint"
				>
					{hint}
				</div>
			)}

			<input
				id={fieldId}
				type={type}
				className={`form-field__input ${
					error ? "form-field__input--error" : ""
				}`}
				value={value}
				onChange={onChange}
				required={required}
				aria-invalid={!!error}
				aria-describedby={
					[hint && hintId, error && errorId].filter(Boolean).join(" ") ||
					undefined
				}
				{...props}
			/>

			{error && (
				<div
					id={errorId}
					className="form-field__error"
					role="alert"
					aria-live="polite"
				>
					{error}
				</div>
			)}
		</div>
	);
}

// ✅ Instruções de erro claras e construtivas
function PasswordField({ value, onChange, ...props }) {
	const [errors, setErrors] = useState([]);

	const validatePassword = (password) => {
		const rules = [
			{
				test: password.length >= 8,
				message: "Password must be at least 8 characters long",
			},
			{
				test: /[A-Z]/.test(password),
				message: "Password must contain at least one uppercase letter",
			},
			{
				test: /[a-z]/.test(password),
				message: "Password must contain at least one lowercase letter",
			},
			{
				test: /\d/.test(password),
				message: "Password must contain at least one number",
			},
		];

		return rules.filter((rule) => !rule.test).map((rule) => rule.message);
	};

	const handleChange = (event) => {
		const newValue = event.target.value;
		const newErrors = validatePassword(newValue);
		setErrors(newErrors);
		onChange(event);
	};

	return (
		<FormField
			type="password"
			label="Password"
			value={value}
			onChange={handleChange}
			error={errors.length > 0 ? errors.join(". ") : null}
			hint="Password must be at least 8 characters with uppercase, lowercase, and number"
			required
			{...props}
		/>
	);
}
```

**4. Robusto:**

```jsx
// ✅ Componentes compatíveis com tecnologias assistivas
function DataTable({ data, columns, caption, sortable = false, onSort }) {
	const [sortConfig, setSortConfig] = useState(null);

	const handleSort = (columnKey) => {
		if (!sortable) return;

		const direction =
			sortConfig?.key === columnKey && sortConfig.direction === "asc"
				? "desc"
				: "asc";

		setSortConfig({ key: columnKey, direction });
		onSort?.(columnKey, direction);
	};

	return (
		<table
			className="data-table"
			role="table"
			aria-label={caption}
		>
			{caption && <caption className="data-table__caption">{caption}</caption>}

			<thead>
				<tr role="row">
					{columns.map((column) => (
						<th
							key={column.key}
							role="columnheader"
							scope="col"
							aria-sort={
								sortConfig?.key === column.key
									? sortConfig.direction === "asc"
										? "ascending"
										: "descending"
									: sortable
									? "none"
									: undefined
							}
							tabIndex={sortable ? 0 : undefined}
							onClick={() => handleSort(column.key)}
							onKeyDown={(e) => {
								if (sortable && (e.key === "Enter" || e.key === " ")) {
									e.preventDefault();
									handleSort(column.key);
								}
							}}
							className={`data-table__header ${
								sortable ? "data-table__header--sortable" : ""
							}`}
						>
							{column.label}
							{sortable && (
								<span
									className="data-table__sort-icon"
									aria-hidden="true"
								>
									{sortConfig?.key === column.key
										? sortConfig.direction === "asc"
											? "↑"
											: "↓"
										: "↕"}
								</span>
							)}
						</th>
					))}
				</tr>
			</thead>

			<tbody>
				{data.map((row, rowIndex) => (
					<tr
						key={rowIndex}
						role="row"
					>
						{columns.map((column) => (
							<td
								key={column.key}
								role="gridcell"
								className="data-table__cell"
							>
								{row[column.key]}
							</td>
						))}
					</tr>
				))}
			</tbody>
		</table>
	);
}
```

---

## 🔧 Tecnologias Assistivas

### **Screen Readers**

```jsx
// ✅ ARIA roles e labels para screen readers
function ProgressBar({ value, max = 100, label, ...props }) {
	const percentage = Math.round((value / max) * 100);

	return (
		<div className="progress-container">
			{label && (
				<div
					id="progress-label"
					className="progress-label"
				>
					{label}
				</div>
			)}

			<div
				role="progressbar"
				aria-valuenow={value}
				aria-valuemin={0}
				aria-valuemax={max}
				aria-valuetext={`${percentage}% complete`}
				aria-labelledby={label ? "progress-label" : undefined}
				className="progress-bar"
				{...props}
			>
				<div
					className="progress-bar__fill"
					style={{ width: `${percentage}%` }}
				/>
			</div>

			<div
				className="progress-text"
				aria-hidden="true"
			>
				{percentage}%
			</div>
		</div>
	);
}

// ✅ Live regions para atualizações dinâmicas
function NotificationSystem() {
	const [notifications, setNotifications] = useState([]);

	const addNotification = (message, type = "info") => {
		const id = Date.now();
		setNotifications((prev) => [...prev, { id, message, type }]);

		// Auto-remove após 5 segundos
		setTimeout(() => {
			setNotifications((prev) => prev.filter((n) => n.id !== id));
		}, 5000);
	};

	return (
		<>
			{/* Live region para anúncios de screen reader */}
			<div
				aria-live="polite"
				aria-atomic="true"
				className="sr-only"
			>
				{notifications.map((notification) => (
					<div key={notification.id}>
						{notification.type}: {notification.message}
					</div>
				))}
			</div>

			{/* Visual notifications */}
			<div className="notifications-container">
				{notifications.map((notification) => (
					<div
						key={notification.id}
						className={`notification notification--${notification.type}`}
						role="alert"
					>
						{notification.message}
					</div>
				))}
			</div>
		</>
	);
}

// ✅ Skip links para navegação eficiente
function SkipLinks() {
	return (
		<div className="skip-links">
			<a
				href="#main-content"
				className="skip-link"
			>
				Skip to main content
			</a>
			<a
				href="#navigation"
				className="skip-link"
			>
				Skip to navigation
			</a>
			<a
				href="#search"
				className="skip-link"
			>
				Skip to search
			</a>
		</div>
	);
}
```

### **Keyboard Navigation**

```jsx
// ✅ Roving tabindex para navegação em listas
function MenuList({ items, onSelect }) {
	const [focusedIndex, setFocusedIndex] = useState(0);
	const menuRefs = useRef([]);

	const handleKeyDown = (event, index) => {
		switch (event.key) {
			case "ArrowDown":
				event.preventDefault();
				const nextIndex = index < items.length - 1 ? index + 1 : 0;
				setFocusedIndex(nextIndex);
				menuRefs.current[nextIndex]?.focus();
				break;

			case "ArrowUp":
				event.preventDefault();
				const prevIndex = index > 0 ? index - 1 : items.length - 1;
				setFocusedIndex(prevIndex);
				menuRefs.current[prevIndex]?.focus();
				break;

			case "Home":
				event.preventDefault();
				setFocusedIndex(0);
				menuRefs.current[0]?.focus();
				break;

			case "End":
				event.preventDefault();
				const lastIndex = items.length - 1;
				setFocusedIndex(lastIndex);
				menuRefs.current[lastIndex]?.focus();
				break;

			case "Enter":
			case " ":
				event.preventDefault();
				onSelect(items[index]);
				break;

			case "Escape":
				// Close menu
				event.target.blur();
				break;
		}
	};

	return (
		<ul
			className="menu-list"
			role="menu"
			aria-orientation="vertical"
		>
			{items.map((item, index) => (
				<li
					key={item.id}
					role="none"
				>
					<button
						ref={(el) => (menuRefs.current[index] = el)}
						role="menuitem"
						tabIndex={index === focusedIndex ? 0 : -1}
						className={`menu-item ${
							index === focusedIndex ? "menu-item--focused" : ""
						}`}
						onClick={() => onSelect(item)}
						onKeyDown={(e) => handleKeyDown(e, index)}
						onFocus={() => setFocusedIndex(index)}
					>
						{item.label}
					</button>
				</li>
			))}
		</ul>
	);
}

// ✅ Indicadores de foco visíveis
const focusStyles = `
  .focusable:focus {
    outline: 2px solid #0066cc;
    outline-offset: 2px;
    box-shadow: 0 0 0 4px rgba(0, 102, 204, 0.2);
  }
  
  .focusable:focus:not(:focus-visible) {
    outline: none;
    box-shadow: none;
  }
  
  .focusable:focus-visible {
    outline: 2px solid #0066cc;
    outline-offset: 2px;
    box-shadow: 0 0 0 4px rgba(0, 102, 204, 0.2);
  }
  
  @media (prefers-reduced-motion: reduce) {
    .focusable:focus {
      transition: none;
    }
  }
`;
```

---

## 🎨 Design Inclusivo

### **Motion & Animation**

```jsx
// ✅ Respeitar preferências de movimento reduzido
function AnimatedCard({ children, ...props }) {
	const prefersReducedMotion = useMedia("(prefers-reduced-motion: reduce)");

	const animationProps = prefersReducedMotion
		? {}
		: {
				initial: { opacity: 0, y: 20 },
				animate: { opacity: 1, y: 0 },
				transition: { duration: 0.3 },
		  };

	return (
		<motion.div
			className="animated-card"
			{...animationProps}
			{...props}
		>
			{children}
		</motion.div>
	);
}

// Hook para media queries
function useMedia(query) {
	const [matches, setMatches] = useState(false);

	useEffect(() => {
		const media = window.matchMedia(query);
		setMatches(media.matches);

		const listener = (event) => setMatches(event.matches);
		media.addListener(listener);

		return () => media.removeListener(listener);
	}, [query]);

	return matches;
}

// ✅ Controles de animação
function AnimationControls() {
	const [animationsEnabled, setAnimationsEnabled] = useState(true);

	useEffect(() => {
		document.documentElement.classList.toggle(
			"reduce-motion",
			!animationsEnabled
		);
	}, [animationsEnabled]);

	return (
		<button
			onClick={() => setAnimationsEnabled(!animationsEnabled)}
			aria-pressed={animationsEnabled}
			className="animation-toggle"
		>
			{animationsEnabled ? "Disable" : "Enable"} Animations
		</button>
	);
}
```

### **Color & Contrast**

```jsx
// ✅ Sistema de cores acessível
const colorSystem = {
	// Base colors with WCAG AA compliance
	primary: {
		50: "#eff6ff", // Light backgrounds
		100: "#dbeafe", // Subtle backgrounds
		500: "#3b82f6", // Main brand color
		600: "#2563eb", // Hover states
		700: "#1d4ed8", // Active states
		900: "#1e3a8a", // High contrast text
	},

	// Semantic colors
	semantic: {
		success: {
			light: "#dcfce7",
			main: "#16a34a", // 4.5:1 contrast ratio
			dark: "#15803d",
		},
		warning: {
			light: "#fefce8",
			main: "#ca8a04", // 4.5:1 contrast ratio
			dark: "#a16207",
		},
		error: {
			light: "#fef2f2",
			main: "#dc2626", // 4.5:1 contrast ratio
			dark: "#b91c1c",
		},
	},
};

// ✅ Componente de status com múltiplos indicadores
function StatusIndicator({ status, children }) {
	const statusConfig = {
		success: {
			color: colorSystem.semantic.success.main,
			icon: "✓",
			bgColor: colorSystem.semantic.success.light,
		},
		warning: {
			color: colorSystem.semantic.warning.main,
			icon: "⚠",
			bgColor: colorSystem.semantic.warning.light,
		},
		error: {
			color: colorSystem.semantic.error.main,
			icon: "✕",
			bgColor: colorSystem.semantic.error.light,
		},
	};

	const config = statusConfig[status];

	return (
		<div
			className="status-indicator"
			style={{
				backgroundColor: config.bgColor,
				color: config.color,
				border: `1px solid ${config.color}`,
			}}
			role="status"
			aria-label={`Status: ${status}`}
		>
			<span
				className="status-indicator__icon"
				aria-hidden="true"
			>
				{config.icon}
			</span>
			<span className="status-indicator__text">{children}</span>
		</div>
	);
}
```

---

## 📱 Responsive Accessibility

### **Touch Targets**

```jsx
// ✅ Touch targets acessíveis (mínimo 44px)
function TouchButton({ size = "medium", children, ...props }) {
	const sizes = {
		small: {
			minHeight: "44px", // WCAG minimum
			minWidth: "44px",
			padding: "8px 12px",
			fontSize: "14px",
		},
		medium: {
			minHeight: "48px", // Comfortable size
			minWidth: "48px",
			padding: "12px 16px",
			fontSize: "16px",
		},
		large: {
			minHeight: "56px", // Generous size
			minWidth: "56px",
			padding: "16px 24px",
			fontSize: "18px",
		},
	};

	return (
		<button
			className="touch-button"
			style={sizes[size]}
			{...props}
		>
			{children}
		</button>
	);
}

// ✅ Espaçamento adequado entre elementos tocáveis
function TouchMenu({ items }) {
	return (
		<nav
			className="touch-menu"
			style={{
				display: "flex",
				flexDirection: "column",
				gap: "8px", // Minimum 8px spacing
			}}
		>
			{items.map((item) => (
				<TouchButton
					key={item.id}
					onClick={item.onClick}
					size="medium"
				>
					{item.label}
				</TouchButton>
			))}
		</nav>
	);
}
```

### **Responsive Patterns**

```jsx
// ✅ Navegação adaptativa
function ResponsiveNavigation({ items }) {
	const [isMobile, setIsMobile] = useState(false);
	const [isMenuOpen, setIsMenuOpen] = useState(false);

	useEffect(() => {
		const checkMobile = () => {
			setIsMobile(window.innerWidth < 768);
		};

		checkMobile();
		window.addEventListener("resize", checkMobile);
		return () => window.removeEventListener("resize", checkMobile);
	}, []);

	if (isMobile) {
		return (
			<nav className="mobile-navigation">
				<button
					className="menu-toggle"
					onClick={() => setIsMenuOpen(!isMenuOpen)}
					aria-expanded={isMenuOpen}
					aria-controls="mobile-menu"
					aria-label="Toggle navigation menu"
				>
					<span
						className="hamburger-icon"
						aria-hidden="true"
					>
						☰
					</span>
				</button>

				<div
					id="mobile-menu"
					className={`mobile-menu ${isMenuOpen ? "mobile-menu--open" : ""}`}
					aria-hidden={!isMenuOpen}
				>
					<ul role="menu">
						{items.map((item) => (
							<li
								key={item.id}
								role="none"
							>
								<a
									href={item.href}
									role="menuitem"
									className="mobile-menu__item"
									onClick={() => setIsMenuOpen(false)}
								>
									{item.label}
								</a>
							</li>
						))}
					</ul>
				</div>
			</nav>
		);
	}

	return (
		<nav className="desktop-navigation">
			<ul role="menubar">
				{items.map((item) => (
					<li
						key={item.id}
						role="none"
					>
						<a
							href={item.href}
							role="menuitem"
							className="desktop-nav__item"
						>
							{item.label}
						</a>
					</li>
				))}
			</ul>
		</nav>
	);
}
```

---

## 🧪 Testing Accessibility

### **Automated Testing**

```jsx
// ✅ Jest + Testing Library para testes a11y
import { render, screen } from "@testing-library/react";
import { axe, toHaveNoViolations } from "jest-axe";
import userEvent from "@testing-library/user-event";

expect.extend(toHaveNoViolations);

describe("Button Accessibility", () => {
	it("should not have accessibility violations", async () => {
		const { container } = render(<Button variant="primary">Click me</Button>);

		const results = await axe(container);
		expect(results).toHaveNoViolations();
	});

	it("should be focusable with keyboard", async () => {
		const user = userEvent.setup();
		render(<Button>Focusable Button</Button>);

		const button = screen.getByRole("button");

		await user.tab();
		expect(button).toHaveFocus();
	});

	it("should have accessible name", () => {
		render(<Button aria-label="Save document">💾</Button>);

		const button = screen.getByRole("button", { name: "Save document" });
		expect(button).toBeInTheDocument();
	});

	it("should announce loading state to screen readers", () => {
		render(<Button loading>Saving...</Button>);

		const button = screen.getByRole("button");
		expect(button).toHaveAttribute("aria-busy", "true");
	});
});

// ✅ Teste de navegação por teclado
describe("Modal Keyboard Navigation", () => {
	it("should trap focus within modal", async () => {
		const user = userEvent.setup();
		const onClose = jest.fn();

		render(
			<Modal
				isOpen
				onClose={onClose}
				title="Test Modal"
			>
				<input placeholder="First input" />
				<input placeholder="Second input" />
				<button>Action</button>
			</Modal>
		);

		const firstInput = screen.getByPlaceholderText("First input");
		const secondInput = screen.getByPlaceholderText("Second input");
		const actionButton = screen.getByRole("button", { name: "Action" });
		const closeButton = screen.getByRole("button", { name: "Close modal" });

		// Tab should cycle through modal elements
		await user.tab();
		expect(closeButton).toHaveFocus();

		await user.tab();
		expect(firstInput).toHaveFocus();

		await user.tab();
		expect(secondInput).toHaveFocus();

		await user.tab();
		expect(actionButton).toHaveFocus();

		// Tab from last element should go to first
		await user.tab();
		expect(closeButton).toHaveFocus();

		// Shift+Tab should go backwards
		await user.tab({ shift: true });
		expect(actionButton).toHaveFocus();
	});

	it("should close on Escape key", async () => {
		const user = userEvent.setup();
		const onClose = jest.fn();

		render(
			<Modal
				isOpen
				onClose={onClose}
				title="Test Modal"
			>
				Content
			</Modal>
		);

		await user.keyboard("{Escape}");
		expect(onClose).toHaveBeenCalled();
	});
});
```

### **Manual Testing Checklist**

```javascript
// ✅ Checklist automatizado para testes manuais
const a11yTestingChecklist = {
	keyboard: [
		"Can navigate to all interactive elements using Tab",
		"Can navigate backwards using Shift+Tab",
		"Focus indicators are clearly visible",
		"Can activate buttons/links using Enter or Space",
		"Can navigate within components using arrow keys",
		"Modal/dropdown focus is properly trapped",
		"Skip links work correctly",
	],

	screenReader: [
		"All content is read aloud in logical order",
		"Headings create proper document outline",
		"Images have descriptive alt text",
		"Form fields have associated labels",
		"Error messages are announced",
		"Status changes are announced (aria-live)",
		"Interactive elements have clear purposes",
	],

	visual: [
		"Text has sufficient color contrast (4.5:1 minimum)",
		"Content is readable at 200% zoom",
		"No information conveyed by color alone",
		"Focus indicators are visible in high contrast mode",
		"Content reflows properly on mobile",
	],

	motor: [
		"Touch targets are at least 44px",
		"Adequate spacing between interactive elements",
		"No time-based interactions without alternatives",
		"Drag and drop has keyboard alternatives",
	],
};

// Função para executar testes automáticos
function runA11yAudit(component) {
	return {
		async checkContrast() {
			// Verificar contraste de cores
			const elements = component.querySelectorAll("*");
			const violations = [];

			elements.forEach((el) => {
				const styles = getComputedStyle(el);
				const color = styles.color;
				const backgroundColor = styles.backgroundColor;

				if (color && backgroundColor) {
					const ratio = calculateContrastRatio(color, backgroundColor);
					if (ratio < 4.5) {
						violations.push({
							element: el,
							ratio,
							expected: 4.5,
						});
					}
				}
			});

			return violations;
		},

		async checkFocusManagement() {
			// Simular navegação por teclado
			const focusableElements = component.querySelectorAll(
				'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
			);

			const violations = [];

			focusableElements.forEach((el) => {
				el.focus();
				const focused = document.activeElement === el;
				const hasVisibleFocus = getComputedStyle(el).outline !== "none";

				if (!focused || !hasVisibleFocus) {
					violations.push({
						element: el,
						issue: !focused ? "not_focusable" : "no_focus_indicator",
					});
				}
			});

			return violations;
		},

		async checkAriaLabels() {
			// Verificar ARIA labels
			const violations = [];
			const interactiveElements = component.querySelectorAll(
				'button, input, select, textarea, [role="button"], [role="link"]'
			);

			interactiveElements.forEach((el) => {
				const hasAccessibleName =
					el.getAttribute("aria-label") ||
					el.getAttribute("aria-labelledby") ||
					el.textContent.trim() ||
					el.getAttribute("title");

				if (!hasAccessibleName) {
					violations.push({
						element: el,
						issue: "missing_accessible_name",
					});
				}
			});

			return violations;
		},
	};
}
```

---

## 🎯 Usability Best Practices

### **Progressive Enhancement**

```jsx
// ✅ Funcionalidade básica sem JavaScript
function SearchForm({ onSubmit }) {
	const [query, setQuery] = useState("");
	const [suggestions, setSuggestions] = useState([]);
	const [jsEnabled, setJsEnabled] = useState(false);

	useEffect(() => {
		setJsEnabled(true);
	}, []);

	const handleSubmit = (e) => {
		e.preventDefault();
		onSubmit(query);
	};

	return (
		<form
			onSubmit={handleSubmit}
			className="search-form"
			// Fallback action for no-JS
			action="/search"
			method="GET"
		>
			<div className="search-input-container">
				<label
					htmlFor="search-input"
					className="sr-only"
				>
					Search
				</label>

				<input
					id="search-input"
					type="search"
					name="q"
					value={query}
					onChange={(e) => setQuery(e.target.value)}
					placeholder="Search..."
					className="search-input"
					autoComplete="off"
					aria-describedby={jsEnabled ? "search-suggestions" : undefined}
					aria-expanded={jsEnabled && suggestions.length > 0}
					aria-haspopup={jsEnabled ? "listbox" : undefined}
				/>

				<button
					type="submit"
					className="search-button"
				>
					<span className="sr-only">Search</span>
					<span aria-hidden="true">🔍</span>
				</button>

				{/* Suggestions apenas com JS habilitado */}
				{jsEnabled && suggestions.length > 0 && (
					<ul
						id="search-suggestions"
						className="search-suggestions"
						role="listbox"
					>
						{suggestions.map((suggestion, index) => (
							<li
								key={index}
								role="option"
								className="search-suggestion"
								onClick={() => setQuery(suggestion)}
							>
								{suggestion}
							</li>
						))}
					</ul>
				)}
			</div>
		</form>
	);
}
```

### **Error Recovery**

```jsx
// ✅ Tratamento gracioso de erros
function RobustComponent({ fallback = null }) {
	return (
		<ErrorBoundary
			fallback={fallback}
			onError={(error, errorInfo) => {
				// Log error for monitoring
				console.error("Component error:", error, errorInfo);

				// Announce error to screen readers
				announceToScreenReader(
					"An error occurred. Please try refreshing the page."
				);
			}}
		>
			<ComplexComponent />
		</ErrorBoundary>
	);
}

class ErrorBoundary extends React.Component {
	constructor(props) {
		super(props);
		this.state = { hasError: false, error: null };
	}

	static getDerivedStateFromError(error) {
		return { hasError: true, error };
	}

	componentDidCatch(error, errorInfo) {
		this.props.onError?.(error, errorInfo);
	}

	render() {
		if (this.state.hasError) {
			return (
				this.props.fallback || (
					<div
						className="error-fallback"
						role="alert"
					>
						<h2>Something went wrong</h2>
						<p>We're sorry, but something unexpected happened.</p>
						<button
							onClick={() => this.setState({ hasError: false, error: null })}
							className="retry-button"
						>
							Try again
						</button>
					</div>
				)
			);
		}

		return this.props.children;
	}
}

// Função para anunciar mensagens para screen readers
function announceToScreenReader(message) {
	const announcement = document.createElement("div");
	announcement.setAttribute("aria-live", "assertive");
	announcement.setAttribute("aria-atomic", "true");
	announcement.className = "sr-only";
	announcement.textContent = message;

	document.body.appendChild(announcement);

	setTimeout(() => {
		document.body.removeChild(announcement);
	}, 1000);
}
```

---

## ✅ Accessibility Checklist

### **WCAG 2.1 Compliance:**

- [ ] **Perceivable** - Alt text, contraste, áudio/vídeo
- [ ] **Operable** - Navegação por teclado, sem convulsões
- [ ] **Understandable** - Conteúdo claro, input assistido
- [ ] **Robust** - Compatível com tecnologias assistivas

### **Technical Implementation:**

- [ ] **Semantic HTML** - Uso correto de elementos HTML
- [ ] **ARIA Attributes** - Roles, properties e states
- [ ] **Focus Management** - Indicadores visíveis e trap
- [ ] **Keyboard Support** - Todas funcionalidades acessíveis

### **Testing:**

- [ ] **Automated Tests** - axe-core, jest-axe
- [ ] **Manual Testing** - Teclado, screen reader
- [ ] **User Testing** - Usuários com deficiências
- [ ] **Performance** - Não impacta carregamento

### **Design:**

- [ ] **Color Contrast** - Mínimo 4.5:1 para texto
- [ ] **Touch Targets** - Mínimo 44px para mobile
- [ ] **Motion** - Respeita prefers-reduced-motion
- [ ] **Progressive Enhancement** - Funciona sem JS

---

_Este guia foca em acessibilidade e usabilidade. Para patterns específicos de React, consulte frontend/react-patterns/_
