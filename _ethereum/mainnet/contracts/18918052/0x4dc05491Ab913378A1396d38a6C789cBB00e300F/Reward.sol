// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract HyprReward is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    address public hyprTokenAddress;

    mapping(address => uint256) public hyprReward;
    mapping(address => uint256) public etherReward;

    constructor(address addr, address updater) {
        hyprTokenAddress = addr;
        _grantRole(UPDATER_ROLE, updater);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function claimHypr(address holder, uint256 amount) public {
        require(amount <= hyprReward[holder], "Claim amount exceed your reward");

        hyprReward[holder] -= amount;

        IERC20 ht = IERC20(hyprTokenAddress);
        ht.safeTransfer(holder, amount);
    }

    function claimEther(address holder, uint256 amount) public {
        require(amount <= hyprReward[holder], "Claim amount exceed your reward");

        hyprReward[holder] -= amount;

        IERC20 ht = IERC20(hyprTokenAddress);
        ht.transfer(holder, amount);
    }

    function setHolderAmount(address[] calldata addrs, uint256[] calldata amounts) external onlyRole(UPDATER_ROLE) {
        require(addrs.length == amounts.length, "require data length equal");

        uint256 total = 0;

        for (uint256 i = 0; i != addrs.length; i++) {
            address holder = addrs[i];
            uint256 amount = amounts[i];

            total += amount;

            hyprReward[holder] = amount;
        }

        IERC20 ht = IERC20(hyprTokenAddress);
        ht.safeTransferFrom(msg.sender, address(this), total);
    }

    function reduceAllToken(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20 ht = IERC20(hyprTokenAddress);
        ht.safeTransfer(msg.sender, amount);
    }

    function getHyprReward(address addr) public view returns (uint256) {
        return hyprReward[addr];
    }

    fallback() external payable {}

    receive() external payable {}
}
