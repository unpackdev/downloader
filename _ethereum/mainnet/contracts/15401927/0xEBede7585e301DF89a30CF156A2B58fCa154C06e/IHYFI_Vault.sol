// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IAccessControlUpgradeable.sol";

interface IHYFI_Vault is IAccessControlUpgradeable {
    function MINTER_ROLE() external view returns (bytes32);

    function BURNER_ROLE() external view returns (bytes32);

    function safeMint(address to, uint256 amount) external;
}
