// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.1;
pragma abicoder v2;

import "./Ownable.sol";
import "./DastraERC20Mintable.sol";

contract DastraERC20MintableDeployer is Ownable {
    function deploy(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimals,
        uint256 cap,
        address trustedForwarder,
        address owner
    ) external onlyOwner returns (address deployed) {
        deployed = address(new DastraERC20Mintable(name, symbol, initialSupply, decimals, cap, trustedForwarder, owner));
    }
}