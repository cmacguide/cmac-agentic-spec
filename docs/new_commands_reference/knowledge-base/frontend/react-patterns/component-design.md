# Frontend: React Component Patterns

## 🎯 Core Principle

**React components should be focused, reusable, and follow the Single Responsibility Principle for UI concerns.**

This guide focuses on React-specific patterns and best practices for building maintainable user interfaces.

---

## 🧩 Component Design Patterns

### **Functional Components with Hooks**

Modern React development uses functional components with hooks for state and lifecycle management.

```tsx
// ✅ Good - Focused functional component
interface UserProfileProps {
	userId: string;
	onUserUpdate?: (user: User) => void;
}

const UserProfile: React.FC<UserProfileProps> = ({ userId, onUserUpdate }) => {
	// State management with hooks
	const [user, setUser] = useState<User | null>(null);
	const [isLoading, setIsLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	// Effect for data fetching
	useEffect(() => {
		const fetchUser = async () => {
			try {
				setIsLoading(true);
				const userData = await userService.getUser(userId);
				setUser(userData);
			} catch (err) {
				setError(err instanceof Error ? err.message : "Failed to load user");
			} finally {
				setIsLoading(false);
			}
		};

		fetchUser();
	}, [userId]);

	// Event handlers
	const handleUserUpdate = useCallback(
		async (updatedUser: Partial<User>) => {
			if (!user) return;

			try {
				const updated = await userService.updateUser(user.id, updatedUser);
				setUser(updated);
				onUserUpdate?.(updated);
			} catch (err) {
				setError("Failed to update user");
			}
		},
		[user, onUserUpdate]
	);

	// Loading state
	if (isLoading) {
		return <UserProfileSkeleton />;
	}

	// Error state
	if (error) {
		return (
			<ErrorMessage
				message={error}
				onRetry={() => window.location.reload()}
			/>
		);
	}

	// No data state
	if (!user) {
		return <EmptyState message="User not found" />;
	}

	// Main render
	return (
		<div className="user-profile">
			<UserAvatar
				user={user}
				size="large"
			/>
			<UserDetails
				user={user}
				onUpdate={handleUserUpdate}
			/>
			<UserPreferences
				user={user}
				onUpdate={handleUserUpdate}
			/>
		</div>
	);
};
```

### **Custom Hooks for Logic Reuse**

Extract component logic into reusable custom hooks:

```tsx
// ✅ Custom hook for user data management
function useUser(userId: string) {
	const [user, setUser] = useState<User | null>(null);
	const [isLoading, setIsLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	const fetchUser = useCallback(async () => {
		try {
			setIsLoading(true);
			setError(null);
			const userData = await userService.getUser(userId);
			setUser(userData);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Failed to load user");
		} finally {
			setIsLoading(false);
		}
	}, [userId]);

	const updateUser = useCallback(
		async (updates: Partial<User>) => {
			if (!user) return;

			try {
				const updated = await userService.updateUser(user.id, updates);
				setUser(updated);
				return updated;
			} catch (err) {
				setError("Failed to update user");
				throw err;
			}
		},
		[user]
	);

	useEffect(() => {
		fetchUser();
	}, [fetchUser]);

	return {
		user,
		isLoading,
		error,
		refetch: fetchUser,
		updateUser,
	};
}

// ✅ Simplified component using custom hook
const UserProfile: React.FC<UserProfileProps> = ({ userId, onUserUpdate }) => {
	const { user, isLoading, error, updateUser } = useUser(userId);

	const handleUserUpdate = useCallback(
		async (updates: Partial<User>) => {
			try {
				const updated = await updateUser(updates);
				onUserUpdate?.(updated);
			} catch (err) {
				// Error already handled by hook
			}
		},
		[updateUser, onUserUpdate]
	);

	if (isLoading) return <UserProfileSkeleton />;
	if (error) return <ErrorMessage message={error} />;
	if (!user) return <EmptyState message="User not found" />;

	return (
		<div className="user-profile">
			<UserAvatar
				user={user}
				size="large"
			/>
			<UserDetails
				user={user}
				onUpdate={handleUserUpdate}
			/>
			<UserPreferences
				user={user}
				onUpdate={handleUserUpdate}
			/>
		</div>
	);
};
```

