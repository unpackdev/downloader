// Twitter: https://twitter.com/LPshareerc 
// Website: https://lpshares.tech
// Telegram: https://t.me/LpShares


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./AccessControl.sol";
import "./ERC20.sol";

contract STLP is ERC20, AccessControl {
    address public bridgeAddress;
    address public stakingAddress;

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    event Bridge(address indexed account, uint256 amount, bytes32 raw);

    constructor() ERC20("Staked LPS", "stLP") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setBrige(address _bridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bridgeAddress = _bridge;
    }

    function setStaking(
        address _staking
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(DEFAULT_ADMIN_ROLE, _staking);
        stakingAddress = _staking;
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mint(to, amount);
    }

    function burn(
        address from,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _burn(from, amount);
    }

    function bridge(
        address to,
        uint256 amount,
        bytes32 _raw
    ) external onlyRole(BRIDGE_ROLE) {
        _burn(_msgSender(), amount);
        emit Bridge(to, amount, _raw);
    }
}
