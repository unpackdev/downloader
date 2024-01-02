// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./ITroveManager.sol";
import "./ICollateralManager.sol";
import "./IUSDEToken.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";

// Common interface for the Trove Manager.
interface IBorrowerOperations {
    // --- Variable container structs  ---
    struct ContractsCache {
        ITroveManager troveManager;
        ICollateralManager collateralManager;
        IActivePool activePool;
        IUSDEToken usdeToken;
    }

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        adjustTrove
    }
    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event CollateralManagerAddressChanged(address _newCollateralManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event USDETokenAddressChanged(address _usdeTokenAddress);
    event WETHAddressChanged(address _wethAddress);
    event TreasuryAddressChanged(address _treasuryAddress);
    event TroveDebtAddressChanged(address _troveDebtAddress);

    event TroveCreated(address indexed _borrower, uint256 arrayIndex);
    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        address[] _colls,
        uint256[] _shares,
        uint256[] _amounts,
        BorrowerOperation operation
    );
    event USDEBorrowingFeePaid(address indexed _borrower, uint256 _USDEFee);

    event Paused();
    event Unpaused();

    event MarketCapChanged(uint256 _newMarketCap);

    event Referrer(
        address indexed _referrer,
        address _referee,
        address[] _colls,
        uint256[] _amounts,
        uint256 _compositeDebt
    );

    // --- Functions ---

    function setAddresses(
        address _troveManagerAddress,
        address _collateralManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _usdeTokenAddress
    ) external;

    function openTrove(
        address[] memory _collaterals,
        uint256[] memory _amounts,
        uint256 _maxFeePercentage,
        uint256 _USDEAmount,
        address _upperHint,
        address _lowerHint,
        address _referrer
    ) external payable;

    function addColl(
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function withdrawColl(
        address[] memory _collsOut,
        uint256[] memory _amountsOut,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawUSDE(
        uint256 _USDEAmount,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external;

    function repayUSDE(
        uint256 _USDEAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function moveCollGainToTrove(
        address _borrower,
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        address _upperHint,
        address _lowerHint
    ) external;

    function adjustTrove(
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        address[] memory _collsOut,
        uint256[] memory _amountsOut,
        uint256 _maxFeePercentage,
        uint256 _USDEChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external payable;

    function closeTrove() external;

    function setPause(bool _val) external;

    function setMarketCap(uint256 _marketCap) external;

    function updateUSDEGas(bool _val, uint256 _amount) external;

    function claimCollateral() external;

    function getCompositeDebt(uint256 _debt) external view returns (uint256);
}
