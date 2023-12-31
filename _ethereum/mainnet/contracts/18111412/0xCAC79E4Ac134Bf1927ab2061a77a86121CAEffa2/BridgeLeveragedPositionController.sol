// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./IERC1155Receiver.sol";
import "./EnumerableSet.sol";

import "./AbstractController.sol";
import "./IUserLeveragePool.sol";
import "./IRewardsGenerator.sol";
import "./IShieldMining.sol";
import "./IBMICoverStaking.sol";
import "./ILeveragePortfolio.sol";
import "./DecimalsConverter.sol";
import "./IBMICoverStakingView.sol";

/**
 * @title BridgeLeveragedPositionController
 * @author Bright Union
 *
 * Manages leveraged position in Bridge Mutual.
 */
contract BridgeLeveragedPositionController is AbstractController, IERC1155Receiver {
    using SafeERC20 for ERC20;
    using SafeMathUpgradeable for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IUserLeveragePool public leveragedPortfolio;

    IRewardsGenerator public rewardsGenerator;
    IShieldMining public shieldMining;
    ERC20 public stblToken;
    uint256 public stblDecimals;
    ERC20 public bmiXToken;
    ERC20 public bmiToken;
    IBMICoverStaking public bmiCoverStaking;
    IBMICoverStakingView public bmiCoverStakingView;

    uint256 public _nftId;

    mapping(bytes32 => address) public exchangeAdapters;

    event NftIdUpdate(uint256 newId);

    function __BridgeLeveragedPositionController_init(
        string calldata _description,
        address _indexAddress,
        address _portfolioAddress,
        FeeInfo memory _feeInfo,
        string[] calldata _exchangeAdaptersNames,
        address[] calldata _exchangeAdapters
    ) external initializer {
        __Ownable_init();
        __AbstractController_init(_description, _indexAddress, _feeInfo);

        //Bridge dependencies
        leveragedPortfolio = IUserLeveragePool(_portfolioAddress);
        stblToken = ERC20(leveragedPortfolio.stblToken());
        stblDecimals = stblToken.decimals();
        bmiXToken = ERC20(address(leveragedPortfolio));
        rewardsGenerator = IRewardsGenerator(leveragedPortfolio.rewardsGenerator());
        shieldMining = IShieldMining(leveragedPortfolio.shieldMining());
        bmiCoverStaking = IBMICoverStaking(leveragedPortfolio.bmiCoverStaking());
        bmiCoverStakingView = IBMICoverStakingView(leveragedPortfolio.bmiCoverStakingView());
        bmiToken = ERC20(bmiCoverStaking.bmiToken());

        // for getting back rewards/unstakes
        base.safeApprove(address(_indexAddress), PreciseUnitMath.MAX_UINT_256);
        // for providing liquidity for STBL rewards
        stblToken.safeApprove(address(leveragedPortfolio), PreciseUnitMath.MAX_UINT_256);
        // for staking LP tokens for BMI rewards
        bmiXToken.safeApprove(address(bmiCoverStaking), PreciseUnitMath.MAX_UINT_256);
        // for unstaking lp -> stbl
        bmiXToken.safeApprove(address(leveragedPortfolio), PreciseUnitMath.MAX_UINT_256);

        for (uint256 i; i < _exchangeAdaptersNames.length; i++) {
            exchangeAdapters[keccak256(bytes(_exchangeAdaptersNames[i]))] = _exchangeAdapters[i];
        }
    }

    function canStake() public view override returns (bool) {
        return true;
    }

    function canCallUnstake() public view override returns (bool) {
        //can call multiple unstakes, new one will override existing
        return true;
    }

    function canUnstake() public view override returns (bool) {
        return
            leveragedPortfolio.getWithdrawalStatus(address(this)) ==
            IUserLeveragePool.WithdrawalStatus.READY;
    }

    function maxUnstake() public view override returns (uint256 _bmiX) {
        _bmiX = bmiCoverStaking.totalStaked(address(this));
        _bmiX = _bmiX.add(leveragedPortfolio.getAvailableBMIXWithdrawableAmount(address(this)));
    }

    function stake(uint256 _amount, bytes calldata _exchangeData, bytes calldata _calldata) external override onlyIndex {
        require(canStake(), "BridgeLeveragedPositionController: BLPC1");
        base.safeTransferFrom(_msgSender(), address(this), _amount);

        ExchangeData memory _data = _decodeExchangeData(_exchangeData);
        address exchangeAdapter = exchangeAdapters[keccak256(bytes(_data.exchangeAdapter))];
        _checkApprovals(base, exchangeAdapter, _amount);
        uint256 _stblAmount = _swap(
            _amount,
            address(base),
            address(stblToken),
            address(this),
            exchangeAdapter,
            _data
        );

        // STBL -> bmiX -> stake
        // will receive a 'bmiCoverStaking' NFT for that
        _stblAmount = DecimalsConverter.convertTo18(_stblAmount, stblDecimals);
        leveragedPortfolio.addLiquidityAndStake(_stblAmount, _stblAmount);

        setStakingState();
    }

    //* @notice Should be called shorty after withdrawRewards(), as the BMI rewards here won't be swapped, to save on gas
    function callUnstake() external override onlyIndex returns (uint256) {
        require(canCallUnstake(), "BridgeLeveragedPositionController: BLPC2");

        //burn nft and unlock bmiXToken
        bmiCoverStaking.withdrawFundsWithProfit(_nftId);
        //should be a small amount here
        bmiToken.transfer(feeInfo.feeRecipient, bmiToken.balanceOf(address(this)));

        uint256 _bmiXAmount = _requestWithdrawal();

        return _bmiXAmount;
    }

    // @notice in rare cases not all staked capital is withdrawable at amy moment (like a claim is submitted)
    function _requestWithdrawal() internal returns (uint256 _bmiXAmount) {
        _bmiXAmount = leveragedPortfolio.getAvailableBMIXWithdrawableAmount(address(this));
        leveragedPortfolio.requestWithdrawal(_bmiXAmount);
        setUnstakingState();
    }

    function unstake(bytes calldata _exchangeData, bytes calldata _signature)
        external
        override
        onlyIndex
        returns (uint256)
    {
        require(canUnstake(), "BridgeLeveragedPositionController: BLPC3");
        leveragedPortfolio.withdrawLiquidity();
        ExchangeData memory _data = _decodeExchangeData(_exchangeData);
        address exchangeAdapter = exchangeAdapters[keccak256(bytes(_data.exchangeAdapter))];
        uint256 _amountStbl = stblToken.balanceOf(address(this));
        _checkTetherApprovals(address(stblToken), exchangeAdapter, _amountStbl);
        uint256 _baseAmount = _swap(
            _amountStbl,
            address(stblToken),
            address(base),
            address(this),
            exchangeAdapter,
            _data
        );
        require(_baseAmount != 0, "BridgeLeveragedPositionController: BLPC9");
        //deposit base into index
        index.depositInternal(_baseAmount);
        setIdleState();
        emit Unstake(_amountStbl);
        return _baseAmount;
    }

    //Sets the nft id pointer to the one where next unstaking actions will be called for
    // access: OWNER
    function setActiveNftId(uint256 _id) external onlyOwner {
        require(
            bmiCoverStaking.ownerOf(_id) == address(this),
            "BridgeLeveragedPositionController: BLPC6"
        );
        _nftId = _id;
        emit NftIdUpdate(_nftId);
    }

    function activeNftId() public view returns (uint256) {
        return _nftId;
    }

    function setExchangeAdapters(
        string[] calldata _exchangeAdaptersNames,
        address[] calldata _exchangeAdapters
    ) external override onlyIndex {
        for (uint256 i; i < _exchangeAdaptersNames.length; i++) {
            exchangeAdapters[keccak256(bytes(_exchangeAdaptersNames[i]))] = _exchangeAdapters[i];
        }
    }

    // access: ANY
    function withdrawRewards(bytes calldata _exchangeData, bytes calldata _calldata) external override onlyOwner{
        //TODO Check shield mining
        bmiCoverStaking.withdrawBMIProfit(_nftId);
        (uint256 _rewards, uint256 _fee) = _applyFees(bmiToken.balanceOf(address(this)));
        require(_rewards > 0, "BridgeLeveragedPositionController: BLPC4");
        require(_rewards >= _fee, "BridgeLeveragedPositionController: BLPC5");

        bmiToken.transfer(feeInfo.feeRecipient, _fee);

        //swap BMI into base
        uint256 _baseAmount = _sellBMI(_rewards, _exchangeData);

        //deposit base into index
        index.depositInternal(_baseAmount);
    }

    function _sellBMI(uint256 _amount, bytes calldata _exchangeData)
        internal
        returns (uint256 _baseAmount)
    {
        ExchangeData memory _data = _decodeExchangeData(_exchangeData);
        address exchangeAdapter = exchangeAdapters[keccak256(bytes(_data.exchangeAdapter))];
        _checkApprovals(bmiToken, exchangeAdapter, _amount);
        _baseAmount = _swap(
            _amount,
            address(bmiToken),
            address(base),
            address(this),
            exchangeAdapter,
            _data
        );
        require(_baseAmount != 0, "BridgeLeveragedPositionController: BLPC8");
    }

    // @dev Note this method is used in withdrawRewards(), fees, and netWorth calculation
    function outstandingRewards() public view override returns (uint256) {
        return
            bmiCoverStaking.getSlashedStakerBMIProfit(
                address(this),
                address(0),
                0,
                PreciseUnitMath.MAX_UINT_256
            );
    }

    function outstandingRewardsWithoutSlashing(uint256 _id) public view returns (uint256) {
        return bmiCoverStaking.getBMIProfit(_id);
    }

    function netWorth() external view override returns (uint256 _worth) {
        //staking
        uint256 _stakedStbl;
        uint256 _rewardsBase;
        (uint256 _bmiRewards, ) = _calculateRewards();
        if (_bmiRewards > 0) {
            _rewardsBase = _priceFeed.howManyTokensAinB(
                address(base),
                address(bmiToken),
                _bmiRewards
            );
        }
        //'deposited and then staked'
        _stakedStbl = bmiCoverStaking.totalStakedSTBL(address(this));
        (uint256 _unstakingBMIX, ) = unstakingInfo();
        //only 'deposited'
        _stakedStbl = _stakedStbl.add(leveragedPortfolio.convertBMIXToSTBL(_unstakingBMIX));

        _stakedStbl = DecimalsConverter.convertFrom18(_stakedStbl, stblDecimals);
        _worth = _priceFeed.howManyTokensAinB(address(base), address(stblToken), _stakedStbl).add(
            _rewardsBase
        );
    }

    function apy() external view override returns (uint256) {
        // sum up BMI rewards with stbl rewards
        return
            leveragedPortfolio.getAPY().add(
                bmiCoverStakingView.getPolicyBookAPY(
                    address(leveragedPortfolio),
                    _priceFeed.howManyTokensAinB(address(stblToken), address(bmiToken), 1 ether)
                )
            );
    }

    function productList() external view override returns (address[] memory _products) {
        ILeveragePortfolio _portfolio = ILeveragePortfolio(address(leveragedPortfolio));
        uint256 _size = _portfolio.countleveragedCoveragePools();
        _products = _portfolio.listleveragedCoveragePools(0, _size);
    }

    function unstakingInfo()
        public
        view
        override
        returns (uint256 _amount, uint256 _unstakeAvailable)
    {
        (_amount, _unstakeAvailable, ) = leveragedPortfolio.withdrawalsInfo(address(this));
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return 0xbc197c81;
    }

    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        //ERC165
        if (interfaceId == 0x01ffc9a7) {
            return true;
        }
        return false;
    }
}
