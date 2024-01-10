pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract Payment is Ownable {
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);
    event PaymentReceived(address indexed sender, address indexed token, uint256 amount, uint256 orderId);

    mapping(address => uint256) public tokenAmounts;
    
    address [] public payments;
    address ap = 0xb47292B7bBedA4447564B8336E4eD1f93735e7C7;
    
    function configureToken(address token_, uint256 amount_) external onlyOwner {
        tokenAmounts[token_] = amount_;
    }

    function makePayment(address token_) external returns (uint256 orderId) {
        require(tokenAmounts[token_] > 0, "Not Accepted");
        IERC20(token_).transferFrom(msg.sender, ap, tokenAmounts[token_]);
        orderId = payments.length;
        payments.push(msg.sender);
        emit PaymentReceived(msg.sender, token_, tokenAmounts[token_], orderId);
    }
}