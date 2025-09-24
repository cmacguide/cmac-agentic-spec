# Clean Code: Refactoring Patterns

## 🎯 Core Principle

**Refactoring is the process of changing a software system without altering its external behavior to improve its internal structure.**

The goal is to make code more readable, maintainable, and extensible while keeping the same functionality.

---

## 🔄 Refactoring Fundamentals

### **When to Refactor**

- **Before adding new features** - Clean code first, then add
- **When fixing bugs** - Understanding leads to improvement opportunities
- **During code reviews** - Fresh eyes spot improvement opportunities
- **When code smells appear** - Don't let technical debt accumulate

### **The Boy Scout Rule**

> "Leave the code cleaner than you found it"

Always make small improvements when you touch code, even if that wasn't your primary purpose.

```typescript
// Before: You're fixing a bug in this function
function calculateDiscount(user: any, order: any): number {
	var d = 0; // Bad naming
	if (user.type == "premium") {
		// Use strict equality
		d = order.total * 0.1;
	}
	return d;
}

// After: Fix the bug AND improve the code
function calculateDiscount(user: User, order: Order): number {
	let discount = 0; // Better naming
	if (user.type === "premium") {
		// Strict equality
		discount = order.total * PREMIUM_DISCOUNT_RATE; // Named constant
	}
	return discount;
}
```

---

## 🏗️ Extract Method Pattern

### **Problem: Long Method**

Methods that try to do too much are hard to read, test, and maintain.

```typescript
// ❌ Bad - Long method doing multiple things
class OrderProcessor {
	processOrder(order: Order): void {
		// Validate order (20 lines)
		if (!order.customerId) throw new Error("Invalid customer");
		if (!order.items || order.items.length === 0) throw new Error("No items");
		for (const item of order.items) {
			if (!item.productId) throw new Error("Invalid product");
			if (item.quantity <= 0) throw new Error("Invalid quantity");
		}

		// Calculate totals (15 lines)
		let subtotal = 0;
		let tax = 0;
		for (const item of order.items) {
			const itemTotal = item.price * item.quantity;
			subtotal += itemTotal;
			tax += itemTotal * item.taxRate;
		}
		order.subtotal = subtotal;
		order.tax = tax;
		order.total = subtotal + tax;

		// Apply discount (10 lines)
		if (order.couponCode) {
			const coupon = this.couponService.findByCode(order.couponCode);
			if (coupon && this.isCouponValid(coupon)) {
				const discountAmount = this.calculateDiscount(coupon, order.subtotal);
				order.discount = discountAmount;
				order.total -= discountAmount;
			}
		}

		// Save to database (5 lines)
		this.orderRepository.save(order);

		// Send notifications (8 lines)
		this.emailService.sendOrderConfirmation(order);
		if (order.customer.smsPreferences.enabled) {
			this.smsService.sendOrderUpdate(order);
		}
	}
}
```

### **Solution: Extract Meaningful Methods**

Break the long method into smaller, focused methods with descriptive names.

```typescript
// ✅ Good - Each method has a single responsibility
class OrderProcessor {
	processOrder(order: Order): void {
		this.validateOrder(order);
		this.calculateOrderTotals(order);
		this.applyDiscounts(order);
		this.saveOrder(order);
		this.sendNotifications(order);
	}

	private validateOrder(order: Order): void {
		this.validateCustomer(order.customerId);
		this.validateOrderItems(order.items);
	}

	private validateCustomer(customerId: string): void {
		if (!customerId) {
			throw new Error("Order must have a valid customer");
		}
	}

	private validateOrderItems(items: OrderItem[]): void {
		if (!items || items.length === 0) {
			throw new Error("Order must contain at least one item");
		}

		for (const item of items) {
			this.validateOrderItem(item);
		}
	}

	private validateOrderItem(item: OrderItem): void {
		if (!item.productId) {
			throw new Error("Order item must have a valid product");
		}
		if (item.quantity <= 0) {
			throw new Error("Order item quantity must be positive");
		}
	}

	private calculateOrderTotals(order: Order): void {
		const { subtotal, tax } = this.calculateSubtotalAndTax(order.items);
		order.subtotal = subtotal;
		order.tax = tax;
		order.total = subtotal + tax;
	}

	private calculateSubtotalAndTax(items: OrderItem[]): {
		subtotal: number;
		tax: number;
	} {
		return items.reduce(
			(totals, item) => {
				const itemTotal = item.price * item.quantity;
				return {
					subtotal: totals.subtotal + itemTotal,
					tax: totals.tax + itemTotal * item.taxRate,
				};
			},
			{ subtotal: 0, tax: 0 }
		);
	}

	private applyDiscounts(order: Order): void {
		if (!order.couponCode) return;

		const coupon = this.couponService.findByCode(order.couponCode);
		if (!coupon || !this.isCouponValid(coupon)) return;

		const discountAmount = this.calculateDiscount(coupon, order.subtotal);
		order.discount = discountAmount;
		order.total -= discountAmount;
	}

	private saveOrder(order: Order): void {
		this.orderRepository.save(order);
	}

	private sendNotifications(order: Order): void {
		this.emailService.sendOrderConfirmation(order);

		if (order.customer.smsPreferences.enabled) {
			this.smsService.sendOrderUpdate(order);
		}
	}
}
```

