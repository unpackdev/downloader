// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

// Inheritance
import "./Ownable.sol";
import "./IWalletFactory.sol";

// References
import "./BeaconProxy.sol";

import "./SimpleWallet.sol";

/// @title Rentable wallet factory
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
/// @notice Wallet factory
contract WalletFactory is Ownable, IWalletFactory {
    /* ========== STATE VARIABLES ========== */

    // beacon for new wallets
    address private _beacon;

    /* ========== EVENTS ========== */

    /// @notice Emitted on wallet beacon change
    /// @param previousBeacon previous wallet beacon address
    /// @param newBeacon new wallet beacon address
    event WalletBeaconChanged(
        address indexed previousBeacon,
        address indexed newBeacon
    );

    /* ========== CONSTRUCTOR ========== */

    /// @dev Instatiate WalletFactory
    /// @param beacon beacon address
    constructor(address beacon) {
        _setBeacon(beacon);
    }

    /* ========== SETTERS ========== */

    /* ---------- Internal ---------- */

    /// @dev Set beacon for new wallets
    /// @param beacon beacon address
    function _setBeacon(address beacon) internal {
        address previousBeacon = _beacon;

        // it's ok to se to 0x0, disabling factory
        // slither-disable-next-line missing-zero-check
        _beacon = beacon;

        emit WalletBeaconChanged(previousBeacon, beacon);
    }

    /* ---------- Public ---------- */

    /// @notice Set beacon for new wallets
    /// @param beacon beacon address
    function setBeacon(address beacon) external onlyOwner {
        _setBeacon(beacon);
    }

    /* ========== VIEWS ========== */

    /// @notice Get beacon to be used for proxies
    /// @return beacon address
    function getBeacon() external view returns (address beacon) {
        return _beacon;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @inheritdoc IWalletFactory
    function createWallet(address owner, address user)
        external
        override
        returns (address payable wallet)
    {
        bytes memory _data = abi.encodeWithSelector(
            SimpleWallet.initialize.selector,
            owner,
            user
        );

        return payable(address(new BeaconProxy(_beacon, _data)));
    }
}
