// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

import "./AbstractController.sol";
//TODO Delete
import "./IPooledStaking.sol";
import "./INXMaster.sol";
import "./INXMToken.sol";
import "./IWNXMToken.sol";
import "./IStakingNFT.sol";
import "./IStakingNFTDescriptor.sol";
import "./IStakingPool.sol";

/**
 * @title NexusPositionController
 * @author Bright Union
 *
 * Manages the leveraged position in Nexus Mutual.
 */
contract NexusPositionController is AbstractController {
    using SafeERC20 for ERC20;
    using SafeMathUpgradeable for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    INXMToken private _nxmToken;
    IWNXMToken private _wNXMToken;

    IStakingPool public stakingPool;
    uint256 public tokenId;

    EnumerableSet.UintSet internal _activeTranches;
    IStakingNFT public stakingNFT;

    mapping(bytes32 => address) public exchangeAdapters;

    function __NexusPositionController_init(
        string calldata _description,
        address _indexAddress,
        address _wNXMTokenAddress,
        address _nxMaster,
        address _stakingPool,
        FeeInfo memory _feeInfo,
        string[] calldata _exchangeAdaptersNames,
        address[] calldata _exchangeAdapters
    ) external initializer {
        __Ownable_init();
        __AbstractController_init(_description, _indexAddress, _feeInfo);

        //Nexus dependencies
        _nxmToken = INXMToken(INXMaster(_nxMaster).tokenAddress());
        _wNXMToken = IWNXMToken(_wNXMTokenAddress);
        stakingPool = IStakingPool(_stakingPool);
        stakingNFT = IStakingNFT(0xcafea508a477D94c502c253A58239fb8F948e97f);

        _nxmToken.approve(
            INXMaster(_nxMaster).getLatestAddress("TC"),
            PreciseUnitMath.MAX_UINT_256
        );
        //wrapping/un-wrapping
        _wNXMToken.approve(address(_nxmToken), PreciseUnitMath.MAX_UINT_256);
        _nxmToken.approve(address(_wNXMToken), PreciseUnitMath.MAX_UINT_256);

        base.safeApprove(address(_indexAddress), PreciseUnitMath.MAX_UINT_256);

        for (uint256 i; i < _exchangeAdaptersNames.length; i++) {
            exchangeAdapters[keccak256(bytes(_exchangeAdaptersNames[i]))] = _exchangeAdapters[i];
        }
    }

    function canStake() public view override returns (bool) {
        return true;
    }

    function canUnstake() public view override returns (bool) {
        return true;
    }

    function stake(uint256 _amount, bytes calldata _exchangeData, bytes calldata _calldata) external override onlyIndex {
        require(canStake(), "NexusPositionController: NPC1");
        (
            uint256 _trancheId,
            uint256 _requestTokenId
        ) = abi.decode(_calldata, (uint256, uint256));
        require (_requestTokenId == tokenId || _requestTokenId == 0, "NexusPositionController: NPC13");
        base.safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 _wNXMAmount = _buyWNXM(_amount, _exchangeData);
        require(_wNXMAmount != 0, "NexusPositionController: NPC2");
        require(_wNXMAmount >= _minStakingAmount(), "NexusPositionController: NPC3");

        _unwrapWNXM(_wNXMAmount);
        require(
            _nxmToken.balanceOf(address(this)) >= _wNXMAmount,
            "NexusPositionController: NPC4"
        );

        uint256 _tokenId = stakingPool.depositTo(
            _wNXMAmount,
            _trancheId,
            _requestTokenId,
            address(this)
        );
        tokenId = _tokenId;
        _activeTranches.add(_trancheId);
        setStakingState();
    }

    function callUnstake() external override onlyIndex returns (uint256) {
        // no need to call unstake anymore, capital is available at the given date
        return 0;
    }

    function unstake(bytes calldata _exchangeData, bytes calldata _calldata)
        external
        override
        onlyIndex
        returns (uint256)
    {
        require(canUnstake(), "NexusPositionController: NPC9");
        (
            uint256 _tokenId,
            uint256[] memory _trancheIds
        ) = abi.decode(_calldata, (uint256,  uint256[]));
        uint256 _amount = _withdrawFromPool(_tokenId, true, false, _trancheIds);
        for (uint256 i; i < _trancheIds.length; i++) {
            _activeTranches.remove(_trancheIds[i]);
        }
        //wrap NXM into wNXM
        _wrapNXM(_amount);

        //swap wXNM into base
        uint256 _baseAmount = _sellWNXM(_amount, _exchangeData);
        //deposit base into index
        index.depositInternal(_baseAmount);

        emit Unstake(_amount);
        return _baseAmount;
    }

    function withdrawRewards(bytes calldata _exchangeData, bytes calldata _calldata) external override onlyOwner{
        (uint256 _rewards, uint256 _fee) = _calculateRewards();
        require(_rewards > 0, "NexusPositionController: NPC5");
        require(_rewards >= _fee, "NexusPositionController: NPC6");

        //withdraw NXM
        (
            uint256 _tokenId,
            uint256[] memory _trancheIds
        ) = abi.decode(_calldata, (uint256,  uint256[]));
        _withdrawFromPool(_tokenId, false, true, _trancheIds);

        if (_fee > 0) {
            _nxmToken.transfer(feeInfo.feeRecipient, _fee);
        }
        _rewards = _nxmToken.balanceOf(address(this));

        //wrap NXM into wNXM
        _wrapNXM(_rewards);

        //swap wXNM into base
        uint256 _baseAmount = _sellWNXM(_rewards, _exchangeData);

        //deposit base into index
        index.depositInternal(_baseAmount);
    }

    function setStakingNFT(address _newStakingNFT) external onlyOwner{
        stakingNFT = IStakingNFT(_newStakingNFT);
    }

    function setExchangeAdapters(
        string[] calldata _exchangeAdaptersNames,
        address[] calldata _exchangeAdapters
    ) external override onlyIndex {
        for (uint256 i; i < _exchangeAdaptersNames.length; i++) {
            exchangeAdapters[keccak256(bytes(_exchangeAdaptersNames[i]))] = _exchangeAdapters[i];
        }
    }

    // @dev Note this method is used in withdrawRewards(), fees, and netWorth calculation
    function outstandingRewards() public view override returns (uint256 _rewards) {
        if (tokenId == 0) {
            return 0;
        }
        IStakingNFTDescriptor nftDescriptor = IStakingNFTDescriptor(
            stakingNFT.nftDescriptor()
        );
        (,,_rewards) = nftDescriptor.getActiveDeposits(tokenId, stakingPool);
    }

    /**
     * @dev Withdraw any Nxm we can from the staking pool.
     * @return amount The amount of funds that are being withdrawn.
     **/
    function _withdrawFromPool(
        uint256 _tokenId,
        bool _withdrawStake,
        bool _withdrawRewards,
        uint256[] memory _trancheIds
    ) internal returns (uint256 amount) {
        (amount, ) = stakingPool.withdraw(
            _tokenId,
            _withdrawStake,
            _withdrawRewards,
            _trancheIds
        );
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


    //**
    //* @dev NXM currently deposited
    //*
    function _currentDeposit() internal view returns (uint256 _totalStake) {
        if (tokenId == 0) {
            return 0;
        }
        IStakingNFTDescriptor nftDescriptor = IStakingNFTDescriptor(
            stakingNFT.nftDescriptor()
        );
        (,_totalStake,) = nftDescriptor.getActiveDeposits(tokenId, stakingPool);
    }

    function _minStakingAmount() internal view returns (uint256) {
        return 1 ether;
    }

    function netWorth() external view override returns (uint256) {
        (uint256 _rewards, ) = _calculateRewards();
        //how many DAI in wNXM
        return
            _priceFeed.howManyTokensAinB(
                address(base),
                address(_wNXMToken),
                _currentDeposit().add(_rewards)
            );
    }

    function apy() external view override returns (uint256 _apy) {
        uint256 _rewardsPerYear = SECONDS_IN_THE_YEAR.mul(stakingPool.getRewardPerSecond());
        uint256 _totalStake = stakingPool.getActiveStake();
        _apy = _rewardsPerYear.mul(PRECISION_5_PERCENTAGE_100).div(_totalStake);
    }

    function productList() external view override returns (address[] memory _products) {
        //to be done on UI via StakingViewer at '0xcafea2b7904ee0089206ab7084bcafb8d476bd04'
        _products = new address[](0);
    }

    function maxUnstake() external view override returns (uint256 _maxUnstake) {
        return _currentDeposit();
    }

    function unstakingInfo()
        public
        view
        override
        returns (uint256 _amount, uint256 _unstakeAvailable)
    {
        //there are no unstaking requests anymore
        return (0, 0);
    }

    function getActiveTranches() external view returns(uint256[] memory) {
        uint256[] memory _result = new uint256[](_activeTranches.length());
        for (uint256 i = 0; i < _activeTranches.length(); i++) {
            _result[i] = _activeTranches.at(i);
        }
        return _result;
    }

}
