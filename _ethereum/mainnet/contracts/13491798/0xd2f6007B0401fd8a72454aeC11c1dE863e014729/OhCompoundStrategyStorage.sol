// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Initializable.sol";
import "./ICompoundStrategyStorage.sol";
import "./OhUpgradeable.sol";

contract OhCompoundStrategyStorage is Initializable, OhUpgradeable, ICompoundStrategyStorage {
    bytes32 internal constant _COMPTROLLER_SLOT = 0x5afedb916735b48cdf292f42c56bdd9f2c18a47029ac6473a9597ce1cb6a8661;

    constructor() {
        assert(_COMPTROLLER_SLOT == bytes32(uint256(keccak256("eip1967.compoundStrategy.comptroller")) - 1));
    }

    function initializeCompoundStorage(address comptroller_) internal initializer {
        _setComptroller(comptroller_);
    }

    function comptroller() public view override returns (address) {
        return getAddress(_COMPTROLLER_SLOT);
    }

    function _setComptroller(address comptroller_) internal {
        setAddress(_COMPTROLLER_SLOT, comptroller_);
    }
}
