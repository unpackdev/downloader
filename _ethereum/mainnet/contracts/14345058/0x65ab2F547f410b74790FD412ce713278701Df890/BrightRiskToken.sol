// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC20PermitUpgradeable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./EnumerableSet.sol";
import "./Math.sol";
import "./SafeMathUpgradeable.sol";

import "./IPositionController.sol";
import "./IBrightRiskToken.sol";
import "./PreciseUnitMath.sol";
import "./IPriceFeed.sol";

contract BrightRiskToken is
    ERC20PermitUpgradeable,
    AccessControlUpgradeable,
    IBrightRiskToken,
    PausableUpgradeable
{
    using Math for uint256;
    using SafeERC20 for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMathUpgradeable for uint256;
    using PreciseUnitMath for int256;

    bytes32 public constant TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");
    bytes32 public constant TOKEN_OPERATOR_ROLE = keccak256("TOKEN_OPERATOR_ROLE");

    uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60;
    uint256 constant PRECISION = 10**25;
    uint256 constant PERCENTAGE_100 = 100 * PRECISION;

    struct FeeState {
        address feeRecipient; // Address to accrue fees to
        uint256 streamingFeePercentage; // Percent of BrightRiskToken accruing to manager annually (1% = 1e16, 100% = 1e18)
        uint256 lastStreamingFeeTimestamp; // Timestamp last streaming fee was accrued
    }

    IPriceFeed public priceFeed;
    FeeState public feeState;
    ERC20 public base;
    // @dev DEPRECATED
    mapping(address => DepositorInfo) public externalPoolByDepositor;
    // @dev DEPRECATED
    EnumerableSet.AddressSet internal _outstandingDepositors;
    uint256 public externalPool;
    // @dev DEPRECATED
    uint256 public internalPool;
    uint256 public minimumBaseDeposit;

    EnumerableSet.AddressSet internal _positionControllers;

    uint256 public depositFee;

    event FeeActualized(address indexed _manager, uint256 _managerFee);
    event Stake(uint256 stake, address stakeAt, uint256 externalPool);
    event IndexDeposit(
        address indexed depositor,
        uint256 amount,
        uint256 mintAmount,
        uint256 externalPool
    );
    event IndexInternalDeposit(address indexed depositor, uint256 amount, uint256 externalPool);
    event CallUnstake(address indexed controller, uint256 amount);
    event Unstake(address indexed controller, uint256 amount);
    event IndexBurn(address indexed sender, uint256 indexAmount, uint256 baseAmount);

    modifier onlyAdmin() {
        require(hasRole(TOKEN_ADMIN_ROLE, msg.sender), "BrightRiskToken: caller is not the admin");
        _;
    }

    modifier onlyOperator() {
        require(
            hasRole(TOKEN_OPERATOR_ROLE, msg.sender),
            "BrightRiskToken: caller is not the operator"
        );
        _;
    }

    modifier onlyController() {
        require(
            _positionControllers.contains(_msgSender()),
            "BrightRiskToken: caller is not the controller"
        );
        _;
    }

    function __BrightRiskToken_init(
        FeeState memory _feeSettings,
        address _baseAsset,
        address _priceFeed
    ) external initializer {
        __ERC20Permit_init("BRI");
        __ERC20_init("Bright Risk Index", "BRI");
        __AccessControl_init();

        _setupRole(TOKEN_ADMIN_ROLE, msg.sender);
        _setupRole(TOKEN_OPERATOR_ROLE, msg.sender);
        _setRoleAdmin(TOKEN_ADMIN_ROLE, TOKEN_ADMIN_ROLE);
        _setRoleAdmin(TOKEN_OPERATOR_ROLE, TOKEN_ADMIN_ROLE);

        require(_feeSettings.feeRecipient != address(0), "BrightRiskToken: BRI3");
        _feeSettings.lastStreamingFeeTimestamp = block.timestamp;
        feeState = _feeSettings;
        base = ERC20(_baseAsset);
        minimumBaseDeposit = 1500 ether;
        depositFee = 1 * 10**5;
        priceFeed = IPriceFeed(_priceFeed);
    }

    // @notice Deposits capital into 'external' pool, to be 'staked' on behalf of the user later on
    // access: ANY
    function deposit(uint256 _amount) external override whenNotPaused {
        require(_amount >= minimumBaseDeposit, "BrightRiskToken: BRI4");
        base.safeTransferFrom(_msgSender(), address(this), _amount);

        uint256 _mintAmount = convertInvestmentToIndex(_applyDepositFee(_amount));
        _mint(_msgSender(), _mintAmount);
        externalPool = externalPool.add(_amount);
        emit IndexDeposit(_msgSender(), _amount, _mintAmount, externalPool);
    }

    // @notice Deposits funds without minting, usually the rewards from position controllers
    // Also can be used to boost the value, from external sources
    // access: ANY
    function depositInternal(uint256 _amount) external override {
        require(_amount > 0, "BrightRiskToken: BR11");
        base.safeTransferFrom(_msgSender(), address(this), _amount);
        externalPool = externalPool.add(_amount);
        emit IndexInternalDeposit(_msgSender(), _amount, externalPool);
    }

    // @notice Stake 'external' pool in the dedicated position,
    // access: OPERATOR
    function stakeAt(
        address _controllerAddress,
        uint256 _maxAmount
    ) external onlyOperator {
        require(_maxAmount > 0, "BrightRiskToken: BRI5");
        require(_maxAmount <= externalPool, "BrightRiskToken: BRI6");
        require(_positionControllers.contains(_controllerAddress), "BrightRiskToken: BRI2");
        uint256 _staking = externalPool.min(_maxAmount);
        _stakeExternalPool(_controllerAddress, _staking);
        _accrueManagerFee();
        emit Stake(_staking, _controllerAddress, externalPool);
    }

    function _stakeExternalPool(address _controllerAddress, uint256 _amount) internal {
        base.safeApprove(_controllerAddress, _amount);
        IPositionController(_controllerAddress).stake(_amount);
        externalPool = externalPool.sub(_amount);
    }

    // @notice Call unstaking on a specific position. Usually subject to a waiting period
    // access: OPERATOR
    function callUnstakeAt(address _controllerAddress) external onlyOperator {
        uint256 _calledAmount = IPositionController(_controllerAddress).callUnstake();
        emit CallUnstake(_controllerAddress, _calledAmount);
    }

    // @notice Unstake capital from a specific position.
    // access: OPERATOR
    function unstakeAt(address _controllerAddress) external onlyOperator {
        uint256 _unstakedAmount = IPositionController(_controllerAddress).unstake();
        emit Unstake(_controllerAddress, _unstakedAmount);
    }

    // @notice Liquidates the index token in return for 'base', taken from the pool
    // access: ANY
    function burn(uint256 _indexTokenAmount) external whenNotPaused {
        require(_indexTokenAmount > 0, "BrightRiskToken: BRI15");
        require(balanceOf(_msgSender()) >= _indexTokenAmount, "BrightRiskToken: BRI16");

        uint256 _investments = convertIndexToInvestment(_indexTokenAmount);
        // apply the fee
        _investments = _applyDepositFee(_investments);
        require(externalPool >= _investments, "BrightRiskToken: BRI17");

        _burn(_msgSender(), _indexTokenAmount);
        externalPool = externalPool.sub(_investments);
        base.transfer(_msgSender(), _investments);
        emit IndexBurn(_msgSender(), _indexTokenAmount, _investments);
    }

    // @notice Adds new staking position.
    // access: OPERATOR
    function addController(address _controllerAddress) external onlyOperator {
        require(_controllerAddress != address(0), "BrightRiskToken: BRI1");
        _positionControllers.add(_controllerAddress);
    }

    // @notice Removes the staking position.
    // access: OPERATOR
    function removeController(address _controllerAddress) external onlyOperator {
        require(_controllerAddress != address(0), "BrightRiskToken: BRI19");
        require(IPositionController(_controllerAddress).netWorth() == 0, "BrightRiskToken: BRI20");
        _positionControllers.remove(_controllerAddress);
    }

    // @notice Sets the threshold for the minimum deposited capital
    // access: OPERATOR
    function setMinimumDeposit(uint256 _newMin) external onlyOperator {
        minimumBaseDeposit = _newMin;
    }

    // @notice Sets the fee that's applied on new deposits and burn to compensate the asset spread losses
    // access: OPERATOR
    function setDepositFee(uint256 _fee) external onlyOperator {
        require(_fee < 5 * 10**5, "BrightRiskToken: BRI25");
        depositFee = _fee;
    }

    // @notice Sets the streaming fee on the index token
    // access: OPERATOR
    function adjustStreamingFee(FeeState memory _feeSettings) external onlyOperator {
        feeState = _feeSettings;
    }

    // @notice Puts the token on pause, external operations are not available after
    // access: OPERATOR
    function pause() external onlyOperator {
        _pause();
    }

    // @notice Switch off the pause
    // access: OPERATOR
    function unpause() external onlyOperator {
        _unpause();
    }

    // @notice Sets the intermediate route for the assets swap
    // access: OPERATOR
    function setSwapViaAt(address _swapVia, address _controllerAddress) external onlyOperator {
        IPositionController(_controllerAddress).setSwapVia(_swapVia);
    }

    // @notice Sets the intermediate route for the assets swap
    // access: OPERATOR
    function setSwapRewardsViaAt(address _swapRewardsVia, address _controllerAddress)
        external
        onlyOperator
    {
        IPositionController(_controllerAddress).setSwapRewardsVia(_swapRewardsVia);
    }

    function convertIndexToInvestment(uint256 _amount) public view returns (uint256) {
        return _amount.mul(_indexRatio()).div(PERCENTAGE_100);
    }

    function convertInvestmentToIndex(uint256 _amount) public view returns (uint256) {
        return _amount.mul(PERCENTAGE_100).div(_indexRatio());
    }

    function _convertInvestmentToIndexWithRatio(uint256 _amount, uint256 _ratio)
        internal
        pure
        returns (uint256)
    {
        return _amount.mul(PERCENTAGE_100).div(_ratio);
    }

    /*
    // @dev ratio with precision
    */
    function _indexRatio() internal view returns (uint256 _ratio) {
        uint256 _stakes = totalTVL();
        uint256 _currentTotalSupply = totalSupply();

        if (_stakes == 0 || _currentTotalSupply == 0) {
            _ratio = PERCENTAGE_100;
        } else {
            _ratio = _stakes.mul(PRECISION).div(_currentTotalSupply);
        }
        _ratio = _ratio.mul(100); //factor x100
    }

    function _applyDepositFee(uint256 _amount) internal view returns (uint256 _withFee) {
        _withFee = _amount.mul(100 * 10**5 - depositFee).div(100 * 10**5);
    }

    function _accrueManagerFee() internal {
        uint256 _feeQuantity = _calculateStreamingFee();
        if (_feeQuantity > 0) {
            _mint(feeState.feeRecipient, _feeQuantity);
        }
        feeState.lastStreamingFeeTimestamp = block.timestamp;
        emit FeeActualized(feeState.feeRecipient, _feeQuantity);
    }

    function _calculateStreamingFee() internal view returns (uint256) {
        uint256 timeSinceLastFee = block.timestamp.sub(feeState.lastStreamingFeeTimestamp);
        uint256 feePercentage = timeSinceLastFee.mul(feeState.streamingFeePercentage).div(
            SECONDS_IN_THE_YEAR
        );

        uint256 amount = feePercentage.mul(totalSupply());

        // ScaleFactor (10e18) - fee
        uint256 b = PreciseUnitMath.preciseUnit().sub(feePercentage);

        return amount.div(b);
    }

    function getPriceFeed() external view override returns (address) {
        return address(priceFeed);
    }

    // Sets new PriceFeed address
    // access: ADMIN
    function setPriceFeed(address _priceFeed) external onlyAdmin {
        require(_priceFeed != address(0), "BrightRiskToken: BRI22");
        priceFeed = IPriceFeed(_priceFeed);
        uint256 _to = _positionControllers.length();
        for (uint256 i = 0; i < _to; i++) {
            IPositionController(_positionControllers.at(i)).setDependencies();
        }
    }

    function countPositions() external view override returns (uint256) {
        return _positionControllers.length();
    }

    /// @notice use with countPositions()
    function listPositions(uint256 offset, uint256 limit)
        public
        view
        override
        returns (address[] memory _positionControllersArr)
    {
        uint256 to = (offset.add(limit)).min(_positionControllers.length()).max(offset);

        _positionControllersArr = new address[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            _positionControllersArr[i - offset] = _positionControllers.at(i);
        }
    }

    function getBase() public view override returns (address) {
        return address(base);
    }

    // @notice Includes staked funds plus deposited assets
    function totalTVL() public view returns (uint256 _tvl) {
        uint256 _to = _positionControllers.length();
        for (uint256 i = 0; i < _to; i++) {
            _tvl = _tvl.add(IPositionController(_positionControllers.at(i)).netWorth());
        }
        _tvl = _tvl.add(externalPool);
    }
}
