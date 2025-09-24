# Component Architecture Patterns

Guia abrangente sobre arquitetura de componentes para UI, focando em hierarquia, composição e reutilização baseado nas melhores práticas do React e Design Systems modernos.

---

## 🏗️ Hierarquia de Componentes

### **Estrutura Pyramid**

```
Application Layer
├── Pages/Views (Smart Components)
├── Layout Components
├── Composite Components
├── Base Components (Atomic)
└── Utility Components
```

### **Smart vs Dumb Components**

**Smart Components (Container):**

```jsx
// ✅ Smart Component - Gerencia estado e lógica
import { useState, useEffect } from "react";
import { UserService } from "../services/UserService";
import { UserProfile } from "./UserProfile";

export function UserProfileContainer({ userId }) {
	const [user, setUser] = useState(null);
	const [loading, setLoading] = useState(false);
	const [error, setError] = useState(null);

	useEffect(() => {
		async function fetchUser() {
			setLoading(true);
			try {
				const userData = await UserService.getById(userId);
				setUser(userData);
			} catch (err) {
				setError(err.message);
			} finally {
				setLoading(false);
			}
		}

		fetchUser();
	}, [userId]);

	const handleUpdateUser = async (updates) => {
		try {
			const updatedUser = await UserService.update(userId, updates);
			setUser(updatedUser);
		} catch (err) {
			setError(err.message);
		}
	};

	return (
		<UserProfile
			user={user}
			loading={loading}
			error={error}
			onUpdate={handleUpdateUser}
		/>
	);
}
```

**Dumb Components (Presentational):**

```jsx
// ✅ Dumb Component - Apenas renderização
import { Button } from "../base/Button";
import { Avatar } from "../base/Avatar";
import { LoadingSpinner } from "../base/LoadingSpinner";

export function UserProfile({ user, loading, error, onUpdate }) {
	if (loading) return <LoadingSpinner />;
	if (error) return <div className="error">{error}</div>;
	if (!user) return <div>User not found</div>;

	return (
		<div className="user-profile">
			<header className="user-profile__header">
				<Avatar
					src={user.avatar}
					alt={user.name}
					size="large"
				/>
				<h1 className="user-profile__name">{user.name}</h1>
				<p className="user-profile__email">{user.email}</p>
			</header>

			<section className="user-profile__actions">
				<Button
					variant="primary"
					onClick={() => onUpdate({ lastActive: new Date() })}
				>
					Update Last Active
				</Button>
			</section>
		</div>
	);
}
```

---

## 🧩 Padrões de Composição

### **Children Prop Pattern**

```jsx
// ✅ Container flexível com children
function Card({ children, title, className = "" }) {
	return (
		<div className={`card ${className}`}>
			{title && (
				<div className="card__header">
					<h2 className="card__title">{title}</h2>
				</div>
			)}
			<div className="card__content">{children}</div>
		</div>
	);
}

// Uso
export function ProfileCard({ user }) {
	return (
		<Card title="User Profile">
			<Avatar
				src={user.avatar}
				alt={user.name}
			/>
			<h3>{user.name}</h3>
			<p>{user.bio}</p>
		</Card>
	);
}
```

### **Render Props Pattern**

```jsx
// ✅ Render Props para lógica compartilhada
function DataFetcher({ url, render }) {
	const [data, setData] = useState(null);
	const [loading, setLoading] = useState(false);
	const [error, setError] = useState(null);

	useEffect(() => {
		async function fetchData() {
			setLoading(true);
			try {
				const response = await fetch(url);
				const result = await response.json();
				setData(result);
			} catch (err) {
				setError(err.message);
			} finally {
				setLoading(false);
			}
		}

		fetchData();
	}, [url]);

	return render({ data, loading, error });
}

// Uso
export function UserList() {
	return (
		<DataFetcher
			url="/api/users"
			render={({ data, loading, error }) => {
				if (loading) return <LoadingSpinner />;
				if (error) return <ErrorMessage error={error} />;
				if (!data) return null;

				return (
					<ul className="user-list">
						{data.map((user) => (
							<li key={user.id}>
								<UserCard user={user} />
							</li>
						))}
					</ul>
				);
			}}
		/>
	);
}
```

### **Compound Components Pattern**

