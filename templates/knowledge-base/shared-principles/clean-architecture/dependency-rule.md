# Clean Architecture: The Dependency Rule

## 🎯 Core Principle

> "Dependencies can only point inward. Nothing in an inner circle can know anything at all about something in an outer circle."

The Dependency Rule is the fundamental principle that makes Clean Architecture work. It ensures that business logic remains independent of external concerns.

---

## 🎪 The Circles of Clean Architecture

```
        🔴 Frameworks & Drivers
      🟡 Interface Adapters
    🟢 Application Business Rules
  🔵 Enterprise Business Rules
```

### **🔵 Inner Circle: Enterprise Business Rules (Entities)**

- **Most stable layer** - changes least frequently
- Contains **core business objects** and **enterprise-wide business rules**
- **Zero dependencies** on outer layers
- Pure business logic with no infrastructure concerns

### **🟢 Second Circle: Application Business Rules (Use Cases)**

- **Application-specific business rules** and workflows
- **Orchestrates entities** to fulfill application requirements
- **Depends only on entities** - no knowledge of UI, database, or frameworks
- Defines interfaces for data access (ports)

### **🟡 Third Circle: Interface Adapters**

- **Converts data** between use cases and external world
- **Controllers, Gateways, Presenters** live here
- **Implements interfaces** defined by use cases
- Knows about both inner circles and outer circle

### **🔴 Outer Circle: Frameworks & Drivers**

- **Frameworks, tools, and external agencies**
- **Web servers, databases, UI frameworks**
- **Most volatile layer** - changes frequently
- Should contain only glue code that connects to inner circles

---

## ⚠️ What the Dependency Rule Prevents

### **❌ Bad: Entities Depending on Infrastructure**

```typescript
// ❌ VIOLATION: Entity depends on database framework
import { MongoCollection } from "mongodb";

class User {
	constructor(
		private id: string,
		private name: string,
		private collection: MongoCollection // WRONG: Infrastructure dependency
	) {}

	async save(): Promise<void> {
		// WRONG: Entity knows about database implementation
		await this.collection.insertOne({
			id: this.id,
			name: this.name,
		});
	}
}

// ❌ VIOLATION: Use case depends on HTTP framework
import { Request, Response } from "express";

class CreateUserUseCase {
	// WRONG: Use case knows about web framework
	async execute(req: Request, res: Response): Promise<void> {
		const user = new User(req.body.id, req.body.name);
		// ...
		res.json({ success: true }); // WRONG: Use case formats HTTP response
	}
}
```

### **✅ Good: Dependencies Point Inward**

```typescript
// ✅ CORRECT: Entity has no external dependencies
class User {
	constructor(
		private readonly id: UserId,
		private name: UserName,
		private email: Email
	) {}

	// Pure business logic
	changeEmail(newEmail: Email, requestingUserId: UserId): void {
		if (!this.id.equals(requestingUserId)) {
			throw new Error("Users can only change their own email");
		}

		if (!newEmail.isValid()) {
			throw new Error("Invalid email format");
		}

		this.email = newEmail;
	}
}

// ✅ CORRECT: Use case depends only on abstractions
interface UserRepository {
	save(user: User): Promise<void>;
	findById(id: UserId): Promise<User | null>;
}

class CreateUserUseCase {
	constructor(
		private userRepository: UserRepository // Abstraction, not concrete implementation
	) {}

	async execute(request: CreateUserRequest): Promise<CreateUserResponse> {
		const user = new User(
			new UserId(request.id),
			new UserName(request.name),
			new Email(request.email)
		);

		await this.userRepository.save(user);

		return new CreateUserResponse(user.getId().value);
	}
}
```

---

## 🔄 Dependency Inversion in Practice

### **The Problem: Natural Dependencies**

Without careful design, dependencies naturally flow outward from stable to volatile:

```
Business Logic → Database
Business Logic → Web Framework
Business Logic → External APIs
```