---

## 🎨 Component Composition Patterns

### **Compound Components**

Build complex components by composing smaller, focused components:

```tsx
// ✅ Compound component pattern
interface CardProps {
	children: React.ReactNode;
	className?: string;
}

const Card: React.FC<CardProps> & {
	Header: React.FC<CardHeaderProps>;
	Body: React.FC<CardBodyProps>;
	Footer: React.FC<CardFooterProps>;
} = ({ children, className }) => {
	return <div className={`card ${className || ""}`}>{children}</div>;
};

// Sub-components
const CardHeader: React.FC<CardHeaderProps> = ({
	title,
	actions,
	children,
}) => (
	<div className="card-header">
		{title && <h3 className="card-title">{title}</h3>}
		{children}
		{actions && <div className="card-actions">{actions}</div>}
	</div>
);

const CardBody: React.FC<CardBodyProps> = ({ children, padding = true }) => (
	<div className={`card-body ${padding ? "card-body--padded" : ""}`}>
		{children}
	</div>
);

const CardFooter: React.FC<CardFooterProps> = ({
	children,
	align = "right",
}) => <div className={`card-footer card-footer--${align}`}>{children}</div>;

// Attach sub-components
Card.Header = CardHeader;
Card.Body = CardBody;
Card.Footer = CardFooter;

// Usage
const UserCard: React.FC<{ user: User }> = ({ user }) => (
	<Card className="user-card">
		<Card.Header
			title={user.name}
			actions={<MoreOptionsButton />}
		/>
		<Card.Body>
			<UserDetails user={user} />
		</Card.Body>
		<Card.Footer>
			<Button variant="secondary">Edit</Button>
			<Button variant="primary">View Profile</Button>
		</Card.Footer>
	</Card>
);
```

### **Render Props Pattern**

Share logic between components using render props:

```tsx
// ✅ Render props for data fetching
interface DataFetcherProps<T> {
	url: string;
	children: (state: {
		data: T | null;
		loading: boolean;
		error: string | null;
		refetch: () => void;
	}) => React.ReactNode;
}

function DataFetcher<T>({ url, children }: DataFetcherProps<T>) {
	const [data, setData] = useState<T | null>(null);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);

	const fetchData = useCallback(async () => {
		try {
			setLoading(true);
			setError(null);
			const response = await fetch(url);
			if (!response.ok) throw new Error("Failed to fetch");
			const result = await response.json();
			setData(result);
		} catch (err) {
			setError(err instanceof Error ? err.message : "Unknown error");
		} finally {
			setLoading(false);
		}
	}, [url]);

	useEffect(() => {
		fetchData();
	}, [fetchData]);

	return <>{children({ data, loading, error, refetch: fetchData })}</>;
}

// Usage with different render implementations
const UserList: React.FC = () => (
	<DataFetcher<User[]> url="/api/users">
		{({ data: users, loading, error, refetch }) => {
			if (loading) return <Spinner />;
			if (error)
				return (
					<ErrorMessage
						message={error}
						onRetry={refetch}
					/>
				);
			if (!users?.length) return <EmptyState message="No users found" />;

			return (
				<div className="user-list">
					{users.map((user) => (
						<UserCard
							key={user.id}
							user={user}
						/>
					))}
				</div>
			);
		}}
	</DataFetcher>
);
```

---

## 🔄 State Management Patterns

### **Local State with useState**

Use local state for component-specific data:

