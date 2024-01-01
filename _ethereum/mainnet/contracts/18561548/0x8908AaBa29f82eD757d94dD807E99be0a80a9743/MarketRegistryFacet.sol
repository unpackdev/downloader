// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./LibAppStorage.sol";
import "./LibMeta.sol";
import "./LibMarketRegistryStorage.sol";
import "./LibMarketStorage.sol";

/// @title helper contract providing the data to the loan market contracts.
contract MarketRegistryFacet is Modifiers {
    event LoanActivateLimitUpdated(uint256 loansActivateLimit);
    event LTVPercentageUpdated(uint256 ltvPercentage);
    event MinLoanAmountUpdated(uint256 minLoanAmount);
    event WhitelistLenderUpdated(address indexed lender, bool value);
    event AllowedMultiCollateral(uint256 collateralLimit);
    event OneInchAggregator(address indexed aggregator);
    event MultiCollateralLimit(uint256 multicollateralLimit);
    event NetworkTokenAddress(address networkTokenAddress);

    /// @dev function to set minimum loan amount allowed to create loan
    /// @param _minLoanAmount should be set in normal value, not in decimals, as decimals are handled in Token and NFT Market Loans
    function setMinLoanAmount(
        uint256 _minLoanAmount
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        require(_minLoanAmount > 0, "minLoanAmount Invalid");
        ms.minLoanAmountAllowed = _minLoanAmount;
        emit MinLoanAmountUpdated(_minLoanAmount);
    }

    /// @dev set the loan activate limit for the token market contract
    /// @param _loansLimit limit allowed for loan activation
    function setloanActivateLimit(
        uint256 _loansLimit
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();
        require(_loansLimit > 0, "GTM: loanlimit error");
        ms.allowedLoanActivateLimit = _loansLimit;
        emit LoanActivateLimitUpdated(_loansLimit);
    }

    /// @dev returns the loan activate limit
    /// @return uint256 returns the loan activation limit for the lender
    function getLoanActivateLimit() external view returns (uint256) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        return ms.allowedLoanActivateLimit;
    }

    /// @dev set the LTV percentage limit
    /// @param _ltvPercentage percentage allowed for the liquidation
    function setLTVPercentage(
        uint256 _ltvPercentage
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        require(_ltvPercentage > 0, "GTM: percentage amount error");
        ms.ltvPercentage = _ltvPercentage;
        emit LTVPercentageUpdated(_ltvPercentage);
    }

    /// @dev get the ltv percentage set by the super admin
    /// @return uint256 returns the ltv percentage amount
    function getLTVPercentage() external view returns (uint256) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        return ms.ltvPercentage;
    }

    /// @dev set or update whitelist address for lending unlimited loans
    /// @param _lender addross of lender for unlimited loan activation
    function updateWhitelistAddress(
        address _lender
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        require(_lender != address(0x0), "GTM: null address error");
        ms.whitelistAddress[_lender] = !ms.whitelistAddress[_lender];
        emit WhitelistLenderUpdated(_lender, ms.whitelistAddress[_lender]);
    }

    function setAllowedMultiCollateralLimit(
        uint256 _collateralLimit
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        require(
            _collateralLimit > 0 && _collateralLimit <= 10,
            "GTM: error set collateral limit"
        );
        ms.multiCollateralLimit = _collateralLimit;

        emit MultiCollateralLimit(_collateralLimit);
    }

    /// @dev set address of 1inch aggregator
    function set1InchAggregator(
        address _1inchAggregatorV5
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        require(
            ms.aggregationRouterV5 == address(0),
            "already set one1inch aggregator address"
        );
        require(_1inchAggregatorV5 != address(0), "aggregator address zero");
        ms.aggregationRouterV5 = _1inchAggregatorV5;
        emit OneInchAggregator(_1inchAggregatorV5);
    }

    function setNetworkTokenAddress(
        address _networkTokenAddress
    ) external onlySuperAdmin(LibMeta._msgSender()) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        require(
            ms.networkTokenAddress == address(0),
            "already set network token address"
        );
        require(
            _networkTokenAddress != address(0),
            "network token address zero"
        );
        ms.networkTokenAddress = _networkTokenAddress;
        emit NetworkTokenAddress(_networkTokenAddress);
    }

    function getMultiCollateralLimit() external view returns (uint256) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();
        return ms.multiCollateralLimit;
    }

    /// @dev returns boolean flag is address is whitelisted for unlimited lending
    /// @param _lender address of the lender for checking if its whitelisted for activate unlimited loans
    /// @return bool value returns for whitelisted addresses
    function isWhitelistedForActivation(
        address _lender
    ) external view returns (bool) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        return ms.whitelistAddress[_lender];
    }

    function getMinLoanAmountAllowed() external view returns (uint256) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();
        return ms.minLoanAmountAllowed;
    }
}
