# Clean Code: Functions

## 🎯 Core Principle

**Functions should do one thing. They should do it well. They should do it only.**

A function should have a single reason to change and should be at a single level of abstraction.

---

## 📏 Size and Structure

### **Small Functions**

- Functions should be **small**
- Functions should be **smaller than that**
- 20 lines is getting large
- 10-15 lines is better
- 5 lines or less is ideal

```typescript
// ❌ Bad - Too long, does multiple things
function processUserRegistration(userData: any): boolean {
	// Validate email format
	const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
	if (!emailRegex.test(userData.email)) {
		console.error("Invalid email format");
		return false;
	}

	// Check if user already exists
	const existingUser = database.findUserByEmail(userData.email);
	if (existingUser) {
		console.error("User already exists");
		return false;
	}

	// Hash password
	const hashedPassword = bcrypt.hashSync(userData.password, 10);

	// Create user record
	const newUser = {
		email: userData.email,
		password: hashedPassword,
		createdAt: new Date(),
		isActive: true,
	};

	// Save to database
	try {
		database.saveUser(newUser);
		console.log("User registered successfully");
		return true;
	} catch (error) {
		console.error("Failed to save user:", error);
		return false;
	}
}

// ✅ Good - Small, focused functions
function processUserRegistration(userData: UserRegistrationData): boolean {
	if (!isValidEmail(userData.email)) return false;
	if (userAlreadyExists(userData.email)) return false;

	const user = createNewUser(userData);
	return saveUser(user);
}

function isValidEmail(email: string): boolean {
	const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
	return emailRegex.test(email);
}

function userAlreadyExists(email: string): boolean {
	return database.findUserByEmail(email) !== null;
}

function createNewUser(userData: UserRegistrationData): User {
	return {
		email: userData.email,
		password: hashPassword(userData.password),
		createdAt: new Date(),
		isActive: true,
	};
}
```

### **Single Level of Abstraction**

All statements in a function should be at the same level of abstraction.

```typescript
// ❌ Bad - Mixed levels of abstraction
function generateReport(users: User[]): string {
	let report = "<html><body><h1>User Report</h1>";

	for (const user of users) {
		// High-level business logic mixed with low-level HTML
		const isActive =
			user.lastLoginDate > new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
		report += `<p>${user.name} - ${isActive ? "Active" : "Inactive"}</p>`;
	}

	report += "</body></html>";
	return report;
}

// ✅ Good - Consistent abstraction level
function generateReport(users: User[]): string {
	const reportData = users.map(analyzeUser);
	return formatAsHtmlReport(reportData);
}

function analyzeUser(user: User): UserAnalysis {
	return {
		name: user.name,
		isActive: isUserActive(user),
		lastLoginDays: calculateDaysSinceLastLogin(user),
	};
}

function isUserActive(user: User): boolean {
	const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
	return user.lastLoginDate > thirtyDaysAgo;
}
```

---

## 🎯 Function Purpose

### **One Thing Rule**

A function should do one thing and do it well. If you can extract another function from it with a meaningful name, it's doing more than one thing.

```typescript
// ❌ Bad - Does multiple things
function processOrder(order: Order): void {
	// Validate order
	if (!order.items.length) throw new Error("Order has no items");
	if (!order.customerId) throw new Error("Order has no customer");

	// Calculate totals
	let subtotal = 0;
	for (const item of order.items) {
		subtotal += item.price * item.quantity;
	}
	const tax = subtotal * 0.1;
	const total = subtotal + tax;

	// Apply discount
	if (order.couponCode) {
		const discount = lookupDiscount(order.couponCode);
		order.total = total - discount;
	} else {
		order.total = total;
	}

	// Send notification
	emailService.sendOrderConfirmation(order);

	// Save to database
	database.saveOrder(order);
}

// ✅ Good - Each function does one thing
function processOrder(order: Order): void {
	validateOrder(order);
	calculateOrderTotal(order);
	saveOrder(order);
	sendOrderConfirmation(order);
}

function validateOrder(order: Order): void {
	if (!order.items.length) throw new Error("Order has no items");
	if (!order.customerId) throw new Error("Order has no customer");
}

function calculateOrderTotal(order: Order): void {
	const subtotal = calculateSubtotal(order.items);
	const tax = calculateTax(subtotal);
	const discount = calculateDiscount(order.couponCode, subtotal);
	order.total = subtotal + tax - discount;
}
```

---

## 📝 Naming Functions

### **Use Descriptive Names**

Don't be afraid of long names. A long descriptive name is better than a short enigmatic one.