```tsx
// ✅ Local state for form management
const ContactForm: React.FC<ContactFormProps> = ({ onSubmit, initialData }) => {
	const [formData, setFormData] = useState({
		name: initialData?.name || "",
		email: initialData?.email || "",
		message: initialData?.message || "",
	});

	const [errors, setErrors] = useState<Record<string, string>>({});
	const [isSubmitting, setIsSubmitting] = useState(false);

	const updateField = useCallback(
		(field: string, value: string) => {
			setFormData((prev) => ({ ...prev, [field]: value }));
			// Clear error when user starts typing
			if (errors[field]) {
				setErrors((prev) => ({ ...prev, [field]: "" }));
			}
		},
		[errors]
	);

	const validateForm = useCallback(() => {
		const newErrors: Record<string, string> = {};

		if (!formData.name.trim()) {
			newErrors.name = "Name is required";
		}

		if (!formData.email.trim()) {
			newErrors.email = "Email is required";
		} else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
			newErrors.email = "Please enter a valid email";
		}

		if (!formData.message.trim()) {
			newErrors.message = "Message is required";
		}

		setErrors(newErrors);
		return Object.keys(newErrors).length === 0;
	}, [formData]);

	const handleSubmit = async (e: React.FormEvent) => {
		e.preventDefault();

		if (!validateForm()) return;

		try {
			setIsSubmitting(true);
			await onSubmit(formData);
			setFormData({ name: "", email: "", message: "" });
		} catch (err) {
			setErrors({ submit: "Failed to send message. Please try again." });
		} finally {
			setIsSubmitting(false);
		}
	};

	return (
		<form
			onSubmit={handleSubmit}
			className="contact-form"
		>
			<FormField
				label="Name"
				value={formData.name}
				error={errors.name}
				onChange={(value) => updateField("name", value)}
				required
			/>

			<FormField
				label="Email"
				type="email"
				value={formData.email}
				error={errors.email}
				onChange={(value) => updateField("email", value)}
				required
			/>

			<FormField
				label="Message"
				as="textarea"
				value={formData.message}
				error={errors.message}
				onChange={(value) => updateField("message", value)}
				required
			/>

			{errors.submit && <ErrorMessage message={errors.submit} />}

			<Button
				type="submit"
				disabled={isSubmitting}
				loading={isSubmitting}
			>
				Send Message
			</Button>
		</form>
	);
};
```

### **Context for Shared State**

Use React Context for state that needs to be shared across components:

```tsx
// ✅ Theme context for UI theming
interface ThemeContextValue {
	theme: "light" | "dark";
	toggleTheme: () => void;
	colors: ThemeColors;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({
	children,
}) => {
	const [theme, setTheme] = useState<"light" | "dark">(() => {
		const stored = localStorage.getItem("theme");
		return (stored as "light" | "dark") || "light";
	});

	const toggleTheme = useCallback(() => {
		setTheme((prev) => {
			const newTheme = prev === "light" ? "dark" : "light";
			localStorage.setItem("theme", newTheme);
			return newTheme;
		});
	}, []);

	const colors = useMemo(() => getThemeColors(theme), [theme]);

	const value = useMemo(
		() => ({
			theme,
			toggleTheme,
			colors,
		}),
		[theme, toggleTheme, colors]
	);

	return (
		<ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
	);
};

// Custom hook for using theme
export const useTheme = () => {
	const context = useContext(ThemeContext);
	if (!context) {
		throw new Error("useTheme must be used within ThemeProvider");
	}
	return context;
};

// Usage in components
const Header: React.FC = () => {
	const { theme, toggleTheme, colors } = useTheme();

	return (
		<header style={{ backgroundColor: colors.background }}>
			<h1 style={{ color: colors.text }}>My App</h1>
			<Button onClick={toggleTheme}>{theme === "light" ? "🌙" : "☀️"}</Button>
		</header>
	);
};
```

---

## ⚡ Performance Optimization Patterns

### **Memoization with React.memo**

Prevent unnecessary re-renders of components:

