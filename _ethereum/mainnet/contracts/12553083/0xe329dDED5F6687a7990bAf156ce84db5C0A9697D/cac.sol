
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

contract CAC is Ownable {

    using SafeERC20 for IERC20;
    IERC20 public token;

    event DepositUSDT(address indexed user, uint256 value);
    event SentUSDT(address indexed to, uint256 value);
    
    constructor(address tokenAddress) public {
        // 初始化token
        token = IERC20(tokenAddress);
    }

    // 入金
    function depositUSDT(uint256 value) external {
        require((value%100) == 0, "deposit usdt need Multiples of 100.");
        require(token.balanceOf(msg.sender) >= value, "usdt balance is not enough.");
        require(token.allowance(msg.sender, address(this)) >= value, "token allowance is not enough.");

        token.safeTransferFrom(msg.sender, address(this), value);
        emit DepositUSDT(msg.sender, value);
    }

    // 出金
    function sendUSDT(address to, uint256 value) external onlyOwner {
        token.safeTransfer(to, value);
        emit SentUSDT(to, value);
    }
}
