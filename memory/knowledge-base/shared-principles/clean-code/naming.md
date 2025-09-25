# Clean Code: Meaningful Names

## 🎯 Core Principle

**Names should reveal intention**. The name of a variable, function, or class should answer all the big questions: why it exists, what it does, and how it is used.

---

## 📋 Naming Guidelines

### **Use Intention-Revealing Names**

Choose names that clearly express what the variable represents or what the function does.

```typescript
// ❌ Bad - Requires comments to understand
const d: number; // elapsed time in days
const list: User[];
const data: any[];

// ✅ Good - Self-documenting
const elapsedTimeInDays: number;
const users: User[];
const customerOrders: Order[];
```

### **Avoid Disinformation**

- Don't use misleading names that hide the true intent
- Avoid platform-specific names (like `List` when it's an array)
- Don't use similar names for different concepts

```typescript
// ❌ Bad - Misleading types
const accountList: Account[]; // It's an array, not a List
const userInfo: User; // Just call it user
const customerData: Customer; // Just call it customer

// ✅ Good - Clear and accurate
const accounts: Account[];
const user: User;
const customer: Customer;
```

### **Make Meaningful Distinctions**

Avoid noise words and number-series naming. Make sure each name represents a distinct concept.

```typescript
// ❌ Bad - Meaningless distinctions
getUserInfo() vs getUserData()
const userData1, userData2;
class CustomerObject {} vs class CustomerInfo {}

// ✅ Good - Clear distinctions
getUser() vs getUserProfile()
const activeUsers, pendingUsers;
class Customer {} vs class CustomerAccount {}
```

### **Use Pronounceable Names**

Code is read far more than it's written. Make names pronounceable so they can be discussed.

```typescript
// ❌ Bad - Unpronounceable
const genymdhms = new Date();
const xyzpdq = calculateTotal();

// ✅ Good - Pronounceable
const generationTimestamp = new Date();
const orderTotal = calculateTotal();
```

### **Use Searchable Names**

Single-letter names and numeric constants are hard to locate across a body of text.

```typescript
// ❌ Bad - Not searchable
for (let i = 0; i < 7; i++) {
	schedule[i] = tasks[i % 5];
}

// ✅ Good - Searchable
const WORK_DAYS_PER_WEEK = 7;
const TASK_ROTATION_PERIOD = 5;

for (let dayIndex = 0; dayIndex < WORK_DAYS_PER_WEEK; dayIndex++) {
	schedule[dayIndex] = tasks[dayIndex % TASK_ROTATION_PERIOD];
}
```

---

## 🎨 Context-Specific Naming

### **Class Names**

- Should be **nouns** or **noun phrases**
- Avoid words like `Manager`, `Processor`, `Data`, `Info`
- Use specific, descriptive names

```typescript
// ❌ Bad
class DataManager {}
class InfoProcessor {}

// ✅ Good
class Customer {}
class UserAccountService {}
class PaymentGateway {}
```

### **Method Names**

- Should be **verbs** or **verb phrases**
- Use consistent vocabulary across the codebase

```typescript
// ❌ Bad - Inconsistent vocabulary
class UserService {
	fetchUser() {}
	getUserData() {}
	retrieveUserInfo() {}
}

// ✅ Good - Consistent vocabulary
class UserService {
	getUser() {}
	getUserProfile() {}
	getUserPreferences() {}
}
```

### **Boolean Variables**

- Use **is/has/can/should** prefixes
- Make the intent clear

```typescript
// ❌ Bad
const user = true;
const visible = false;

// ✅ Good
const isActiveUser = true;
const isMenuVisible = false;
const canEditProfile = userPermissions.includes("edit");
const shouldSendNotification = user.preferences.notifications;
```

---

## 🚀 Advanced Naming Patterns

### **Domain-Specific Language**

Use the vocabulary of the problem domain consistently throughout the code.

```typescript
// ✅ E-commerce domain
class ShoppingCart {
	addItem(product: Product, quantity: number): void {}
	removeItem(productId: string): void {}
	calculateSubtotal(): Money {}
	applyDiscount(coupon: Coupon): void {}
}

// ✅ Banking domain
class BankAccount {
	deposit(amount: Money): void {}
	withdraw(amount: Money): void {}
	getBalance(): Money {}
	transferTo(targetAccount: BankAccount, amount: Money): void {}
}
```

### **Avoid Mental Mapping**

Don't force readers to mentally translate abbreviations or single-letter variables.

```typescript
// ❌ Bad - Requires mental mapping
const usr = getCurrentUser();
const addr = usr.getAddress();
const ph = usr.getPhoneNumber();

// ✅ Good - Clear and direct
const currentUser = getCurrentUser();
const userAddress = currentUser.getAddress();
const phoneNumber = currentUser.getPhoneNumber();
```

---

## ✅ Quick Naming Checklist

Before finalizing any name, ask:

- [ ] **Does the name reveal the intent?**
- [ ] **Can I pronounce it easily?**
- [ ] **Can I search for it in the codebase?**
- [ ] **Is it distinct from similar concepts?**
- [ ] **Does it use domain vocabulary?**
- [ ] **Would a newcomer understand it?**

---

## 🔗 Related Principles

- **Functions**: Names should describe what the function does, not how
- **Classes**: Names should represent the concept or entity
- **Comments**: Good names reduce the need for explanatory comments
- **Refactoring**: Improving names is often the first step in refactoring

---

_Based on "Clean Code" by Robert C. Martin - Chapter 2: Meaningful Names_
