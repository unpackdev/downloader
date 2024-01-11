// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

// References
import "./IERC721ReadOnlyProxy.sol";
import "./RentableTypes.sol";

/// @title Rentable Storage contract
/// @author Rentable Team <hello@rentable.world>
/// @custom:security Rentable Security Team <security@rentable.world>
contract RentableStorageV1 {
    /* ========== CONSTANTS ========== */

    // paymentTokenAllowlist possible values
    // used during fee distribution
    uint8 internal constant NOT_ALLOWED_TOKEN = 0;
    uint8 internal constant ERC20_TOKEN = 1;
    uint8 internal constant ERC1155_TOKEN = 2;

    // percentage protocol fee, min 0.01%
    uint16 internal constant BASE_FEE = 10000;

    /* ========== STATE VARIABLES ========== */

    // (token address, token id) => rental conditions mapping
    // slither-disable-next-line naming-convention
    mapping(address => mapping(uint256 => RentableTypes.RentalConditions))
        internal _rentalConditions;

    // (token address, token id) => rental expiration mapping
    // slither-disable-next-line naming-convention
    mapping(address => mapping(uint256 => uint256)) internal _expiresAt;

    // token address => o/w token mapping
    // slither-disable-next-line naming-convention,similar-names
    mapping(address => address) internal _orentables;
    // slither-disable-next-line naming-convention,similar-names
    mapping(address => address) internal _wrentables;

    // token address => library mapping, for custom logic execution
    // slither-disable-next-line naming-convention
    mapping(address => address) internal _libraries;

    // allowed payment tokens, see fee distribution in Rentable-rent
    // slither-disable-next-line naming-convention
    mapping(address => uint8) internal _paymentTokenAllowlist;

    // enabled selectors for target, see Rentable-proxyCall
    // slither-disable-next-line naming-convention
    mapping(address => mapping(bytes4 => bool)) internal _proxyAllowList;

    // user wallet factory
    // slither-disable-next-line naming-convention
    address internal _walletFactory;

    // user => wallet mapping, for account abstraction
    // slither-disable-next-line naming-convention
    mapping(address => address payable) internal _wallets;

    // protocol fee
    // slither-disable-next-line naming-convention
    uint16 internal _fee;
    // protocol fee collector
    // slither-disable-next-line naming-convention
    address payable internal _feeCollector;
}
