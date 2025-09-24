# Clean Architecture Implementation Patterns

## 🏗️ Folder Structure Patterns

### **Feature-Based Organization**

```
src/
├── domain/                          # Enterprise Business Rules
│   ├── entities/
│   │   ├── User.ts
│   │   ├── Project.ts
│   │   └── Task.ts
│   └── valueObjects/
│   |    ├── UserId.ts
│   |    ├── Email.ts
│   |    └── ProjectName.ts
│   |__ events
|
├── application/                   # Application Business Rules
│   ├── useCases/
│   │   ├── user/
│   │   │   ├── CreateUser/
│   │   │   │   ├── CreateUserUseCase.ts
│   │   │   │   ├── CreateUserRequest.ts
│   │   │   │   └── CreateUserResponse.ts
│   │   │   └── GetUser/
│   │   └── project/
│   ├── ports/                     # Interfaces (Dependency Inversion)
│   │   ├── repositories/
│   │   │   ├── UserRepository.ts
│   │   │   └── ProjectRepository.ts
│   │   └── services/
│   │       ├── EmailService.ts
│   │       └── FileStorageService.ts
│   └── services/                  # Domain Services
│       ├── UserDomainService.ts
│       └── ProjectDomainService.ts
│
├── infrastructure/                # Interface Adapters
│   ├── repositories/
│   │   ├── MongoUserRepository.ts
│   │   └── PostgresProjectRepository.ts
│   ├── services/
│   │   ├── SendGridEmailService.ts
│   │   └── AWSFileStorageService.ts
│   ├── controllers/
│   │   ├── UserController.ts
│   │   └── ProjectController.ts
│   └── presenters/
│       ├── UserPresenter.ts
│       └── ProjectPresenter.ts
│
└── frameworks/                    # Frameworks & Drivers
    ├── web/
    │   ├── express/
    │   │   ├── routes/
    │   │   └── middleware/
    │   └── fastify/
    ├── database/
    │   ├── mongodb/
    │   └── postgresql/
    └── external/
        ├── aws/
        └── sendgrid/
```

## 🎯 SOLID Principles in Practice

### **Single Responsibility Principle (SRP)**

```typescript
// ❌ Bad - Multiple responsibilities
class User {
  constructor(public name: string, public email: string) {}

  // Responsibility 1: User business logic
  validateEmail(): boolean {
    return this.email.includes("@");
  }

  // Responsibility 2: Database operations
  save(): void {
    // Database save logic
  }

  // Responsibility 3: Email sending
  sendWelcomeEmail(): void {
    // Email sending logic
  }
}

// ✅ Good - Single responsibility per class
class User {
  constructor(
    private readonly id: UserId,
    private name: UserName,
    private email: Email
  ) {}

  // Only responsibility: User business logic
  changeName(newName: UserName): void {
    this.name = newName;
  }

  getEmail(): Email {
    return this.email;
  }
}

class UserRepository {
  // Only responsibility: Data persistence
  async save(user: User): Promise<void> {
    // Database save logic
  }

  async findById(id: UserId): Promise<User | null> {
    // Database find logic
  }
}

class EmailService {
  // Only responsibility: Email operations
  async sendWelcomeEmail(user: User): Promise<void> {
    // Email sending logic
  }
}
```

### **Open/Closed Principle (OCP)**

```typescript
// ✅ Open for extension, closed for modification
abstract class NotificationService {
  abstract send(message: string, recipient: string): Promise<void>;
}

class EmailNotificationService extends NotificationService {
  async send(message: string, recipient: string): Promise<void> {
    // Email implementation
  }
}

class SMSNotificationService extends NotificationService {
  async send(message: string, recipient: string): Promise<void> {
    // SMS implementation
  }
}

class SlackNotificationService extends NotificationService {
  async send(message: string, recipient: string): Promise<void> {
    // Slack implementation
  }
}

// Usage - Can add new notification types without modifying existing code
class NotificationUseCase {
  constructor(private notificationServices: NotificationService[]) {}

  async sendNotification(message: string, recipient: string): Promise<void> {
    for (const service of this.notificationServices) {
      await service.send(message, recipient);
    }
  }
}
```

### **Liskov Substitution Principle (LSP)**

