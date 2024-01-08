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
pragma experimental ABIEncoderV2;

import "./XPNSettlement.sol";
import "./XPNUtils.sol";
import "./XPNVault.sol";
import "./XPNPortfolio.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";
import "./IFundDeployer.sol";
import "./IComptroller.sol";
import "./IIntegrationManager.sol";
import "./IPolicyManager.sol";

// @title core contract for XPN
// @notice responsible for the global state of the entire contract and external interactions
// @dev overrides all functional _hooks and lazy-hydrate state to downstream functional contracts,
contract XPNCore is Pausable, XPNVault, XPNSettlement, XPNPortfolio {
    using SafeERC20 for IERC20;
    int256 constant chainlinkONE = 1e8;

    struct State {
        address defaultAdmin; // xpn admin account, only used on deployment
        address defaultSettler; // EOA responsible for calling settlement, only used on deployment
        address signal; // contract address for signal to pull from
        string signalName; // signal name
        address denomAssetAddress; // address of the denominated asset
        string denomAssetSymbol; // symbol of the denominated asset
        address EZdeployer; // Enzyme FundDeployer contract
        address EZintegrationManager; // Enzyme IntegrationManager contract
        address EZtrackedAssetAdapter; // Enzyme TrackedAssetAdapter contract
        address EZpolicy; // Enzyme PolicyManager contract
        address EZwhitelistPolicy; // Enzyme InvestorWhitelist contract
        address EZcomptroller; // Enzyme Vault's ComptrollerProxy contract
        address EZshares; // Enzyme Vault's shares
        bytes EZfeeConfig; // configuration for fees
        string name; // name of the fund on Enzyme Vault
    }

    // @notice application state
    // @notice the target portfolio value to maintain after
    // the rebalance, default to 98%
    State internal globalState;
    int256 expectedEfficiency;
    // @notice the contract state after successful migration
    State private postMigrationState;

    // @notice a hardcoded selector for all Enzyme DEX trades
    bytes4 constant TAKE_ORDER_SELECTOR =
        bytes4(keccak256("takeOrder(address,bytes,bytes)"));
    // @notice a hardcoded selector for all Enzyme lending
    bytes4 constant LEND_ORDER_SELECTOR =
        bytes4(keccak256("lend(address,bytes,bytes)"));
    // @notice a hardcoded selector for all Enzyme redemption
    bytes4 constant REDEEM_ORDER_SELECTOR =
        bytes4(keccak256("redeem(address,bytes,bytes)"));

    // @notice minimum seconds between 2 enzyme shares action
    // zero to allow for multiple redemptions in one block
    uint256 constant SHARES_TIMELOCK = 0;
    // @notice enzyme integration manager ID for integration
    uint256 constant DEFI_INTEGRATION = 0;

    bool public restricted;

    mapping(address => bool) internal walletWhitelist;
    mapping(address => bool) internal venueWhitelist;
    mapping(address => bool) internal assetWhitelist;
    mapping(string => address) public symbolToAsset;
    mapping(address => address) public assetToPriceFeed;

    event SetRestricted(bool toggle);
    event WalletWhitelisted(address wallet);
    event WalletDeWhitelisted(address wallet);
    event VenueWhitelisted(address venue);
    event VenueDeWhitelisted(address venue);
    event AssetWhitelisted(address asset);
    event AssetDeWhitelisted(address asset);
    event AssetConfigAdded(string symbol, address asset, address feed);
    event AssetConfigRemoved(string symbol);
    event NewSignal(address signal);
    event MigrationCreated(State postMigrationState);
    event MigrationSignaled();
    event MigrationExecuted();

    // @dev we don't do further validation of the constructor arguments on deployment
    // assume all the inputs are valid
    constructor(
        State memory _constructorConfig,
        string memory _tokenName,
        string memory _symbol
    ) XPNPortfolio() XPNVault(_tokenName, _symbol) XPNSettlement() {
        globalState = _constructorConfig;
        _whitelistAsset(globalState.denomAssetAddress); //denominated asset is automatically whitelisted

        (globalState.EZcomptroller, globalState.EZshares) = IFundDeployer(
            globalState.EZdeployer
        ).createNewFund(
                address(this), // fund deployer
                globalState.name, // fund name
                address(globalState.denomAssetAddress), // denomination asset
                SHARES_TIMELOCK, // timelock for share actions
                globalState.EZfeeConfig, // fees configuration
                "" // no policy manager data
            );
        XPNUtils.enforceSoleEnzymeDepositor(
            globalState.EZcomptroller,
            globalState.EZpolicy,
            globalState.EZwhitelistPolicy
        );
        expectedEfficiency = 98e16;
    }

    /////////////////////////
    // configuration functions
    /////////////////////////

    // @notice sets the contract on restricted mode
    function _setRestricted(bool _toggle) internal {
        restricted = _toggle;
        emit SetRestricted(_toggle);
    }

    // @notice configure token symbol => token address and token address => price feed
    // @dev used in Portfolio's ensureTrade modifier, must ensure that the feed is correct
    function _addAssetConfig(
        string memory _symbol,
        address _token,
        address _feed
    ) internal {
        symbolToAsset[_symbol] = _token;
        assetToPriceFeed[_token] = _feed;
        emit AssetConfigAdded(_symbol, _token, _feed);
    }

    // @notice remove the mapping of token symbol => token address => price feed
    function _removeAssetConfig(string memory _symbol) internal {
        address prevAddress = symbolToAsset[_symbol];
        symbolToAsset[_symbol] = address(0);
        assetToPriceFeed[prevAddress] = address(0);
        emit AssetConfigRemoved(_symbol);
    }

    // @notice switch to a different signal contract and name
    // @dev will ensure that the signal supports the correct asset symbols, assume signal provider is trusted
    function _swapSignal(address _signal, string memory _name) internal {
        _verifySignal(_signal, _name);
        globalState.signal = _signal;
        _setSignal(_signal, _name);
        emit NewSignal(_signal);
    }

    /////////////////////////
    // whitelist functions
    /////////////////////////

    function _whitelistWallet(address _wallet) internal {
        walletWhitelist[_wallet] = true;
        emit WalletWhitelisted(_wallet);
    }

    function _deWhitelistWallet(address _wallet) internal {
        walletWhitelist[_wallet] = false;
        emit WalletDeWhitelisted(_wallet);
    }

    function _whitelistVenue(address _venue) internal {
        venueWhitelist[_venue] = true;
        emit VenueWhitelisted(_venue);
    }

    function _deWhitelistVenue(address _venue) internal {
        venueWhitelist[_venue] = false;
        emit VenueDeWhitelisted(_venue);
    }

    function _whitelistAsset(address _asset) internal {
        assetWhitelist[_asset] = true;
        emit AssetWhitelisted(_asset);
    }

    function _deWhitelistAsset(address _asset) internal {
        assetWhitelist[_asset] = false;
        emit AssetDeWhitelisted(_asset);
    }

    /////////////////////////
    // settlement functions
    /////////////////////////

    // @notice settle trade transactions on trading venues
    function _settleTrade(bytes[] calldata _trades, address[] memory _venues)
        internal
        returns (bool)
    {
        return _submitTradeOrders(_trades, _venues);
    }

    // @notice settle lending/ redemption transctions on trading venues
    function _settlePool(
        bytes[] calldata _orders,
        Pool[] calldata _txTypes,
        address[] memory _venues
    ) internal returns (bool) {
        return _submitPoolOrders(_orders, _txTypes, _venues);
    }

    // @notice verify that the assets in the provided signal contract is supported
    // @dev supported signal should have correct asset symbols and signal name
    function _verifySignal(address _signal, string memory _signalName)
        internal
        view
    {
        string[] memory symbols = ISignal(_signal).getSignalSymbols(
            _signalName
        );
        for (uint256 i; i < symbols.length; i++) {
            string memory symbol = symbols[i];
            if (XPNUtils.compareStrings(symbol, _getDenomAssetSymbol())) {
                continue;
            }
            require(
                symbolToAsset[symbol] != address(0),
                "XPNCore: token symbol is not registered"
            );
            require(
                assetWhitelist[symbolToAsset[symbol]],
                "XPNCore: token is not whitelisted"
            );
        }
    }

    // @dev enzyme-specific functionality to track zero balance asset
    function _addTrackedAsset(address _asset) internal {
        XPNUtils.addEnzymeTrackedAsset(
            globalState.EZcomptroller,
            globalState.EZintegrationManager,
            _asset
        );
    }

    // @dev enzyme-specific functionality to remove tracked asset
    function _removeTrackedAsset(address _asset) internal {
        XPNUtils.removeEnzymeTrackedAsset(
            globalState.EZcomptroller,
            globalState.EZintegrationManager,
            _asset
        );
    }

    /////////////////////////
    // overidden hook functions
    /////////////////////////

    // @notice hooks are implemented in this contract to pass state
    // or override interaction with third party contracts

    // @notice fetch token price for an asset
    // @dev we utilize Chainlink price feed interface to get current price data,
    // in the case that the asset is not supported on Chainlink,
    // we need to ensure that we interact with a custom adapter
    function _getTokenPrice(address _asset)
        internal
        view
        override
        returns (int256)
    {
        return XPNUtils.parseChainlinkPrice(assetToPriceFeed[_asset]);
    }

    function _getVaultAddress() internal view override returns (address) {
        return globalState.EZshares;
    }

    function _getSymbolToToken(string memory _symbol)
        internal
        view
        override
        returns (address)
    {
        return symbolToAsset[_symbol];
    }

    function _getDenomAssetAddress() internal view override returns (address) {
        return globalState.denomAssetAddress;
    }

    function _getDenomAssetSymbol()
        internal
        view
        override
        returns (string memory)
    {
        return globalState.denomAssetSymbol;
    }

    // @dev implements actual enzyme share purchase on the comptroller
    function _depositHook(uint256 _amount)
        internal
        override
        whenNotPaused
        returns (uint256)
    {
        IERC20(globalState.denomAssetAddress).safeApprove(
            address(globalState.EZcomptroller),
            _amount
        );

        return XPNUtils.buyEnzymeShares(globalState.EZcomptroller, _amount);
    }

    // @dev implements actual enzyme share redemption on the comptroller
    function _withdrawHook(uint256 _amount)
        internal
        override
        returns (address[] memory, uint256[] memory)
    {
        return XPNUtils.redeemEnzymeShares(globalState.EZcomptroller, _amount);
    }

    function _venueIsWhitelisted(address _venue)
        internal
        view
        override
        returns (bool)
    {
        return venueWhitelist[_venue];
    }

    // @dev implements the actual trade order on Enzyme comptroller
    function _submitTrade(bytes calldata _trade, address _venue)
        internal
        override
        returns (bool successfulTrade)
    {
        bytes memory callargs = abi.encode(_venue, TAKE_ORDER_SELECTOR, _trade);
        IComptroller(globalState.EZcomptroller).callOnExtension(
            globalState.EZintegrationManager,
            DEFI_INTEGRATION, // action id = 0
            callargs
        );
        return true;
    }

    // @dev implements the actual lending order on Enzyme comptroller
    function _submitLending(bytes calldata _lending, address _venue)
        internal
        override
        returns (bool)
    {
        bytes memory callargs = abi.encode(
            _venue,
            LEND_ORDER_SELECTOR,
            _lending
        );
        IComptroller(globalState.EZcomptroller).callOnExtension(
            globalState.EZintegrationManager,
            DEFI_INTEGRATION, // action id = 0
            callargs
        );
        return true;
    }

    // @dev implements the actual redemption order on Enzyme comptroller
    function _submitRedemption(bytes calldata _redemption, address _venue)
        internal
        override
        returns (bool)
    {
        bytes memory callargs = abi.encode(
            _venue,
            REDEEM_ORDER_SELECTOR,
            _redemption
        );
        IComptroller(globalState.EZcomptroller).callOnExtension(
            globalState.EZintegrationManager,
            DEFI_INTEGRATION, // action id = 0
            callargs
        );
        return true;
    }

    // @dev performs 2 actions: settle current fee on Enzyme vault and mint
    //      new shares to vault owner representing accrued fees
    function _redeemFeesHook(address _feeManager, address[] memory _fees)
        internal
        override
    {
        XPNUtils.invokeAndPayoutEnzymeFees(
            globalState.EZcomptroller,
            _feeManager,
            _fees
        );
    }

    /////////////////////////
    //  vault migration functions
    /////////////////////////

    // @notice deploys new comptroller on enzyme fund deployer
    function _createMigration(State memory _newState) internal {
        postMigrationState = _newState;

        address newComptrollerProxy = IFundDeployer(
            postMigrationState.EZdeployer
        ).createMigratedFundConfig(
                globalState.denomAssetAddress, // denominated asset
                SHARES_TIMELOCK, // sets shares action timelock
                _newState.EZfeeConfig, // utilize new fee config
                ""
            );

        (postMigrationState.EZcomptroller, postMigrationState.EZshares) = (
            newComptrollerProxy,
            globalState.EZshares
        );
        emit MigrationCreated(_newState);
    }

    // @notice initiate the migration process, will start the timelock
    function _signalMigration() internal {
        _pause();
        IFundDeployer(postMigrationState.EZdeployer).signalMigration(
            globalState.EZshares,
            postMigrationState.EZcomptroller
        );
        emit MigrationSignaled();
    }

    // @notice execute the migration process, migrate global state to new state
    function _executeMigration() internal {
        IFundDeployer(postMigrationState.EZdeployer).executeMigration(
            globalState.EZshares
        );
        globalState = postMigrationState;
        XPNUtils.enforceSoleEnzymeDepositor(
            postMigrationState.EZcomptroller,
            postMigrationState.EZpolicy,
            postMigrationState.EZwhitelistPolicy
        );
        _unpause();
        emit MigrationExecuted();
    }

    /////////////////////////
    // state getter functions
    /////////////////////////

    function _getSharesAddress() internal view override returns (address) {
        return globalState.EZshares;
    }

    // @notice set target signal
    // @param signalPoolAddress address of signal contract
    // @param signalName name of the target signal in the signal contract
    // @dev this function assume that caller already verify the compatability off chain.
    function _setSignal(address _signalPoolAddress, string memory _signalName)
        internal
    {
        (globalState.signal, globalState.signalName) = (
            _signalPoolAddress,
            _signalName
        );
    }

    function _getSignal() internal view override returns (int256[] memory) {
        return ISignal(globalState.signal).getSignal(globalState.signalName);
    }

    function _getSignalSymbols()
        internal
        view
        override
        returns (string[] memory)
    {
        return
            ISignal(globalState.signal).getSignalSymbols(
                globalState.signalName
            );
    }

    function _getExpectedEfficiency() internal view override returns (int256) {
        return expectedEfficiency;
    }

    // @notice set expected trade efficiency
    // @dev note 1e18 = 100% default is 98e16 (98%)
    function _setExpectedEfficiency(int256 _expectedEfficiency) internal {
        expectedEfficiency = _expectedEfficiency;
    }
}
