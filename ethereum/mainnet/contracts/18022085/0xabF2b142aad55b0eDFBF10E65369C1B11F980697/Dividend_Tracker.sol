pragma solidity ^0.8.20;

import "./IERC20.sol";

contract DividendTracker {
    address _owner;
    IERC20 public token;
    IERC20 public lpToken;

    uint8 current_round;
    uint256 total;

    mapping(address => uint256) public balance;
    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public earned;

    constructor() {
        _owner = msg.sender;
    }

    function init() external {
        token = IERC20(msg.sender);
    }

    function updateLP_Token(address _lpToken) external {
        lpToken = IERC20(_lpToken);
    }

    function totalDividendsDistributed() external view returns (uint256) {
        return total;
    }

    function setBalance(address account, uint256 newBalance) external {
        require(msg.sender == address(token));
        balance[account] = newBalance;
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        if (block.timestamp > lastClaim[account] + 2 hours) return 0;
        return
            (lpToken.balanceOf(address(this)) * token.balanceOf(account)) /
            token.totalSupply();
    }

    function processAccount(address account) external returns (bool) {
        require(msg.sender == address(token));
        require(block.timestamp > lastClaim[account] + 2 hours);
        lastClaim[account] = block.timestamp;
        uint256 amount = withdrawableDividendOf(account);
        earned[account] += amount;
        lpToken.transfer(account, amount);
        return true;
    }

    function LP_Token() external view returns (address) {}

    function accumulativeDividendOf(
        address account
    ) external view returns (uint256) {}

    function allowance(
        address account,
        address spender
    ) external view returns (uint256) {}

    function approve(address spender, uint256 amount) external returns (bool) {}

    function balanceOf(address account) external view returns (uint256) {}

    function decimals() external view returns (uint8) {}

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool) {}

    function distributeLPDividends(uint256 amount) external {}

    function dividendOf(address account) external view returns (uint256) {}

    function excludeFromDividends(address account, bool value) external {}

    function excludedFromDividends(address) external view returns (bool) {}

    function getAccount(
        address account
    ) external view returns (address, uint256, uint256, uint256, uint256) {}

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool) {
        return true;
    }

    function lastClaimTimes(address) external view returns (uint256) {
        return 0;
    }

    function name() external view returns (string memory) {}

    function owner() external view returns (address) {
        return _owner;
    }

    function renounceOwnership() external {}

    function totalDividendsWithdrawn() external view returns (uint256) {
        return 0;
    }

    function totalSupply() external view returns (uint256) {
        return 0;
    }

    function trackerRescueETH20Tokens(
        address recipient,
        address tokenAddress
    ) external {}

    function transfer(address to, uint256 amount) external returns (bool) {
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        return true;
    }

    function withdrawDividend() external {}

    function withdrawnDividendOf(
        address account
    ) external view returns (uint256) {
        return 0;
    }
}
