// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IETokenFactory.sol";
import "./IEToken.sol";
import "./IEPool.sol";
import "./ControllerMixin.sol";
import "./ChainlinkMixin.sol";
import "./TokenUtils.sol";
import "./Math.sol";
import "./EPoolLibrary.sol";

contract EPool is ControllerMixin, ChainlinkMixin, IEPool {
    using SafeERC20 for IERC20;
    using TokenUtils for IERC20;
    using TokenUtils for IEToken;

    uint256 public constant FEE_RATE_LIMIT = 0.5e18;
    uint256 public constant TRANCHE_LIMIT = 5;

    IETokenFactory public immutable eTokenFactory;

    IERC20 public immutable override tokenA;
    IERC20 public immutable override tokenB;
    // scaling factor for TokenA and TokenB
    // assuming decimals can't be changed for both token
    uint256 public immutable override sFactorA;
    uint256 public immutable override sFactorB;

    mapping(address => Tranche) public tranches;
    address[] public tranchesByIndex;

    // rebalancing strategy
    uint256 public override rebalanceMinRDiv;
    uint256 public override rebalanceInterval;
    uint256 public override lastRebalance;

    // fees
    uint256 public override feeRate;
    uint256 public override cumulativeFeeA;
    uint256 public override cumulativeFeeB;

    event AddedTranche(address indexed eToken);
    event RebalancedTranches(uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv);
    event IssuedEToken(address indexed eToken, uint256 amount, uint256 amountA, uint256 amountB, address user);
    event RedeemedEToken(address indexed eToken, uint256 amount, uint256 amountA, uint256 amountB, address user);
    event SetMinRDiv(uint256 minRDiv);
    event SetRebalanceInterval(uint256 interval);
    event SetFeeRate(uint256 feeRate);
    event TransferFees(address indexed feesOwner, uint256 cumulativeFeeA, uint256 cumulativeFeeB);
    event RecoveredToken(address token, uint256 amount);

    /**
     * @dev Token with higher precision should be set as TokenA for max. precision
     * @param _controller Address of Controller
     * @param _eTokenFactory Address of the EToken factory
     * @param _tokenA Address of TokenA
     * @param _tokenB Address of TokenB
     * @param _aggregator Address of the exchange rate aggregator
     * @param inverseRate Bool indicating whether rate returned from aggregator should be inversed (1/rate)
     */
    constructor(
        IController _controller,
        IETokenFactory _eTokenFactory,
        IERC20 _tokenA,
        IERC20 _tokenB,
        address _aggregator,
        bool inverseRate
    ) ControllerMixin(_controller) ChainlinkMixin(_aggregator, inverseRate, EPoolLibrary.sFactorI) {
        eTokenFactory = _eTokenFactory;
        (tokenA, tokenB) = (_tokenA, _tokenB);
        (sFactorA, sFactorB) = (10**_tokenA.decimals(), 10**_tokenB.decimals());
    }

    /**
     * @notice Returns the address of the current Aggregator which provides the exchange rate between TokenA and TokenB
     * @return Address of aggregator
     */
    function getController() external view override returns (address) {
        return address(controller);
    }

    /**
     * @notice Updates the Controller
     * @dev Can only called by an authorized sender
     * @param _controller Address of the new Controller
     * @return True on success
     */
    function setController(address _controller) external override onlyDao("EPool: not dao") returns (bool) {
        _setController(_controller);
        return true;
    }

    /**
     * @notice Returns the price of TokenA denominated in TokenB
     * @return current exchange rate
     */
    function getRate() external view override returns (uint256) {
        return _rate();
    }

    /**
     * @notice Returns the address of the current Aggregator which provides the exchange rate between TokenA and TokenB
     * @return Address of aggregator
     */
    function getAggregator() external view override returns (address) {
        return address(aggregator);
    }

    /**
     * @notice Updates the Aggregator which provides the the exchange rate between TokenA and TokenB
     * @dev Can only called by an authorized sender. Setting the aggregator to 0x0 disables rebalancing
     * and issuance of new EToken and redeeming TokenA and TokenB is based on the users current share of EToken.
     * @param _aggregator Address of the new exchange rate aggregator
     * @param inverseRate Bool indicating whether rate returned from aggregator should be inversed (1/rate)
     * @return True on success
     */
    function setAggregator(
        address _aggregator,
        bool inverseRate
    ) external override onlyDao("EPool: not dao") returns (bool) {
        _setAggregator(_aggregator, inverseRate);
        return true;
    }

    /**
     * @notice Set min. deviation (in percentage scaled by 1e18) required for triggering a rebalance
     * @dev Can only be called by an authorized sender
     * @param minRDiv min. ratio deviation
     * @return True on success
     */
    function setMinRDiv(
        uint256 minRDiv
    ) external onlyDao("EPool: not dao") returns (bool) {
        rebalanceMinRDiv = minRDiv;
        emit SetMinRDiv(minRDiv);
        return true;
    }

    /**
     * @notice Set frequency of rebalances
     * @dev Can only be called by an authorized sender
     * @param interval rebalance interval
     * @return True on success
     */
    function setRebalanceInterval(
        uint256 interval
    ) external onlyDao("EPool: not dao") returns (bool) {
        rebalanceInterval = interval;
        emit SetRebalanceInterval(interval);
        return true;
    }

    /**
     * @notice Sets the fee rate
     * @dev Can only be called by the dao
     * @param _feeRate fee rate
     * @return True on success
     */
    function setFeeRate(uint256 _feeRate) external override onlyDao("EPool: not dao") returns (bool) {
        require(_feeRate <= FEE_RATE_LIMIT, "EPool: above fee rate limit");
        feeRate = _feeRate;
        emit SetFeeRate(_feeRate);
        return true;
    }

    /**
     * @notice Transfers the accumulated fees in TokenA and TokenB to feesOwner
     * @return True on success
     */
    function transferFees() external override returns (bool) {
        (uint256 _cumulativeFeeA, uint256 _cumulativeFeeB) = (cumulativeFeeA, cumulativeFeeB);
        (cumulativeFeeA, cumulativeFeeB) = (0, 0);
        tokenA.safeTransfer(controller.feesOwner(), _cumulativeFeeA);
        tokenB.safeTransfer(controller.feesOwner(), _cumulativeFeeB);
        emit TransferFees(controller.feesOwner(), _cumulativeFeeA, _cumulativeFeeB);
        return true;
    }

    /**
     * @notice Returns the tranche data for a EToken
     * @param eToken Address of the EToken
     * @return Tranche
     */
    function getTranche(address eToken) external view override returns(Tranche memory) {
        return tranches[eToken];
    }

    /**
     * @notice Returns the all tranches of the EPool
     * @return _tranches Tranches
     */
    function getTranches() external view override returns(Tranche[] memory _tranches) {
        _tranches = new Tranche[](tranchesByIndex.length);
        for (uint256 i = 0; i < tranchesByIndex.length; i++) {
            _tranches[i] = tranches[tranchesByIndex[i]];
        }
    }

    /**
     * @notice Adds a new tranche to the EPool
     * @dev Can only called by an authorized sender
     * @param targetRatio Target ratio between reserveA and reserveB as reserveValueA/reserveValueB
     * @param eTokenName Name of the tranches EToken
     * @param eTokenSymbol Symbol of the tranches EToken
     * @return True on success
     */
    function addTranche(
        uint256 targetRatio,
        string memory eTokenName,
        string memory eTokenSymbol
    ) external override onlyDao("EPool: not dao") returns (bool) {
        require(tranchesByIndex.length < TRANCHE_LIMIT, "EPool: max. tranche count");
        require(targetRatio != 0, "EPool: targetRatio == 0");
        IEToken eToken = eTokenFactory.createEToken(eTokenName, eTokenSymbol);
        tranches[address(eToken)] = Tranche(eToken, 10**eToken.decimals(), 0, 0, targetRatio);
        tranchesByIndex.push(address(eToken));
        emit AddedTranche(address(eToken));
        return true;
    }

    function _trancheDelta(
        Tranche storage t, uint256 fracDelta
    ) internal view returns (uint256 deltaA, uint256 deltaB, uint256 rChange) {
        uint256 rate = _rate();
        (uint256 _deltaA, uint256 _deltaB, uint256 _rChange) = EPoolLibrary.trancheDelta(
            t, rate, sFactorA, sFactorB
        );
        (deltaA, deltaB, rChange) = (
            fracDelta * _deltaA / EPoolLibrary.sFactorI, fracDelta * _deltaB / EPoolLibrary.sFactorI, _rChange
        );
    }

    /**
     * @notice Rebalances all tranches based on the current rate
     */
    function _rebalanceTranches(
        uint256 fracDelta
    ) internal returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv) {
        require(fracDelta <= EPoolLibrary.sFactorI, "EPool: fracDelta > 1.0");
        uint256 totalReserveA;
        int256 totalDeltaA;
        int256 totalDeltaB;
        for (uint256 i = 0; i < tranchesByIndex.length; i++) {
            Tranche storage t = tranches[tranchesByIndex[i]];
            totalReserveA += t.reserveA;
            (uint256 _deltaA, uint256 _deltaB, uint256 _rChange) = _trancheDelta(t, fracDelta);
            if (_rChange == 0) {
                (t.reserveA, t.reserveB) = (t.reserveA - _deltaA, t.reserveB + _deltaB);
                (totalDeltaA, totalDeltaB) = (totalDeltaA - int256(_deltaA), totalDeltaB + int256(_deltaB));
            } else {
                (t.reserveA, t.reserveB) = (t.reserveA + _deltaA, t.reserveB - _deltaB);
                (totalDeltaA, totalDeltaB) = (totalDeltaA + int256(_deltaA), totalDeltaB - int256(_deltaB));
            }
        }
        if (totalDeltaA > 0 && totalDeltaB < 0)  {
            (deltaA, deltaB, rChange) = (uint256(totalDeltaA), uint256(-totalDeltaB), 1);
        } else if (totalDeltaA < 0 && totalDeltaB > 0) {
            (deltaA, deltaB, rChange) = (uint256(-totalDeltaA), uint256(totalDeltaB), 0);
        }
        rDiv = (totalReserveA == 0) ? 0 : deltaA * EPoolLibrary.sFactorI / totalReserveA;
        emit RebalancedTranches(deltaA, deltaB, rChange, rDiv);
    }

    /**
     * @notice Rebalances all tranches based on the current rate
     * @dev Can be overriden contract inherting EPool for custom logic during rebalancing
     * @param fracDelta Fraction of the delta of deltaA or deltaB to rebalance
     * @return deltaA Rebalanced delta of reserveA
     * @return deltaB Rebalanced delta of reserveB
     * @return rChange 0 for deltaA <= 0 and deltaB >= 0, 1 for deltaA > 0 and deltaB < 0 (trancheDelta method)
     * @return rDiv Deviation from target in percentage (1e18)
     */
    function rebalance(
        uint256 fracDelta
    ) external virtual override returns (uint256 deltaA, uint256 deltaB, uint256 rChange, uint256 rDiv) {
        (deltaA, deltaB, rChange, rDiv) = _rebalanceTranches(fracDelta);
        require(rDiv >= rebalanceMinRDiv, "EPool: minRDiv not met");
        require(block.timestamp >= lastRebalance + rebalanceInterval, "EPool: within interval");
        lastRebalance = block.timestamp;
        if (rChange == 0) {
            tokenA.safeTransfer(msg.sender, deltaA);
            tokenB.safeTransferFrom(msg.sender, address(this), deltaB);
        } else {
            tokenA.safeTransferFrom(msg.sender, address(this), deltaA);
            tokenB.safeTransfer(msg.sender, deltaB);
        }
    }

    /**
     * @notice Issues EToken by depositing TokenA and TokenB proportionally to the current ratio
     * @dev Requires setting allowance for TokenA and TokenB
     * @param eToken Address of the eToken of the tranche
     * @param amount Amount of EToken to redeem
     * @return amountA Amount of TokenA deposited
     * @return amountB Amount of TokenB deposited
     */
    function issueExact(
        address eToken,
        uint256 amount
    ) external override issuanceNotPaused("EPool: issuance paused") returns (uint256 amountA, uint256 amountB) {
        Tranche storage t = tranches[eToken];
        (amountA, amountB) = EPoolLibrary.tokenATokenBForEToken(t, amount, _rate(), sFactorA, sFactorB);
        (t.reserveA, t.reserveB) = (t.reserveA + amountA, t.reserveB + amountB);
        t.eToken.mint(msg.sender, amount);
        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);
        emit IssuedEToken(eToken, amount, amountA, amountB, msg.sender);
    }

    /**
     * @notice Redeems EToken for TokenA and TokenB proportionally to the current ratio
     * @dev Requires setting allowance for EToken
     * @param eToken Address of the eToken of the tranche
     * @param amount Amount of EToken to redeem
     * @return amountA Amount of TokenA withdrawn
     * @return amountB Amount of TokenB withdrawn
     */
    function redeemExact(
        address eToken,
        uint256 amount
    ) external override returns (uint256 amountA, uint256 amountB) {
        Tranche storage t = tranches[eToken];
        require(t.reserveA + t.reserveB > 0, "EPool: insufficient liquidity");
        require(amount <= t.eToken.balanceOf(msg.sender), "EPool: insufficient EToken");
        (amountA, amountB) = EPoolLibrary.tokenATokenBForEToken(t, amount, 0, sFactorA, sFactorB);
        (t.reserveA, t.reserveB) = (t.reserveA - amountA, t.reserveB - amountB);
        t.eToken.burn(msg.sender, amount);
        if (feeRate != 0) {
            (uint256 feeA, uint256 feeB) = EPoolLibrary.feeAFeeBForTokenATokenB(amountA, amountB, feeRate);
            (cumulativeFeeA, cumulativeFeeB) = (cumulativeFeeA + feeA, cumulativeFeeB + feeB);
            (amountA, amountB) = (amountA - feeA, amountB - feeB);
        }
        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);
        emit RedeemedEToken(eToken, amount, amountA, amountB, msg.sender);
    }

    /**
     * @notice Recovers untracked amounts
     * @dev Can only called by an authorized sender
     * @param token Address of the token
     * @param amount Amount to recover
     * @return True on success
     */
    function recover(IERC20 token, uint256 amount) external override onlyDao("EPool: not dao") returns (bool) {
        uint256 reserved;
        if (token == tokenA) {
            for (uint256 i = 0; i < tranchesByIndex.length; i++) {
                reserved += tranches[tranchesByIndex[i]].reserveA;
            }
        } else if (token == tokenB) {
            for (uint256 i = 0; i < tranchesByIndex.length; i++) {
                reserved += tranches[tranchesByIndex[i]].reserveB;
            }
        }
        require(amount <= token.balanceOf(address(this)) - reserved, "EPool: no excess");
        token.safeTransfer(msg.sender, amount);
        emit RecoveredToken(address(token), amount);
        return true;
    }
}