```jsx
// ✅ Compound Components - Componentes que trabalham juntos
const Tabs = ({ children, defaultTab = 0 }) => {
	const [activeTab, setActiveTab] = useState(defaultTab);

	return (
		<div className="tabs">
			{React.Children.map(children, (child, index) =>
				React.cloneElement(child, {
					activeTab,
					setActiveTab,
					index,
				})
			)}
		</div>
	);
};

const TabList = ({ children, activeTab, setActiveTab }) => (
	<div
		className="tabs__list"
		role="tablist"
	>
		{React.Children.map(children, (child, index) =>
			React.cloneElement(child, {
				active: activeTab === index,
				onClick: () => setActiveTab(index),
				index,
			})
		)}
	</div>
);

const Tab = ({ children, active, onClick, index }) => (
	<button
		className={`tab ${active ? "tab--active" : ""}`}
		role="tab"
		aria-selected={active}
		onClick={onClick}
	>
		{children}
	</button>
);

const TabPanels = ({ children, activeTab }) => (
	<div className="tabs__panels">
		{React.Children.toArray(children)[activeTab]}
	</div>
);

const TabPanel = ({ children }) => (
	<div
		className="tab-panel"
		role="tabpanel"
	>
		{children}
	</div>
);

// Atribuir sub-componentes
Tabs.List = TabList;
Tabs.Tab = Tab;
Tabs.Panels = TabPanels;
Tabs.Panel = TabPanel;

// Uso
export function SettingsPanel() {
	return (
		<Tabs defaultTab={0}>
			<Tabs.List>
				<Tabs.Tab>General</Tabs.Tab>
				<Tabs.Tab>Security</Tabs.Tab>
				<Tabs.Tab>Privacy</Tabs.Tab>
			</Tabs.List>

			<Tabs.Panels>
				<Tabs.Panel>
					<GeneralSettings />
				</Tabs.Panel>
				<Tabs.Panel>
					<SecuritySettings />
				</Tabs.Panel>
				<Tabs.Panel>
					<PrivacySettings />
				</Tabs.Panel>
			</Tabs.Panels>
		</Tabs>
	);
}
```

### **Higher-Order Components (HOC)**

```jsx
// ✅ HOC para funcionalidades transversais
function withLoading(WrappedComponent) {
	return function WithLoadingComponent(props) {
		const [loading, setLoading] = useState(false);

		const startLoading = () => setLoading(true);
		const stopLoading = () => setLoading(false);

		if (loading) {
			return <LoadingSpinner />;
		}

		return (
			<WrappedComponent
				{...props}
				startLoading={startLoading}
				stopLoading={stopLoading}
			/>
		);
	};
}

// Uso
const UserListWithLoading = withLoading(UserList);

export function UsersPage() {
	return (
		<div className="users-page">
			<h1>Users</h1>
			<UserListWithLoading />
		</div>
	);
}
```

---

## 🔄 Reutilização e Modularidade

### **Component Variants Pattern**

```jsx
// ✅ Sistema de variantes flexível
const Button = ({
	children,
	variant = "primary",
	size = "medium",
	disabled = false,
	loading = false,
	icon,
	...props
}) => {
	const baseClasses = "btn";
	const variantClasses = `btn--${variant}`;
	const sizeClasses = `btn--${size}`;
	const stateClasses = [disabled && "btn--disabled", loading && "btn--loading"]
		.filter(Boolean)
		.join(" ");

	const className = [
		baseClasses,
		variantClasses,
		sizeClasses,
		stateClasses,
	].join(" ");

	return (
		<button
			className={className}
			disabled={disabled || loading}
			{...props}
		>
			{loading && <Spinner size="small" />}
			{icon && <Icon name={icon} />}
			{children}
		</button>
	);
};

// Uso das variantes
export function ActionPanel() {
	return (
		<div className="action-panel">
			<Button
				variant="primary"
				size="large"
			>
				Save Changes
			</Button>

			<Button
				variant="secondary"
				icon="download"
			>
				Export Data
			</Button>

			<Button
				variant="danger"
				size="small"
			>
				Delete
			</Button>

			<Button
				variant="ghost"
				loading
			>
				Processing...
			</Button>
		</div>
	);
}
```

### **Component Factory Pattern**

```jsx
// ✅ Factory para componentes similares
function createFormField(fieldType) {
	return function FormField({ label, name, error, required, ...fieldProps }) {
		const FieldComponent =
			{
				text: "input",
				email: "input",
				password: "input",
				textarea: "textarea",
				select: "select",
			}[fieldType] || "input";

		const fieldSpecificProps =
			fieldType === "textarea" ? { rows: 4 } : { type: fieldType };

		return (
			<div className="form-field">
				<label className="form-field__label">
					{label}
					{required && <span className="required">*</span>}
				</label>

				<FieldComponent
					className={`form-field__input ${
						error ? "form-field__input--error" : ""
					}`}
					name={name}
					aria-invalid={!!error}
					aria-describedby={error ? `${name}-error` : undefined}
					{...fieldSpecificProps}
					{...fieldProps}
				/>

				{error && (
					<span
						id={`${name}-error`}
						className="form-field__error"
						role="alert"
					>
						{error}
					</span>
				)}
			</div>
		);
	};
}

// Criar componentes específicos
const TextField = createFormField("text");
const EmailField = createFormField("email");
const PasswordField = createFormField("password");
const TextAreaField = createFormField("textarea");

// Uso
export function ContactForm() {
	return (
		<form className="contact-form">
			<TextField
				label="Full Name"
				name="fullName"
				required
			/>

			<EmailField
				label="Email Address"
				name="email"
				required
			/>

			<TextAreaField
				label="Message"
				name="message"
				placeholder="Enter your message..."
				required
			/>
		</form>
	);
}
```

