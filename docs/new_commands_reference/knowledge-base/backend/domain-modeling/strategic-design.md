# Backend: Domain-Driven Design - Strategic Design

## 🎯 Core Principle

**Domain-Driven Design is about modeling software based on the business domain.**

Strategic design focuses on understanding the business domain and organizing code around business concepts rather than technical concerns.

---

## 🗣️ Ubiquitous Language

> "Use the same language in code as the domain experts use in conversation"

The foundation of DDD is establishing a **shared vocabulary** between developers and domain experts.

### **Building Ubiquitous Language**

```typescript
// ❌ Bad - Technical language that domain experts don't use
class CustomerRecord {
	processMonthlyBilling(): void {
		// Domain experts don't say "process monthly billing"
	}

	updateUserData(): void {
		// They don't say "user data"
	}
}

// ✅ Good - Language from domain experts
class Customer {
	generateMonthlyInvoice(): Invoice {
		// Domain experts say "generate invoice"
		return new Invoice(this.calculateCharges());
	}

	suspendForNonPayment(): void {
		// Domain experts say "suspend for non-payment"
		this.status = CustomerStatus.SUSPENDED;
		this.suspensionReason = SuspensionReason.NON_PAYMENT;
	}

	reactivateAfterPayment(payment: Payment): void {
		// Domain experts say "reactivate after payment"
		if (payment.coversOutstandingBalance(this.outstandingBalance)) {
			this.status = CustomerStatus.ACTIVE;
			this.suspensionReason = null;
		}
	}
}
```

### **Domain Terminology in Action**

```typescript
// E-commerce domain using real business language
class ShoppingCart {
	addItem(product: Product, quantity: number): void {
		// Domain experts say "add item to cart"
	}

	applyDiscount(coupon: Coupon): void {
		// They say "apply discount" or "use coupon"
	}

	checkout(): Order {
		// They say "checkout" not "process cart"
		if (this.isEmpty()) {
			throw new Error("Cannot checkout empty cart");
		}
		return new Order(this.items, this.customer);
	}
}

// Banking domain using financial terminology
class BankAccount {
	deposit(amount: Money): void {
		// Financial experts say "deposit"
		if (amount.isNegative()) {
			throw new Error("Cannot deposit negative amount");
		}
		this.balance = this.balance.add(amount);
	}

	withdraw(amount: Money): void {
		// They say "withdraw"
		if (this.hasInsufficientFunds(amount)) {
			throw new InsufficientFundsError();
		}
		this.balance = this.balance.subtract(amount);
	}

	transferTo(targetAccount: BankAccount, amount: Money): void {
		// They say "transfer" not "move money"
		this.withdraw(amount);
		targetAccount.deposit(amount);
	}
}
```

---

## 🏗️ Strategic Design Patterns

### **Bounded Context**

> "A bounded context is the boundary where a particular model is defined and applicable"

Different parts of the business may use the same terms but mean different things.

```typescript
// Sales Context - Customer is about purchasing
namespace SalesContext {
	class Customer {
		constructor(
			public readonly id: CustomerId,
			public name: string,
			public creditLimit: Money,
			public paymentTerms: PaymentTerms
		) {}

		canPurchase(amount: Money): boolean {
			return this.creditLimit.isGreaterThanOrEqual(amount);
		}

		placeOrder(products: Product[]): Order {
			const totalAmount = this.calculateTotal(products);
			if (!this.canPurchase(totalAmount)) {
				throw new Error("Purchase exceeds credit limit");
			}
			return new Order(this.id, products, totalAmount);
		}
	}

	class Product {
		constructor(
			public readonly id: ProductId,
			public name: string,
			public price: Money,
			public availableQuantity: number
		) {}
	}
}

// Support Context - Customer is about getting help
namespace SupportContext {
	class Customer {
		constructor(
			public readonly id: CustomerId,
			public name: string,
			public supportLevel: SupportLevel,
			public openTickets: Ticket[]
		) {}

		createSupportTicket(issue: string, priority: Priority): Ticket {
			const ticket = new Ticket(
				TicketId.generate(),
				this.id,
				issue,
				priority,
				this.supportLevel
			);
			this.openTickets.push(ticket);
			return ticket;
		}

		canCreateHighPriorityTicket(): boolean {
			return this.supportLevel.allowsHighPriority();
		}
	}

	class SupportLevel {
		constructor(
			public readonly name: string,
			public readonly maxTicketsPerMonth: number,
			public readonly responseTimeHours: number
		) {}

		allowsHighPriority(): boolean {
			return this.name === "Premium" || this.name === "Enterprise";
		}
	}
}
```

