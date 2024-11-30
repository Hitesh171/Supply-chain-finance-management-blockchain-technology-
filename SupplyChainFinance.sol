// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SupplyChainFinance {

    // Define the stakeholders
    address public owner;
    address public buyer;
    address public supplier;
    address public financier;

    // Structs
    struct Invoice {
        uint256 invoiceId;
        uint256 amount;
        uint256 dueDate;
        address issuedBy; // Buyer
        address to; // Supplier
        bool paid;
    }

    struct FinancingRequest {
        uint256 invoiceId;
        uint256 requestedAmount;
        uint256 financedAmount; // Total amount financed
        uint256 repaidAmount;   // Amount repaid so far
        uint256 outstandingAmount; // Amount remaining to be repaid
        bool approved;
        bool paid;
    }

    // Mappings to store invoices and financing requests
    mapping(uint256 => Invoice) public invoices;
    mapping(uint256 => FinancingRequest) public financingRequests;

    // Events
    event InvoiceIssued(uint256 invoiceId, uint256 amount, uint256 dueDate, address indexed issuedBy, address indexed to);
    event FinancingRequested(uint256 invoiceId, uint256 requestedAmount, address indexed supplier);
    event FinancingApproved(uint256 invoiceId, uint256 financedAmount, address indexed financier);
    event PaymentConfirmed(uint256 invoiceId, uint256 amount, address indexed buyer);
    event LoanRepayment(uint256 invoiceId, uint256 repaidAmount, uint256 remainingAmount, address indexed repaidBy);

    // Modifiers to check permissions
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can perform this action");
        _;
    }

    modifier onlySupplier() {
        require(msg.sender == supplier, "Only the supplier can perform this action");
        _;
    }

    modifier onlyFinancier() {
        require(msg.sender == financier, "Only the financier can perform this action");
        _;
    }

    modifier invoiceExists(uint256 invoiceId) {
        require(invoices[invoiceId].amount > 0, "Invoice does not exist");
        _;
    }

    modifier financingExists(uint256 invoiceId) {
        require(financingRequests[invoiceId].requestedAmount > 0, "Financing request does not exist");
        _;
    }

    modifier invoiceNotPaid(uint256 invoiceId) {
        require(!invoices[invoiceId].paid, "Invoice already paid");
        _;
    }

    modifier financingNotPaid(uint256 invoiceId) {
        require(!financingRequests[invoiceId].paid, "Financing already paid");
        _;
    }

    constructor(address _buyer, address _supplier, address _financier) {
        owner = msg.sender;
        buyer = _buyer;
        supplier = _supplier;
        financier = _financier;
    }

    // Buyer issues an invoice
    function issueInvoice(uint256 invoiceId, uint256 amount, uint256 dueDate) external onlyBuyer {
        require(invoices[invoiceId].amount == 0, "Invoice ID already exists");

        invoices[invoiceId] = Invoice({
            invoiceId: invoiceId,
            amount: amount,
            dueDate: dueDate,
            issuedBy: buyer,
            to: supplier,
            paid: false
        });

        emit InvoiceIssued(invoiceId, amount, dueDate, buyer, supplier);
    }

    // Supplier requests financing
    function requestFinancing(uint256 invoiceId, uint256 requestedAmount) external onlySupplier invoiceExists(invoiceId) invoiceNotPaid(invoiceId) {
        require(requestedAmount <= invoices[invoiceId].amount, "Request exceeds invoice amount");

        financingRequests[invoiceId] = FinancingRequest({
            invoiceId: invoiceId,
            requestedAmount: requestedAmount,
            financedAmount: 0,
            repaidAmount: 0,
            outstandingAmount: requestedAmount,
            approved: false,
            paid: false
        });

        emit FinancingRequested(invoiceId, requestedAmount, supplier);
    }

    // Financier approves or denies the financing request
    function approveFinancing(uint256 invoiceId) external onlyFinancier financingExists(invoiceId) invoiceNotPaid(invoiceId) {
        require(financingRequests[invoiceId].approved == false, "Financing already approved");

        financingRequests[invoiceId].approved = true;
        uint256 financedAmount = financingRequests[invoiceId].requestedAmount;

        // Transfer funds to the supplier (assuming enough funds are available in the contract)
        payable(supplier).transfer(financedAmount);

        financingRequests[invoiceId].financedAmount = financedAmount;
        financingRequests[invoiceId].outstandingAmount = financedAmount;

        emit FinancingApproved(invoiceId, financedAmount, financier);
    }

    // Buyer confirms the payment of the invoice
    function confirmPayment(uint256 invoiceId) external onlyBuyer invoiceExists(invoiceId) invoiceNotPaid(invoiceId) {
        invoices[invoiceId].paid = true;

        // If financing was requested, mark it as paid
        if (financingRequests[invoiceId].approved && !financingRequests[invoiceId].paid) {
            financingRequests[invoiceId].paid = true;
        }

        emit PaymentConfirmed(invoiceId, invoices[invoiceId].amount, buyer);
    }

    // Function to deposit funds into the contract for financing
    function deposit() external payable onlyFinancier {
        // Financier can deposit funds for financing purposes
    }

    // Function to make loan repayments
    function repayLoan(uint256 invoiceId, uint256 amount) external payable onlySupplier financingExists(invoiceId) {
        require(amount > 0, "Repayment amount must be greater than zero");
        require(msg.value == amount, "Sent amount must equal repayment amount");
        require(financingRequests[invoiceId].outstandingAmount > 0, "Loan is already fully repaid");
        require(financingRequests[invoiceId].outstandingAmount >= amount, "Repayment exceeds outstanding loan amount");

        // Update the financing request
        financingRequests[invoiceId].repaidAmount += amount;
        financingRequests[invoiceId].outstandingAmount -= amount;

        if (financingRequests[invoiceId].outstandingAmount == 0) {
            financingRequests[invoiceId].paid = true; // Mark the loan as fully repaid
        }

        // Transfer the repayment to the Financier
        payable(financier).transfer(amount);

        emit LoanRepayment(invoiceId, amount, financingRequests[invoiceId].outstandingAmount, supplier);
    }

    // Get invoice details
    function getInvoice(uint256 invoiceId) external view returns (Invoice memory) {
        return invoices[invoiceId];
    }

    // Get financing request details
    function getFinancingRequest(uint256 invoiceId) external view returns (FinancingRequest memory) {
        return financingRequests[invoiceId];
    }

    // Fallback function to accept ether
    receive() external payable {}

    fallback() external payable {}
}