This makes business logic fragile and hard to test.

### **The Solution: Invert Dependencies**

Use abstractions to invert the dependency direction:

```typescript
// ✅ Define interface in the use case layer (inner)
interface EmailService {
	send(to: Email, subject: string, body: string): Promise<void>;
}

interface UserRepository {
	save(user: User): Promise<void>;
	findByEmail(email: Email): Promise<User | null>;
}

// ✅ Use case depends on abstractions (pointing inward)
class RegisterUserUseCase {
	constructor(
		private userRepository: UserRepository,
		private emailService: EmailService
	) {}

	async execute(request: RegisterUserRequest): Promise<void> {
		// Business logic using abstractions
		const existingUser = await this.userRepository.findByEmail(request.email);
		if (existingUser) {
			throw new Error("User already exists");
		}

		const user = new User(
			new UserId(generateId()),
			new UserName(request.name),
			request.email
		);

		await this.userRepository.save(user);
		await this.emailService.send(
			user.getEmail(),
			"Welcome!",
			"Welcome to our platform!"
		);
	}
}
```

### **Implementation in Outer Layers**

```typescript
// ✅ Infrastructure implements the abstractions (outer layer)
import { MongoClient } from "mongodb";
import { SendGridService } from "@sendgrid/mail";

class MongoUserRepository implements UserRepository {
	constructor(private mongoClient: MongoClient) {}

	async save(user: User): Promise<void> {
		// MongoDB-specific implementation
		await this.mongoClient
			.db("myapp")
			.collection("users")
			.insertOne(user.toJSON());
	}

	async findByEmail(email: Email): Promise<User | null> {
		// MongoDB-specific implementation
		const doc = await this.mongoClient
			.db("myapp")
			.collection("users")
			.findOne({ email: email.value });

		return doc ? User.fromJSON(doc) : null;
	}
}

class SendGridEmailService implements EmailService {
	constructor(private sendGrid: SendGridService) {}

	async send(to: Email, subject: string, body: string): Promise<void> {
		// SendGrid-specific implementation
		await this.sendGrid.send({
			to: to.value,
			from: "noreply@myapp.com",
			subject,
			text: body,
		});
	}
}
```

---

## 🏗️ Layer Communication Patterns

### **Controllers → Use Cases**

Controllers translate external requests into use case requests:

```typescript
// ✅ Controller depends on use case (inward dependency)
class UserController {
	constructor(
		private registerUserUseCase: RegisterUserUseCase,
		private getUserUseCase: GetUserUseCase
	) {}

	async register(httpRequest: HttpRequest): Promise<HttpResponse> {
		try {
			// Translate HTTP request to use case request
			const request = new RegisterUserRequest(
				httpRequest.body.name,
				new Email(httpRequest.body.email)
			);

			await this.registerUserUseCase.execute(request);

			return new HttpResponse(201, { success: true });
		} catch (error) {
			return new HttpResponse(400, { error: error.message });
		}
	}
}
```

### **Use Cases → Entities**

Use cases orchestrate entities to fulfill business requirements:

```typescript
// ✅ Use case orchestrates entities
class TransferMoneyUseCase {
	constructor(private accountRepository: AccountRepository) {}

	async execute(request: TransferMoneyRequest): Promise<void> {
		// Load entities
		const fromAccount = await this.accountRepository.findById(
			request.fromAccountId
		);
		const toAccount = await this.accountRepository.findById(
			request.toAccountId
		);

		if (!fromAccount || !toAccount) {
			throw new Error("Invalid account");
		}

		// Entities enforce business rules
		fromAccount.withdraw(request.amount); // May throw if insufficient funds
		toAccount.deposit(request.amount);

		// Save changes
		await this.accountRepository.save(fromAccount);
		await this.accountRepository.save(toAccount);
	}
}
```

### **Repositories → Database**

Repositories implement data access while hiding implementation details:

