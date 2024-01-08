// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

abstract contract TRLabOwnableUpgradeable is OwnableUpgradeable {
    address private _trlab;

    event TRLabAddressTransferred(address indexed previousTRLab, address indexed newTRLab);
    /**
     * @dev Throws if called by any account other than the owner or TRLabCore
     */
    modifier onlyOwnerOrTRLab() {
        require(owner() == _msgSender() || trlabToken() == _msgSender(), "caller is not the owner or TRLab Token");
        _;
    }

    /**
     * @dev Returns the address of trlab token.
     */
    function trlabToken() public view returns (address) {
        return _trlab;
    }

    /**
     * @dev Returns the address of trlab token.
     */
    function setTRLab(address newTRLab) external onlyOwner {
        require(newTRLab != address(0), "TRLabOwnable: new TRLab Token is the zero address");
        emit TRLabAddressTransferred(_trlab, newTRLab);
        _trlab = newTRLab;
    }

    uint256[49] private __gap;
}
