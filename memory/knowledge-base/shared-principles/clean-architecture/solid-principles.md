# Clean Architecture: SOLID Principles

## 🎯 Core Principle

**SOLID principles are fundamental design principles that make software designs more understandable, flexible, and maintainable.**

These principles guide the creation of clean, well-structured code that follows Clean Architecture patterns.

---

## 🔥 Single Responsibility Principle (SRP)

> "A class should have only one reason to change."

Each class should have only one job or responsibility.

### **Problem: Multiple Responsibilities**

```typescript
// ❌ Bad - Multiple responsibilities in one class
class User {
	constructor(public name: string, public email: string) {}

	// Responsibility 1: User business logic
	validateEmail(): boolean {
		return this.email.includes("@");
	}

	// Responsibility 2: Database operations
	save(): void {
		// Database saving logic
		console.log("Saving user to database...");
	}

	// Responsibility 3: Email notifications
	sendWelcomeEmail(): void {
		// Email sending logic
		console.log(`Sending welcome email to ${this.email}`);
	}

	// Responsibility 4: Data formatting
	toJSON(): string {
		return JSON.stringify({
			name: this.name,
			email: this.email,
		});
	}
}
```

### **Solution: Separate Responsibilities**

```typescript
// ✅ Good - Each class has one responsibility
class User {
	constructor(public readonly name: string, public readonly email: string) {}

	validateEmail(): boolean {
		return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email);
	}
}

class UserRepository {
	save(user: User): void {
		// Database saving logic
		console.log("Saving user to database...");
	}

	findByEmail(email: string): User | null {
		// Database retrieval logic
		return null;
	}
}

class EmailService {
	sendWelcomeEmail(user: User): void {
		// Email sending logic
		console.log(`Sending welcome email to ${user.email}`);
	}
}

class UserPresenter {
	toJSON(user: User): string {
		return JSON.stringify({
			name: user.name,
			email: user.email,
		});
	}

	toHTML(user: User): string {
		return `<div><h3>${user.name}</h3><p>${user.email}</p></div>`;
	}
}
```

---

## 🔓 Open/Closed Principle (OCP)

> "Software entities should be open for extension, but closed for modification."

You should be able to extend behavior without modifying existing code.

### **Problem: Modifying Existing Code for New Features**

```typescript
// ❌ Bad - Must modify existing code to add new discount types
class DiscountCalculator {
	calculateDiscount(order: Order, discountType: string): number {
		if (discountType === "student") {
			return order.total * 0.1; // 10% student discount
		} else if (discountType === "senior") {
			return order.total * 0.15; // 15% senior discount
		} else if (discountType === "employee") {
			return order.total * 0.2; // 20% employee discount
		}
		return 0;
	}
}
```

### **Solution: Use Abstraction for Extension**

```typescript
// ✅ Good - Open for extension, closed for modification
abstract class DiscountStrategy {
	abstract calculateDiscount(order: Order): number;
}

class StudentDiscountStrategy extends DiscountStrategy {
	calculateDiscount(order: Order): number {
		return order.total * 0.1; // 10% student discount
	}
}

class SeniorDiscountStrategy extends DiscountStrategy {
	calculateDiscount(order: Order): number {
		return order.total * 0.15; // 15% senior discount
	}
}

class EmployeeDiscountStrategy extends DiscountStrategy {
	calculateDiscount(order: Order): number {
		return order.total * 0.2; // 20% employee discount
	}
}

// New discount types can be added without modifying existing code
class VIPDiscountStrategy extends DiscountStrategy {
	calculateDiscount(order: Order): number {
		return order.total * 0.25; // 25% VIP discount
	}
}

class DiscountCalculator {
	calculateDiscount(order: Order, strategy: DiscountStrategy): number {
		return strategy.calculateDiscount(order);
	}
}
```

---

## 🔄 Liskov Substitution Principle (LSP)

> "Objects of a superclass should be replaceable with objects of a subclass without breaking the application."

Subtypes must be substitutable for their base types.

### **Problem: Subclass Changes Expected Behavior**

```typescript
// ❌ Bad - Violates LSP
class Rectangle {
	constructor(protected width: number, protected height: number) {}

	setWidth(width: number): void {
		this.width = width;
	}

	setHeight(height: number): void {
		this.height = height;
	}

	getArea(): number {
		return this.width * this.height;
	}
}

class Square extends Rectangle {
	constructor(side: number) {
		super(side, side);
	}

	// Violates LSP - changes the behavior expected from Rectangle
	setWidth(width: number): void {
		this.width = width;
		this.height = width; // Square constraint
	}

	setHeight(height: number): void {
		this.width = height; // Square constraint
		this.height = height;
	}
}

// This function expects Rectangle behavior but breaks with Square
function calculateArea(rectangle: Rectangle): number {
	rectangle.setWidth(5);
	rectangle.setHeight(4);
	return rectangle.getArea(); // Expected: 20, but Square returns 16
}
```