```typescript
// ✅ Subtypes must be substitutable for their base types
abstract class Storage {
  abstract store(key: string, data: any): Promise<void>;
  abstract retrieve(key: string): Promise<any>;
  abstract delete(key: string): Promise<void>;
}

class FileStorage extends Storage {
  async store(key: string, data: any): Promise<void> {
    // File system implementation
    // Must fulfill the contract: successfully store data
  }

  async retrieve(key: string): Promise<any> {
    // Must return data or null, never throw for missing keys
    try {
      return await this.readFile(key);
    } catch {
      return null; // Consistent behavior
    }
  }

  async delete(key: string): Promise<void> {
    // Must not throw if key doesn't exist
    try {
      await this.deleteFile(key);
    } catch {
      // Silently handle missing files
    }
  }
}

class DatabaseStorage extends Storage {
  async store(key: string, data: any): Promise<void> {
    // Database implementation with same guarantees
  }

  async retrieve(key: string): Promise<any> {
    // Same contract as FileStorage
    const result = await this.db.findOne({ key });
    return result?.data || null;
  }

  async delete(key: string): Promise<void> {
    // Same contract as FileStorage
    await this.db.deleteOne({ key }); // No error if not exists
  }
}
```

### **Interface Segregation Principle (ISP)**

```typescript
// ❌ Bad - Fat interface
interface UserOperations {
  createUser(data: CreateUserData): Promise<User>;
  updateUser(id: string, data: UpdateUserData): Promise<User>;
  deleteUser(id: string): Promise<void>;
  sendEmailToUser(id: string, message: string): Promise<void>;
  generateUserReport(id: string): Promise<string>;
  backupUserData(id: string): Promise<void>;
}

// ✅ Good - Segregated interfaces
interface UserRepository {
  save(user: User): Promise<void>;
  findById(id: UserId): Promise<User | null>;
  delete(id: UserId): Promise<void>;
}

interface UserNotificationService {
  sendEmail(user: User, message: string): Promise<void>;
}

interface UserReportService {
  generateReport(user: User): Promise<string>;
}

interface UserBackupService {
  backup(user: User): Promise<void>;
}

// Classes implement only what they need
class DatabaseUserRepository implements UserRepository {
  // Only data persistence methods
}

class EmailNotificationService implements UserNotificationService {
  // Only email methods
}
```

### **Dependency Inversion Principle (DIP)**

```typescript
// ✅ Depend on abstractions, not concretions
interface PaymentGateway {
  processPayment(amount: number, cardToken: string): Promise<PaymentResult>;
}

interface OrderRepository {
  save(order: Order): Promise<void>;
  findById(id: OrderId): Promise<Order | null>;
}

// High-level module depends on abstractions
class ProcessOrderUseCase {
  constructor(
    private paymentGateway: PaymentGateway, // Abstraction
    private orderRepository: OrderRepository // Abstraction
  ) {}

  async execute(request: ProcessOrderRequest): Promise<ProcessOrderResponse> {
    const order = this.createOrder(request);

    const paymentResult = await this.paymentGateway.processPayment(
      order.getTotal(),
      request.cardToken
    );

    if (paymentResult.success) {
      order.markAsPaid();
      await this.orderRepository.save(order);
      return ProcessOrderResponse.success(order);
    }

    return ProcessOrderResponse.failure(paymentResult.error);
  }
}

// Low-level modules implement abstractions
class StripePaymentGateway implements PaymentGateway {
  async processPayment(
    amount: number,
    cardToken: string
  ): Promise<PaymentResult> {
    // Stripe-specific implementation
  }
}

class PayPalPaymentGateway implements PaymentGateway {
  async processPayment(
    amount: number,
    cardToken: string
  ): Promise<PaymentResult> {
    // PayPal-specific implementation
  }
}
```

## 🔌 Dependency Injection Patterns

### **Constructor Injection**

```typescript
class CreateProjectUseCase {
  constructor(
    private projectRepository: ProjectRepository,
    private userRepository: UserRepository,
    private notificationService: NotificationService,
    private logger: Logger
  ) {}
}
```

### **Container-based DI**

```typescript
// Dependency Injection Container
class DIContainer {
  private services = new Map<string, any>();
  private factories = new Map<string, () => any>();

  register<T>(token: string, factory: () => T): void {
    this.factories.set(token, factory);
  }

  get<T>(token: string): T {
    if (this.services.has(token)) {
      return this.services.get(token);
    }

    const factory = this.factories.get(token);
    if (!factory) {
      throw new Error(`Service ${token} not registered`);
    }

    const service = factory();
    this.services.set(token, service);
    return service;
  }
}

// Registration
const container = new DIContainer();

container.register(
  "UserRepository",
  () => new MongoUserRepository(container.get("Database"))
);

container.register(
  "CreateUserUseCase",
  () =>
    new CreateUserUseCase(
      container.get("UserRepository"),
      container.get("EmailService")
    )
);

// Usage
const createUserUseCase = container.get<CreateUserUseCase>("CreateUserUseCase");
```

## 🧪 Testing Patterns

### **Arrange-Act-Assert Pattern**