```typescript
// ✅ Repository hides database specifics from use cases
class PostgresAccountRepository implements AccountRepository {
	constructor(private db: PostgresDatabase) {}

	async findById(id: AccountId): Promise<Account | null> {
		const row = await this.db.query("SELECT * FROM accounts WHERE id = $1", [
			id.value,
		]);

		return row ? this.mapToAccount(row) : null;
	}

	async save(account: Account): Promise<void> {
		const data = this.mapToData(account);
		await this.db.query(
			"UPDATE accounts SET balance = $1, updated_at = $2 WHERE id = $3",
			[data.balance, data.updatedAt, data.id]
		);
	}

	private mapToAccount(row: any): Account {
		return new Account(
			new AccountId(row.id),
			new Money(row.balance),
			new Date(row.created_at)
		);
	}
}
```

---

## 🔍 Testing Benefits of Dependency Rule

### **Isolated Unit Testing**

When dependencies point inward, inner layers can be tested in isolation:

```typescript
// ✅ Test use case without external dependencies
describe("RegisterUserUseCase", () => {
	let useCase: RegisterUserUseCase;
	let mockUserRepository: jest.Mocked<UserRepository>;
	let mockEmailService: jest.Mocked<EmailService>;

	beforeEach(() => {
		mockUserRepository = {
			save: jest.fn(),
			findByEmail: jest.fn(),
		};

		mockEmailService = {
			send: jest.fn(),
		};

		useCase = new RegisterUserUseCase(mockUserRepository, mockEmailService);
	});

	it("should register new user successfully", async () => {
		// Arrange
		mockUserRepository.findByEmail.mockResolvedValue(null);

		const request = new RegisterUserRequest(
			"John Doe",
			new Email("john@example.com")
		);

		// Act
		await useCase.execute(request);

		// Assert
		expect(mockUserRepository.save).toHaveBeenCalledWith(expect.any(User));
		expect(mockEmailService.send).toHaveBeenCalledWith(
			new Email("john@example.com"),
			"Welcome!",
			"Welcome to our platform!"
		);
	});

	it("should throw error if user already exists", async () => {
		// Arrange
		const existingUser = new User(
			new UserId("123"),
			new UserName("Existing User"),
			new Email("john@example.com")
		);

		mockUserRepository.findByEmail.mockResolvedValue(existingUser);

		const request = new RegisterUserRequest(
			"John Doe",
			new Email("john@example.com")
		);

		// Act & Assert
		await expect(useCase.execute(request)).rejects.toThrow(
			"User already exists"
		);
		expect(mockUserRepository.save).not.toHaveBeenCalled();
	});
});
```

---

## ✅ Dependency Rule Checklist

When designing your architecture, verify:

### **Dependencies:**

- [ ] **Do all dependencies point toward the center?**
- [ ] **Do inner layers know nothing about outer layers?**
- [ ] **Are external dependencies inverted through abstractions?**

### **Layer Responsibilities:**

- [ ] **Do entities contain only pure business logic?**
- [ ] **Do use cases orchestrate without knowing about infrastructure?**
- [ ] **Do controllers only translate between external formats and use cases?**

### **Interface Design:**

- [ ] **Are interfaces defined in inner layers and implemented in outer layers?**
- [ ] **Do abstractions not depend on details?**
- [ ] **Do details depend on abstractions?**

### **Testing:**

- [ ] **Can business logic be tested without external dependencies?**
- [ ] **Can use cases be tested with mocks/stubs?**
- [ ] **Are integration tests focused on outer layer implementations?**

---

## 🔗 Related Principles

- **SOLID Principles**: Especially Dependency Inversion Principle (DIP)
- **Ports and Adapters**: Hexagonal Architecture pattern
- **Domain-Driven Design**: Entity and Value Object patterns
- **Inversion of Control**: Dependency injection containers

---

_Based on "Clean Architecture" by Robert C. Martin_
