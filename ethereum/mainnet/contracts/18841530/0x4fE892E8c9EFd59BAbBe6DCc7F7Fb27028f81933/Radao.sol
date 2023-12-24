// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Pausable.sol";
import "./ERC20Permit.sol";

import "./Withdrawable.sol";

abstract contract Radao is ERC20Pausable, ERC20Permit, Withdrawable {
    uint8 public constant RADAO_VERSION = 1;
    bytes32 public constant RADAO_META_ROLE = keccak256("RADAO_META_ROLE");
    bytes32 public constant RADAO_PAUSER_ROLE = keccak256("RADAO_PAUSER_ROLE");

    mapping(string => string) public meta;

    constructor(string memory name, string memory symbol, address admin) ERC20(name, symbol) ERC20Permit(name) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RADAO_META_ROLE, admin);
        _grantRole(RADAO_PAUSER_ROLE, admin);
        _grantRole(WITHDRAW_ROLE, admin);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function pause() public onlyRole(RADAO_PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(RADAO_PAUSER_ROLE) {
        _unpause();
    }

    function getMeta(string[] memory keys) public view returns (string[] memory values) {
        values = new string[](keys.length);
        for (uint i = 0; i < keys.length; i++) {
            values[i] = meta[keys[i]];
        }
        return values;
    }

    function getMeta(string memory key) public view returns (string memory value) {
        return meta[key];
    }

    function setMeta(string[] memory entries) public {
        require(entries.length % 2 == 0, "Radao: entries length must be even ([key1, value1, ...])");
        for (uint i = 0; i < entries.length; i += 2) {
            setMeta(entries[i], entries[i + 1]);
        }
    }

    function setMeta(string memory key, string memory value) public onlyRole(RADAO_META_ROLE) {
        meta[key] = value;
    }

    function deleteMeta(string[] memory keys) public {
        for (uint i = 0; i < keys.length; i++) {
            deleteMeta(keys[i]);
        }
    }

    function deleteMeta(string memory key) public onlyRole(RADAO_META_ROLE) {
        delete meta[key];
    }
}
