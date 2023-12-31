// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract StrategyDummyImplementation {
    // basic & ReadModule
    function MAX_SAFE_AGGREGATED_RATIO() public pure returns (uint256) {}

    function MIN_SAFE_AGGREGATED_RATIO() public pure returns (uint256) {}

    function PERMISSIBLE_LIMIT() public pure returns (uint256) {}

    function STETH_ADDR() external view returns (address) {}

    function UPDATE_FEE_BASE() public pure returns (uint256) {}

    function WETH_ADDR() external view returns (address) {}

    function WSTETH_ADDR() external view returns (address) {}

    function availableProtocol(uint8 _protocolId) external view returns (bool) {}

    function exchangePrice() external view returns (uint256) {}

    function executor() external view returns (address) {}

    function feeReceiver() external view returns (address) {}

    function flashloanHelper() external view returns (address) {}

    function getAvailableBorrowsETH(uint8 _protocolId) public view returns (uint256) {}

    function getAvailableWithdrawsStETH(uint8 _protocolId) public view returns (uint256) {}

    function getCurrentExchangePrice() public view returns (uint256 newExchangePrice_, uint256 newRevenue_) {}

    function getNetAssets() public view returns (uint256) {}

    function getNetAssetsInfo() public view returns (uint256, uint256, uint256, uint256) {}

    function getProtocolAccountData(uint8 _protocolId)
        external
        view
        returns (uint256 stEthAmount_, uint256 debtEthAmount_)
    {}

    function getProtocolCollateralRatio(uint8 _protocolId) public view returns (uint256 protocolRatio_, bool isOK_) {}

    function getProtocolLeverageAmount(uint8 _protocolId, bool _isDepositOrWithdraw, uint256 _depositOrWithdraw)
        public
        view
        returns (bool isLeverage_, uint256 amount_)
    {}

    function getProtocolNetAssets(uint8 _protocolId) public view returns (uint256) {}

    function getProtocolRatio(uint8 _protocolId) public view returns (uint256) {}

    function getVersion() public pure returns (string memory) {}

    function lendingLogic() external view returns (address) {}

    function owner() external view returns (address) {}

    function rebalancer(address _rebalancer) external view returns (bool) {}

    function revenue() external view returns (uint256) {}

    function revenueExchangePrice() external view returns (uint256) {}

    function revenueRate() external view returns (uint256) {}

    function safeAggregatedRatio() external view returns (uint256) {}

    function safeProtocolRatio(uint8 _protocolId) external view returns (uint256) {}

    function updateExchangePrice() external returns (uint256 newExchangePrice_, uint256 newRevenue_) {}

    function vault() external view returns (address) {}

    // AdminModule
    function collectRevenue() external {}

    function enterProtocol(uint8 _protocolId) external {}

    function exitProtocol(uint8 _protocolId) external {}

    function initialize(
        uint256 _revenueRate,
        uint256 _safeAggregatedRatio,
        uint256[] memory _safeProtocolRatio,
        address[] memory _rebalancers,
        address _flashloanHelper,
        address _lendingLogic,
        address _feeReceiver
    ) external {}

    function setVault(address _vault) external {}

    function updateFeeReceiver(address _newFeeReceiver) public {}

    function updateFlashloanHelper(address _newLendingLogic) external {}

    function updateLendingLogic(address _newLendingLogic) external {}

    function updateRebalancer(address[] calldata _rebalancers, bool[] calldata _isAllowed) external {}

    function updateRevenueRate(uint256 _newRevenueRate) external {}

    function updateSafeAggregatedRatio(uint256 _newSafeAggregatedRatio) external {}

    function updateSafeProtocolRatio(uint8[] calldata _protocolId, uint256[] calldata _safeProtocolRatio) external {}

    // LeverageModule
    function REBALANCE_FEE_BASE() public pure returns (uint256) {}

    function deleverage(
        uint8 _protocolId,
        uint256 _withdraw,
        uint256 _debtAmount,
        bytes calldata _swapData,
        uint256 _swapGetMin,
        uint256 _flashloanSelector
    ) external {}

    function deleverageAndWithdraw(
        uint8 _protocolId,
        uint256 _withdrawShare,
        bytes calldata _swapData,
        uint256 _swapGetMin,
        bool _isETH,
        uint256 _flashloanSelector
    ) external returns (uint256) {}

    function getDeleverageAmount(uint256 _share, uint8 _protocolId) public view returns (uint256) {}

    function leverage(
        uint8 _protocolId,
        uint256 _deposit,
        uint256 _debtAmount,
        bytes calldata _swapData,
        uint256 _swapGetMin,
        uint256 _flashloanSelector
    ) external {}

    function onFlashLoanOne(address _initiator, address _token, uint256 _amount, uint256 _fee, bytes calldata _params)
        external
        returns (bytes32)
    {}

    // MigrateModule
    function MIGRATE_FEE_BASE() public pure returns (uint256) {}

    function migrate(
        uint8 _fromProtocolId,
        uint8 _toProtocolId,
        uint256 _stAmount,
        uint256 _debtAmount,
        uint256 _flashloanSelector
    ) external {}

    function onFlashLoanTwo(address _initiator, address _token, uint256 _amount, uint256 _fee, bytes calldata _params)
        external
        returns (bytes32)
    {}

    // UserModule
    function deposit(uint256 _stAmount) external returns (uint256 operateExchangePrice_) {}

    function withdraw(uint256 _stAmount) external returns (uint256 userStGet_) {}
}
