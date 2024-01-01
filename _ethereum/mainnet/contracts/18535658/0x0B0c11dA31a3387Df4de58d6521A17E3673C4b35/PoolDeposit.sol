// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
// import "./IERC20.sol";
// import "./console.sol";

contract PoolDeposit {

    address public immutable owner;

    address public rabbit;
    IERC20 public paymentToken;

    uint256 nextDepositId = 1e16;
    uint256 nextPoolId = 1;

    event Deposit(uint256 indexed id, address indexed trader, uint256 amount, uint256 indexed poolId);
    event PooledDeposit(uint256 indexed id, uint256 amount);

    struct Contribution {
        address contributor;
        uint256 amount;
    } 

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

    function setRabbit(address _rabbit) external onlyOwner {
        rabbit = _rabbit;
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
