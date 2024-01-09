// SPDX-License-Identifier: MIT

/**
 * ░█▄ █▒█▀░▀█▀  ▒█▀▄▒██▀░█ ░▒█▒▄▀▄▒█▀▄░█▀▄░▄▀▀
 * ░█▒▀█░█▀ ▒█▒▒░░█▀▄░█▄▄░▀▄▀▄▀░█▀█░█▀▄▒█▄▀▒▄██
 * 
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.9;


import "./AccessControlUpgradeable.sol";
import "./UUPSUpgradeable.sol";

/**
 * Holds receivers addresses and allowances
 */
contract AllowancesStore is AccessControlUpgradeable, UUPSUpgradeable {
    struct Allowance {
        address minter;
        uint16 amount;
    }

    mapping(address => uint16) public allowances;
    address[] public minters;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer { }

    function initialize() public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
    
    function update(Allowance[] memory _allowances) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < _allowances.length; i++) {
            if (_allowances[i].amount != 0 && allowances[_allowances[i].minter] == 0) {
                minters.push(_allowances[i].minter);
            }
            allowances[_allowances[i].minter] = _allowances[i].amount;
        }
    }

    function updateTo(address[] memory _receivers, uint16 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < _receivers.length; i++) {
            if (amount != 0 && allowances[_receivers[i]] == 0) {
                minters.push(_receivers[i]);
            }
            allowances[_receivers[i]] = amount;
        }
    }

    function totalAllowed() public view returns (uint64) {
        uint64 _allowed = 0;
        for (uint i = 0; i < minters.length; i++) {
            _allowed += allowances[minters[i]];
        }
        return _allowed;
    }

    function length() public view returns (uint256) {
        return minters.length;
    }

    function list() public view returns (Allowance[] memory) {
        Allowance[] memory _allowances = new Allowance[](minters.length);
        for (uint i = 0; i < minters.length; i++) {
            _allowances[i] = Allowance(minters[i], allowances[minters[i]]);
        }
        return _allowances;
    }
}
