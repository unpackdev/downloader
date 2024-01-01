// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./ERC20BurnableUpgradeable.sol";

import "./ERC165CheckerUpgradeable.sol";

import "./IERC721ReceiverUpgradeable.sol";
import "./IERC721Upgradeable.sol";

import "./ReentrancyGuardUpgradeable.sol";

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";

import "./SafeCastUpgradeable.sol";

import "./AddressUpgradeable.sol";

import "./Initializable.sol";

import "./IRewardsBooster.sol";

import "./SafeERC20.sol";

import "./IESASXVesting.sol";

import "./IERC20.sol";

import "./PrizePoolV2Errors.sol";

import "./UniswapWrapper.sol";

import "./ICompLike.sol";

import "./IOracle.sol";

import "./IPrizePoolV2.sol";
import "./IDrawBeacon.sol";
import "./ITicket.sol";

import "./Ownable.sol";

import "./Constants.sol";

/**
 * @title  Asymetrix Protocol V2 PrizePoolV2
 * @author Asymetrix Protocol Inc Team
 * @notice Escrows assets and deposits them into a yield source. Exposes interest to Prize Flush. Users deposit and
 *         withdraw from thi contract to participate in Prize Pool V2. Accounting is managed using Controlled Tokens,
 *         whose mint and burn functions can only be called by this contract. Must be inherited to provide specific
 *         yield-bearing asset control, such as Compound cTokens.
 */