```typescript
describe("CreateUserUseCase", () => {
  let useCase: CreateUserUseCase;
  let mockUserRepository: jest.Mocked<UserRepository>;
  let mockEmailService: jest.Mocked<EmailService>;

  beforeEach(() => {
    // Arrange - Set up test dependencies
    mockUserRepository = {
      save: jest.fn(),
      findByEmail: jest.fn(),
      findById: jest.fn(),
    };

    mockEmailService = {
      sendWelcomeEmail: jest.fn(),
    };

    useCase = new CreateUserUseCase(mockUserRepository, mockEmailService);
  });

  it("should create user successfully when valid data provided", async () => {
    // Arrange - Set up test data and expectations
    const request = new CreateUserRequest("John Doe", "john@example.com");
    mockUserRepository.findByEmail.mockResolvedValue(null);
    mockUserRepository.save.mockResolvedValue();
    mockEmailService.sendWelcomeEmail.mockResolvedValue();

    // Act - Execute the use case
    const response = await useCase.execute(request);

    // Assert - Verify results
    expect(response.success).toBe(true);
    expect(response.user).toBeDefined();
    expect(mockUserRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({
        email: expect.objectContaining({ value: "john@example.com" }),
      })
    );
    expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalled();
  });
});
```

### **Test Doubles (Mocks, Stubs, Fakes)**

```typescript
// Stub - Returns predefined responses
class StubUserRepository implements UserRepository {
  private users: User[] = [];

  async save(user: User): Promise<void> {
    this.users.push(user);
  }

  async findById(id: UserId): Promise<User | null> {
    return this.users.find((u) => u.getId().equals(id)) || null;
  }
}

// Fake - Simple working implementation
class InMemoryUserRepository implements UserRepository {
  private users = new Map<string, User>();

  async save(user: User): Promise<void> {
    this.users.set(user.getId().value, user);
  }

  async findById(id: UserId): Promise<User | null> {
    return this.users.get(id.value) || null;
  }
}

// Mock - Behavior verification
const mockEmailService = {
  sendWelcomeEmail: jest.fn().mockResolvedValue(),
};

// Verify behavior
expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalledTimes(1);
expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalledWith(
  expect.objectContaining({ email: "john@example.com" })
);
```

## 📊 Error Handling Patterns

### **Result Pattern**

```typescript
class Result<T, E = Error> {
  private constructor(
    public readonly success: boolean,
    public readonly value?: T,
    public readonly error?: E
  ) {}

  static ok<T>(value: T): Result<T> {
    return new Result(true, value);
  }

  static fail<E>(error: E): Result<never, E> {
    return new Result(false, undefined, error);
  }

  isSuccess(): boolean {
    return this.success;
  }

  isFailure(): boolean {
    return !this.success;
  }
}

// Usage in Use Case
class CreateUserUseCase {
  async execute(request: CreateUserRequest): Promise<Result<User, string>> {
    // Validation
    if (!this.isValidEmail(request.email)) {
      return Result.fail("Invalid email format");
    }

    // Business rule check
    const existingUser = await this.userRepository.findByEmail(request.email);
    if (existingUser) {
      return Result.fail("User already exists");
    }

    // Create and save user
    try {
      const user = this.createUser(request);
      await this.userRepository.save(user);
      return Result.ok(user);
    } catch (error) {
      return Result.fail("Failed to create user");
    }
  }
}
```

### **Domain Events Pattern**

```typescript
abstract class DomainEvent {
  public readonly occurredOn: Date;

  constructor() {
    this.occurredOn = new Date();
  }
}

class UserCreatedEvent extends DomainEvent {
  constructor(public readonly user: User) {
    super();
  }
}

class AggregateRoot {
  private domainEvents: DomainEvent[] = [];

  protected addDomainEvent(event: DomainEvent): void {
    this.domainEvents.push(event);
  }

  getDomainEvents(): DomainEvent[] {
    return [...this.domainEvents];
  }

  clearDomainEvents(): void {
    this.domainEvents = [];
  }
}

class User extends AggregateRoot {
  static create(name: UserName, email: Email): User {
    const user = new User(UserId.generate(), name, email, new Date());
    user.addDomainEvent(new UserCreatedEvent(user));
    return user;
  }
}

// Event Handling
interface DomainEventHandler<T extends DomainEvent> {
  handle(event: T): Promise<void>;
}

class SendWelcomeEmailHandler implements DomainEventHandler<UserCreatedEvent> {
  constructor(private emailService: EmailService) {}

  async handle(event: UserCreatedEvent): Promise<void> {
    await this.emailService.sendWelcomeEmail(event.user);
  }
}
```

_These patterns help maintain clean separation of concerns and make your architecture more maintainable and testable._
