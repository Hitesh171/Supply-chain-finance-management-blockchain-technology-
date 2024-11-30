import React, { useState } from "react";
import { useEth } from "./contexts/EthContext";
import "./styles.css";

function MainComp() {
  const { state: { contract, accounts } } = useEth();

  const [invoiceData, setInvoiceData] = useState({
    invoiceId: "",
    amount: "",
    dueDate: "",
  });

  const [financingData, setFinancingData] = useState({
    invoiceId: "",
    requestedAmount: "",
    repayAmount: "",
  });

  const [invoices, setInvoices] = useState([]);
  const [financingRequests, setFinancingRequests] = useState([]);

  // Fetch all invoices
  const fetchInvoices = async () => {
    try {
      const invoiceIds = Object.keys(await contract.methods.invoices().call());
      const invoiceList = await Promise.all(
        invoiceIds.map((id) => contract.methods.getInvoice(id).call())
      );
      setInvoices(invoiceList);
    } catch (error) {
      console.error("Error fetching invoices:", error);
    }
  };

  // Fetch all financing requests
  const fetchFinancingRequests = async () => {
    try {
      const financingIds = Object.keys(await contract.methods.financingRequests().call());
      const financingList = await Promise.all(
        financingIds.map((id) => contract.methods.getFinancingRequest(id).call())
      );
      setFinancingRequests(financingList);
    } catch (error) {
      console.error("Error fetching financing requests:", error);
    }
  };

  // Issue an invoice
  const handleIssueInvoice = async () => {
    const { invoiceId, amount, dueDate } = invoiceData;
    try {
      await contract.methods
        .issueInvoice(invoiceId, amount, dueDate)
        .send({ from: accounts[0] });
      alert("Invoice issued successfully!");
    } catch (error) {
      console.error("Error issuing invoice:", error);
    }
  };

  // Request financing
  const handleRequestFinancing = async () => {
    const { invoiceId, requestedAmount } = financingData;
    try {
      await contract.methods
        .requestFinancing(invoiceId, requestedAmount)
        .send({ from: accounts[0] });
      alert("Financing requested successfully!");
    } catch (error) {
      console.error("Error requesting financing:", error);
    }
  };

  // Approve financing
  const handleApproveFinancing = async () => {
    const { invoiceId } = financingData;
    try {
      await contract.methods
        .approveFinancing(invoiceId)
        .send({ from: accounts[0] });
      alert("Financing approved successfully!");
    } catch (error) {
      console.error("Error approving financing:", error);
    }
  };

  // Confirm payment
  const handleConfirmPayment = async () => {
    const { invoiceId } = financingData;
    try {
      await contract.methods
        .confirmPayment(invoiceId)
        .send({ from: accounts[0] });
      alert("Payment confirmed successfully!");
    } catch (error) {
      console.error("Error confirming payment:", error);
    }
  };

  // Repay loan
  const handleRepayLoan = async () => {
    const { invoiceId, repayAmount } = financingData;
    try {
      await contract.methods
        .repayLoan(invoiceId, repayAmount)
        .send({ from: accounts[0], value: repayAmount });
      alert("Loan repaid successfully!");
    } catch (error) {
      console.error("Error repaying loan:", error);
    }
  };

  return (
    <div id="App">
      <div className="container">
        <h1>Supply Chain Finance DApp</h1>

        {/* Issue Invoice */}
        <div>
          <h2>Issue Invoice</h2>
          <input
            placeholder="Invoice ID"
            onChange={(e) => setInvoiceData({ ...invoiceData, invoiceId: e.target.value })}
          />
          <input
            placeholder="Amount"
            onChange={(e) => setInvoiceData({ ...invoiceData, amount: e.target.value })}
          />
          <input
            placeholder="Due Date"
            onChange={(e) => setInvoiceData({ ...invoiceData, dueDate: e.target.value })}
          />
          <button onClick={handleIssueInvoice}>Issue Invoice</button>
        </div>

        {/* Request Financing */}
        <div>
          <h2>Request Financing</h2>
          <input
            placeholder="Invoice ID"
            onChange={(e) => setFinancingData({ ...financingData, invoiceId: e.target.value })}
          />
          <input
            placeholder="Requested Amount"
            onChange={(e) => setFinancingData({ ...financingData, requestedAmount: e.target.value })}
          />
          <button onClick={handleRequestFinancing}>Request Financing</button>
        </div>

        {/* Approve Financing */}
        <div>
          <h2>Approve Financing</h2>
          <input
            placeholder="Invoice ID"
            onChange={(e) => setFinancingData({ ...financingData, invoiceId: e.target.value })}
          />
          <button onClick={handleApproveFinancing}>Approve Financing</button>
        </div>

        {/* Confirm Payment */}
        <div>
          <h2>Confirm Payment</h2>
          <input
            placeholder="Invoice ID"
            onChange={(e) => setFinancingData({ ...financingData, invoiceId: e.target.value })}
          />
          <button onClick={handleConfirmPayment}>Confirm Payment</button>
        </div>

        {/* Repay Loan */}
        <div>
          <h2>Repay Loan</h2>
          <input
            placeholder="Invoice ID"
            onChange={(e) => setFinancingData({ ...financingData, invoiceId: e.target.value })}
          />
          <input
            placeholder="Repayment Amount"
            onChange={(e) => setFinancingData({ ...financingData, repayAmount: e.target.value })}
          />
          <button onClick={handleRepayLoan}>Repay Loan</button>
        </div>

        {/* Display Invoices */}
        <div>
          <h2>Invoices</h2>
          <button onClick={fetchInvoices}>View Invoices</button>
          <ul>
            {invoices.map((invoice, index) => (
              <li key={index}>
                ID: {invoice.invoiceId}, Amount: {invoice.amount}, Due Date: {invoice.dueDate}, Paid: {invoice.paid.toString()}
              </li>
            ))}
          </ul>
        </div>

        {/* Display Financing Requests */}
        <div>
          <h2>Financing Requests</h2>
          <button onClick={fetchFinancingRequests}>View Requests</button>
          <ul>
            {financingRequests.map((request, index) => (
              <li key={index}>
                Invoice ID: {request.invoiceId}, Requested: {request.requestedAmount}, Financed: {request.financedAmount}, Outstanding: {request.outstandingAmount}, Paid: {request.paid.toString()}
              </li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}

export default MainComp;