### **Solution: Ensure Substitutability**

```typescript
// ✅ Good - Proper abstraction that maintains substitutability
abstract class Shape {
	abstract getArea(): number;
}

class Rectangle extends Shape {
	constructor(private width: number, private height: number) {
		super();
	}

	getArea(): number {
		return this.width * this.height;
	}

	setDimensions(width: number, height: number): void {
		this.width = width;
		this.height = height;
	}
}

class Square extends Shape {
	constructor(private side: number) {
		super();
	}

	getArea(): number {
		return this.side * this.side;
	}

	setSide(side: number): void {
		this.side = side;
	}
}

// Now both shapes can be used interchangeably
function printArea(shape: Shape): void {
	console.log(`Area: ${shape.getArea()}`);
}
```

---

## 🔌 Interface Segregation Principle (ISP)

> "Clients should not be forced to depend on interfaces they do not use."

Create specific interfaces rather than one large general-purpose interface.

### **Problem: Fat Interface**

```typescript
// ❌ Bad - Fat interface forces unnecessary dependencies
interface Worker {
	work(): void;
	eat(): void;
	sleep(): void;
	code(): void;
	design(): void;
	test(): void;
}

class Developer implements Worker {
	work(): void {
		/* implementation */
	}
	eat(): void {
		/* implementation */
	}
	sleep(): void {
		/* implementation */
	}
	code(): void {
		/* implementation */
	}

	// Forced to implement methods that don't apply
	design(): void {
		throw new Error("Developers don't design");
	}

	test(): void {
		throw new Error("Developers don't test"); // Bad assumption, but example
	}
}

class Designer implements Worker {
	work(): void {
		/* implementation */
	}
	eat(): void {
		/* implementation */
	}
	sleep(): void {
		/* implementation */
	}
	design(): void {
		/* implementation */
	}

	// Forced to implement methods that don't apply
	code(): void {
		throw new Error("Designers don't code");
	}

	test(): void {
		throw new Error("Designers don't test");
	}
}
```

### **Solution: Segregated Interfaces**

```typescript
// ✅ Good - Segregated interfaces
interface Workable {
	work(): void;
}

interface Eatable {
	eat(): void;
}

interface Sleepable {
	sleep(): void;
}

interface Codeable {
	code(): void;
}

interface Designable {
	design(): void;
}

interface Testable {
	test(): void;
}

class Developer implements Workable, Eatable, Sleepable, Codeable, Testable {
	work(): void {
		/* implementation */
	}
	eat(): void {
		/* implementation */
	}
	sleep(): void {
		/* implementation */
	}
	code(): void {
		/* implementation */
	}
	test(): void {
		/* implementation */
	}
}

class Designer implements Workable, Eatable, Sleepable, Designable {
	work(): void {
		/* implementation */
	}
	eat(): void {
		/* implementation */
	}
	sleep(): void {
		/* implementation */
	}
	design(): void {
		/* implementation */
	}
}

class QATester implements Workable, Eatable, Sleepable, Testable {
	work(): void {
		/* implementation */
	}
	eat(): void {
		/* implementation */
	}
	sleep(): void {
		/* implementation */
	}
	test(): void {
		/* implementation */
	}
}
```

---

## ⬇️ Dependency Inversion Principle (DIP)

> "High-level modules should not depend on low-level modules. Both should depend on abstractions."

Depend on abstractions, not concretions.

### **Problem: High-Level Depends on Low-Level**

```typescript
// ❌ Bad - High-level module depends on low-level modules
class MySQLUserRepository {
	save(user: User): void {
		// MySQL-specific implementation
		console.log("Saving user to MySQL database");
	}

	findById(id: string): User | null {
		// MySQL-specific implementation
		return null;
	}
}

class EmailService {
	send(to: string, subject: string, body: string): void {
		// Email implementation
		console.log(`Sending email to ${to}`);
	}
}

// High-level module depends on concrete implementations
class UserService {
	private userRepository = new MySQLUserRepository(); // Direct dependency
	private emailService = new EmailService(); // Direct dependency

	createUser(userData: any): void {
		const user = new User(userData.name, userData.email);
		this.userRepository.save(user); // Tightly coupled to MySQL
		this.emailService.send(user.email, "Welcome", "Welcome to our service!");
	}
}
```

### **Solution: Depend on Abstractions**