```typescript
// ❌ Bad - Unclear purpose
function calc(u: User): number {}
function proc(data: any): void {}
function handle(req: Request): Response {}

// ✅ Good - Clear purpose
function calculateUserCreditScore(user: User): number {}
function processPaymentTransaction(transactionData: PaymentData): void {}
function handleUserRegistrationRequest(
	request: RegistrationRequest
): RegistrationResponse {}
```

### **Verb/Noun Pairs**

Functions should be verbs or verb phrases that clearly indicate their action.

```typescript
// ✅ Good naming patterns
function getUser(id: string): User {}
function setUserEmail(user: User, email: string): void {}
function isValidPassword(password: string): boolean {}
function canUserAccessResource(user: User, resource: Resource): boolean {}
function shouldSendNotification(user: User, event: Event): boolean {}
```

---

## 🔧 Function Arguments

### **Argument Count Guidelines**

- **Zero arguments** (niladic) - ideal
- **One argument** (monadic) - good
- **Two arguments** (dyadic) - sometimes necessary
- **Three arguments** (triadic) - avoid when possible
- **More than three** - requires very special justification

```typescript
// ✅ Good - Zero arguments
function getCurrentTimestamp(): Date {
	return new Date();
}

// ✅ Good - One argument
function calculateSquare(number: number): number {
	return number * number;
}

// ✅ Good - Two arguments (natural pair)
function createPoint(x: number, y: number): Point {
	return { x, y };
}

// ❌ Bad - Too many arguments
function createUser(
	firstName: string,
	lastName: string,
	email: string,
	phone: string,
	address: string,
	city: string,
	zipCode: string,
	country: string
): User {}

// ✅ Good - Use object for multiple related parameters
function createUser(userData: UserCreationData): User {}

interface UserCreationData {
	firstName: string;
	lastName: string;
	email: string;
	phone: string;
	address: Address;
}
```

### **Avoid Flag Arguments**

Flag arguments are ugly and indicate the function does more than one thing.

```typescript
// ❌ Bad - Flag argument
function render(isSuite: boolean): void {
	if (isSuite) {
		renderSuite();
	} else {
		renderSingleTest();
	}
}

// ✅ Good - Separate functions
function renderSuite(): void {
	// Render suite-specific UI
}

function renderSingleTest(): void {
	// Render single test UI
}
```

---

## 🚫 Avoid Side Effects

### **Functions Should Be Predictable**

A function should not have hidden behaviors or unexpected side effects.

```typescript
// ❌ Bad - Hidden side effect
function checkPassword(userName: string, password: string): boolean {
	const user = User.findByName(userName);
	if (user && user.cryptedPassword === encrypt(password)) {
		Session.initialize(); // Hidden side effect!
		return true;
	}
	return false;
}

// ✅ Good - Separate concerns
function isValidPassword(userName: string, password: string): boolean {
	const user = User.findByName(userName);
	return user && user.cryptedPassword === encrypt(password);
}

function authenticateUser(userName: string, password: string): boolean {
	if (isValidPassword(userName, password)) {
		Session.initialize();
		return true;
	}
	return false;
}
```

### **Command Query Separation**

Functions should either do something or answer something, but not both.

```typescript
// ❌ Bad - Does both command and query
function set(attribute: string, value: string): boolean {
	// Sets the value AND returns whether it was successful
	if (this.attributes.has(attribute)) {
		this.attributes.set(attribute, value);
		return true;
	}
	return false;
}

// ✅ Good - Separate command and query
function setAttribute(attribute: string, value: string): void {
	this.attributes.set(attribute, value);
}

function hasAttribute(attribute: string): boolean {
	return this.attributes.has(attribute);
}
```

---

## ✅ Function Design Checklist

Before finalizing any function, verify:

- [ ] **Does one thing and does it well**
- [ ] **Has a descriptive, intention-revealing name**
- [ ] **Is small (preferably < 20 lines)**
- [ ] **Has minimal arguments (0-2 preferred)**
- [ ] **Has no flag arguments**
- [ ] **Has no side effects (or they're obvious)**
- [ ] **Is at a single level of abstraction**
- [ ] **Can be easily tested**
- [ ] **Has a clear return type**

---

## 🔗 Related Principles

- **Single Responsibility Principle**: Functions should have one reason to change
- **Open/Closed Principle**: Functions should be open for extension, closed for modification
- **Clean Code Naming**: Function names should be clear and intention-revealing
- **Error Handling**: Functions should have clear error handling strategies

---

_Based on "Clean Code" by Robert C. Martin - Chapter 3: Functions_
