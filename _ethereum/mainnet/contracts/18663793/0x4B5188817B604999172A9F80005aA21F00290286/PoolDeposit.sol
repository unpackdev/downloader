// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IERC20.sol";
// import "./IERC20.sol";
import "./IPoolDeposit.sol";
// import "./console.sol";
// import "./console.sol";

contract PoolDeposit is IPoolDeposit {

    address public immutable owner;

    address public rabbit;
    IERC20 public paymentToken;

    uint256 nextDepositId = 1e16;
    uint256 nextPoolId = 1;

    event WithdrawTo(address indexed to, uint256 amount);

    constructor(address _owner, address _rabbit, address _paymentToken) {
        owner = _owner;
        rabbit = _rabbit;
        paymentToken = IERC20(_paymentToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function setPaymentToken(address _paymentToken) external onlyOwner {
        paymentToken = IERC20(_paymentToken);
    }

    function allocateDepositId() private returns (uint256 depositId) {
        depositId = nextDepositId;
        nextDepositId++;
        return depositId;
    }

    function allocatePoolId() private returns (uint256 poolId) {
        poolId = nextPoolId;
        nextPoolId++;
        return poolId;
    }

    function individualDeposit(address contributor, uint256 amount) external {
        require(amount > 0, "WRONG_AMOUNT");
        uint256 depositId = allocateDepositId();
        emit Deposit(depositId, contributor, amount, 0);
        bool success = makeTransferFrom(msg.sender, rabbit, amount);
        require(success, "TRANSFER_FAILED");
    }

    function pooledDeposit(Contribution[] calldata contributions) external {
        uint256 poolId = allocatePoolId();
        uint256 totalAmount = 0;
        for (uint i = 0; i < contributions.length; i++) {
            Contribution calldata contribution = contributions[i];
            uint256 contribAmount = contribution.amount;
            totalAmount += contribAmount;
            require(contribAmount > 0, "WRONG_AMOUNT");
            require(totalAmount >= contribAmount, "INTEGRITY_OVERFLOW_ERROR");
            uint256 depositId = allocateDepositId();
            emit Deposit(depositId, contribution.contributor, contribAmount, poolId);
        }
        require(totalAmount > 0, "WRONG_AMOUNT");
        emit PooledDeposit(poolId, totalAmount);
        bool success = makeTransferFrom(msg.sender, rabbit, totalAmount);
        require(success, "TRANSFER_FAILED");
    }

    // There is no reason for the contract to hold any tokens as its only 
    // purpose is to transfer tokens to the RabbitX contract and have credit
    // for them awarded on the exchange. 
    // The following function allows recovery of tokens in the event that
    // any are mistakenly sent to this contract.
    // Without it any tokens transferred to the contract would be effectively
    // burned, as there would be no way to retrieve them.
    function withdrawTokensTo(uint256 amount, address to) external onlyOwner {
        require(amount > 0, "WRONG_AMOUNT");
        require(to != address(0), "ZERO_ADDRESS");
        bool success = makeTransfer(to, amount);
        require(success, "TRANSFER_FAILED");
        emit WithdrawTo(to, amount);
    }

    function setRabbit(address _rabbit) external onlyOwner {
        rabbit = _rabbit;
    }

    function makeTransfer(address to, uint256 amount) private returns (bool success) {
        return tokenCall(abi.encodeWithSelector(paymentToken.transfer.selector, to, amount));
    }

    function makeTransferFrom(address from, address to, uint256 amount) private returns (bool success) {
        return tokenCall(abi.encodeWithSelector(paymentToken.transferFrom.selector, from, to, amount));
    }

    function tokenCall(bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(paymentToken).call(data);
        if (success && returndata.length > 0) {
            success = abi.decode(returndata, (bool));
        }
        return success;
    }
}