### **Plugin Architecture**

```jsx
// ✅ Sistema de plugins para extensibilidade
class ComponentRegistry {
	constructor() {
		this.components = new Map();
		this.plugins = new Map();
	}

	register(name, component) {
		this.components.set(name, component);
	}

	addPlugin(name, plugin) {
		this.plugins.set(name, plugin);
	}

	render(name, props) {
		let Component = this.components.get(name);

		if (!Component) {
			throw new Error(`Component "${name}" not found`);
		}

		// Aplicar plugins
		for (const [pluginName, plugin] of this.plugins) {
			if (plugin.applies(name, props)) {
				Component = plugin.enhance(Component);
			}
		}

		return <Component {...props} />;
	}
}

// Plugin de exemplo
const withAnalytics = {
	applies: (componentName, props) => props.trackEvents,
	enhance: (Component) => (props) => {
		const handleClick = (event) => {
			// Track event
			analytics.track("component_interaction", {
				component: Component.name,
				action: "click",
			});

			if (props.onClick) {
				props.onClick(event);
			}
		};

		return (
			<Component
				{...props}
				onClick={handleClick}
			/>
		);
	},
};

// Uso
const registry = new ComponentRegistry();
registry.register("Button", Button);
registry.addPlugin("analytics", withAnalytics);

export function App() {
	return (
		<div>
			{registry.render("Button", {
				children: "Click me",
				trackEvents: true,
			})}
		</div>
	);
}
```

---

## 🎨 Design Token Integration

### **Theme Provider Pattern**

```jsx
// ✅ Context para tokens de design
const ThemeContext = createContext();

export const ThemeProvider = ({ theme, children }) => {
	const themeValues = {
		colors: {
			primary: theme.primary || "#007bff",
			secondary: theme.secondary || "#6c757d",
			success: theme.success || "#28a745",
			danger: theme.danger || "#dc3545",
			warning: theme.warning || "#ffc107",
			info: theme.info || "#17a2b8",
		},
		spacing: {
			xs: "0.25rem",
			sm: "0.5rem",
			md: "1rem",
			lg: "1.5rem",
			xl: "3rem",
		},
		typography: {
			fontFamily: theme.fontFamily || "system-ui, sans-serif",
			fontSize: {
				sm: "0.875rem",
				base: "1rem",
				lg: "1.125rem",
				xl: "1.25rem",
				"2xl": "1.5rem",
			},
		},
		breakpoints: {
			sm: "640px",
			md: "768px",
			lg: "1024px",
			xl: "1280px",
		},
	};

	return (
		<ThemeContext.Provider value={themeValues}>
			{children}
		</ThemeContext.Provider>
	);
};

export const useTheme = () => {
	const context = useContext(ThemeContext);
	if (!context) {
		throw new Error("useTheme must be used within a ThemeProvider");
	}
	return context;
};

// Componente usando theme
export function StyledButton({ children, variant = "primary", ...props }) {
	const theme = useTheme();

	const styles = {
		backgroundColor: theme.colors[variant],
		padding: `${theme.spacing.sm} ${theme.spacing.md}`,
		fontFamily: theme.typography.fontFamily,
		fontSize: theme.typography.fontSize.base,
		border: "none",
		borderRadius: "0.25rem",
		cursor: "pointer",
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

---

## 📱 Responsive Component Patterns

### **Container Queries Simulation**

```jsx
// ✅ Hook para container queries
function useContainerQuery() {
	const [containerRef, setContainerRef] = useState(null);
	const [size, setSize] = useState({ width: 0, height: 0 });

	useEffect(() => {
		if (!containerRef) return;

		const resizeObserver = new ResizeObserver((entries) => {
			for (const entry of entries) {
				setSize({
					width: entry.contentRect.width,
					height: entry.contentRect.height,
				});
			}
		});

		resizeObserver.observe(containerRef);

		return () => {
			resizeObserver.disconnect();
		};
	}, [containerRef]);

	return [setContainerRef, size];
}

