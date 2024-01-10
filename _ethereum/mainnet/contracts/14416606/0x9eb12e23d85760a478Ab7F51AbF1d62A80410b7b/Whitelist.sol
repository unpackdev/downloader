// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.6.10;

import "./WhitelistInterface.sol";
import "./AddressBookInterface.sol";
import "./OracleInterface.sol";
import "./OtokenInterface.sol";
import "./Ownable.sol";

/**
 * @author Opyn Team
 * @title Whitelist Module
 * @notice The whitelist module keeps track of all valid oToken addresses, product hashes, collateral addresses, and callee addresses.
 */
contract Whitelist is Ownable, WhitelistInterface {
    /// @notice AddressBook module address
    address public override addressBook;
    /// @dev mapping to track whitelisted products
    mapping(bytes32 => bool) internal whitelistedProduct;
    /// @dev mapping to track products whitelisted by the owner address
    mapping(bytes32 => bool) internal ownerWhitelistedProduct;
    /// @dev mapping to track whitelisted collateral
    mapping(address => bool) internal whitelistedCollateral;
    /// @dev mapping to track whitelisted oTokens
    mapping(address => bool) internal whitelistedOtoken;
    /// @dev mapping to track whitelisted callee addresses for the call action
    mapping(address => bool) internal whitelistedCallee;
    /// @dev mapping to track whitelisted vault owners
    mapping(address => bool) internal whitelistedOwner;

    /**
     * @dev constructor
     * @param _addressBook AddressBook module address
     */
    constructor(address _addressBook) public {
        require(_addressBook != address(0), "Invalid address book");

        addressBook = _addressBook;
    }

    /// @notice emits an event a product is whitelisted by anyone
    event ProductWhitelisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event a product is whitelisted by the owner address
    event OwnerProductWhitelisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event a product is blacklisted by the owner address
    event ProductBlacklisted(
        bytes32 productHash,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        bool isPut
    );
    /// @notice emits an event when a collateral address is whitelisted by anyone
    event CollateralWhitelisted(address indexed collateral);
    /// @notice emits an event when a collateral address is blacklisted by the owner address
    event CollateralBlacklisted(address indexed collateral);
    /// @notice emits an event when an oToken is whitelisted by the OtokenFactory module
    event OtokenWhitelisted(address indexed otoken);
    /// @notice emits an event when an oToken is blacklisted by the OtokenFactory module
    event OtokenBlacklisted(address indexed otoken);
    /// @notice emits an event when a callee address is whitelisted by the owner address
    event CalleeWhitelisted(address indexed _callee);
    /// @notice emits an event when a callee address is blacklisted by the owner address
    event CalleeBlacklisted(address indexed _callee);
    /// @notice emits an event when a vault owner is whitelisted
    event OwnerWhitelisted(address indexed account);
    /// @notice emits an event when a vault owner is blacklisted
    event OwnerBlacklisted(address indexed account);

    /**
     * @notice check if the sender is the oTokenFactory module
     */
    modifier onlyFactory() {
        require(
            msg.sender == AddressBookInterface(addressBook).getOtokenFactory(),
            "Whitelist: Sender is not OtokenFactory"
        );

        _;
    }

    /**
     * @notice check if a product is whitelisted
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     * @return boolean, True if product is whitelisted
     */
    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view override returns (bool) {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        return whitelistedProduct[productHash];
    }

    /**
     * @notice check if a product is whitelisted by the owner
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     * @return boolean, True if product is whitelisted
     */
    function isOwnerWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view override returns (bool) {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        return ownerWhitelistedProduct[productHash];
    }

    /**
     * @notice check if a collateral asset is whitelisted
     * @param _collateral asset that is held as collateral against short/written options
     * @return boolean, True if the collateral is whitelisted
     */
    function isWhitelistedCollateral(address _collateral) external view override returns (bool) {
        return whitelistedCollateral[_collateral];
    }

    /**
     * @notice check if an oToken is whitelisted
     * @param _otoken oToken address
     * @return boolean, True if the oToken is whitelisted
     */
    function isWhitelistedOtoken(address _otoken) external view override returns (bool) {
        return whitelistedOtoken[_otoken];
    }

    /**
     * @notice check if an oToken and its product specifications is whitelisted by the owner
     * @param _otoken oToken address
     * @return boolean, True if the oToken is whitelisted
     */
    function isOwnerWhitelistedOtoken(address _otoken) external view override returns (bool) {
        return
            whitelistedOtoken[_otoken] && // Avoids computing the product hash if oToken isn't whitelisted
            ownerWhitelistedProduct[
                keccak256(
                    abi.encode(
                        OtokenInterface(_otoken).underlyingAsset(),
                        OtokenInterface(_otoken).strikeAsset(),
                        OtokenInterface(_otoken).collateralAsset(),
                        OtokenInterface(_otoken).isPut()
                    )
                )
            ];
    }

    /**
     * @notice check if a callee address is whitelisted for the call action
     * @param _callee callee destination address
     * @return boolean, True if the address is whitelisted
     */
    function isWhitelistedCallee(address _callee) external view override returns (bool) {
        return whitelistedCallee[_callee];
    }

    /**
     * @notice check if a vault owner is whitelisted
     * @param _owner vault owner address
     * @return boolean, True if the address is whitelisted
     */
    function isWhitelistedOwner(address _owner) external view override returns (bool) {
        return whitelistedOwner[_owner];
    }

    /**
     * @notice allows anyone to whitelist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * product must have an oracle for its underlying asset before being whitelisted
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external override {
        require(whitelistedCollateral[_collateral], "Whitelist: Collateral is not whitelisted");
        require(
            OracleInterface(AddressBookInterface(addressBook).getOracle()).getPrice(_underlying) > 0,
            "Whitelist: Underlying must have price"
        );
        require(
            OracleInterface(AddressBookInterface(addressBook).getOracle()).getPrice(_strike) > 0,
            "Whitelist: Strike must have price"
        );

        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        whitelistedProduct[productHash] = true;

        emit ProductWhitelisted(productHash, _underlying, _strike, _collateral, _isPut);
    }

    /**
     * @notice allows the owner to whitelist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function ownerWhitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external override onlyOwner {
        require(whitelistedCollateral[_collateral], "Whitelist: Collateral is not whitelisted");

        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        whitelistedProduct[productHash] = true;

        ownerWhitelistedProduct[productHash] = true;

        emit ProductWhitelisted(productHash, _underlying, _strike, _collateral, _isPut);
        emit OwnerProductWhitelisted(productHash, _underlying, _strike, _collateral, _isPut);
    }

    /**
     * @notice allow the owner to blacklist a product
     * @dev product is the hash of underlying asset, strike asset, collateral asset, and isPut
     * can only be called from the owner address
     * @param _underlying asset that the option references
     * @param _strike asset that the strike price is denominated in
     * @param _collateral asset that is held as collateral against short/written options
     * @param _isPut True if a put option, False if a call option
     */
    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external override onlyOwner {
        bytes32 productHash = keccak256(abi.encode(_underlying, _strike, _collateral, _isPut));

        whitelistedProduct[productHash] = false;

        ownerWhitelistedProduct[productHash] = false;

        emit ProductBlacklisted(productHash, _underlying, _strike, _collateral, _isPut);
    }

    /**
     * @notice allows anyone to whitelist a collateral with an oracle
     * @dev can only be called from the owner address. This function is used to whitelist any asset other than Otoken as collateral. WhitelistOtoken() is used to whitelist Otoken contracts.
     * @param _collateral collateral asset address
     */
    function whitelistCollateral(address _collateral) external override {
        require(
            OracleInterface(AddressBookInterface(addressBook).getOracle()).getPrice(_collateral) > 0,
            "Whitelist: Collateral must have price"
        );

        whitelistedCollateral[_collateral] = true;

        emit CollateralWhitelisted(_collateral);
    }

    /**
     * @notice allows the owner to whitelist a collateral address
     * @dev can only be called from the owner address. This function is used to whitelist any asset other than Otoken as collateral. WhitelistOtoken() is used to whitelist Otoken contracts.
     * @param _collateral collateral asset address
     */
    function ownerWhitelistCollateral(address _collateral) external override onlyOwner {
        whitelistedCollateral[_collateral] = true;

        emit CollateralWhitelisted(_collateral);
    }

    /**
     * @notice allows the owner to blacklist a collateral address
     * @dev can only be called from the owner address
     * @param _collateral collateral asset address
     */
    function blacklistCollateral(address _collateral) external override onlyOwner {
        whitelistedCollateral[_collateral] = false;

        emit CollateralBlacklisted(_collateral);
    }

    /**
     * @notice allows the OtokenFactory module to whitelist a new option
     * @dev can only be called from the OtokenFactory address
     * @param _otokenAddress oToken
     */
    function whitelistOtoken(address _otokenAddress) external override onlyFactory {
        whitelistedOtoken[_otokenAddress] = true;

        emit OtokenWhitelisted(_otokenAddress);
    }

    /**
     * @notice allows the owner to blacklist an option
     * @dev can only be called from the owner address
     * @param _otokenAddress oToken
     */
    function blacklistOtoken(address _otokenAddress) external override onlyOwner {
        whitelistedOtoken[_otokenAddress] = false;

        emit OtokenBlacklisted(_otokenAddress);
    }

    /**
     * @notice allows the owner to whitelist a destination address for the call action
     * @dev can only be called from the owner address
     * @param _callee callee address
     */
    function whitelistCallee(address _callee) external override onlyOwner {
        whitelistedCallee[_callee] = true;

        emit CalleeWhitelisted(_callee);
    }

    /**
     * @notice allows the owner to blacklist a destination address for the call action
     * @dev can only be called from the owner address
     * @param _callee callee address
     */
    function blacklistCallee(address _callee) external override onlyOwner {
        whitelistedCallee[_callee] = false;

        emit CalleeBlacklisted(_callee);
    }

    /**
     * @notice whitelists a vault owner
     * @dev can only be called from the owner address
     * @param account vault owner
     */
    function whitelistOwner(address account) external override onlyOwner {
        whitelistedOwner[account] = true;

        emit OwnerWhitelisted(account);
    }

    /**
     * @notice blacklists a vault owner
     * @dev can only be called from the owner address
     * @param account vault owner
     */
    function blacklistOwner(address account) external override onlyOwner {
        whitelistedOwner[account] = false;

        emit OwnerBlacklisted(account);
    }
}
