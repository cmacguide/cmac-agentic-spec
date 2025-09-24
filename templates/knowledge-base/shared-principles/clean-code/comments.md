# Clean Code: Comments

## 🎯 Core Principle

**Don't comment bad code—rewrite it.**

The proper use of comments is to compensate for our failure to express ourselves in code. Comments are a necessary evil—use them sparingly and maintain them carefully.

---

## ⚠️ Comments Are a Last Resort

### **Express Yourself in Code, Not Comments**

Before writing a comment, try to express the same information in code through better naming and structure.

```typescript
// ❌ Bad - Comment explains unclear code
// Check to see if the employee is eligible for full benefits
if (employee.flags & HOURLY_FLAG && employee.age > 65) {
	// ...
}

// ✅ Good - Code is self-explanatory
function isEligibleForFullBenefits(employee: Employee): boolean {
	return employee.isHourly() && employee.age > 65;
}

if (isEligibleForFullBenefits(employee)) {
	// ...
}
```

### **Comments Don't Make Up for Bad Code**

When you feel the need to write a comment, first try to clean up the code instead.

```typescript
// ❌ Bad - Commenting messy code
// This function processes user data and validates it
// It returns true if valid, false otherwise
// Note: handles edge cases for null values
function process(d: any): boolean {
	if (!d) return false;
	if (!d.email || !d.email.includes("@")) return false;
	if (!d.name || d.name.length < 2) return false;
	return true;
}

// ✅ Good - Clean code needs no comments
function isValidUserData(userData: UserData): boolean {
	if (!userData) return false;
	return isValidEmail(userData.email) && isValidName(userData.name);
}

function isValidEmail(email: string): boolean {
	return email && email.includes("@");
}

function isValidName(name: string): boolean {
	return name && name.length >= 2;
}
```

---

## ✅ Good Comments

Sometimes comments are necessary and valuable. Here are the types worth keeping:

### **1. Legal Comments**

Copyright and authorship statements required by corporate standards.

```typescript
/*
 * Copyright (c) 2025 CMAC Systems. All rights reserved.
 * Licensed under the MIT License.
 */
```

### **2. Informative Comments**

Provide useful information that cannot be easily expressed in code.

```typescript
// Returns an instance of the Responder being tested
function responderInstance(): Responder {
	return new MockResponder();
}

// Regex pattern: validates email format
const EMAIL_PATTERN = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
```

### **3. Explanation of Intent**

Explain the reasoning behind a design decision.

```typescript
// We use a separate thread pool for file operations
// because they might block for extended periods
const fileOperationPool = new ThreadPool(FILE_OPERATION_THREADS);

// Intentionally using loose comparison to handle both null and undefined
if (value == null) {
	// ...
}
```

### **4. Clarification**

When you cannot alter code to make it clearer (e.g., third-party libraries).

```typescript
// Third-party library returns cryptic status codes
const result = thirdPartyLibrary.process(data);
// Status 42 means "temporary failure, retry recommended"
if (result.status === 42) {
	scheduleRetry();
}
```

### **5. Warning of Consequences**

Alert other developers about potential issues.

```typescript
// WARNING: This function is not thread-safe
function incrementCounter(): void {
	counter++;
}

// Don't run this test in production - it clears the database
function clearAllUserData(): void {
	// ...
}
```

### **6. TODO Comments**

Document planned improvements or known issues.

```typescript
// TODO: Replace with async/await when Node.js 14+ is required
function processData(
	callback: (error: Error | null, result?: any) => void
): void {
	// Legacy callback-based implementation
}

// TODO: Add input validation once schema is finalized
function createUser(userData: any): User {
	// ...
}
```

### **7. Amplification**

Emphasize the importance of something that might otherwise seem inconsequential.

```typescript
// This trim() is extremely important. Extra whitespace will cause
// the authentication to fail and users won't be able to log in.
const cleanEmail = userInput.email.trim();
```

---

## ❌ Bad Comments

These types of comments add no value and should be avoided:

### **1. Mumbling**

Unclear or confusing comments that don't add understanding.

```typescript
// ❌ Bad - What does this mean?
// utility function
function doStuff(): void {
	// ...
}

// ❌ Bad - Vague and unhelpful
// handle the user thing
if (user) {
	// process somehow
}
```

### **2. Redundant Comments**

Comments that simply repeat what the code obviously does.

```typescript
// ❌ Bad - Stating the obvious
i++; // increment i
const users = []; // create empty array
user.setName(name); // set the user's name
```

