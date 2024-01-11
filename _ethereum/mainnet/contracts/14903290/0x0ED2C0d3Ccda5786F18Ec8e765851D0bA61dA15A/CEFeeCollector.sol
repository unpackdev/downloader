// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract CEFeeCollector is AccessControlEnumerable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant PERCENT_PRECISION = 1e18; // 1%

    uint256[4] public distribution;
    address[4] public wallets;

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not an admin"
        );
        _;
    }

    constructor(
        address _admin,
        address wallet1,
        address wallet2,
        address wallet3,
        address wallet4
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        distribution[0] = 30 * PERCENT_PRECISION; // 30%
        distribution[1] = 30 * PERCENT_PRECISION; // 30%
        distribution[2] = 20 * PERCENT_PRECISION; // 20%
        distribution[3] = 20 * PERCENT_PRECISION; // 20%

        wallets[0] = wallet1;
        wallets[1] = wallet2;
        wallets[2] = wallet3;
        wallets[3] = wallet4;
    }

    function totalRatio() public view returns (uint256 total) {
        for (uint256 i; i < distribution.length; i++) {
            total = total.add(distribution[i]);
        }
    }

    function setWallet(uint256 index, address wallet) external onlyAdmin {
        require(index < wallets.length, "index out of range");
        require(wallet != address(0), "invalid address");
        require(wallets[index] != wallet, "same value");
        wallets[index] = wallet;
    }

    function setDistribution(uint256 index, uint256 ratio) external onlyAdmin {
        require(index < distribution.length, "index out of range");
        require(distribution[index] != ratio, "same value");
        distribution[index] = ratio;
    }

    function claim() external {
        uint256 totalAmount = address(this).balance;
        require(totalAmount > 0, "nothing to be claimed");
        require(totalRatio() == 100e18, "invalid distribution");
        for (uint256 i; i < wallets.length; i++) {
            uint256 amount = totalAmount.mul(distribution[i]).div(
                PERCENT_PRECISION.mul(100)
            );
            (bool success, ) = payable(wallets[i]).call{value: amount}("");
            require(success, "failed to send native");
        }
    }

    function claim(address token) external {
        require(token != address(0), "invalid address");
        uint256 totalAmount = IERC20(token).balanceOf(address(this));
        require(totalAmount > 0, "nothing to be claimed");
        require(totalRatio() == 100e18, "invalid distribution");
        for (uint256 i; i < wallets.length; i++) {
            uint256 amount = totalAmount.mul(distribution[i]).div(
                PERCENT_PRECISION.mul(100)
            );
            IERC20(token).safeTransfer(wallets[i], amount);
        }
    }

    receive() external payable {}
}