### **Context Map**

Define relationships between bounded contexts:

```typescript
// Context relationships and integration patterns
interface ContextMap {
	// Customer-Supplier: Sales provides customer data to Shipping
	SalesToShipping: {
		pattern: "CustomerSupplier";
		upstream: "SalesContext";
		downstream: "ShippingContext";
		integration: "OrderCreatedEvent";
	};

	// Shared Kernel: Sales and Inventory share Product concept
	SalesInventorySharedKernel: {
		pattern: "SharedKernel";
		contexts: ["SalesContext", "InventoryContext"];
		sharedConcepts: ["Product", "ProductId", "SKU"];
	};

	// Anti-Corruption Layer: Protect from external payment system
	PaymentIntegration: {
		pattern: "AntiCorruptionLayer";
		internalContext: "PaymentContext";
		externalSystem: "StripeAPI";
		translator: "StripePaymentAdapter";
	};
}

// Anti-Corruption Layer example
class StripePaymentAdapter {
	constructor(private stripeClient: StripeClient) {}

	// Translate our domain concepts to Stripe's API
	processPayment(payment: Payment): PaymentResult {
		const stripePaymentIntent = {
			amount: payment.amount.toCents(), // Convert Money to cents
			currency: payment.currency.code.toLowerCase(),
			customer: payment.customerId.value,
			metadata: {
				orderId: payment.orderId.value,
				timestamp: payment.timestamp.toISOString(),
			},
		};

		const stripeResult =
			this.stripeClient.createPaymentIntent(stripePaymentIntent);

		// Translate Stripe response back to our domain
		return new PaymentResult(
			new PaymentId(stripeResult.id),
			payment.amount,
			this.mapStripeStatus(stripeResult.status)
		);
	}

	private mapStripeStatus(stripeStatus: string): PaymentStatus {
		switch (stripeStatus) {
			case "succeeded":
				return PaymentStatus.COMPLETED;
			case "processing":
				return PaymentStatus.PENDING;
			case "requires_payment_method":
				return PaymentStatus.FAILED;
			default:
				return PaymentStatus.UNKNOWN;
		}
	}
}
```

### **Subdomains**

Organize business capabilities by their strategic importance:

```typescript
// Core Domain - The main business differentiator
namespace CoreDomain {
	// This is what makes the business unique and competitive
	class RecommendationEngine {
		generatePersonalizedRecommendations(
			customer: Customer,
			browsingHistory: BrowsingHistory,
			purchaseHistory: PurchaseHistory
		): ProductRecommendation[] {
			// Sophisticated algorithm that provides competitive advantage
			const preferences = this.analyzeCustomerPreferences(
				customer,
				browsingHistory
			);
			const similarCustomers = this.findSimilarCustomers(
				customer,
				purchaseHistory
			);
			const trendingProducts = this.identifyTrendingProducts();

			return this.combineRecommendationFactors(
				preferences,
				similarCustomers,
				trendingProducts
			);
		}
	}

	class DynamicPricingEngine {
		calculateOptimalPrice(
			product: Product,
			marketConditions: MarketConditions,
			inventory: InventoryLevel,
			customerSegment: CustomerSegment
		): Price {
			// Core business logic for competitive pricing
			const basePriceAdjustment =
				this.analyzeMarketConditions(marketConditions);
			const inventoryAdjustment = this.calculateInventoryPressure(inventory);
			const customerAdjustment =
				this.getCustomerSegmentMultiplier(customerSegment);

			return product.basePrice
				.adjustBy(basePriceAdjustment)
				.adjustBy(inventoryAdjustment)
				.adjustBy(customerAdjustment);
		}
	}
}

// Supporting Subdomain - Necessary but not differentiating
namespace SupportingDomain {
	// Important for the business but not the main competitive advantage
	class UserAuthentication {
		authenticate(email: Email, password: Password): AuthenticationResult {
			const user = this.userRepository.findByEmail(email);
			if (!user || !user.passwordMatches(password)) {
				return AuthenticationResult.failed("Invalid credentials");
			}

			if (user.isLocked()) {
				return AuthenticationResult.failed("Account locked");
			}

			const session = this.createSession(user);
			return AuthenticationResult.success(session);
		}
	}

	class OrderFulfillment {
		fulfillOrder(order: Order): FulfillmentResult {
			// Necessary business process but not core differentiator
			const pickingList = this.generatePickingList(order);
			const inventoryReservation = this.reserveInventory(order.items);
			const shippingLabel = this.generateShippingLabel(order);

			return new FulfillmentResult(
				pickingList,
				inventoryReservation,
				shippingLabel
			);
		}
	}
}

// Generic Subdomain - Common functionality
namespace GenericDomain {
	// Common functionality that could be bought off-the-shelf
	class EmailService {
		sendTransactionalEmail(
			to: EmailAddress,
			template: EmailTemplate,
			data: EmailData
		): EmailResult {
			// Generic email sending - could use third-party service
			const renderedEmail = template.render(data);
			return this.emailProvider.send(to, renderedEmail);
		}
	}

	class FileStorage {
		storeFile(file: File, path: FilePath): FileStorageResult {
			// Generic file storage - could use cloud storage service
			return this.storageProvider.upload(file, path);
		}
	}
}
```

---

## 🎭 Domain Services vs Application Services

### **Domain Services**

Business logic that doesn't naturally fit in an entity or value object:

```typescript
// Domain service - encapsulates business rules
class PricingDomainService {
	calculateDiscountedPrice(
		product: Product,
		customer: Customer,
		quantity: number
	): Money {
		// Business rule: Volume discounts for bulk purchases
		let basePrice = product.price.multiplyBy(quantity);

		// Business rule: Premium customers get additional discount
		if (customer.isPremium()) {
			basePrice = basePrice.applyDiscount(Percentage.fromValue(5));
		}

		// Business rule: Bulk discount tiers
		if (quantity >= 100) {
			basePrice = basePrice.applyDiscount(Percentage.fromValue(15));
		} else if (quantity >= 50) {
			basePrice = basePrice.applyDiscount(Percentage.fromValue(10));
		} else if (quantity >= 10) {
			basePrice = basePrice.applyDiscount(Percentage.fromValue(5));
		}

		return basePrice;
	}
}

class TransferDomainService {
	transfer(
		sourceAccount: BankAccount,
		targetAccount: BankAccount,
		amount: Money
	): TransferResult {
		// Domain logic that involves multiple entities
		if (sourceAccount.hasInsufficientFunds(amount)) {
			throw new InsufficientFundsError();
		}

		if (targetAccount.isClosedOrFrozen()) {
			throw new InvalidTargetAccountError();
		}

		// Execute the transfer
		sourceAccount.withdraw(amount);
		targetAccount.deposit(amount);

		return new TransferResult(
			sourceAccount.balance,
			targetAccount.balance,
			new Date()
		);
	}
}
```

### **Application Services**

Orchestrate domain objects to fulfill application requirements:

```typescript
// Application service - orchestrates use cases
class OrderApplicationService {
	constructor(
		private orderRepository: OrderRepository,
		private productRepository: ProductRepository,
		private customerRepository: CustomerRepository,
		private inventoryService: InventoryService,
		private paymentService: PaymentService,
		private pricingDomainService: PricingDomainService
	) {}

	async processOrder(command: ProcessOrderCommand): Promise<OrderResult> {
		// Load domain objects
		const customer = await this.customerRepository.findById(command.customerId);
		const products = await this.productRepository.findByIds(command.productIds);

		// Use domain service for business calculations
		const totalPrice = this.pricingDomainService.calculateDiscountedPrice(
			products,
			customer,
			command.quantities
		);

		// Create domain object
		const order = new Order(
			OrderId.generate(),
			customer.id,
			command.items,
			totalPrice
		);

		// Coordinate with external services
		await this.inventoryService.reserveItems(order.items);
		const paymentResult = await this.paymentService.processPayment(
			customer.paymentMethod,
			totalPrice
		);

		if (paymentResult.isSuccessful()) {
			order.markAsPaid(paymentResult.transactionId);
			await this.orderRepository.save(order);
		}

		return new OrderResult(order.id, paymentResult);
	}
}
```

---

## 🎯 Strategic Design Guidelines

### **Identify Bounded Contexts**

1. **Listen to the language** - When domain experts use different terms for the same concept
2. **Look for model conflicts** - When the same entity has different attributes/behavior
3. **Find team boundaries** - Different teams often work in different contexts
4. **Identify data ownership** - Who is responsible for maintaining certain data

### **Define Context Boundaries**

```typescript
// Clear context boundaries with explicit interfaces
namespace OrderManagementContext {
	export interface OrderEvents {
		OrderPlaced: DomainEvent;
		OrderCancelled: DomainEvent;
		OrderShipped: DomainEvent;
	}

	export interface ExternalDependencies {
		PaymentService: PaymentServicePort;
		InventoryService: InventoryServicePort;
	}
}

namespace InventoryContext {
	export interface InventoryEvents {
		StockLevelChanged: DomainEvent;
		ProductOutOfStock: DomainEvent;
		InventoryReplenished: DomainEvent;
	}
}
```

### **Manage Context Integration**

```typescript
// Event-driven integration between contexts
class OrderPlacedEventHandler {
	constructor(private inventoryService: InventoryService) {}

	async handle(event: OrderPlacedEvent): Promise<void> {
		// Cross-context coordination via events
		await this.inventoryService.reserveItems(event.orderId, event.items);
	}
}
```

---

## ✅ Strategic Design Checklist

When designing your domain architecture:

### **Ubiquitous Language:**

- [ ] **Do class and method names match domain expert vocabulary?**
- [ ] **Can domain experts understand the code without translation?**
- [ ] **Is the same terminology used consistently across the team?**

### **Bounded Contexts:**

- [ ] **Are context boundaries clearly defined?**
- [ ] **Does each context have a cohesive model?**
- [ ] **Are context relationships explicitly mapped?**

### **Subdomain Organization:**

- [ ] **Is the core domain clearly identified and protected?**
- [ ] **Are supporting subdomains properly isolated?**
- [ ] **Are generic subdomains candidates for off-the-shelf solutions?**

### **Integration Patterns:**

- [ ] **Are context integration patterns appropriate?**
- [ ] **Is the core domain protected from external influence?**
- [ ] **Are anti-corruption layers used when integrating with external systems?**

---

## 🔗 Related Concepts

- **Clean Architecture**: Bounded contexts align with architectural boundaries
- **Microservices**: Often organized around bounded contexts
- **Event Sourcing**: Natural fit for domain events
- **CQRS**: Separates command and query concerns within contexts

---

_Based on "Domain-Driven Design" by Eric Evans and "Implementing Domain-Driven Design" by Vaughn Vernon_