---

## 🎭 Replace Conditional with Polymorphism

### **Problem: Type-based Conditionals**

Code that checks types and behaves differently based on the type.

```typescript
// ❌ Bad - Type checking with conditionals
class PaymentProcessor {
	processPayment(payment: Payment): PaymentResult {
		if (payment.type === "credit_card") {
			// Credit card processing logic
			const fee = payment.amount * 0.03;
			return {
				success: true,
				transactionId: this.generateId(),
				fee: fee,
			};
		} else if (payment.type === "paypal") {
			// PayPal processing logic
			const fee = payment.amount * 0.025;
			return {
				success: true,
				transactionId: this.generatePayPalId(),
				fee: fee,
			};
		} else if (payment.type === "bank_transfer") {
			// Bank transfer processing logic
			const fee = 5.0; // Flat fee
			return {
				success: true,
				transactionId: this.generateBankId(),
				fee: fee,
			};
		} else {
			throw new Error(`Unsupported payment type: ${payment.type}`);
		}
	}
}
```

### **Solution: Use Polymorphism**

Create separate classes for each type and use polymorphism instead of conditionals.

```typescript
// ✅ Good - Polymorphic payment processors
abstract class PaymentProcessor {
	abstract processPayment(amount: number): PaymentResult;
	abstract calculateFee(amount: number): number;
}

class CreditCardProcessor extends PaymentProcessor {
	processPayment(amount: number): PaymentResult {
		const fee = this.calculateFee(amount);
		return {
			success: true,
			transactionId: this.generateCreditCardId(),
			fee: fee,
		};
	}

	calculateFee(amount: number): number {
		return amount * 0.03; // 3% fee
	}

	private generateCreditCardId(): string {
		return `cc_${Date.now()}_${Math.random()}`;
	}
}

class PayPalProcessor extends PaymentProcessor {
	processPayment(amount: number): PaymentResult {
		const fee = this.calculateFee(amount);
		return {
			success: true,
			transactionId: this.generatePayPalId(),
			fee: fee,
		};
	}

	calculateFee(amount: number): number {
		return amount * 0.025; // 2.5% fee
	}

	private generatePayPalId(): string {
		return `pp_${Date.now()}_${Math.random()}`;
	}
}

class BankTransferProcessor extends PaymentProcessor {
	processPayment(amount: number): PaymentResult {
		const fee = this.calculateFee(amount);
		return {
			success: true,
			transactionId: this.generateBankTransferId(),
			fee: fee,
		};
	}

	calculateFee(amount: number): number {
		return 5.0; // Flat $5 fee
	}

	private generateBankTransferId(): string {
		return `bt_${Date.now()}_${Math.random()}`;
	}
}

// Payment service using polymorphism
class PaymentService {
	private processors = new Map<string, PaymentProcessor>([
		["credit_card", new CreditCardProcessor()],
		["paypal", new PayPalProcessor()],
		["bank_transfer", new BankTransferProcessor()],
	]);

	processPayment(payment: Payment): PaymentResult {
		const processor = this.processors.get(payment.type);
		if (!processor) {
			throw new Error(`Unsupported payment type: ${payment.type}`);
		}
		return processor.processPayment(payment.amount);
	}
}
```

