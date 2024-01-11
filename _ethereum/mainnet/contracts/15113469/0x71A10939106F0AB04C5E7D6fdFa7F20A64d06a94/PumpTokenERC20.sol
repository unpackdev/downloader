// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./AccessControl.sol";
import "./ERC20.sol";

contract PumpTokenERC20 is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public maxStakeYield = 30000000 ether;
    uint256 public currentStakeYield = 0;

    address private daoWallet = address(0x0205Fb409df16bd8B96372f4118F4720c7474d6A);

    constructor() ERC20("Pump", "PMP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _mint(daoWallet, 70000000 ether);
    }

    function grantMinterRole(address stakingContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, stakingContract);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(amount > 0);
        if ((currentStakeYield + amount) > maxStakeYield) {
            amount = maxStakeYield - currentStakeYield;
        }
        _mint(to, amount);
        currentStakeYield += amount;
    }
}