```typescript
// ✅ Good - Depend on abstractions
interface UserRepository {
	save(user: User): void;
	findById(id: string): User | null;
}

interface NotificationService {
	send(to: string, subject: string, body: string): void;
}

// Low-level modules implement abstractions
class MySQLUserRepository implements UserRepository {
	save(user: User): void {
		console.log("Saving user to MySQL database");
	}

	findById(id: string): User | null {
		return null;
	}
}

class PostgreSQLUserRepository implements UserRepository {
	save(user: User): void {
		console.log("Saving user to PostgreSQL database");
	}

	findById(id: string): User | null {
		return null;
	}
}

class EmailNotificationService implements NotificationService {
	send(to: string, subject: string, body: string): void {
		console.log(`Sending email to ${to}`);
	}
}

class SMSNotificationService implements NotificationService {
	send(to: string, subject: string, body: string): void {
		console.log(`Sending SMS to ${to}`);
	}
}

// High-level module depends on abstractions
class UserService {
	constructor(
		private userRepository: UserRepository, // Abstraction
		private notificationService: NotificationService // Abstraction
	) {}

	createUser(userData: any): void {
		const user = new User(userData.name, userData.email);
		this.userRepository.save(user);
		this.notificationService.send(
			user.email,
			"Welcome",
			"Welcome to our service!"
		);
	}
}

// Dependency injection at composition root
const userRepository = new MySQLUserRepository();
const notificationService = new EmailNotificationService();
const userService = new UserService(userRepository, notificationService);
```

---

## 🏗️ SOLID in Clean Architecture

### **How SOLID Enables Clean Architecture**

```typescript
// Example: Clean Architecture with SOLID principles
// Entity (Core) - SRP: Only business rules
class User {
	constructor(
		public readonly id: UserId,
		public readonly email: Email,
		public readonly name: string
	) {}

	// Business rule: User can only change their own data
	canModify(requestingUserId: UserId): boolean {
		return this.id.equals(requestingUserId);
	}
}

// Use Case (Application) - SRP: Application-specific business logic
class CreateUserUseCase {
	constructor(
		private userRepository: UserRepository, // DIP: Depend on abstraction
		private emailService: EmailService // DIP: Depend on abstraction
	) {}

	async execute(request: CreateUserRequest): Promise<CreateUserResponse> {
		// Application business logic
		const user = new User(
			new UserId(request.id),
			new Email(request.email),
			request.name
		);

		await this.userRepository.save(user);
		await this.emailService.sendWelcomeEmail(user);

		return new CreateUserResponse(user.id.value);
	}
}

// Interface Adapter - LSP: Substitutable implementations
class PostgreSQLUserRepository implements UserRepository {
	async save(user: User): Promise<void> {
		// PostgreSQL-specific implementation
	}
}

class MySQLUserRepository implements UserRepository {
	async save(user: User): Promise<void> {
		// MySQL-specific implementation
	}
}

// Controller - ISP: Specific interface for web concerns
interface WebController {
	handle(request: WebRequest): Promise<WebResponse>;
}

class CreateUserController implements WebController {
	constructor(private createUserUseCase: CreateUserUseCase) {} // DIP

	async handle(request: WebRequest): Promise<WebResponse> {
		try {
			const result = await this.createUserUseCase.execute({
				id: request.body.id,
				email: request.body.email,
				name: request.body.name,
			});

			return new WebResponse(201, result);
		} catch (error) {
			return new WebResponse(400, { error: error.message });
		}
	}
}
```

---

## ✅ SOLID Principles Checklist

When designing classes and interfaces, verify:

### **Single Responsibility Principle:**

- [ ] **Does this class have only one reason to change?**
- [ ] **Can I describe what this class does in one sentence?**
- [ ] **Are all methods related to the class's main responsibility?**

### **Open/Closed Principle:**

- [ ] **Can I add new behavior without modifying existing code?**
- [ ] **Are extension points clearly defined through abstractions?**
- [ ] **Is the class protected from changes due to new requirements?**

### **Liskov Substitution Principle:**

- [ ] **Can I replace the base class with any derived class?**
- [ ] **Do derived classes strengthen (not weaken) preconditions?**
- [ ] **Do derived classes weaken (not strengthen) postconditions?**

### **Interface Segregation Principle:**

- [ ] **Are interfaces focused on specific client needs?**
- [ ] **Do clients depend only on methods they actually use?**
- [ ] **Can interfaces be composed to create more complex contracts?**

### **Dependency Inversion Principle:**

- [ ] **Do high-level modules depend on abstractions?**
- [ ] **Are concrete implementations injected from the outside?**
- [ ] **Can I easily swap implementations for testing or different environments?**

---

## 🔗 Related Principles

- **Clean Architecture Layers**: SOLID principles guide the design of each layer
- **Dependency Rule**: DIP enables the dependency rule that makes Clean Architecture work
- **Use Cases**: SRP ensures use cases are focused and testable
- **Domain Entities**: LSP and ISP help design robust domain models

---

_Based on "Clean Architecture" by Robert C. Martin and the original SOLID principles_