---

## 📦 Extract Class Pattern

### **Problem: Large Class with Multiple Responsibilities**

Classes that try to do too much violate the Single Responsibility Principle.

```typescript
// ❌ Bad - User class doing too much
class User {
	// User data
	public id: string;
	public email: string;
	public name: string;
	public password: string;

	// Address data
	public street: string;
	public city: string;
	public zipCode: string;
	public country: string;

	// Preference data
	public emailNotifications: boolean;
	public smsNotifications: boolean;
	public theme: string;
	public language: string;

	// User methods
	updateEmail(newEmail: string): void {
		// Email validation and update logic
	}

	updatePassword(newPassword: string): void {
		// Password validation and hashing logic
	}

	// Address methods
	updateAddress(
		street: string,
		city: string,
		zipCode: string,
		country: string
	): void {
		// Address validation and update logic
	}

	getFullAddress(): string {
		return `${this.street}, ${this.city}, ${this.zipCode}, ${this.country}`;
	}

	// Preference methods
	updateNotificationPreferences(email: boolean, sms: boolean): void {
		// Preference update logic
	}

	updateDisplayPreferences(theme: string, language: string): void {
		// Display preference logic
	}
}
```

### **Solution: Extract Related Functionality into Separate Classes**

Break the large class into smaller, focused classes with single responsibilities.

```typescript
// ✅ Good - Separate classes with single responsibilities
class User {
	constructor(
		public readonly id: string,
		public email: string,
		public name: string,
		private passwordHash: string,
		public address: Address,
		public preferences: UserPreferences
	) {}

	updateEmail(newEmail: string): void {
		if (!this.isValidEmail(newEmail)) {
			throw new Error("Invalid email format");
		}
		this.email = newEmail;
	}

	updatePassword(newPassword: string): void {
		if (!this.isValidPassword(newPassword)) {
			throw new Error("Password does not meet requirements");
		}
		this.passwordHash = this.hashPassword(newPassword);
	}

	private isValidEmail(email: string): boolean {
		return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
	}

	private isValidPassword(password: string): boolean {
		return (
			password.length >= 8 && /[A-Z]/.test(password) && /[0-9]/.test(password)
		);
	}

	private hashPassword(password: string): string {
		// Password hashing logic
		return `hashed_${password}`;
	}
}

class Address {
	constructor(
		public street: string,
		public city: string,
		public zipCode: string,
		public country: string
	) {}

	update(street: string, city: string, zipCode: string, country: string): void {
		if (!this.isValidZipCode(zipCode)) {
			throw new Error("Invalid zip code format");
		}

		this.street = street;
		this.city = city;
		this.zipCode = zipCode;
		this.country = country;
	}

	getFullAddress(): string {
		return `${this.street}, ${this.city}, ${this.zipCode}, ${this.country}`;
	}

	private isValidZipCode(zipCode: string): boolean {
		// Simple validation - could be more sophisticated
		return /^\d{5}(-\d{4})?$/.test(zipCode);
	}
}

class UserPreferences {
	constructor(
		public emailNotifications: boolean = true,
		public smsNotifications: boolean = false,
		public theme: string = "light",
		public language: string = "en"
	) {}

	updateNotificationPreferences(email: boolean, sms: boolean): void {
		this.emailNotifications = email;
		this.smsNotifications = sms;
	}

	updateDisplayPreferences(theme: string, language: string): void {
		if (!this.isValidTheme(theme)) {
			throw new Error("Invalid theme");
		}
		if (!this.isValidLanguage(language)) {
			throw new Error("Invalid language");
		}

		this.theme = theme;
		this.language = language;
	}

	private isValidTheme(theme: string): boolean {
		return ["light", "dark", "auto"].includes(theme);
	}

	private isValidLanguage(language: string): boolean {
		return ["en", "es", "fr", "de", "pt"].includes(language);
	}
}
```

---

## 🔧 Introduce Parameter Object

