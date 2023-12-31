// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./Mutex.sol";
import "./Initializable.sol";

contract PreSaleShutdown is Initializable, Mutex {
    uint256 constant DECIMALS = 18;
    uint256 constant USDT_DECIMALS = 6;
    uint256 constant START_PRICE = 3 * 10 ** 14; // 0.0003 USDT
    uint256 constant PRICE_PER_USDT = 5 * 10 ** 10; // 0.00000005
    uint256 constant MAX_TOTAL_SUPPLY = 6_993_000_000 * 10 ** DECIMALS;

    address public admin;
    IERC20 private usdt;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    function init(address admin_, address usdt_) external whenNotInitialized {
        require(admin_ != address(0), "zero admin address");
        require(usdt_ != address(0), "zero usdt address");
        admin = admin_;
        usdt = IERC20(usdt_);
    }

    receive() external payable mutex {
        // Add ETH recv
    }

    function emergencyWithdraw(address recipient) external {
        require(msg.sender == admin, "only admin");
        usdt.transfer(recipient, usdt.balanceOf(address(this)));
    }
}