// Componente responsivo baseado no container
export function ResponsiveCard({ title, content, actions }) {
	const [containerRef, { width }] = useContainerQuery();

	const layout = width < 300 ? "stack" : width < 600 ? "compact" : "full";

	return (
		<div
			ref={containerRef}
			className={`card card--${layout}`}
		>
			<header className="card__header">
				<h3 className="card__title">{title}</h3>
			</header>

			<div className="card__content">{content}</div>

			{actions && <footer className="card__actions">{actions}</footer>}
		</div>
	);
}
```

---

## 🧪 Testing Component Architecture

### **Component Testing Strategy**

```jsx
// ✅ Teste de componente isolado
import { render, screen, fireEvent } from "@testing-library/react";
import { Button } from "./Button";

describe("Button Component", () => {
	it("renders with default props", () => {
		render(<Button>Click me</Button>);

		const button = screen.getByRole("button", { name: /click me/i });
		expect(button).toBeInTheDocument();
		expect(button).toHaveClass("btn", "btn--primary", "btn--medium");
	});

	it("applies variant classes correctly", () => {
		render(<Button variant="secondary">Secondary</Button>);

		const button = screen.getByRole("button");
		expect(button).toHaveClass("btn--secondary");
		expect(button).not.toHaveClass("btn--primary");
	});

	it("handles click events", () => {
		const handleClick = jest.fn();
		render(<Button onClick={handleClick}>Click me</Button>);

		fireEvent.click(screen.getByRole("button"));
		expect(handleClick).toHaveBeenCalledTimes(1);
	});

	it("disables button when loading", () => {
		render(<Button loading>Loading</Button>);

		const button = screen.getByRole("button");
		expect(button).toBeDisabled();
		expect(button).toHaveClass("btn--loading");
	});
});

// ✅ Teste de composição
describe("Card with Button Composition", () => {
	it("renders card with button correctly", () => {
		render(
			<Card title="Test Card">
				<Button variant="primary">Action</Button>
			</Card>
		);

		expect(screen.getByText("Test Card")).toBeInTheDocument();
		expect(screen.getByRole("button", { name: /action/i })).toBeInTheDocument();
	});
});
```

---

## 🔍 Anti-Patterns to Avoid

### **❌ God Components**

```jsx
// ❌ Componente monolítico fazendo muitas coisas
function UserDashboard({ userId }) {
	// Muita lógica, muitas responsabilidades
	const [user, setUser] = useState(null);
	const [posts, setPosts] = useState([]);
	const [notifications, setNotifications] = useState([]);
	const [settings, setSettings] = useState({});
	// ... 50+ linhas de useState e useEffect

	return <div className="dashboard">{/* 100+ linhas de JSX complexo */}</div>;
}

// ✅ Decomposição em componentes menores
function UserDashboard({ userId }) {
	return (
		<div className="dashboard">
			<DashboardHeader userId={userId} />
			<div className="dashboard__content">
				<UserProfile userId={userId} />
				<UserPosts userId={userId} />
				<NotificationPanel userId={userId} />
			</div>
			<DashboardSidebar userId={userId} />
		</div>
	);
}
```

### **❌ Prop Drilling Excessivo**

```jsx
// ❌ Props passadas por muitos níveis
function App() {
	const [user, setUser] = useState(null);

	return (
		<Layout user={user}>
			<Dashboard user={user}>
				<UserSection user={user}>
					<UserProfile user={user} />
				</UserSection>
			</Dashboard>
		</Layout>
	);
}

// ✅ Context para dados globais
const UserContext = createContext();

function App() {
	const [user, setUser] = useState(null);

	return (
		<UserContext.Provider value={{ user, setUser }}>
			<Layout>
				<Dashboard>
					<UserSection>
						<UserProfile />
					</UserSection>
				</Dashboard>
			</Layout>
		</UserContext.Provider>
	);
}
```

---

## ✅ Component Architecture Checklist

### **Design:**

- [ ] **Single Responsibility** - Um componente, uma responsabilidade
- [ ] **Composition over Inheritance** - Favor composição
- [ ] **Prop Interface** - Interface clara e tipada
- [ ] **Default Props** - Valores padrão sensatos

### **Reusability:**

- [ ] **Generic Design** - Componente reutilizável
- [ ] **Variant System** - Sistema de variantes consistente
- [ ] **Theme Integration** - Uso de design tokens
- [ ] **Responsive** - Adapta-se a diferentes tamanhos

### **Performance:**

- [ ] **React.memo** - Otimização de re-renders
- [ ] **useCallback/useMemo** - Otimização de callbacks
- [ ] **Code Splitting** - Lazy loading quando apropriado
- [ ] **Bundle Size** - Impacto mínimo no bundle

### **Testing:**

- [ ] **Unit Tests** - Testes de componente isolado
- [ ] **Integration Tests** - Testes de composição
- [ ] **Visual Tests** - Snapshot ou screenshot tests
- [ ] **Accessibility Tests** - Testes a11y automatizados

---

_Este guia foca em padrões de arquitetura de componentes. Para princípios universais de código limpo, consulte shared-principles/clean-code/_