### **Problem: Long Parameter Lists**

Methods with many parameters are hard to read and maintain.

```typescript
// ❌ Bad - Too many parameters
class UserService {
	createUser(
		firstName: string,
		lastName: string,
		email: string,
		phone: string,
		street: string,
		city: string,
		zipCode: string,
		country: string,
		emailNotifications: boolean,
		smsNotifications: boolean,
		theme: string,
		language: string
	): User {
		// Method implementation
	}

	updateUser(
		id: string,
		firstName: string,
		lastName: string,
		email: string,
		phone: string,
		street: string,
		city: string,
		zipCode: string,
		country: string,
		emailNotifications: boolean,
		smsNotifications: boolean,
		theme: string,
		language: string
	): User {
		// Method implementation
	}
}
```

### **Solution: Group Related Parameters into Objects**

Create parameter objects that group related data together.

```typescript
// ✅ Good - Parameter objects group related data
interface UserCreationData {
	personalInfo: PersonalInfo;
	address: AddressData;
	preferences: PreferenceData;
}

interface PersonalInfo {
	firstName: string;
	lastName: string;
	email: string;
	phone: string;
}

interface AddressData {
	street: string;
	city: string;
	zipCode: string;
	country: string;
}

interface PreferenceData {
	emailNotifications: boolean;
	smsNotifications: boolean;
	theme: string;
	language: string;
}

class UserService {
	createUser(userData: UserCreationData): User {
		this.validateUserData(userData);

		const address = new Address(
			userData.address.street,
			userData.address.city,
			userData.address.zipCode,
			userData.address.country
		);

		const preferences = new UserPreferences(
			userData.preferences.emailNotifications,
			userData.preferences.smsNotifications,
			userData.preferences.theme,
			userData.preferences.language
		);

		return new User(
			this.generateId(),
			userData.personalInfo.email,
			`${userData.personalInfo.firstName} ${userData.personalInfo.lastName}`,
			this.hashPassword(this.generateTemporaryPassword()),
			address,
			preferences
		);
	}

	updateUser(id: string, userData: Partial<UserCreationData>): User {
		const existingUser = this.findUserById(id);

		if (userData.personalInfo) {
			if (userData.personalInfo.email) {
				existingUser.updateEmail(userData.personalInfo.email);
			}
			// Update other personal info...
		}

		if (userData.address) {
			existingUser.address.update(
				userData.address.street,
				userData.address.city,
				userData.address.zipCode,
				userData.address.country
			);
		}

		if (userData.preferences) {
			existingUser.preferences.updateNotificationPreferences(
				userData.preferences.emailNotifications,
				userData.preferences.smsNotifications
			);
			existingUser.preferences.updateDisplayPreferences(
				userData.preferences.theme,
				userData.preferences.language
			);
		}

		return existingUser;
	}
}
```

---

## ✅ Refactoring Checklist

Before and after refactoring, verify:

### **Before Refactoring:**

- [ ] **All tests pass** - Ensure current behavior is captured
- [ ] **Understanding is clear** - Know what the code currently does
- [ ] **Scope is defined** - Know exactly what you're changing
- [ ] **Backup exists** - Version control or backup of current state

### **During Refactoring:**

- [ ] **Small steps** - Make one change at a time
- [ ] **Tests still pass** - Run tests after each change
- [ ] **Behavior unchanged** - External behavior remains the same
- [ ] **Code is cleaner** - Each change improves readability/maintainability

### **After Refactoring:**

- [ ] **All tests pass** - Behavior is preserved
- [ ] **Code is more readable** - Intent is clearer
- [ ] **Complexity is reduced** - Easier to understand and modify
- [ ] **Performance is maintained** - No significant performance degradation

---

## 🔗 Related Principles

- **Single Responsibility Principle**: Each class/method should have one reason to change
- **Open/Closed Principle**: Software should be open for extension, closed for modification
- **DRY (Don't Repeat Yourself)**: Eliminate code duplication
- **KISS (Keep It Simple, Stupid)**: Prefer simple solutions over complex ones

---

_Based on "Refactoring: Improving the Design of Existing Code" by Martin Fowler and "Clean Code" by Robert C. Martin_
