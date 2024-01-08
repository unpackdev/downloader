//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./AccessControl.sol";

import "./IOperationsRegistry.sol";
import "./IEurPriceFeed.sol";

/**
 * @title Authorization
 * @author Protofire
 * @dev Contract module to keep track of the EUR amount being tradded for each user by operation.
 *
 */
contract OperationsRegistry is IOperationsRegistry, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ASSETS_MANAGER_ROLE = keccak256("ASSETS_MANAGER_ROLE");
    bytes32 public constant FEED_MANAGER_ROLE = keccak256("FEED_MANAGER_ROLE");

    /**
     * @dev Address of EUR Price feed module from where to get assets EUR prices.
     */
    address public eurPriceFeed;

    /**
     * @dev Assets that are allowed for updating user traiding balances.
     */
    mapping(address => bool) public allowedAssets;

    /**
     * @dev EUR amount tradded for each user by operation.
     */
    mapping(address => mapping(bytes4 => uint256)) public override tradingBalanceByOperation;

    /**
     * @dev Emitted when `eurPriceFeed` address is set.
     */
    event EurPriceFeedSet(address indexed newEurPriceFeed);

    /**
     * @dev Emitted when `asset` is allowed.
     */
    event AssetAllowed(address indexed asset);

    /**
     * @dev Emitted when `asset` is disallowed.
     */
    event AssetDisallowed(address indexed asset);

    /**
     * @dev Sets the values for {eurPriceFeed}.
     *
     * Grants the contract deployer the default admin role.
     *
     */
    constructor(address _eurPriceFeed) {
        require(_eurPriceFeed != address(0), "eur price feed is the zero address");
        emit EurPriceFeedSet(_eurPriceFeed);
        eurPriceFeed = _eurPriceFeed;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Throws if called by any asset not allowed.
     */
    modifier onlyAllowedAsset() {
        require(allowedAssets[_msgSender()], "asset is not allowed");
        _;
    }

    /**
     * @dev Throws if called by some address with ASSETS_MANAGER_ROLE.
     */
    modifier onlyAssetsManager() {
        require(hasRole(ASSETS_MANAGER_ROLE, _msgSender()), "must have asset manager role");
        _;
    }

    /**
     * @dev Grants FEED_MANAGER_ROLE to `_account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setFeedManager(address _account) external {
        grantRole(FEED_MANAGER_ROLE, _account);
    }

    /**
     * @dev Grants ASSETS_MANAGER_ROLE to `_account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setAssetsManager(address _account) external {
        grantRole(ASSETS_MANAGER_ROLE, _account);
    }

    /**
     * @dev Sets `_eurPriceFeed` as the new EUR Price feed module.
     *
     * Requirements:
     *
     * - the caller must have FEED_MANAGER_ROLE.
     * - `_eurPriceFeed` should not be the zero address.
     *
     * @param _eurPriceFeed The address of the new EUR Price feed module.
     */
    function setEurPriceFeed(address _eurPriceFeed) external override {
        require(hasRole(FEED_MANAGER_ROLE, _msgSender()), "must have feed manager role");
        require(_eurPriceFeed != address(0), "eur price feed is the zero address");
        emit EurPriceFeedSet(_eurPriceFeed);
        eurPriceFeed = _eurPriceFeed;
    }

    /**
     * @dev Sets `_asset` as allowed for calling `addTrade`.
     *
     * Requirements:
     *
     * - the caller must have ASSETS_MANAGER.
     * - `_asset` should not be the zero address.
     *
     * @param _asset asset's address.
     */
    function allowAsset(address _asset) external override onlyAssetsManager {
        require(_asset != address(0), "asset is the zero address");
        emit AssetAllowed(_asset);
        allowedAssets[_asset] = true;
    }

    /**
     * @dev Sets `_asset` as disallowed for calling `addTrade`.
     *
     * Requirements:
     *
     * - the caller mustbe the owner.
     * - `_asset` should not be the zero address.
     *
     * @param _asset asset's address.
     */
    function disallowAsset(address _asset) external override onlyAssetsManager {
        require(_asset != address(0), "asset is the zero address");
        emit AssetDisallowed(_asset);
        allowedAssets[_asset] = false;
    }

    /**
     * @dev Adds `_amount` converted to ERU to the balance traded by `_user` for an `_operation`
     *
     * Requirements:
     *
     * - the caller must be an allowed asset.
     *
     * @param _user user's address
     * @param _operation msg.sig of the function considered an operation.
     * @param _amount asset amount which is converted to EUR and added to balance traded by `_user` for `_operation`.
     */
    function addTrade(
        address _user,
        bytes4 _operation,
        uint256 _amount
    ) external override onlyAllowedAsset {
        uint256 currentBalance = tradingBalanceByOperation[_user][_operation];
        tradingBalanceByOperation[_user][_operation] = currentBalance.add(
            IEurPriceFeed(eurPriceFeed).calculateAmount(_msgSender(), _amount)
        );
    }
}
