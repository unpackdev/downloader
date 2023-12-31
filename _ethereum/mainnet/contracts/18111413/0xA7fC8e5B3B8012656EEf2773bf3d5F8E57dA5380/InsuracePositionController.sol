// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./EnumerableSet.sol";
import "./Math.sol";
import "./AbstractController.sol";
import "./IStakersPoolV2.sol";
import "./IStakingV2Controller.sol";

import "./ILPToken.sol";
import "./IRewardController.sol";

/**
 * @title InsuracePositionController
 * @author Bright Union
 *
 * Manages one staking asset in InsurAce
 */
contract InsuracePositionController is AbstractController {
    using Math for uint256;
    using SafeERC20 for ERC20;
    using SafeMathUpgradeable for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IStakersPoolV2 private _stakersPool;
    IStakingV2Controller private _stakingController;
    IRewardController private _rewardController;
    address constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public insurToken;
    address public stakingAsset;
    address public lpToken;
    mapping(bytes32 => address) public exchangeAdapters;

    function __InsuracePositionController_init(
        string calldata _description,
        address _indexAddress,
        address _rewardControllerAddress,
        address _stkingAssetsAddress,
        FeeInfo memory _feeInfo,
        string[] calldata _exchangeAdaptersNames,
        address[] calldata _exchangeAdapters
    ) external initializer {
        __Ownable_init();
        __AbstractController_init(_description, _indexAddress, _feeInfo);

        //InsurAce dependencies
        _rewardController = IRewardController(_rewardControllerAddress);
        _stakingController = IStakingV2Controller(_rewardController.stakingController());
        _stakersPool = IStakersPoolV2(_stakingController.stakersPoolV2());

        insurToken = _rewardController.insur();
        stakingAsset = _stkingAssetsAddress;
        lpToken = _stakingController.tokenToLPTokenMap(stakingAsset);

        // for getting back rewards/unstakes
        base.safeApprove(address(_indexAddress), PreciseUnitMath.MAX_UINT_256);
        // stakingAsset approve stakingController
        _checkTetherApprovals(
            _stkingAssetsAddress,
            address(_stakingController),
            PreciseUnitMath.MAX_UINT_256
        );
        //unstaking
        ERC20(lpToken).safeApprove(address(address(_stakersPool)), PreciseUnitMath.MAX_UINT_256);
        for (uint256 i; i < _exchangeAdaptersNames.length; i++) {
            exchangeAdapters[keccak256(bytes(_exchangeAdaptersNames[i]))] = _exchangeAdapters[i];
        }
    }

    function canCallUnstake() public view override returns (bool) {
        uint256 _collateral = positionSupply();
        return
            _stakingController.minUnstakeAmtPT(stakingAsset) <= _collateral &&
            _stakingController.maxUnstakeAmtPT(stakingAsset) >= _collateral &&
            super.canCallUnstake();
    }

    function stake(uint256 _amount, bytes calldata _exchangeData, bytes calldata _calldata) external override onlyIndex {
        require(canStake(), "InsuracePositionController: IPC0");
        require(
            _amount >= _stakingController.minStakeAmtPT(stakingAsset),
            "InsuracePositionController: IPC1"
        );
        base.safeTransferFrom(_msgSender(), address(this), _amount);
        // If we want to stake other than the base currency, we swap.
        if (address(base) != stakingAsset) {
            ExchangeData memory _data = _decodeExchangeData(_exchangeData);
            address _exchangeAdapter = exchangeAdapters[keccak256(bytes(_data.exchangeAdapter))];
            _checkApprovals(IERC20(base), _exchangeAdapter, _amount);
            _swap(_amount, address(base), stakingAsset, address(this), _exchangeAdapter, _data);
        }

        uint256 investmentAmount = ERC20(stakingAsset).balanceOf(address(this));
        require(investmentAmount != 0, "InsuracePositionController: IPC3");
        // Stake
        _stakingController.stakeTokens(investmentAmount, stakingAsset);
        // Check our balance for lptokens
        uint256 _lptokenBalance = ERC20(lpToken).balanceOf(address(this));
        require(_lptokenBalance >= 0, "InsuracePositionController: IPC4");

        setStakingState();
    }

    function callUnstake() external override onlyIndex returns (uint256) {
        require(canCallUnstake(), "InsuracePositionController: IPC5");
        uint256 _collateral = positionSupply();

        _stakingController.proposeUnstake(_collateral, stakingAsset);
        setUnstakingState();
        uint256[] memory _unstakeAmount = new uint256[](1);
        _unstakeAmount[0] = _collateral;
        emit CallUnstake(_unstakeAmount);
        return _collateral;
    }

    function unstake(bytes calldata _exchangeData, bytes calldata _signature)
        external
        override
        onlyIndex
        returns (uint256)
    {
        require(canUnstake(), "InsuracePositionController: IPC7");
        (
            uint256 _nonce,
            uint256 _deadline,
            uint8[] memory _v,
            bytes32[] memory _r,
            bytes32[] memory _s
        ) = abi.decode(_signature, (uint256, uint256, uint8[], bytes32[], bytes32[]));
        _stakingController.withdrawTokens(
            address(this),
            payable(address(this)),
            positionSupply(),
            stakingAsset,
            _nonce,
            _deadline,
            _v,
            _r,
            _s
        );
        uint256 _unstakedAmount = ERC20(stakingAsset).balanceOf(address(this));
        require(_unstakedAmount > 0, "InsuracePositionController: IPC8");

        uint256 _baseTokenAmount;
        if (address(base) != stakingAsset) {
            // Convert unstaked asset to base asset
            ExchangeData memory _data = _decodeExchangeData(_exchangeData);
            address _exchangeAdapter = exchangeAdapters[keccak256(bytes(_data.exchangeAdapter))];
            _checkTetherApprovals(address(stakingAsset), _exchangeAdapter, _unstakedAmount);
            _baseTokenAmount = _swap(
                _unstakedAmount,
                stakingAsset,
                address(base),
                address(this),
                _exchangeAdapter,
                _data
            );
        } else {
            _baseTokenAmount = _unstakedAmount;
        }

        // Return to index
        index.depositInternal(_baseTokenAmount);

        setIdleState();
        emit Unstake(positionSupply());
        return _baseTokenAmount;
    }

    // @notice Preliminary step to withdrwap INSUR rewards
    // Unclocked rewards won't be got but locked into the linear vesting contract
    function unlockRewards() external {
        address[] memory stakingAssetAddresses = new address[](1);
        stakingAssetAddresses[0] = stakingAsset;
        _rewardController.unlockReward(
            stakingAssetAddresses, // _tokenList
            false, // _bBuyCoverUnlockedAmt,
            false, // _bClaimUnlockedAmt,
            false // _bReferralUnlockedAmt
        );
    }

    function withdrawRewards(bytes calldata _exchangeData, bytes calldata _calldata) external override onlyOwner{
        (uint256 _withdrawableNow, ) = rewardsInVesting();

        (uint256 _rewards, uint256 _fee) = _applyFees(_withdrawableNow);

        _rewardController.withdrawReward(_withdrawableNow);

        require(
            ERC20(insurToken).balanceOf(address(this)) >= _withdrawableNow,
            "InsuracePositionController IPC10"
        );
        ERC20(insurToken).transfer(feeInfo.feeRecipient, _fee);

        // swap INSUR into base
        ExchangeData memory _data = _decodeExchangeData(_exchangeData);
        address _exchangeAdapter = exchangeAdapters[keccak256(bytes(_data.exchangeAdapter))];
        _checkApprovals(IERC20(insurToken), _exchangeAdapter, _rewards);
        uint256 _baseTokenAmount = _swap(
            _rewards,
            address(insurToken),
            address(base),
            address(this),
            _exchangeAdapter,
            _data
        );

        require(_baseTokenAmount != 0, "InsuracePositionController: IPC11");
        // Deposit to index
        index.depositInternal(_baseTokenAmount);
    }

    function setExchangeAdapters(
        string[] calldata _exchangeAdaptersNames,
        address[] calldata _exchangeAdapters
    ) external override onlyIndex {
        for (uint256 i; i < _exchangeAdaptersNames.length; i++) {
            exchangeAdapters[keccak256(bytes(_exchangeAdaptersNames[i]))] = _exchangeAdapters[i];
        }
    }

    function _getStakingToLPRatio(uint256 currentLiquidity) internal view returns (uint256) {
        uint256 _currentTotalSupply = ERC20Upgradeable(lpToken).totalSupply();

        if (_currentTotalSupply == 0) {
            return PERCENTAGE_100;
        }

        return currentLiquidity.mul(PERCENTAGE_100).div(_currentTotalSupply);
    }

    function convertLPToStaking(uint256 _amount) public view returns (uint256) {
        uint256 _currentLiquidity = IStakersPoolV2(_stakersPool).getStakedAmountPT(stakingAsset);

        return _amount.mul(_getStakingToLPRatio(_currentLiquidity)).div(PERCENTAGE_100);
    }

    function convertStakingToLP(uint256 _amount) public view returns (uint256) {
        uint256 _currentLiquidity = IStakersPoolV2(_stakersPool).getStakedAmountPT(stakingAsset);

        return _amount.mul(PERCENTAGE_100).div(_getStakingToLPRatio(_currentLiquidity));
    }

    // @notice Gives total rewards, earnings and pending in vestings
    // @dev Note this method is used in netWorth calculation
    function outstandingRewards() public view override returns (uint256) {
        (uint256 _withdrawableNow, uint256 _lockedInVesting) = rewardsInVesting();
        return rewardsInEarnings().add(_lockedInVesting).add(_withdrawableNow);
    }

    function rewardsInEarnings() public view returns (uint256 _rewards) {
        _rewards = _stakersPool.showPendingRewards(address(this), lpToken);
    }

    function rewardsInVesting()
        public
        view
        returns (uint256 _withdrawableNow, uint256 _lockedInVesting)
    {
        (_withdrawableNow, _lockedInVesting) = _rewardController.getRewardInfo();
    }

    function positionSupply() public view returns (uint256) {
        uint256 _lptokenBalance = ERC20(lpToken).balanceOf(address(this));
        if (_lptokenBalance == 0) {
            return 0;
        }
        return convertLPToStaking(_lptokenBalance);
    }

    function netWorth() external view override returns (uint256) {
        (uint256 _rewards, ) = _calculateRewards();

        uint256 _rewardsBase;
        if (_rewards != 0) {
            // returns INSUR rewards in base asset
            _rewardsBase = _priceFeed.howManyTokensAinB(address(base), insurToken, _rewards);
        }

        // returns currently staked amount in base asset
        uint256 _stakedBase;
        if (address(base) != stakingAsset) {
            _stakedBase = _priceFeed.howManyTokensAinB(
                address(base),
                stakingAsset,
                positionSupply()
            );
        } else {
            _stakedBase = positionSupply();
        }

        return _stakedBase.add(_rewardsBase);
    }

    function productList() external view override returns (address[] memory _products) {
        _products = new address[](1);
        _products[0] = stakingAsset;
    }

    function apy() external view override returns (uint256 _apy) {
        uint256 _blocksYear = SECONDS_IN_THE_YEAR.div(15);
        uint256 _rewardsPerYear = _rewardsPerBlockPerPool().mul(_blocksYear);

        uint256 _poolTVLInStakingAsset = _stakersPool.getStakedAmountPT(stakingAsset);
        uint256 _stakingDecimals = ERC20(stakingAsset).decimals();
        uint256 _insurInOneStaking = _priceFeed.howManyTokensAinB(
            insurToken,
            stakingAsset,
            1 * 10**_stakingDecimals
        );
        uint256 _poolTVLInRewardsAsset = _poolTVLInStakingAsset.mul(_insurInOneStaking).div(
            10**_stakingDecimals
        );

        _apy = _rewardsPerYear.mul(PRECISION_5_PERCENTAGE_100).div(_poolTVLInRewardsAsset);
    }

    function _rewardsPerBlockPerPool() internal view returns (uint256 _rewards) {
        // R-sub-all : The total reward for all mining pools (in INSUR)
        uint256 _rewardsPB = _stakersPool.rewardPerBlock();
        // W = The weight of the mining pool
        uint256 _poolWeight = _stakersPool.poolWeightPT(lpToken);
        // W-sub-all = The sum of the weights of all mining pools
        uint256 _totalPoolWeight = _stakersPool.totalPoolWeight();

        return _poolWeight.mul(_rewardsPB).div(_totalPoolWeight);
    }

    function maxUnstake() external view override returns (uint256 _maxUnstake) {
        return ERC20(lpToken).balanceOf(address(this));
    }

    function unstakingInfo()
        public
        view
        override
        returns (uint256 _amount, uint256 _unstakeAvailable)
    {
        // unstake lock period
        _unstakeAvailable = ILPToken(lpToken).burnWeightPH(address(this));

        uint256 _amountLocked = ILPToken(lpToken).pendingBurnAmtPH(address(this));
        uint256 _amountAvailable = ILPToken(lpToken).burnableAmtOf(address(this));
        _amount = _amountLocked.max(_amountAvailable);
    }

    function rewardsVestingInfo()
        public
        view
        returns (
            uint256 vestingEndBlockPerAccount,
            uint256 vestingStartBlockPerAccount,
            uint256 vestingWithdrawableAmountPerAccount,
            uint256 vestingWithdrawedAmountPerAccount,
            uint256 vestingDuration,
            uint256 vestingAmountPerAccount
        )
    {
        vestingStartBlockPerAccount = _rewardController.vestingStartBlockPerAccount(address(this));
        vestingEndBlockPerAccount = _rewardController.vestingEndBlockPerAccount(address(this));
        vestingWithdrawableAmountPerAccount = _rewardController
            .vestingWithdrawableAmountPerAccount(address(this));
        vestingWithdrawedAmountPerAccount = _rewardController.vestingWithdrawedAmountPerAccount(
            address(this)
        );
        vestingDuration = _rewardController.vestingDuration();
        vestingAmountPerAccount = _rewardController.vestingVestingAmountPerAccount(address(this));
    }
}