abstract contract PrizePoolV2 is
    Initializable,
    IPrizePoolV2,
    Ownable,
    Constants,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ERC165CheckerUpgradeable for address;
    using SafeCastUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20 for IERC20;

    //************************************************************************//
    //                                V1                                      //
    //************************************************************************//

    /// @notice Semver Version.
    string public constant VERSION = "4.0.0";

    /// @notice Accuracy for calculations.
    uint256 internal constant ACCURACY = 10 ** 18;

    /// @notice Prize Pool ticket. Can only be set once by calling `setTicket()`.
    ITicket internal ticket;

    /// @notice Draw Beacon contract. Can only be set once by calling `setDrawBeacon()`.
    IDrawBeacon internal drawBeacon;

    /// @notice ASX token contract. Can only be set once in the constructor.
    IERC20Upgradeable internal rewardToken;

    /// @notice The Prize Flush that this Prize Pool V2 is bound to.
    address internal prizeFlush;

    /// @notice The reward last updated timestamp.
    uint64 internal lastUpdated;

    /// @notice The reward claim interval, in seconds.
    /// @dev Unused in PrizePoolV2
    uint32 internal claimInterval;

    /// @notice The total amount of tickets a user can hold.
    uint256 internal balanceCap;

    /// @notice The total amount of funds that the prize pool can hold.
    uint256 internal liquidityCap;

    /// @notice The awardable balance.
    uint256 internal _currentAwardBalance;

    /// @notice The reward per second that will be used in time of distribution of ASX tokens.
    /// @custom:oz-renamed-from rewardPerSecond
    uint256 internal asxRewardPerSecond;

    /// @notice The ASX reward per share coefficient.
    /// @custom:oz-renamed-from rewardPerShare
    uint256 internal asxRewardPerShare;

    /// @notice Stores information about users' stakes and rewards.
    mapping(address => UserStakeInfo) internal userStakeInfo;

    /// @notice The timestamp when ASX tokens distribution will finish.
    uint32 internal distributionEnd;

    /// @notice The duration after finishing of a draw when user can leave the protocol without fee charging (in stETH).
    uint32 internal freeExitDuration;

    /// @notice The timestamp of the deployment of this contract.
    uint32 internal deploymentTimestamp;

    /// @notice The timestamp of the first Lido's rebase that will take place after the deployment of this contract.
    uint32 internal firstLidoRebaseTimestamp;

    /// @notice The maximum claim interval, in seconds.
    /// @dev Unused in PrizePoolV2
    uint32 internal maxClaimInterval;

    /// @notice The APR of the Lido protocol, percentage with 2 decimals.
    uint16 internal lidoAPR;

    //************************************************************************//
    //                                V2                                      //
    //************************************************************************//

    /**
     * @notice esASX token contract. Can only be set once during initialization.
     */
    IERC20 public esAsx;

    /**
     * @notice RewardsBooster contract. Can only be set once during initialization.
     */
    IRewardsBooster public rewardsBooster;

    /**
     * @notice ESASXVesting contract. Used for creation of vestings in time of  esASX tokens claim. Can only be set once
     *         during initialization.
     */
    IESASXVesting public esAsxVesting;

    /**
     * @notice A wrapper contract address that helps to interact with Uniswap V3.
     */
    UniswapWrapper public uniswapWrapper;

    /**
     * @notice An oracle for ASX token that returns price of ASX token in WETH.
     */
    IOracle public asxOracle;

    /**
     * @notice The reward per second that will be used in time of distribution of esASX tokens.
     */
    uint256 public esAsxRewardPerSecond;

    /**
     * @notice The esASX reward per share coefficient.
     */
    uint256 public esAsxRewardPerShare;

    /**
     * @notice Amount of esASX tokens that are available for liquidation.
     */
    uint256 public availableForLiquidationEsAsx;

    /**
     * @notice WETH token address.
     */
    address public weth;

    /**
     * @notice Minimum threshold for partial liquidation of users' boosts.
     */
    uint16 public liquidationThreshold;

    /**
     * @notice A slippage tolerance to apply in time of swap 0f ETH for ASX.
     */
    uint16 public slippageTolerance;

    uint24 private constant UNISWAP_V3_POOL_FEE = 3000; // 0.3000%
    uint16 public constant ONE_HUNDRED_PERCENTS = 10000; // 100.00%

    /* ============ Modifiers ============ */

    /// @dev Function modifier to ensure caller is the prize-flush.
    modifier onlyPrizeFlush() {
        if (msg.sender != prizeFlush) revert PrizePoolV2Errors.OnlyPrizeFlush();
        _;
    }

    /// @dev Function modifier to ensure caller is the ticket.
    modifier onlyTicket() {
        if (msg.sender != address(ticket)) revert PrizePoolV2Errors.OnlyTicket();
        _;
    }

    /// @dev Function modifier to ensure the deposit amount does not exceed the liquidity cap (if set).
    modifier canAddLiquidity(uint256 _amount) {
        if (!_canAddLiquidity(_amount)) revert PrizePoolV2Errors.InvalidLiquidityCap();
        _;
    }

    /* ============ Initialize ============ */

    /**
     * @notice Deploy the Prize Pool V2 contract.
     * @param _esAsx esASX token address.
     * @param _rewardsBooster RewardsBooster contract address.
     * @param _esAsxVesting ESASXVesting contract address.
     * @param _uniswapWrapper A wrapper contract address that helps to interact with Uniswap V3.
     * @param _asxOracle An oracle for ASX token that returns price of ASX token in ETH.
     * @param _weth WETH token address.
     * @param _esAsxRewardPerSecond The reward per second that will be used in time of distribution of esASX tokens.
     * @param _liquidationThreshold Minimum threshold for partial liquidation of users' boosts.
     * @param _slippageTolerance A slippage tolerance to apply in time of swap of ETH for ASX.
     */
    function __PrizePoolV2_init_unchained(
        address _esAsx,
        address _rewardsBooster,
        address _esAsxVesting,
        address _uniswapWrapper,
        address _asxOracle,
        address _weth,
        uint256 _esAsxRewardPerSecond,
        uint16 _liquidationThreshold,
        uint16 _slippageTolerance
    ) internal onlyInitializing {
        _onlyContract(_esAsx);
        _onlyContract(_rewardsBooster);
        _onlyContract(_esAsxVesting);
        _setUniswapWrapper(_uniswapWrapper);
        _setAsxOracle(_asxOracle);
        _onlyContract(_weth);

        esAsx = IERC20(_esAsx);
        rewardsBooster = IRewardsBooster(_rewardsBooster);
        esAsxVesting = IESASXVesting(_esAsxVesting);
        weth = _weth;

        _setEsAsxRewardPerSecond(_esAsxRewardPerSecond);
        _setLiquidationThreshold(_liquidationThreshold);
        _setSlippageTolerance(_slippageTolerance);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizePoolV2
    function balance() external override returns (uint256) {
        return _balance();
    }

    /// @inheritdoc IPrizePoolV2
    function awardBalance() external view override returns (uint256) {
        return _currentAwardBalance;
    }

    /// @inheritdoc IPrizePoolV2
    function canAwardExternal(address _externalToken) external view override returns (bool) {
        return _canAwardExternal(_externalToken);
    }

    /// @inheritdoc IPrizePoolV2
    function isControlled(ITicket _controlledToken) external view override returns (bool) {
        return _isControlled(_controlledToken);
    }

    /// @inheritdoc IPrizePoolV2
    function getAccountedBalance() external view override returns (uint256) {
        return _ticketTotalSupply();
    }

    /// @inheritdoc IPrizePoolV2
    function getBalanceCap() external view override returns (uint256) {
        return balanceCap;
    }

    /// @inheritdoc IPrizePoolV2
    function getLiquidityCap() external view override returns (uint256) {
        return liquidityCap;
    }

    /// @inheritdoc IPrizePoolV2
    function getTicket() external view override returns (ITicket) {
        return ticket;
    }

    /// @inheritdoc IPrizePoolV2
    function getDrawBeacon() external view override returns (IDrawBeacon) {
        return drawBeacon;
    }

    /// @inheritdoc IPrizePoolV2
    function getRewardToken() external view override returns (IERC20Upgradeable) {
        return rewardToken;
    }

    /// @inheritdoc IPrizePoolV2
    function getPrizeFlush() external view override returns (address) {
        return prizeFlush;
    }

    /// @inheritdoc IPrizePoolV2
    function getToken() external view override returns (address) {
        return address(_token());
    }

    /// @inheritdoc IPrizePoolV2
    function getLastUpdated() external view override returns (uint64) {
        return lastUpdated;
    }

    /// @inheritdoc IPrizePoolV2
    function getAsxRewardPerSecond() external view override returns (uint256) {
        return asxRewardPerSecond;
    }

    /// @inheritdoc IPrizePoolV2
    function getAsxRewardPerShare() external view override returns (uint256) {
        return asxRewardPerShare;
    }

    /// @inheritdoc IPrizePoolV2
    function getFreeExitDuration() external view override returns (uint32) {
        return freeExitDuration;
    }

    /// @inheritdoc IPrizePoolV2
    function getDeploymentTimestamp() external view override returns (uint32) {
        return deploymentTimestamp;
    }

    /// @inheritdoc IPrizePoolV2
    function getFirstLidoRebaseTimestamp() external view override returns (uint32) {
        return firstLidoRebaseTimestamp;
    }

    /// @inheritdoc IPrizePoolV2
    function getLidoAPR() external view override returns (uint16) {
        return lidoAPR;
    }

    /// @inheritdoc IPrizePoolV2
    function getUserStakeInfo(address _user) external view override returns (UserStakeInfo memory) {
        return userStakeInfo[_user];
    }

    /// @inheritdoc IPrizePoolV2
    function getDistributionEnd() external view override returns (uint32) {
        return distributionEnd;
    }

    /// @inheritdoc IPrizePoolV2
    function getClaimableRewards(
        address _user
    ) external view override returns (uint256 _asxReward, uint256 _esAsxReward) {
        UserStakeInfo memory _userInfo = userStakeInfo[_user];
        uint256 _bal = ticket.balanceOf(_user);
        (uint256 _asxRewardPerShare, uint256 _esAsxRewardPerShare) = _getUpdatedAsxAndEsAsxRewardPerShare();

        _asxReward = (_userInfo.reward + ((_bal * _asxRewardPerShare) - _userInfo.former)) / ACCURACY;
        _esAsxReward =
            (_userInfo.esAsxBoostableReward + ((_bal * _esAsxRewardPerShare) - _userInfo.esAsxFormer)) /
            ACCURACY;

        (uint32 _boost, bool _isAppliable) = rewardsBooster.getBoost(_user);

        if (_isAppliable) {
            _esAsxReward = (_esAsxReward * _boost) / 100;
        }

        _esAsxReward += _userInfo.esAsxBoostlessReward;
    }

    /// @inheritdoc IPrizePoolV2
    function captureAwardBalance() external override nonReentrant returns (uint256) {
        uint256 ticketTotalSupply = _ticketTotalSupply();
        uint256 currentAwardBalance = _currentAwardBalance;

        /**
         * It's possible for the balance to be slightly less due to rounding
         * errors in the underlying yield source
         */
        uint256 currentBalance = _balance();
        uint256 totalInterest = (currentBalance > ticketTotalSupply) ? currentBalance - ticketTotalSupply : 0;
        uint256 unaccountedPrizeBalance = (totalInterest > currentAwardBalance)
            ? totalInterest - currentAwardBalance
            : 0;

        if (unaccountedPrizeBalance > 0) {
            currentAwardBalance = totalInterest;
            _currentAwardBalance = currentAwardBalance;

            emit AwardCaptured(unaccountedPrizeBalance);
        }

        return currentAwardBalance;
    }

    /// @inheritdoc IPrizePoolV2
    function depositTo(address _to, uint256 _amount) external override nonReentrant canAddLiquidity(_amount) {
        _depositTo(msg.sender, _to, _amount);
    }

    /// @inheritdoc IPrizePoolV2
    function depositToAndDelegate(
        address _to,
        uint256 _amount,
        address _delegate
    ) external override nonReentrant canAddLiquidity(_amount) {
        _depositTo(msg.sender, _to, _amount);

        ticket.controllerDelegateFor(msg.sender, _delegate);
    }

    /// @notice Transfers tokens in from one user and mints tickets to another.
    /// @notice _operator The user to transfer tokens from.
    /// @notice _to The user to mint tickets to.
    /// @notice _amount The amount to transfer and mint.
    function _depositTo(address _operator, address _to, uint256 _amount) internal {
        if (!_canDeposit(_to, _amount)) revert PrizePoolV2Errors.InvalidBalanceCap();

        _updateReward();

        UserStakeInfo storage userInfo = userStakeInfo[_to];
        uint256 _asxRewardPerShare = asxRewardPerShare;
        uint256 _esAsxRewardPerShare = esAsxRewardPerShare;
        ITicket _ticket = ticket;
        uint256 _beforeTicketBalance = _ticket.balanceOf(_to);

        _token().safeTransferFrom(_operator, address(this), _amount);

        userInfo.reward += (_beforeTicketBalance * _asxRewardPerShare) - userInfo.former;
        userInfo.esAsxBoostableReward += (_beforeTicketBalance * _esAsxRewardPerShare) - userInfo.esAsxFormer;

        _mint(_to, _amount, _ticket);

        uint256 _afterTicketBalance = _ticket.balanceOf(_to);

        userInfo.former = _afterTicketBalance * _asxRewardPerShare;
        userInfo.esAsxFormer = _afterTicketBalance * _esAsxRewardPerShare;

        emit Deposited(_operator, _to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePoolV2
    function withdrawFrom(address _from, uint256 _amount) external override nonReentrant returns (uint256) {
        _updateReward();

        UserStakeInfo storage userInfo = userStakeInfo[_from];
        uint256 _asxRewardPerShare = asxRewardPerShare;
        uint256 _esAsxRewardPerShare = esAsxRewardPerShare;
        ITicket _ticket = ticket;
        uint256 _beforeTicketBalance = _ticket.balanceOf(_from);

        userInfo.reward += (_beforeTicketBalance * _asxRewardPerShare) - userInfo.former;
        userInfo.esAsxBoostableReward += (_beforeTicketBalance * _esAsxRewardPerShare) - userInfo.esAsxFormer;

        // Burn the tickets
        _ticket.controllerBurnFrom(msg.sender, _from, _amount);

        // Redeem the tickets
        uint256 _redeemed = _amount;
        uint256 _afterTicketBalance = _ticket.balanceOf(_from);

        userInfo.former = _afterTicketBalance * _asxRewardPerShare;
        userInfo.esAsxFormer = _afterTicketBalance * _esAsxRewardPerShare;

        if (
            drawBeacon.getNextDrawId() == 1 ||
            uint32(block.timestamp) - drawBeacon.getBeaconPeriodStartedAt() > freeExitDuration
        ) {
            uint256 _secondsNumber = uint256(_getSecondsNumberToPayExitFee(uint32(block.timestamp)));
            uint256 _percent = ((_secondsNumber * uint256(lidoAPR)) * 1 ether) / 31_536_000 / 10 ** 4;
            uint256 _actualRedeemed = (_redeemed * (1 ether - _percent)) / 1 ether;

            _redeemed = _actualRedeemed;
        }

        _token().safeTransfer(_from, _redeemed);

        emit Withdrawal(msg.sender, _from, _ticket, _amount, _redeemed, _amount - _redeemed);

        return _redeemed;
    }

    /// @inheritdoc IPrizePoolV2
    function updateUserRewardAndFormer(
        address _user,
        uint256 _beforeBalance,
        uint256 _afterBalance
    ) external override onlyTicket {
        _updateReward();

        UserStakeInfo storage userInfo = userStakeInfo[_user];
        uint256 _asxRewardPerShare = asxRewardPerShare;
        uint256 _esAsxRewardPerShare = esAsxRewardPerShare;

        userInfo.reward += (_beforeBalance * _asxRewardPerShare) - userInfo.former;
        userInfo.esAsxBoostableReward += (_beforeBalance * _esAsxRewardPerShare) - userInfo.esAsxFormer;

        userInfo.former = _afterBalance * _asxRewardPerShare;
        userInfo.esAsxFormer = _afterBalance * _esAsxRewardPerShare;
    }

    /// @inheritdoc IPrizePoolV2
    function claim(address _user) external override nonReentrant {
        _updateReward();

        UserStakeInfo storage userInfo = userStakeInfo[_user];
        uint256 _asxRewardPerShare = asxRewardPerShare;
        uint256 _esAsxRewardPerShare = esAsxRewardPerShare;
        uint256 _ticketBalance = ticket.balanceOf(_user);

        userInfo.reward += (_ticketBalance * _asxRewardPerShare) - userInfo.former;
        userInfo.esAsxBoostableReward += (_ticketBalance * _esAsxRewardPerShare) - userInfo.esAsxFormer;

        _claimEsAsxAndVest(userInfo, _user);

        userInfo.former = _ticketBalance * _asxRewardPerShare;
        userInfo.esAsxFormer = _ticketBalance * _esAsxRewardPerShare;
    }

    /// @inheritdoc IPrizePoolV2
    function liquidate(address[] calldata _users, uint256[] calldata _amounts) external payable override nonReentrant {
        if (_users.length != _amounts.length) revert PrizePoolV2Errors.InvalidArrayLength();

        _liquidate(_users, _amounts);
    }

    /// @inheritdoc IPrizePoolV2
    function award(address _to, uint256 _amount) external override onlyPrizeFlush {
        if (_amount == 0) {
            return;
        }

        uint256 currentAwardBalance = _currentAwardBalance;

        if (_amount > currentAwardBalance) revert PrizePoolV2Errors.AwardNotAvailable();

        unchecked {
            _currentAwardBalance = currentAwardBalance - _amount;
        }

        ITicket _ticket = ticket;

        _mint(_to, _amount, _ticket);

        emit Awarded(_to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePoolV2
    function transferExternalERC20(
        address _to,
        address _externalToken,
        uint256 _amount
    ) external override onlyPrizeFlush {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit TransferredExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePoolV2
    function awardExternalERC20(address _to, address _externalToken, uint256 _amount) external override onlyPrizeFlush {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit AwardedExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePoolV2
    function awardExternalERC721(
        address _to,
        address _externalToken,
        uint256[] calldata _tokenIds
    ) external override onlyPrizeFlush {
        if (!_canAwardExternal(_externalToken)) revert PrizePoolV2Errors.InvalidExternalToken();

        if (_tokenIds.length == 0) {
            return;
        }

        if (_tokenIds.length > MAX_TOKEN_IDS_LENGTH) revert PrizePoolV2Errors.InvalidArrayLength();

        uint256[] memory _awardedTokenIds = new uint256[](_tokenIds.length);
        bool hasAwardedTokenIds;

        for (uint256 i; i < _tokenIds.length; ++i) {
            try IERC721Upgradeable(_externalToken).safeTransferFrom(address(this), _to, _tokenIds[i]) {
                hasAwardedTokenIds = true;
                _awardedTokenIds[i] = _tokenIds[i];
            } catch (bytes memory error) {
                emit ErrorAwardingExternalERC721(error);
            }
        }
        if (hasAwardedTokenIds) {
            emit AwardedExternalERC721(_to, _externalToken, _awardedTokenIds);
        }
    }

    /// @inheritdoc IPrizePoolV2
    function setBalanceCap(uint256 _balanceCap) external override onlyOwner returns (bool) {
        _setBalanceCap(_balanceCap);

        return true;
    }

    /// @inheritdoc IPrizePoolV2
    function setLiquidityCap(uint256 _liquidityCap) external override onlyOwner {
        _setLiquidityCap(_liquidityCap);
    }

    /// @inheritdoc IPrizePoolV2
    function setTicket(ITicket _ticket) external override onlyOwner returns (bool) {
        if (address(_ticket) == address(0)) revert PrizePoolV2Errors.InvalidAddress();
        if (address(ticket) != address(0)) revert PrizePoolV2Errors.TicketAlreadySet();

        ticket = _ticket;

        emit TicketSet(_ticket);

        _setBalanceCap(type(uint256).max);

        return true;
    }

    /// @inheritdoc IPrizePoolV2
    function setDrawBeacon(IDrawBeacon _drawBeacon) external onlyOwner {
        if (address(_drawBeacon) == address(0)) revert PrizePoolV2Errors.InvalidAddress();

        drawBeacon = _drawBeacon;

        emit DrawBeaconSet(_drawBeacon);
    }

    /// @inheritdoc IPrizePoolV2
    function setPrizeFlush(address _prizeFlush) external onlyOwner {
        _setPrizeFlush(_prizeFlush);
    }

    /// @inheritdoc IPrizePoolV2
    function setAsxRewardPerSecond(uint256 _asxRewardPerSecond) external override onlyOwner {
        _setAsxRewardPerSecond(_asxRewardPerSecond);
    }

    /// @inheritdoc IPrizePoolV2
    function setEsAsxRewardPerSecond(uint256 _esAsxRewardPerSecond) external override onlyOwner {
        _setEsAsxRewardPerSecond(_esAsxRewardPerSecond);
    }

    /// @inheritdoc IPrizePoolV2
    function setLiquidationThreshold(uint16 _liquidationThreshold) external override onlyOwner {
        _setLiquidationThreshold(_liquidationThreshold);
    }

    /**
     * @notice Sets a new UniswapWrapper contract by an owner.
     * @param _newUniswapWrapper A new UniswapWrapper contract address.
     */
    function setUniswapWrapper(address _newUniswapWrapper) external onlyOwner {
        _setUniswapWrapper(_newUniswapWrapper);
    }

    /**
     * @notice Sets a new oracle for ASX token that returns price of ASX token in ETH by an owner.
     * @param _newAsxOracle A new oracle for ASX token that returns price of ASX token in ETH.
     */
    function setAsxOracle(address _newAsxOracle) external onlyOwner {
        _setAsxOracle(_newAsxOracle);
    }

    /**
     * @notice Sets a new slippage tolerance by an owner.
     * @param _newSlippageTolerance A new slippage tolerance.
     */
    function setSlippageTolerance(uint16 _newSlippageTolerance) external onlyOwner {
        _setSlippageTolerance(_newSlippageTolerance);
    }

    /// @inheritdoc IPrizePoolV2
    function setDistributionEnd(uint32 _newDistributionEnd) external onlyOwner {
        if (_newDistributionEnd < uint32(block.timestamp)) revert PrizePoolV2Errors.InvalidTimestamp();

        distributionEnd = _newDistributionEnd;
    }

    /// @inheritdoc IPrizePoolV2
    function setFreeExitDuration(uint32 _freeExitDuration) external override onlyOwner {
        _setFreeExitDuration(_freeExitDuration);
    }

    /// @inheritdoc IPrizePoolV2
    function setLidoAPR(uint16 _lidoAPR) external override onlyOwner {
        _setLidoAPR(_lidoAPR);
    }

    /// @inheritdoc IPrizePoolV2
    function compLikeDelegate(ICompLike _compLike, address _to) external override onlyOwner {
        if (_compLike.balanceOf(address(this)) > 0) {
            _compLike.delegate(_to);
        }
    }

    /// @inheritdoc IERC721ReceiverUpgradeable
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /* ============ Internal Functions ============ */

    /// @notice Transfer out `amount` of `externalToken` to recipient `to`.
    /// @dev Only awardable `externalToken` can be transferred out.
    /// @param _to Recipient address.
    /// @param _externalToken Address of the external asset token being transferred.
    /// @param _amount Amount of external assets to be transferred.
    /// @return `true` if transfer is successful.
    function _transferOut(address _to, address _externalToken, uint256 _amount) internal returns (bool) {
        if (!_canAwardExternal(_externalToken)) revert PrizePoolV2Errors.InvalidAddress();

        if (_amount == 0) {
            return false;
        }

        IERC20Upgradeable(_externalToken).safeTransfer(_to, _amount);

        return true;
    }

    /// @notice Called to mint controlled tokens.  Ensures that token listener callbacks are fired.
    /// @param _to The user who is receiving the tokens.
    /// @param _amount The amount of tokens they are receiving.
    /// @param _controlledToken The token that is going to be minted.
    function _mint(address _to, uint256 _amount, ITicket _controlledToken) internal {
        _controlledToken.controllerMint(_to, _amount);
    }

    /// @dev Checks if `user` can deposit in the Prize Pool based on the current balance cap.
    /// @param _user Address of the user depositing.
    /// @param _amount The amount of tokens to be deposited into the Prize Pool.
    /// @return True if the Prize Pool can receive the specified `amount` of tokens.
    function _canDeposit(address _user, uint256 _amount) internal view returns (bool) {
        uint256 _balanceCap = balanceCap;

        if (_balanceCap == type(uint256).max) return true;

        return (ticket.balanceOf(_user) + _amount <= _balanceCap);
    }

    /// @dev Checks if the Prize Pool can receive liquidity based on the current cap.
    /// @param _amount The amount of liquidity to be added to the Prize Pool.
    /// @return True if the Prize Pool can receive the specified amount of liquidity.
    function _canAddLiquidity(uint256 _amount) internal view returns (bool) {
        uint256 _liquidityCap = liquidityCap;

        if (_liquidityCap == type(uint256).max) return true;

        return (_ticketTotalSupply() + _amount <= _liquidityCap);
    }

    /// @dev Checks if a specific token is controlled by the Prize Pool.
    /// @param _controlledToken The address of the token to check.
    /// @return `true` if the token is a controlled token, `false` otherwise.
    function _isControlled(ITicket _controlledToken) internal view returns (bool) {
        return (ticket == _controlledToken);
    }

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @param _balanceCap New balance cap.
    function _setBalanceCap(uint256 _balanceCap) internal {
        balanceCap = _balanceCap;

        emit BalanceCapSet(_balanceCap);
    }

    /// @notice Allows the owner to set a liquidity cap for the pool.
    /// @param _liquidityCap New liquidity cap.
    function _setLiquidityCap(uint256 _liquidityCap) internal {
        if (address(ticket) != address(0)) {
            if (_liquidityCap < _ticketTotalSupply()) revert PrizePoolV2Errors.InvalidLiquidityCap();
        }

        liquidityCap = _liquidityCap;

        emit LiquidityCapSet(_liquidityCap);
    }

    /// @notice Sets the prize flush of the prize pool.
    /// @param _prizeFlush The new prize flush.
    function _setPrizeFlush(address _prizeFlush) internal {
        if (_prizeFlush == address(0)) revert PrizePoolV2Errors.InvalidAddress();

        prizeFlush = _prizeFlush;

        emit PrizeFlushSet(_prizeFlush);
    }

    /// @notice Sets the reward per second for the prize pool that will be used for ASX tokens distribution.
    /// @param _asxRewardPerSecond The new reward per second in ASX tokens.
    function _setAsxRewardPerSecond(uint256 _asxRewardPerSecond) internal {
        _updateReward();

        asxRewardPerSecond = _asxRewardPerSecond;

        emit AsxRewardPerSecondSet(_asxRewardPerSecond);
    }

    /// @notice Sets the reward per second for the prize pool that will be used for esASX tokens distribution.
    /// @param _esAsxRewardPerSecond The new reward per second in esASX tokens.
    function _setEsAsxRewardPerSecond(uint256 _esAsxRewardPerSecond) internal {
        _updateReward();

        esAsxRewardPerSecond = _esAsxRewardPerSecond;

        emit EsAsxRewardPerSecondSet(_esAsxRewardPerSecond);
    }

    /// @notice Sets a new liquidation threshold.
    /// @param _liquidationThreshold Minimum threshold for partial liquidation of users' boosts.
    function _setLiquidationThreshold(uint16 _liquidationThreshold) internal {
        if (_liquidationThreshold == 0 || _liquidationThreshold > ONE_HUNDRED_PERCENTS)
            revert PrizePoolV2Errors.InvalidLiquidationThreshold();

        liquidationThreshold = _liquidationThreshold;

        emit LiquidationThresholdSet(_liquidationThreshold);
    }

    /**
     * @notice Sets a new UniswapWrapper contract.
     * @param _newUniswapWrapper A new UniswapWrapper contract address.
     */
    function _setUniswapWrapper(address _newUniswapWrapper) private {
        _onlyContract(_newUniswapWrapper);

        uniswapWrapper = UniswapWrapper(_newUniswapWrapper);
    }

    /**
     * @notice Sets a new oracle for ASX token that reruns price of ASX token in ETH.
     * @param _newAsxOracle A new oracle for ASX token that reruns price of ASX token in ETH.
     */
    function _setAsxOracle(address _newAsxOracle) private {
        _onlyContract(_newAsxOracle);

        asxOracle = IOracle(_newAsxOracle);
    }

    /**
     * @notice Sets a new slippage tolerance.
     * @param _newSlippageTolerance A new slippage tolerance.
     */
    function _setSlippageTolerance(uint16 _newSlippageTolerance) private {
        if (_newSlippageTolerance == 0 || _newSlippageTolerance > ONE_HUNDRED_PERCENTS)
            revert PrizePoolV2Errors.InvalidSlippageTolerance();

        slippageTolerance = _newSlippageTolerance;
    }

    /// @notice Sets the free exit duration, in seconds.
    /// @param _freeExitDuration The duration after finishing of a draw when user can leave the protocol without fee
    ///                          charging (in stETH).
    function _setFreeExitDuration(uint32 _freeExitDuration) internal {
        freeExitDuration = _freeExitDuration;

        emit FreeExitDurationSet(_freeExitDuration);
    }

    /// @notice Set APR of the Lido protocol.
    /// @dev 10000 is equal to 100.00% (2 decimals). Zero (0) is a valid value.
    /// @param _lidoAPR An APR of the Lido protocol.
    function _setLidoAPR(uint16 _lidoAPR) internal {
        if (_lidoAPR > ONE_HUNDRED_PERCENTS) revert PrizePoolV2Errors.InvalidLidoAPR();

        lidoAPR = _lidoAPR;

        emit LidoAPRSet(_lidoAPR);
    }

    /// @notice The current total of tickets.
    /// @return Ticket total supply.
    function _ticketTotalSupply() internal view returns (uint256) {
        return ticket.totalSupply();
    }

    /// @dev Gets the current time as represented by the current block.
    /// @return The timestamp of the current block.
    function _currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Updates the reward during each deposit, withdraw and transfer.
    function _updateReward() internal {
        if (lastUpdated <= uint64(distributionEnd)) {
            (asxRewardPerShare, esAsxRewardPerShare) = _getUpdatedAsxAndEsAsxRewardPerShare();
            lastUpdated = uint64(block.timestamp);

            emit RewardUpdated(lastUpdated);
        }
    }

    /// @dev Calculates new ASX and esASX reward per share.
    /// @return _asxRewardPerShare Updated ASX reward per share.
    /// @return _esAsxRewardPerShare Updated esASX reward per share.
    function _getUpdatedAsxAndEsAsxRewardPerShare()
        internal
        view
        returns (uint256 _asxRewardPerShare, uint256 _esAsxRewardPerShare)
    {
        _asxRewardPerShare = asxRewardPerShare;
        _esAsxRewardPerShare = esAsxRewardPerShare;

        if (address(ticket) != address(0)) {
            uint256 _totalSupply = _ticketTotalSupply();

            if (_totalSupply != 0) {
                uint32 _distributionEnd = distributionEnd;
                uint64 _timeDelta = uint32(block.timestamp) > _distributionEnd
                    ? uint64(_distributionEnd) - lastUpdated
                    : uint64(block.timestamp) - lastUpdated;
                uint256 _asxReward = uint256(_timeDelta) * asxRewardPerSecond;
                uint256 _esAsxReward = uint256(_timeDelta) * esAsxRewardPerSecond;

                _asxRewardPerShare += (_asxReward * ACCURACY) / _totalSupply;
                _esAsxRewardPerShare += (_esAsxReward * ACCURACY) / _totalSupply;
            }
        }
    }

    /**
     * @notice Claims earned ASX tokens for the user and sends them to him.
     * @param userInfo A structure with stake user info.
     * @param _user A user for whom to claim the rewards in ASX tokens.
     */
    function _claimAsx(UserStakeInfo storage userInfo, address _user) private {
        uint256 _asxReward = userInfo.reward / ACCURACY;
        uint256 _rewardTokenBalance = rewardToken.balanceOf(address(this));

        if (_rewardTokenBalance < _asxReward) {
            _asxReward = _rewardTokenBalance;
        }

        if (_asxReward > 0) {
            userInfo.reward = userInfo.reward - (_asxReward * ACCURACY);
            userInfo.lastClaimed = uint32(block.timestamp);

            rewardToken.safeTransfer(_user, _asxReward);
        }
    }

    /**
     * @notice Claims earned esASX tokens for the user, applies a boost, and creates a new esASX vesting position for
     *         the user.
     * @param userInfo A structure with stake user info.
     * @param _user A user for whom to claim the rewards in esASX tokens.
     */
    function _claimEsAsxAndVest(UserStakeInfo storage userInfo, address _user) private {
        uint256 _esAsxReward = userInfo.esAsxBoostableReward / ACCURACY;
        uint256 _prevEsAsxReward = _esAsxReward;
        (uint32 _boost, bool _isAppliable) = rewardsBooster.getBoost(_user);
        uint256 _boostedEsAsxReward = (_esAsxReward * _boost) / 100;

        if (!_isAppliable) {
            availableForLiquidationEsAsx += _boostedEsAsxReward - _esAsxReward;
        } else {
            _esAsxReward = _boostedEsAsxReward;
        }

        _esAsxReward += userInfo.esAsxBoostlessReward;
        userInfo.esAsxBoostlessReward = 0;

        IERC20 _esAsx = esAsx;
        uint256 _esAsxBalance = _esAsx.balanceOf(address(this));

        if (_esAsxBalance < _esAsxReward) {
            userInfo.esAsxBoostlessReward = _esAsxReward - _esAsxBalance;
            _esAsxReward = _esAsxBalance;
        }

        IESASXVesting _esAsxVesting = esAsxVesting;

        userInfo.esAsxBoostableReward = userInfo.esAsxBoostableReward - (_prevEsAsxReward * ACCURACY);
        userInfo.esAsxLastClaimed = uint32(block.timestamp);

        uint256 _asxAvailable = _esAsxVesting.getWithdrawableASXAmount();

        if (_esAsxReward < _esAsxVesting.getMinVestingAmount() || _asxAvailable == 0) {
            userInfo.esAsxBoostlessReward += _esAsxReward;
        } else if (_esAsxReward <= _asxAvailable) {
            _esAsx.approve(address(_esAsxVesting), _esAsxReward);
            _esAsxVesting.createVestingPosition(_user, _esAsxReward);
        } else {
            _esAsx.approve(address(_esAsxVesting), _asxAvailable);
            _esAsxVesting.createVestingPosition(_user, _asxAvailable);

            userInfo.esAsxBoostlessReward += _esAsxReward - _asxAvailable;
        }
    }

    /// @notice Liquidates a user boosted rewards in esASX tokens for the user.
    /// @param _users The array of the users for whom to execute a liquidation. If element in the array equals to zero
    ///               address liquidation will be executed for esSEX tokens from `availableForLiquidationEsAsx` pool
    /// @param _amounts An array of the amounts of esASX tokens to liquidate.
    function _liquidate(address[] calldata _users, uint256[] calldata _amounts) private {
        _updateReward();

        uint256 _totalAmountToLiquidate;

        for (uint256 i = 0; i < _users.length; i++) {
            if (_users[i] == address(0)) {
                if (_amounts[i] > availableForLiquidationEsAsx) revert PrizePoolV2Errors.NothingToLiquidate();

                _totalAmountToLiquidate += _amounts[i];

                availableForLiquidationEsAsx -= _amounts[i];
            } else {
                (uint32 _boost, bool _isAppliable) = rewardsBooster.getBoost(_users[i]);

                if (_isAppliable || _boost <= 100) revert PrizePoolV2Errors.NothingToLiquidate();

                UserStakeInfo storage userInfo = userStakeInfo[_users[i]];
                uint256 _esAsxRewardPerShare = esAsxRewardPerShare;
                uint256 _ticketBalance = ticket.balanceOf(_users[i]);

                userInfo.esAsxBoostableReward += (_ticketBalance * _esAsxRewardPerShare) - userInfo.esAsxFormer;

                uint256 _esAsxReward = userInfo.esAsxBoostableReward / ACCURACY;
                uint256 _boostedEsAsxReward = (_esAsxReward * _boost) / 100;
                uint256 _availableForLiquidationEsAsx = _boostedEsAsxReward - _esAsxReward;

                if (_amounts[i] > _availableForLiquidationEsAsx) revert PrizePoolV2Errors.InvalidLiquidationAmount();

                if (_amounts[i] < (_availableForLiquidationEsAsx * liquidationThreshold) / ONE_HUNDRED_PERCENTS)
                    revert PrizePoolV2Errors.TooSmallLiquidationAmount();

                _totalAmountToLiquidate += _amounts[i];

                availableForLiquidationEsAsx += _availableForLiquidationEsAsx - _amounts[i];

                userInfo.esAsxBoostlessReward += _esAsxReward;
                userInfo.esAsxBoostableReward = userInfo.esAsxBoostableReward - (_esAsxReward * ACCURACY);
                userInfo.esAsxFormer = _ticketBalance * _esAsxRewardPerShare;
            }
        }

        _liquidateESASX(_totalAmountToLiquidate);
    }

    /**
     * @notice Liquidates a specified amount of esASX tokens.
     * @param _amount An amount of esASX tokens to liquidate.
     */
    function _liquidateESASX(uint256 _amount) private {
        if (_amount == 0) revert PrizePoolV2Errors.InvalidLiquidationAmount();

        IESASXVesting _esAsxVesting = esAsxVesting;
        uint256 _asxAvailable = _esAsxVesting.getWithdrawableASXAmount();

        if (_amount > _asxAvailable) revert PrizePoolV2Errors.NothingToLiquidate();

        address _asx = address(rewardToken);

        if (msg.value == 0) {
            uint256 _asxAmountToPayAndBurn = _amount >> 1;

            IERC20(_asx).safeTransferFrom(msg.sender, address(this), _asxAmountToPayAndBurn);
            _buybackAndBurn(0, _asxAmountToPayAndBurn);
        } else {
            IOracle _asxOracle = asxOracle;
            uint256 _asxPriceInWeth = uint256(_asxOracle.latestAnswer());
            uint256 _ethNeeded = ((_asxPriceInWeth * _amount) >> 1) / (10 ** _asxOracle.decimals());

            if (msg.value > _ethNeeded) {
                payable(msg.sender).transfer(msg.value - _ethNeeded);
            } else {
                if (msg.value != _ethNeeded) revert PrizePoolV2Errors.NotEnoughETH();
            }

            _buybackAndBurn(_ethNeeded, 0);
        }

        esAsx.approve(address(_esAsxVesting), _amount);
        _esAsxVesting.createVestingPosition(msg.sender, _amount);
    }

    /**
     * @notice Swaps ETH for ASX and burns output ASX tokens.
     * @param _ethAmount An amount of ETH to swap for ASX.
     * @param _asxAmount An amount of ASX to burn with swapped ASX.
     */
    function _buybackAndBurn(uint256 _ethAmount, uint256 _asxAmount) internal {
        uint256 _swappedAsxAmount;
        address _asx = address(rewardToken);

        if (_ethAmount > 0) {
            IOracle _asxOracle = asxOracle;
            uint256 _asxPriceInEth = (uint256(_asxOracle.latestAnswer()) * 1e18) / 10 ** _asxOracle.decimals();
            uint256 _amountOut = _ethAmount / _asxPriceInEth;
            uint256 _amountOutMin = _amountOut - ((_amountOut * slippageTolerance) / ONE_HUNDRED_PERCENTS);

            _swappedAsxAmount = uniswapWrapper.swapSingle{ value: _ethAmount }(
                _asx,
                UNISWAP_V3_POOL_FEE,
                _ethAmount,
                _amountOutMin
            );
        }

        uint256 _asxAmountToBurn = _swappedAsxAmount + _asxAmount;

        if (_asxAmountToBurn > 0) ERC20BurnableUpgradeable(_asx).burn(_asxAmountToBurn);
    }

    /// @notice Calculates a number of seconds for which the user has to pay the exit fee.
    /// @dev If Lido's rebase operatio didn't happen yet, calculates the seconds difference between contract's
    ///      deployment timestamp and user's current withdraw timestamp.
    /// @dev If at least one Lido's rebase operation took place, calculates the seconds difference between last Lido's
    ///      rebase timestamp and user's current withdraw timestamp.
    /// @param _withdrawTimestamp The timestamp of the withdraw transaction.
    /// @return The number of seconds for which the user has to pay the exit fee.
    function _getSecondsNumberToPayExitFee(uint32 _withdrawTimestamp) private view returns (uint32) {
        uint32 _firstLidoRebaseTimestamp = firstLidoRebaseTimestamp;

        if (_withdrawTimestamp < _firstLidoRebaseTimestamp) {
            return _withdrawTimestamp - deploymentTimestamp;
        } else {
            return _withdrawTimestamp - _getLastLidoRebaseTimestamp(_firstLidoRebaseTimestamp, _withdrawTimestamp);
        }
    }

    /**
     * @notice Checks if an address is a contract.
     * @param _contract An address to check.
     */
    function _onlyContract(address _contract) private view {
        if (!_contract.isContract()) revert PrizePoolV2Errors.NotContract();
    }

    /// @notice Calculates Lido's last rebase timestamp using Lido's first rebase timestamp.
    /// @param _firstLidoRebaseTimestamp The timestamp of Lido's first rebase operation.
    /// @param _actionTimestamp The timestamp of an operation for which to calculate Lido's last rebase timestamp.
    /// @return The Lido's last rebase timestamp.
    function _getLastLidoRebaseTimestamp(
        uint32 _firstLidoRebaseTimestamp,
        uint32 _actionTimestamp
    ) private pure returns (uint32) {
        uint32 _secondsPerDay = 86_400;
        uint32 _daysDiff = (_actionTimestamp - _firstLidoRebaseTimestamp) / _secondsPerDay;

        return _firstLidoRebaseTimestamp + (_daysDiff * _secondsPerDay);
    }

    /* ============ Abstract Contract Implementatiton ============ */

    /// @notice Determines whether the passed token can be transferred out as an external award.
    /// @dev Different yield sources will hold the deposits as another kind of token: such a Compound's cToken. The
    ///      prize flush should not be allowed to move those tokens.
    /// @dev Should be implemented in a child contract during the inheritance.
    /// @param _externalToken The address of the token to check.
    /// @return `true` if the token may be awarded, `false` otherwise.
    function _canAwardExternal(address _externalToken) internal view virtual returns (bool);

    /// @notice Returns the ERC20 asset token used for deposits.
    /// @dev Should be implemented in a child contract during the inheritance.
    /// @return The ERC20 asset token.
    function _token() internal view virtual returns (IERC20Upgradeable);

    /// @notice Returns the total balance (in asset tokens). This includes the deposits and interest.
    /// @dev Should be implemented in a child contract during the inheritance.
    /// @return The underlying balance of asset tokens.
    function _balance() internal virtual returns (uint256);

    uint256[36] private __gap;
}