### **3. Misleading Comments**

Comments that are inaccurate or become outdated.

```typescript
// ❌ Bad - Comment doesn't match the code
// Loads configuration from config.json
function loadConfiguration(): Config {
	return loadFromDatabase(); // Actually loads from database!
}
```

### **4. Mandated Comments**

Required comments that add no value.

```typescript
// ❌ Bad - Useless mandated comments
/**
 * @param title The title
 * @param body The body
 * @returns void
 */
function setContent(title: string, body: string): void {
	// ...
}
```

### **5. Journal Comments**

Change history that belongs in version control, not comments.

```typescript
// ❌ Bad - Change log in comments
/*
 * Changes:
 * 2023-01-15: Added error handling - John
 * 2023-02-01: Fixed null pointer issue - Sarah
 * 2023-02-15: Refactored for performance - Mike
 */
```

### **6. Noise Comments**

Comments that restate the obvious without adding value.

```typescript
// ❌ Bad - Noise comments
const today = new Date(); // Get today's date
if (user !== null) {
	// If user is not null
	user.process(); // Process the user
}
```

### **7. Position Markers**

Visual separators that clutter the code.

```typescript
// ❌ Bad - Position markers
///////////////// Actions ////////////////////////
function doAction(): void {
	// ...
}

///////////////// Utilities /////////////////////
function helper(): void {
	// ...
}
```

### **8. Commented-Out Code**

Dead code should be deleted, not commented out.

```typescript
// ❌ Bad - Commented-out code
function processUser(user: User): void {
	validateUser(user);
	// const oldResult = legacyProcess(user);
	// if (oldResult.isValid) {
	//   return oldResult;
	// }
	return newProcess(user);
}
```

---

## 📝 Comment Maintenance

### **Keep Comments Current**

If you change code, update related comments immediately. Outdated comments are worse than no comments.

```typescript
// ❌ Bad - Outdated comment
// Calculates user's age in years
function calculateUserScore(user: User): number {
	// Function name changed!
	return user.points * user.level;
}

// ✅ Good - Updated comment
// Calculates user's total score based on points and level
function calculateUserScore(user: User): number {
	return user.points * user.level;
}
```

### **Remove Obsolete Comments**

Delete comments that no longer apply.

```typescript
// ❌ Bad - Obsolete comment remains
// TODO: Add validation once User class is implemented
function processUser(user: User): void {
	// User class exists now!
	user.validate(); // Validation is implemented
	// ...
}

// ✅ Good - Comment removed
function processUser(user: User): void {
	user.validate();
	// ...
}
```

---

## 💡 Comment Best Practices

### **Write for Your Audience**

Consider who will read your comments and what they need to know.

```typescript
// ✅ Good - Helpful for maintainers
// Performance optimization: Cache results for 5 minutes
// to avoid expensive database queries during peak traffic
const CACHE_DURATION = 5 * 60 * 1000;
```

### **Be Concise and Clear**

Use the minimum words necessary to convey the information.

```typescript
// ❌ Bad - Wordy and unclear
// This function is responsible for the calculation of the total amount
// that the customer needs to pay including tax and shipping costs
function calculateTotal(): number {
	// ...
}

// ✅ Good - Concise and clear
// Returns total amount including tax and shipping
function calculateTotal(): number {
	// ...
}
```

### **Focus on Why, Not What**

Explain the reasoning, not the mechanics (which should be clear from the code).

```typescript
// ❌ Bad - Explains what (obvious from code)
// Loop through users array
for (const user of users) {
	// ...
}

// ✅ Good - Explains why
// Process users in registration order to maintain priority
for (const user of users) {
	// ...
}
```

---

## ✅ Comment Review Checklist

Before keeping any comment, ask:

- [ ] **Is this information clear from the code itself?**
- [ ] **Does this comment explain WHY, not WHAT?**
- [ ] **Is the comment accurate and up-to-date?**
- [ ] **Would a newcomer find this comment helpful?**
- [ ] **Can I express this information better through code?**
- [ ] **Will I remember to update this comment when the code changes?**

---

## 🔗 Related Principles

- **Clean Code Naming**: Good names reduce the need for comments
- **Functions**: Small, well-named functions are often self-documenting
- **Code Structure**: Well-organized code reduces the need for explanatory comments
- **Version Control**: Use VCS for change history, not comments

---

_Based on "Clean Code" by Robert C. Martin - Chapter 4: Comments_