```tsx
// ✅ Memoized component to prevent unnecessary renders
interface UserCardProps {
	user: User;
	onEdit: (user: User) => void;
	onDelete: (userId: string) => void;
}

const UserCard = React.memo<UserCardProps>(({ user, onEdit, onDelete }) => {
	const handleEdit = useCallback(() => {
		onEdit(user);
	}, [user, onEdit]);

	const handleDelete = useCallback(() => {
		onDelete(user.id);
	}, [user.id, onDelete]);

	return (
		<div className="user-card">
			<UserAvatar user={user} />
			<div className="user-info">
				<h3>{user.name}</h3>
				<p>{user.email}</p>
			</div>
			<div className="user-actions">
				<Button onClick={handleEdit}>Edit</Button>
				<Button
					onClick={handleDelete}
					variant="danger"
				>
					Delete
				</Button>
			</div>
		</div>
	);
});

// Custom comparison function for complex props
const UserCardWithCustomComparison = React.memo<UserCardProps>(
	({ user, onEdit, onDelete }) => {
		// Component implementation...
	},
	(prevProps, nextProps) => {
		// Custom comparison - only re-render if user data actually changed
		return (
			prevProps.user.id === nextProps.user.id &&
			prevProps.user.name === nextProps.user.name &&
			prevProps.user.email === nextProps.user.email &&
			prevProps.user.avatar === nextProps.user.avatar
		);
	}
);
```

### **Lazy Loading and Code Splitting**

Split your application into smaller chunks for better performance:

```tsx
// ✅ Lazy loading with React.lazy and Suspense
const UserSettings = React.lazy(() => import("./UserSettings"));
const UserAnalytics = React.lazy(() => import("./UserAnalytics"));
const UserBilling = React.lazy(() => import("./UserBilling"));

const UserDashboard: React.FC = () => {
	const [activeTab, setActiveTab] = useState("profile");

	const renderTabContent = () => {
		switch (activeTab) {
			case "settings":
				return (
					<Suspense fallback={<TabLoadingSkeleton />}>
						<UserSettings />
					</Suspense>
				);
			case "analytics":
				return (
					<Suspense fallback={<TabLoadingSkeleton />}>
						<UserAnalytics />
					</Suspense>
				);
			case "billing":
				return (
					<Suspense fallback={<TabLoadingSkeleton />}>
						<UserBilling />
					</Suspense>
				);
			default:
				return <UserProfile />;
		}
	};

	return (
		<div className="user-dashboard">
			<TabNavigation
				activeTab={activeTab}
				onTabChange={setActiveTab}
				tabs={[
					{ id: "profile", label: "Profile" },
					{ id: "settings", label: "Settings" },
					{ id: "analytics", label: "Analytics" },
					{ id: "billing", label: "Billing" },
				]}
			/>

			<div className="tab-content">{renderTabContent()}</div>
		</div>
	);
};
```

---

## ✅ React Component Checklist

When creating or reviewing React components:

### **Component Structure:**

- [ ] **Single responsibility** - Component has one clear purpose
- [ ] **Pure function** - Same props always produce same output
- [ ] **Props interface** - Clear TypeScript interface for props
- [ ] **Default props** - Sensible defaults where appropriate

### **State Management:**

- [ ] **Appropriate state location** - Local vs context vs external store
- [ ] **Immutable updates** - State updates don't mutate existing state
- [ ] **Effect dependencies** - useEffect dependencies are correct
- [ ] **Cleanup** - Effects clean up subscriptions/timers

### **Performance:**

- [ ] **Memoization** - Expensive calculations memoized with useMemo
- [ ] **Callback stability** - Event handlers memoized with useCallback
- [ ] **Re-render prevention** - React.memo used where appropriate
- [ ] **Bundle size** - Heavy dependencies lazy loaded

### **User Experience:**

- [ ] **Loading states** - Clear loading indicators
- [ ] **Error handling** - Graceful error boundaries and messaging
- [ ] **Empty states** - Helpful empty state messages
- [ ] **Accessibility** - ARIA labels, keyboard navigation, semantic HTML

---

## 🔗 Related Frontend Concepts

- **State Management**: Redux, Zustand, Context patterns
- **UI Architecture**: Component hierarchies, design systems
- **Performance**: Optimization strategies, lazy loading
- **Testing**: Component testing, integration testing

---

_This guide focuses specifically on React component patterns. For universal principles like naming and functions, see shared-principles/clean-code/_
