// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeMathUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./TroveManagerDataTypes.sol";
import "./DataTypes.sol";
import "./Errors.sol";
import "./ITroveManager.sol";
import "./IBorrowerOperations.sol";
import "./ICollateralManager.sol";
import "./IPriceFeed.sol";
import "./IOracle.sol";
import "./IEToken.sol";

contract CollateralManager is
    OwnableUpgradeable,
    TroveManagerDataTypes,
    ICollateralManager
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // During bootsrap period redemptions are not allowed
    uint256 public BOOTSTRAP_PERIOD;

    // Minimum collateral ratio for individual troves
    uint256 public MCR;

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint256 public CCR;

    // Amount of USDE to be locked in gas pool on opening troves
    uint256 public USDE_GAS_COMPENSATION;

    // Minimum amount of net USDE debt a trove must have
    uint256 public MIN_NET_DEBT;

    uint256 public BORROWING_FEE_FLOOR;

    uint256 public REDEMPTION_FEE_FLOOR;
    uint256 public RECOVERY_FEE;
    uint256 public MAX_BORROWING_FEE;

    address public borrowerOperationsAddress;
    address public troveManagerRedemptionsAddress;
    address public wethAddress;

    ITroveManager internal troveManager;

    mapping(address => DataTypes.CollateralParams) public collateralParams;

    // The array of collaterals that support,
    // index 0 represents the highest priority,
    // the lowest priority collateral in the same trove will be prioritized for liquidation or redemption
    address[] public collateralSupport;

    uint256 public collateralsCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        BOOTSTRAP_PERIOD = 14 days;
        MCR = 11e17; // 110%
        CCR = 14e17; // 140%
        USDE_GAS_COMPENSATION = 200e18;
        MIN_NET_DEBT = 1800e18;
        BORROWING_FEE_FLOOR = (DECIMAL_PRECISION / 10000) * 25; // 0.25%

        REDEMPTION_FEE_FLOOR = (DECIMAL_PRECISION / 1000) * 5; // 0.5%
        RECOVERY_FEE = DECIMAL_PRECISION / 1000; // 0.1%
        MAX_BORROWING_FEE = (DECIMAL_PRECISION / 1000) * 25; // 2.5%
    }

    function setAddresses(
        address _activePoolAddress,
        address _borrowerOperationsAddress,
        address _defaultPoolAddress,
        address _priceFeedAddress,
        address _troveManagerAddress,
        address _troveManagerRedemptionsAddress,
        address _wethAddress
    ) external override onlyOwner {
        _requireIsContract(_activePoolAddress);
        _requireIsContract(_borrowerOperationsAddress);
        _requireIsContract(_defaultPoolAddress);
        _requireIsContract(_priceFeedAddress);
        _requireIsContract(_wethAddress);
        _requireIsContract(_troveManagerAddress);
        _requireIsContract(_troveManagerRedemptionsAddress);

        borrowerOperationsAddress = _borrowerOperationsAddress;
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        priceFeed = IPriceFeed(_priceFeedAddress);
        wethAddress = _wethAddress;

        troveManager = ITroveManager(_troveManagerAddress);

        troveManagerRedemptionsAddress = _troveManagerRedemptionsAddress;

        emit ActivePoolAddressChanged(_activePoolAddress);
        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        emit PriceFeedAddressChanged(_priceFeedAddress);
        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit TroveManagerRedemptionsAddressChanged(
            _troveManagerRedemptionsAddress
        );
        emit WETHAddressChanged(_wethAddress);
    }

    function addCollateral(
        address _collateral,
        address _oracle,
        address _eTokenAddress,
        uint256 _ratio
    ) external override onlyOwner {
        _requireIsContract(_collateral);
        _requireIsContract(_oracle);
        _requireIsContract(_eTokenAddress);
        if (getIsSupport(_collateral)) {
            revert Errors.CM_CollExists();
        }
        if (_ratio > DECIMAL_PRECISION) {
            revert Errors.CM_BadValue();
        }

        collateralParams[_collateral] = DataTypes.CollateralParams(
            _ratio,
            _eTokenAddress,
            _oracle,
            DataTypes.CollStatus(1),
            collateralsCount
        );
        collateralSupport.push(_collateral);
        collateralsCount = collateralsCount.add(1);
        if (collateralsCount > 15) {
            revert Errors.CM_BadValue();
        }
    }

    function removeCollateral(address _collateral) external override onlyOwner {
        address collAddress = _collateral;
        if (!getIsSupport(collAddress) || getIsActive(collAddress)) {
            revert Errors.CM_CollNotPaused();
        }
        if (collateralsCount == 1) {
            revert Errors.CM_NoMoreColl();
        }
        address collateral;
        uint256 i = getIndex(collAddress);
        for (; i < collateralsCount - 1; ) {
            collateral = collateralSupport[i];
            collateralSupport[i] = collateralSupport[i + 1];
            collateralSupport[i + 1] = collateral;
            collateralParams[collateralSupport[i]].index = i;
            unchecked {
                ++i;
            }
        }
        collateralSupport.pop();
        collateralsCount = collateralsCount.sub(1);
        delete collateralParams[collAddress];
    }

    function setCollateralPriority(
        address _collateral,
        uint256 _newIndex
    ) external override onlyOwner {
        _requireCollIsActive(_collateral);
        uint256 oldIndex = getIndex(_collateral);
        uint256 newIndex = _newIndex;
        if (newIndex == oldIndex || newIndex >= collateralsCount) {
            revert Errors.CM_BadValue();
        }
        if (newIndex < oldIndex) {
            uint256 tmpIndex = oldIndex;
            uint256 gap = oldIndex - newIndex;
            uint256 i = 0;
            for (; i < gap; ) {
                tmpIndex = _up(tmpIndex);
                unchecked {
                    ++i;
                }
            }
        } else {
            uint256 tmpIndex = oldIndex;
            uint256 gap = newIndex - oldIndex;
            uint256 i = 0;
            for (; i < gap; ) {
                tmpIndex = _down(tmpIndex);
                unchecked {
                    ++i;
                }
            }
        }
    }

    function _up(uint256 _index) internal returns (uint256) {
        uint256 index = _index;
        _swap(index, index - 1);
        return index - 1;
    }

    function _down(uint256 _index) internal returns (uint256) {
        uint256 index = _index;
        _swap(index, index + 1);
        return index + 1;
    }

    function _swap(uint256 _x, uint256 _y) internal {
        address collateral_1 = collateralSupport[_x];
        address collateral_2 = collateralSupport[_y];
        collateralSupport[_x] = collateral_2;
        collateralSupport[_y] = collateral_1;
        collateralParams[collateral_1].index = _y;
        collateralParams[collateral_2].index = _x;
    }

    function pauseCollateral(address _collateral) external override onlyOwner {
        _setStatus(_collateral, 2);
    }

    function activeCollateral(address _collateral) external override onlyOwner {
        _setStatus(_collateral, 1);
    }

    function _setStatus(address _collateral, uint256 _num) internal {
        if (!getIsSupport(_collateral)) {
            revert Errors.CM_CollNotSupported();
        }
        collateralParams[_collateral].status = DataTypes.CollStatus(_num);
    }

    function setOracle(
        address _collateral,
        address _oracle
    ) public override onlyOwner {
        _requireIsContract(_oracle);
        _requireCollIsActive(_collateral);
        collateralParams[_collateral].oracle = _oracle;
    }

    function setEToken(
        address _collateral,
        address _eTokenAddress
    ) public override onlyOwner {
        _requireIsContract(_eTokenAddress);
        _requireCollIsActive(_collateral);
        collateralParams[_collateral].eToken = _eTokenAddress;
    }

    function setRatio(
        address _collateral,
        uint256 _ratio
    ) public override onlyOwner {
        _requireCollIsActive(_collateral);
        if (_ratio > DECIMAL_PRECISION) {
            revert Errors.CM_BadValue();
        }
        collateralParams[_collateral].ratio = _ratio;
    }

    function priceUpdate() public override {
        if (collateralsCount < 2) {
            return;
        }
        uint256 i = 1;
        for (; i < collateralsCount; ) {
            IOracle(collateralParams[collateralSupport[i]].oracle).fetchPrice();
            unchecked {
                ++i;
            }
        }
    }

    function getValue(
        address[] memory _collaterals,
        uint256[] memory _amounts,
        uint256 _price
    )
        public
        view
        override
        returns (uint256 totalValue, uint256[] memory values)
    {
        uint256 collLen = _collaterals.length;
        if (collLen != _amounts.length) {
            revert Errors.LengthMismatch();
        }
        values = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            if (_amounts[i] != 0) {
                values[i] = _calcValue(_collaterals[i], _amounts[i], _price);
                totalValue = totalValue.add(values[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _calcValue(
        address _collateral,
        uint256 _amount,
        uint256 _price
    ) internal view returns (uint256 value) {
        if (_collateral != wethAddress) {
            IOracle coll_adjust = IOracle(collateralParams[_collateral].oracle);
            uint256 valueRatio = collateralParams[_collateral].ratio;
            value = coll_adjust
                .fetchPrice_view()
                .mul(valueRatio)
                .div(DECIMAL_PRECISION)
                .mul(_amount)
                .div(DECIMAL_PRECISION)
                .mul(_price)
                .div(DECIMAL_PRECISION);
        } else {
            value = _amount.mul(_price).div(DECIMAL_PRECISION);
        }
    }

    function getTotalValue(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) public view override returns (uint256 totalValue) {
        (totalValue, ) = getValue(
            _collaterals,
            _amounts,
            priceFeed.fetchPrice_view()
        );
    }

    function mintEToken(
        address[] memory _collaterals,
        uint256[] memory _amounts,
        address _account,
        uint256 _price
    ) external override returns (uint256[] memory, uint256) {
        _requireCollIsBO();
        uint256 collLen = _collaterals.length;
        uint256[] memory shares = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            if (_amounts[i] != 0) {
                shares[i] = mint(_account, _collaterals[i], _amounts[i]);
            }

            unchecked {
                ++i;
            }
        }
        if (_price != 0) {
            (uint256 value, ) = getValue(_collaterals, _amounts, _price);
            return (shares, value);
        } else {
            return (shares, 0);
        }
    }

    function applyRewards(
        address _borrower,
        uint256[] memory _pendingRewards
    ) external override returns (uint256[] memory) {
        _requireCollIsTM();
        uint256[] memory newShares = new uint256[](collateralsCount);
        uint256 i = 0;
        for (; i < collateralsCount; ) {
            if (_pendingRewards[i] != 0) {
                mint(_borrower, collateralSupport[i], _pendingRewards[i]);
            }
            newShares[i] = IEToken(
                collateralParams[collateralSupport[i]].eToken
            ).sharesOf(_borrower);
            unchecked {
                ++i;
            }
        }
        return newShares;
    }

    function burnEToken(
        address[] memory _collaterals,
        uint256[] memory _amounts,
        address _account,
        uint256 _price
    ) external override returns (uint256[] memory, uint256) {
        _requireCollIsBO();
        uint256 collLen = _collaterals.length;
        uint256[] memory shares = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            if (_amounts[i] != 0) {
                shares[i] = burn(_account, _collaterals[i], _amounts[i]);
            }
            unchecked {
                ++i;
            }
        }
        if (_price != 0) {
            (uint256 value, ) = getValue(_collaterals, _amounts, _price);
            return (shares, value);
        } else {
            return (shares, 0);
        }
    }

    function mint(
        address _account,
        address _collateral,
        uint256 _amount
    ) internal returns (uint256) {
        return
            IEToken(collateralParams[_collateral].eToken).mint(
                _account,
                _amount
            );
    }

    function burn(
        address _account,
        address _collateral,
        uint256 _amount
    ) internal returns (uint256) {
        return
            IEToken(collateralParams[_collateral].eToken).burn(
                _account,
                _amount
            );
    }

    function clearEToken(
        address _account,
        DataTypes.Status closedStatus
    ) external override returns (address[] memory) {
        _requireCollIsBOOrTM();
        if (closedStatus == DataTypes.Status.closedByOwner) {
            return collateralSupport;
        }
        uint256 i = 0;
        for (; i < collateralsCount; ) {
            IEToken(collateralParams[collateralSupport[i]].eToken).clear(
                _account
            );
            unchecked {
                ++i;
            }
        }
        return collateralSupport;
    }

    function resetEToken(
        address _account,
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) external override returns (uint256[] memory) {
        if (msg.sender != troveManagerRedemptionsAddress) {
            revert Errors.Caller_NotTMR();
        }
        uint256 collLen = _collaterals.length;
        uint256[] memory shares = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            if (_amounts[i] != 0) {
                shares[i] = IEToken(collateralParams[_collaterals[i]].eToken)
                    .reset(_account, _amounts[i]);
            }
            unchecked {
                ++i;
            }
        }
        return shares;
    }

    function getShares(
        address[] memory _collaterals,
        uint256[] memory _amounts
    ) public view override returns (uint256[] memory) {
        uint256 collLen = _collaterals.length;
        uint256[] memory amounts = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            if (_amounts[i] != 0) {
                amounts[i] = IEToken(collateralParams[_collaterals[i]].eToken)
                    .getShare(_amounts[i]);
            }
            unchecked {
                ++i;
            }
        }
        return amounts;
    }

    function getAmounts(
        address[] memory _collaterals,
        uint256[] memory _shares
    ) public view override returns (uint256[] memory) {
        uint256 collLen = _collaterals.length;
        uint256[] memory amounts = new uint256[](collLen);
        uint256 i = 0;
        for (; i < collLen; ) {
            if (_shares[i] != 0) {
                amounts[i] = IEToken(collateralParams[_collaterals[i]].eToken)
                    .getAmount(_shares[i]);
            }
            unchecked {
                ++i;
            }
        }
        return amounts;
    }

    function getShare(
        address _collateral,
        uint256 _amount
    ) external view override returns (uint256) {
        return IEToken(collateralParams[_collateral].eToken).getShare(_amount);
    }

    function getAmount(
        address _collateral,
        uint256 _share
    ) external view override returns (uint256) {
        return IEToken(collateralParams[_collateral].eToken).getAmount(_share);
    }

    function getTroveColls(
        address _borrower
    )
        public
        view
        override
        returns (uint256[] memory, uint256[] memory, address[] memory)
    {
        uint256[] memory amounts = new uint256[](collateralsCount);
        uint256[] memory shares = new uint256[](collateralsCount);
        uint256 i = 0;
        for (; i < collateralsCount; ) {
            (amounts[i], shares[i]) = getTroveColl(
                _borrower,
                collateralSupport[i]
            );
            unchecked {
                ++i;
            }
        }
        return (amounts, shares, collateralSupport);
    }

    function getTroveColl(
        address _borrower,
        address _collateral
    ) public view override returns (uint256, uint256) {
        uint256 amount = IEToken(collateralParams[_collateral].eToken)
            .balanceOf(_borrower);
        uint256 share = IEToken(collateralParams[_collateral].eToken).sharesOf(
            _borrower
        );

        return (amount, share);
    }

    function getCollateralShares(
        address _borrower
    ) external view override returns (address[] memory, uint256[] memory) {
        uint256[] memory shares = new uint256[](collateralsCount);
        uint256 i = 0;
        for (; i < collateralsCount; ) {
            shares[i] = IEToken(collateralParams[collateralSupport[i]].eToken)
                .sharesOf(_borrower);
            unchecked {
                ++i;
            }
        }
        return (collateralSupport, shares);
    }

    function getEntireCollValue()
        external
        view
        override
        returns (address[] memory, uint256[] memory, uint256)
    {
        uint256 price = priceFeed.fetchPrice_view();
        return getEntireCollValue(price);
    }

    function getEntireCollValue(
        uint256 _price
    )
        public
        view
        override
        returns (address[] memory, uint256[] memory, uint256)
    {
        uint256 totalValue;
        uint256[] memory amounts = new uint256[](collateralsCount);
        uint256 activeBalance;
        uint256 defautBalance;
        uint256 i = 0;
        for (; i < collateralsCount; ) {
            activeBalance = IEToken(
                collateralParams[collateralSupport[i]].eToken
            ).totalSupply();
            defautBalance = IERC20Upgradeable(collateralSupport[i]).balanceOf(
                address(defaultPool)
            );
            amounts[i] = activeBalance.add(defautBalance);
            totalValue = totalValue.add(
                _calcValue(collateralSupport[i], amounts[i], _price)
            );
            unchecked {
                ++i;
            }
        }
        return (collateralSupport, amounts, totalValue);
    }

    // --- Getters ---
    function getCollateralSupport()
        external
        view
        override
        returns (address[] memory)
    {
        return collateralSupport;
    }

    function getIsActive(
        address _collateral
    ) public view override returns (bool) {
        return
            collateralParams[_collateral].status == DataTypes.CollStatus.active;
    }

    function getIsSupport(
        address _collateral
    ) public view override returns (bool) {
        return
            collateralParams[_collateral].status !=
            DataTypes.CollStatus.nonSupport;
    }

    function getCollateralOracle(
        address _collateral
    ) external view override returns (address) {
        return collateralParams[_collateral].oracle;
    }

    function getCollateralOracles()
        external
        view
        override
        returns (address[] memory)
    {
        address[] memory oracles = new address[](collateralsCount);
        uint256 i = 0;
        for (; i < collateralsCount; ) {
            oracles[i] = collateralParams[collateralSupport[i]].oracle;
            unchecked {
                ++i;
            }
        }
        return oracles;
    }

    function getCollateralParams(
        address _collateral
    ) external view override returns (DataTypes.CollateralParams memory) {
        return collateralParams[_collateral];
    }

    function getCollateralsAmount() external view override returns (uint256) {
        return collateralsCount;
    }

    function getIndex(
        address _collateral
    ) public view override returns (uint256) {
        if (!getIsSupport(_collateral)) {
            revert Errors.CM_CollNotSupported();
        }
        return collateralParams[_collateral].index;
    }

    function getRatio(
        address _collateral
    ) external view override returns (uint256) {
        return collateralParams[_collateral].ratio;
    }

    // --- 'require' wrapper functions ---

    function _requireIsContract(address _contract) internal view {
        if (!_contract.isContract()) {
            revert Errors.NotContract();
        }
    }

    function _requireCollIsActive(address _collateral) internal view {
        if (!getIsActive(_collateral)) {
            revert Errors.CM_CollNotActive();
        }
    }

    function _requireCollIsBO() internal view {
        if (msg.sender != borrowerOperationsAddress) {
            revert Errors.Caller_NotBO();
        }
    }

    function _requireCollIsTM() internal view {
        if (msg.sender != address(troveManager)) {
            revert Errors.Caller_NotTM();
        }
    }

    function _requireCollIsBOOrTM() internal view {
        if (
            msg.sender != borrowerOperationsAddress &&
            msg.sender != address(troveManager)
        ) {
            revert Errors.Caller_NotBOOrTM();
        }
    }

    function adjustColls(
        uint256[] memory _initialAmounts,
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        address[] memory _collsOut,
        uint256[] memory _amountsOut
    ) external view override returns (uint256[] memory newAmounts) {
        newAmounts = ERDMath._getArrayCopy(_initialAmounts);
        uint256 collsInLen = _collsIn.length;
        uint256 collsOutLen = _collsOut.length;
        uint256 i = 0;
        for (; i < collsInLen; ) {
            uint256 idx = getIndex(_collsIn[i]);
            newAmounts[idx] = newAmounts[idx].add(_amountsIn[i]);
            unchecked {
                ++i;
            }
        }
        i = 0;
        for (; i < collsOutLen; ) {
            uint256 idx = getIndex(_collsOut[i]);
            newAmounts[idx] = newAmounts[idx].sub(_amountsOut[i]);
            unchecked {
                ++i;
            }
        }
    }

    // --- Config update functions ---

    function setMCR(uint256 _mcr) external override onlyOwner {
        MCR = _mcr;
    }

    function setCCR(uint256 _ccr) external override onlyOwner {
        CCR = _ccr;
    }

    function setGasCompensation(uint256 _gas) external override onlyOwner {
        if (_gas > MIN_NET_DEBT) {
            revert Errors.CM_BadValue();
        }
        bool increase;
        uint256 offset;
        if (USDE_GAS_COMPENSATION > _gas) {
            increase = false;
            offset = USDE_GAS_COMPENSATION - _gas;
        } else {
            increase = true;
            offset = _gas - USDE_GAS_COMPENSATION;
        }
        USDE_GAS_COMPENSATION = _gas;
        IBorrowerOperations(borrowerOperationsAddress).updateUSDEGas(
            increase,
            offset
        );
    }

    function setMinDebt(uint256 _minDebt) external override onlyOwner {
        if (_minDebt < USDE_GAS_COMPENSATION) {
            revert Errors.CM_BadValue();
        }
        MIN_NET_DEBT = _minDebt;
    }

    function setBorrowingFeeFloor(
        uint256 _borrowingFloor
    ) external override onlyOwner {
        BORROWING_FEE_FLOOR = _borrowingFloor;
    }

    function setRedemptionFeeFloor(
        uint256 _redemptionFloor
    ) external override onlyOwner {
        REDEMPTION_FEE_FLOOR = _redemptionFloor;
    }

    function setRecoveryFee(
        uint256 _redemptionFloor
    ) external override onlyOwner {
        RECOVERY_FEE = _redemptionFloor;
    }

    function setMaxBorrowingFee(
        uint256 _maxBorrowingFee
    ) external override onlyOwner {
        MAX_BORROWING_FEE = _maxBorrowingFee;
    }

    function setBootstrapPeriod(uint256 _period) external override onlyOwner {
        BOOTSTRAP_PERIOD = _period;
    }

    function setFactor(uint256 _factor) external override onlyOwner {
        troveManager.setFactor(_factor);
    }

    function renounceOwnership() public view override onlyOwner {
        revert Errors.OwnershipCannotBeRenounced();
    }

    function getFactor() external view override returns (uint256) {
        return troveManager.getFactor();
    }

    function getCCR() external view override returns (uint256) {
        return CCR;
    }

    function getMCR() external view override returns (uint256) {
        return MCR;
    }

    function getUSDEGasCompensation() external view override returns (uint256) {
        return USDE_GAS_COMPENSATION;
    }

    function getMinNetDebt() external view override returns (uint256) {
        return MIN_NET_DEBT;
    }

    function getMaxBorrowingFee() external view override returns (uint256) {
        return MAX_BORROWING_FEE;
    }

    function getBorrowingFeeFloor() external view override returns (uint256) {
        return BORROWING_FEE_FLOOR;
    }

    function getRedemptionFeeFloor() external view override returns (uint256) {
        return REDEMPTION_FEE_FLOOR;
    }

    function getRecoveryFee() external view override returns (uint256) {
        return RECOVERY_FEE;
    }

    function getBootstrapPeriod() external view override returns (uint256) {
        return BOOTSTRAP_PERIOD;
    }
}
