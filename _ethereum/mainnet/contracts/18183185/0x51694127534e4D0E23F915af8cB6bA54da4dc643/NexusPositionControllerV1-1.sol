// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

import "./AbstractControllerV11.sol";
import "./IPooledStaking.sol";
import "./INXMaster.sol";
import "./INXMToken.sol";
import "./IWNXMToken.sol";
import "./IMemberRoles.sol";

/**
 * @title NexusPositionController
 * @author Bright Union
 *
 * Manages the leveraged position in Nexus Mutual.
 */
contract NexusPositionControllerV11 is AbstractControllerV11 {
    using SafeERC20 for ERC20;
    using SafeMathUpgradeable for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address[] public allProducts;

    IPooledStaking private _pooledStaking;
    INXMToken private _nxmToken;
    IWNXMToken private _wNXMToken;
    uint256 _unstakeRequestId;

    mapping(bytes32 => address) public exchangeAdapters;

    function __NexusPositionController_init(
        string calldata _description,
        address _indexAddress,
        address _wNXMTokenAddress,
        address _nxMaster,
        address[] calldata _products,
        FeeInfo memory _feeInfo,
        string[] calldata _exchangeAdaptersNames,
        address[] calldata _exchangeAdapters
    ) external initializer {
        __Ownable_init();
        __AbstractController_init(_description, _indexAddress, _feeInfo);

        //Nexus dependencies
        _pooledStaking = IPooledStaking(INXMaster(_nxMaster).getLatestAddress("PS"));
        _nxmToken = INXMToken(INXMaster(_nxMaster).tokenAddress());
        _wNXMToken = IWNXMToken(_wNXMTokenAddress);

        _nxmToken.approve(
            INXMaster(_nxMaster).getLatestAddress("TC"),
            PreciseUnitMath.MAX_UINT_256
        );
        //wrapping/un-wrapping
        _wNXMToken.approve(address(_nxmToken), PreciseUnitMath.MAX_UINT_256);
        _nxmToken.approve(address(_wNXMToken), PreciseUnitMath.MAX_UINT_256);

        base.safeApprove(address(_indexAddress), PreciseUnitMath.MAX_UINT_256);

        allProducts = _products;

        for (uint256 i; i < _exchangeAdaptersNames.length; i++) {
            exchangeAdapters[keccak256(bytes(_exchangeAdaptersNames[i]))] = _exchangeAdapters[i];
        }
    }

    function canStake() public view override returns (bool) {
        return !_pooledStaking.hasPendingActions() && super.canStake();
    }

    function canUnstake() public view override returns (bool) {
        return !_pooledStaking.hasPendingBurns() && maxUnstake() > 0 && super.canUnstake();
    }

    function maxUnstake() public view override returns (uint256) {
        return _pooledStaking.stakerMaxWithdrawable(address(this));
    }

    function stake(uint256 _amount, bytes calldata _exchangeData) external override onlyIndex {
        require(canStake(), "NexusPositionController: NPC1");
        base.safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 _wNXMAmount = _buyWNXM(_amount, _exchangeData);
        require(_wNXMAmount != 0, "NexusPositionController: NPC2");
        require(_wNXMAmount >= _minStakingAmount(), "NexusPositionController: NPC3");

        _unwrapWNXM(_wNXMAmount);
        require(
            _nxmToken.balanceOf(address(this)) >= _wNXMAmount,
            "NexusPositionController: NPC4"
        );

        uint256[] memory _stakes = _stakingStructure(_wNXMAmount);
        _pooledStaking.depositAndStake(_wNXMAmount, allProducts, _stakes);

        setStakingState();
    }

    function callUnstake() external override onlyIndex returns (uint256) {
        require(canCallUnstake(), "NexusPositionController: NPC10");

        uint256[] memory _unstakes = _stakingStructure(0);
        _unstakeRequestId = _pooledStaking.lastUnstakeRequestId();
        _pooledStaking.requestUnstake(allProducts, _unstakes, _unstakeRequestId);
        setUnstakingState();
        emit CallUnstake(_unstakes);
        return _unstakes[0];
    }

    function unstake(bytes calldata _exchangeData, bytes calldata _signature)
    external
    override
    onlyIndex
    returns (uint256)
    {
        require(canUnstake(), "NexusPositionController: NPC9");
        uint256 _amount = _pooledStaking.stakerMaxWithdrawable(address(this));
        _pooledStaking.withdraw(_amount);
        emit Unstake(_amount);

        //wrap NXM into wNXM
        _wrapNXM(_amount);

        //swap wXNM into base
        uint256 _baseAmount = _sellWNXM(_amount, _exchangeData);

        //deposit base into index
        index.depositInternal(_baseAmount);

        _unstakeRequestId = 0;
        setIdleState();
        return _baseAmount;
    }

    function withdrawRewards(bytes calldata _exchangeData) external override {
        (uint256 _rewards, uint256 _fee) = _calculateRewards();
        require(_rewards > 0, "NexusPositionController: NPC5");
        require(_rewards >= _fee, "NexusPositionController: NPC6");

        //withdraw NXM
        _pooledStaking.withdrawReward(address(this));

        _nxmToken.transfer(feeInfo.feeRecipient, _fee);

        //wrap NXM into wNXM
        _wrapNXM(_rewards);

        //swap wXNM into base
        uint256 _baseAmount = _sellWNXM(_rewards, _exchangeData);

        //deposit base into index
        index.depositInternal(_baseAmount);
    }

    function setExchangeAdapters(
        string[] calldata _exchangeAdaptersNames,
        address[] calldata _exchangeAdapters
    ) external override onlyIndex {
        for (uint256 i; i < _exchangeAdaptersNames.length; i++) {
            exchangeAdapters[keccak256(bytes(_exchangeAdaptersNames[i]))] = _exchangeAdapters[i];
        }
    }

    function switchMembership(address newAddress) external onlyOwner {
        IMemberRoles(0x055CC48f7968FD8640EF140610dd4038e1b03926).switchMembership(newAddress);
    }

    // @dev Note this method is used in withdrawRewards(), fees, and netWorth calculation
    function outstandingRewards() public view override returns (uint256) {
        return _pooledStaking.stakerReward(address(this));
    }

    function _buyWNXM(uint256 _amount, bytes calldata _exchangeData) internal returns (uint256) {
        ExchangeData memory _data = _decodeExchangeData(_exchangeData);
        address exchangeAdapter = exchangeAdapters[keccak256(bytes(_data.exchangeAdapter))];
        _checkApprovals(base, exchangeAdapter, _amount);
        return
        _swap(
            _amount,
            address(base),
            address(_wNXMToken),
            address(this),
            exchangeAdapter,
            _data
        );
    }

    function _sellWNXM(uint256 _amount, bytes calldata _exchangeData)
    internal
    returns (uint256 _baseAmount)
    {
        ExchangeData memory _data = _decodeExchangeData(_exchangeData);
        address exchangeAdapter = exchangeAdapters[keccak256(bytes(_data.exchangeAdapter))];
        _checkApprovals(_wNXMToken, exchangeAdapter, _amount);
        _baseAmount = _swap(
            _amount,
            address(_wNXMToken),
            address(base),
            address(this),
            exchangeAdapter,
            _data
        );

        require(_baseAmount != 0, "NexusPositionController: NPC8");
    }

    function _unwrapWNXM(uint256 _amount) internal {
        _wNXMToken.unwrap(_amount);
    }

    function _wrapNXM(uint256 _amount) internal {
        _wNXMToken.wrap(_amount);
        require(_wNXMToken.balanceOf(address(this)) >= _amount, "NexusPositionController: NPC7");
    }

    function _stakingStructure(uint256 _amount)
    internal
    view
    returns (uint256[] memory _resultAmounts)
    {
        _resultAmounts = new uint256[](allProducts.length);
        for (uint256 i = 0; i < allProducts.length; i++) {
            _resultAmounts[i] = currentlyAtStake(allProducts[i]).add(_amount);
        }
    }

    //**
    //* @dev NXM currently deposited, in total
    //*
    function _deposit() internal view returns (uint256) {
        return _pooledStaking.stakerDeposit(address(this));
    }

    function currentlyAtStake(address _product) public view returns (uint256) {
        return _pooledStaking.stakerContractStake(address(this), _product);
    }

    function _minStakingAmount() internal view returns (uint256) {
        return _pooledStaking.MIN_STAKE();
    }

    function netWorth() external view override returns (uint256) {
        (uint256 _rewards, ) = _calculateRewards();
        //how many DAI in wNXM
        return
        _priceFeed.howManyTokensAinB(
            address(base),
            address(_wNXMToken),
            _deposit().add(_rewards)
        );
    }

    function apy() external view override returns (uint256) {
        // actual APY is based on cover purchases
        return 0;
    }

    function productList() external view override returns (address[] memory _products) {
        _products = allProducts;
    }

    function unstakingInfo()
    public
    view
    override
    returns (uint256 _amount, uint256 _unstakeAvailable)
    {
        if (_unstakeRequestId == 0) {
            return (0, 0);
        } else {
            (, , , , uint256 _next) = _pooledStaking.unstakeRequests(_unstakeRequestId);
            (_amount, _unstakeAvailable, , , ) = _pooledStaking.unstakeRequests(_next);
        }
    }
}
