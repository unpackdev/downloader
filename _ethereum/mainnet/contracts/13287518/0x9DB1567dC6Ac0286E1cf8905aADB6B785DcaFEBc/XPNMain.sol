// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;
import "./AccessControlEnumerable.sol";
import "./ReentrancyGuard.sol";
import "./XPNCore.sol";

// @title monolith contract for exponent vault
// @notice require post deployment configuration
// @dev expose only external functions
contract XPNMain is XPNCore, AccessControlEnumerable, ReentrancyGuard {
    // @notice default admin role is part of AccessControlEnumerable library
    // bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");

    bytes32 public constant SETTLER_ROLE = keccak256("SETTLER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant VENUE_WHITELIST_ROLE =
        keccak256("VENUE_WHITELIST_ROLE");
    bytes32 public constant ASSET_WHITELIST_ROLE =
        keccak256("ASSET_WHITELIST_ROLE");

    constructor(
        State memory _constructorConfig,
        string memory _tokenName,
        string memory _symbol
    ) XPNCore(_constructorConfig, _tokenName, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _constructorConfig.defaultAdmin);
        _setupRole(SETTLER_ROLE, _constructorConfig.defaultSettler);
    }

    /////////////////////////
    // configuration functions
    /////////////////////////

    // @notice swap signal address and signal name
    // @param _signalPoolAddress address of the signal contract
    // @param _signalName name identifier of the signal
    // @dev only callable by admin role
    function swapSignal(address _signalPoolAddress, string memory _signalName)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _swapSignal(_signalPoolAddress, _signalName);
    }

    // @notice set the contract on restricted mode, under restricted mode- only whitelist contract can make deposit
    // @param boolean to set the restricted mode on/off
    // @dev only callable by manager role
    function setRestricted(bool _toggle) external onlyRole(MANAGER_ROLE) {
        _setRestricted(_toggle);
    }

    // @notice whitelist wallet by address
    // @param address of the wallet to whitelist
    // @dev only callable by the manager role
    function whitelistWallet(address _wallet) external onlyRole(MANAGER_ROLE) {
        _whitelistWallet(_wallet);
    }

    // @notice un-whitelist wallet by address
    // @param address of the wallet to un-whitelist
    // @dev only callable by the manager role
    function deWhitelistWallet(address _wallet)
        external
        onlyRole(MANAGER_ROLE)
    {
        _deWhitelistWallet(_wallet);
    }

    // @notice whitelist venue by address
    // @param address of the venue to whitelist
    // @dev only callable by the venue whitelist role
    function whitelistVenue(address _venue)
        external
        onlyRole(VENUE_WHITELIST_ROLE)
    {
        _whitelistVenue(_venue);
    }

    // @notice un-whitelist venue by address
    // @param address of the venue to un-whitelist
    // @dev only callable by the venue whitelist role
    function deWhitelistVenue(address _venue)
        external
        onlyRole(VENUE_WHITELIST_ROLE)
    {
        _deWhitelistVenue(_venue);
    }

    // @notice whitelist asset by address
    // @param address of the asset to whitelist
    // @dev only callable by the asset whitelist role
    function whitelistAsset(address _asset)
        external
        onlyRole(ASSET_WHITELIST_ROLE)
    {
        _whitelistAsset(_asset);
    }

    // @notice un-whitelist asset by address
    // @param address of the asset to un-whitelist
    // @dev only callable by the asset whitelist role
    function deWhitelistAsset(address _asset)
        external
        onlyRole(ASSET_WHITELIST_ROLE)
    {
        _deWhitelistAsset(_asset);
    }

    // @notice configure and resolve asset name to address and price feed
    // @param _symbol asset name
    // @param _token asset address,
    // @param _feed destination of the price feed
    // @dev only callable by asset whitelist role
    function addAssetFeedConfig(
        string memory _symbol,
        address _token,
        address _feed
    ) external onlyRole(ASSET_WHITELIST_ROLE) {
        _addAssetConfig(_symbol, _token, _feed);
    }

    // @notice add tracked asset by address
    // @param address of the asset to track
    // @dev enzyme-specific functionality to track zero balance asset
    function addTrackedAsset(address _asset)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _addTrackedAsset(_asset);
    }

    // @notice remove tracked asset by address
    // @param address of the asset to track
    // @dev enzyme-specific functionality to un-track zero balance asset
    function removeTrackedAsset(address _asset)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _removeTrackedAsset(_asset);
    }

    /////////////////////////
    //  vault migration functions
    /////////////////////////

    // @notice create the migration
    // @param _newState the new global state of the contract to migrate to
    // @dev deploys a new enzyme comptroller proxy
    // @dev only callable by admin role
    function createMigration(State memory _newState)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _createMigration(_newState);
    }

    // @notice signal migration
    // @dev start the time lock for enzyme vault migration, users can withdraw but no longer allowed to deposit
    // @dev only callable by admin role
    function signalMigration() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _signalMigration();
    }

    // @notice execute the migration
    // @dev requires the current time > enzyme dispatcher's timelock
    // @dev change the global state of the contract, users are allowed to deposit again
    // @dev only callable by admin role
    function executeMigration() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _executeMigration();
    }

    /////////////////////////
    // vault functions
    /////////////////////////

    // @dev index zero admin is used as the recipient for fee collection
    // @dev we assume there will be only a single admin address
    // override to always ensure we get only the first admin
    // external contract should not rely on this as the only source of truth
    function _getAdminAddress() internal view override returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    // @notice deposit denominated asset into the contract
    // @param amount of the denominated asset to deposit
    // @dev requires the restricted mode off
    function deposit(uint256 _amount) external nonReentrant returns (uint256) {
        if (restricted) {
            require(walletWhitelist[msg.sender], "Wallet is not whitelisted");
            return _deposit(_amount);
        } else {
            return _deposit(_amount);
        }
    }

    // @notice withdraw a basket of assets from the contract based on lp tokens held
    // @return payoutAssets array of addresses of the assets in the basket
    // @return payoutAmounts array of amounts of the assets in the basket
    function withdraw(uint256 _amount)
        external
        nonReentrant
        returns (address[] memory payoutAssets, uint256[] memory payoutAmounts)
    {
        return _withdraw(_amount);
    }

    // @notice redeem fees accrued
    // @param _feeManager addresses of the feeManager contract
    // @param _fees addresses of fee contracts ie. management and performance fees
    function redeemFees(address _feeManager, address[] calldata _fees)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address[] memory payoutAssets, uint256[] memory payoutAmounts)
    {
        return _redeemFees(_feeManager, _fees);
    }

    /////////////////////////
    // portfolio  functions
    /////////////////////////

    // @notice calculate different between current portfolio position and target from signal
    // in balance of coresponding erc20
    // @dev 100% = 1e18.
    // @return int256 array balance different from target for each asset (directional)
    function signalPortfolioDiffToken()
        external
        view
        returns (int256[] memory)
    {
        return _signalPortfolioDiffToken();
    }

    // @notice set expected trade efficiency
    // @dev note 1e18 = 100% default is 98e16 (98%)
    // @dev only callable by admin role
    function setExpectedEfficiency(int256 _expectedEfficiency)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setExpectedEfficiency(_expectedEfficiency);
    }

    /////////////////////////
    // settlement functions
    /////////////////////////

    // @notice submit trusted trade orders
    // @params _trades array of abi encoded order data
    // @params _venues array of venue address
    // @dev only callable by settler role
    function submitTrustedTradeOrders(
        bytes[] calldata _trades,
        address[] memory _venues
    ) external onlyRole(SETTLER_ROLE) returns (bool) {
        return _settleTrade(_trades, _venues);
    }

    // @notice submit trusted lending pool orders
    // @params _orders array of abi encoded order data
    // @params _venues array of venue address
    // @dev only callable by settler role
    function submitTrustedPoolOrders(
        bytes[] calldata _orders,
        XPNSettlement.Pool[] calldata _txTypes,
        address[] memory _venues
    ) external onlyRole(SETTLER_ROLE) returns (bool) {
        return _settlePool(_orders, _txTypes, _venues);
    }

    // @notice submit trade orders
    // @params _trades array of abi encoded order data
    // @params _venues array of venue address
    // @dev ensure that trade executes with result as expected by the signal contract
    function submitTradeOrders(
        bytes[] calldata _trades,
        address[] memory _venues
    ) external ensureTrade returns (bool) {
        return _settleTrade(_trades, _venues);
    }

    // @notice submit lending pool orders
    // @params _trades array of abi encoded order data
    // @params _venues array of venue address
    // @dev ensure that trade executes with result as expected by the signal contract
    function submitPoolOrders(
        bytes[] calldata _orders,
        XPNSettlement.Pool[] calldata _txTypes,
        address[] memory _venues
    ) external ensureTrade returns (bool) {
        return _settlePool(_orders, _txTypes, _venues);
    }

    /////////////////////////
    // state getter functions
    /////////////////////////

    function getExponentConfig()
        external
        view
        returns (
            address,
            address,
            address,
            string memory,
            address
        )
    {
        return (
            globalState.denomAssetAddress,
            address(lptoken),
            globalState.signal,
            globalState.signalName,
            _getAdminAddress()
        );
    }

    function getEnzymeConfig()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            address,
            address
        )
    {
        return (
            globalState.EZshares,
            globalState.EZcomptroller,
            globalState.EZwhitelistPolicy,
            globalState.EZpolicy,
            globalState.EZtrackedAssetAdapter,
            globalState.EZintegrationManager,
            globalState.EZdeployer
        );
    }

    function isVenueWhitelisted(address _venue) external view returns (bool) {
        return venueWhitelist[_venue];
    }

    function isAssetWhitelisted(address _asset) external view returns (bool) {
        return assetWhitelist[_asset];
    }

    function isWalletWhitelisted(address wallet) external view returns (bool) {
        return walletWhitelist[wallet];
    }
}
