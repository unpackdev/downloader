// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "./LibAppStorage.sol";
import "./LibDistribution.sol";
import "./LibGetters.sol";
import "./LibRoundToken.sol";
import "./LibTradingFee.sol";
import "./Modifiers.sol";
import "./Math.sol";

import "./IERC20.sol";
import "./IERC721.sol";

import "./console.sol";

/// @title  AMM Facet
///
/// @author Test-in-Prod.
///
/// @notice The facet contract for the core to trade round tokens.
///
contract AMMFacet is Modifiers {
    AppStorage internal s;

    /// @notice The Swap Event.
    ///
    /// @param  _metaNftId      The MetaNFT ID
    /// @param  _sender         The address of the sender.
    /// @param  _baseIn         The amount of base tokens into the pool.
    /// @param  _baseInFee      The amount of base fee into the pool.
    /// @param  _roundIn        The amount of round tokens into the pool.
    /// @param  _roundInFee     The amount of round fee for the metaNFT owner.
    /// @param  _baseOut        The amount of base tokens out from the pool.
    /// @param  _baseOutFee     The amount of base fee out from the pool.
    /// @param  _roundOut       The amount of round tokens out from the pool.
    /// @param  _roundOutFee    The amount of round fee for the metaNFT owner.
    ///
    event Swap(
        uint256 _metaNftId,
        address indexed _sender,
        uint128 _baseIn,
        uint128 _baseInFee,
        uint128 _roundIn,
        uint128 _roundInFee,
        uint128 _baseOut,
        uint128 _baseOutFee,
        uint128 _roundOut,
        uint128 _roundOutFee
    );

    function _modifyBaseReserve(uint256 _metaNftId, bool _isBuy, uint128 _actual, uint128 _virtual) private {
        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);

        /// Mint when it is a buy and burn when it is a sell.
        if(_isBuy) {
            pairInfo.actualBaseReserve += _actual;
            pairInfo.mintBaseReserve += _virtual;
        } else {
            pairInfo.actualBaseReserve -= _actual;
            pairInfo.mintBaseReserve -= _virtual;
        }
    }

    function _floorRounds(uint128 _in) private pure returns (uint128 _out) {
        /// Floor to the nearest round unit K.
        _out = _in / K * K;
    }

    /// @notice Retreives the balance of the given account address for the given pair ID.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _account    The addresss of the account.
    ///
    /// @return _balance    The balance.
    ///
    function balanceOf(uint256 _metaNftId, address _account) public view returns (uint128 _balance) {
        _balance = LibRoundToken._balanceOf(_metaNftId, _account);
    }


    /// @notice Retrieves the reserves of base ERC-20 and round tokens for the given pair ID.
    ///
    /// @param  _metaNftId      The pair identifier.
    ///
    /// @return _baseReserve    The base token reserve.
    /// @return _roundReserve   The round token reserve.
    ///
    function getReserves(uint256 _metaNftId) external view returns (uint128 _baseReserve, uint128 _roundReserve) {
        (_baseReserve, _roundReserve) = LibGetters._getPairReserves(_metaNftId);
    }

    function getBaseToken(uint256 _metaNftId) external view returns (address _baseToken) {
        _baseToken = LibGetters._getBaseToken(_metaNftId);
    }

    function _computeDeltaBase(
        uint256 _metaNftId,
        bool _isBuy,
        uint128 _deltaRound
    ) private view listed(_metaNftId) returns (
        uint128 _deltaBaseActual,
        uint128 _deltaBaseVirtual
    ) {
        /// Floor to the nearest round unit K.
        _deltaRound = _floorRounds(_deltaRound);

        PairInfo storage pairInfo = LibGetters._getPairInfo(_metaNftId);

        /// f_m(y_init)
        uint128 actualBase = pairInfo.actualBaseReserve;

        /// y_init
        uint128 initBase = pairInfo.initBaseReserve;

        /// h_m(y_init)
        uint128 mintBase = pairInfo.mintBaseReserve;

        /// m
        uint128 mintRound = (pairInfo.roundTotalSupply - INITIAL_ROUNDS);

        /// n = m +/- delta_n
        uint128 n = (_isBuy ? mintRound + _deltaRound : mintRound - _deltaRound) / K;

        /// g_n(y_init) - y_init
        uint256 newBase = Math.exp(uint256(INITIAL_ROUNDS + K) * 1 ether / INITIAL_ROUNDS, 2 * n) * initBase / 1 ether;
        newBase -= initBase;

        /// h_n(y_init) = x_init / (2 * x_init + K) * newBase
        uint256 newMintBase = INITIAL_ROUNDS * newBase / (2 * INITIAL_ROUNDS + K);

        /// f_n(y_init) = newBase - h_n(y_init)
        uint256 newActualBase = newBase - newMintBase;

        /// The absolute value is calculated for the deltas.
        if(_isBuy) {
            _deltaBaseActual = uint128(newActualBase - actualBase);
            _deltaBaseVirtual = uint128(newMintBase - mintBase);
        } else {
            _deltaBaseActual = uint128(actualBase - newActualBase);
            _deltaBaseVirtual = uint128(mintBase - newMintBase);
        }
    }

    /// @notice Quotes for buying a given number of round tokens with base tokens.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _roundOut   The amount of round tokens to get a quote.
    ///
    /// @return _baseIn     The amount of base tokens needed to purchase.
    ///
    function quoteBuyExactRounds(
        uint256 _metaNftId,
        uint128 _roundOut
    ) external view returns (
        uint128 _baseIn
    ) {
        /// Input validation.
        uint128 m = _roundOut / K;
        require(m > 0);

        uint128 roundOutBeforeFee = (m + LibTradingFee._calculateRoundFeeInverse(m)) * K;

        /// Compute the amount in.
        (_baseIn, ) = _computeDeltaBase(_metaNftId, true, roundOutBeforeFee);

        /// Apply the fee.
        _baseIn += LibTradingFee._calculateBaseFeeInverse(_baseIn);
    }

    /// @notice Quotes for buying round tokens with a given number of base tokens.
    ///
    /// @param  _baseIn     The amount of base tokens to get a quote.
    ///
    /// @return _roundOut   The amount of round tokens that can be purchased.
    ///
    /// @custom:warning     This method may return incorrect results. USE IT AT YOUR OWN RISK.
    ///
    function quoteBuyWithExactBases(
        uint256 _metaNftId,
        uint128 _baseIn
    ) public view listed(_metaNftId) returns (
        uint128 _roundOut
    ) {
        /// Input validation
        (uint256 baseReserve, uint256 roundReserve) = LibGetters._getPairReserves(_metaNftId);
        require(_baseIn > 0);

        /// Apply the fee.
        uint256 baseInAfterFee = _baseIn - LibTradingFee._calculateBaseFee(_baseIn);

        /// N * (2x + k) / ((x + k) y)
        uint256 frac = baseInAfterFee * (2 * roundReserve + K) * 1 ether / ((roundReserve + K) * baseReserve);

        /// floor(lg(1 + frac) / 2lgDenom)
        uint128 m = uint128(Math.log2(1 ether + frac) * 1 ether / LOG_DENOM / 1 ether);
        require(m > s.roundFeeNumerator);

        /// Apply the fee => r - ceil(r / fee_denominator) * fee_numerator
        m -= LibTradingFee._calculateRoundFee(m);

        /// m * K
        _roundOut = m * K;
    }

    /// @notice Quotes for selling a given number of round tokens with base tokens.
    ///
    /// @param  _roundIn  The amount of round tokens to get a quote.
    ///
    /// @return _baseOut  The amount of base tokens to be received.
    ///
    function quoteSellExactRounds(
        uint256 _metaNftId,
        uint128 _roundIn
    ) external view returns (
        uint128 _baseOut
    ) {
        /// Input validation.
        uint128 m = _roundIn / K;
        require(m > s.roundFeeNumerator);

        /// Apply the fee => r - ceil(r / fee_denominator) * fee_numerator
        uint128 roundInAfterFee = (m - LibTradingFee._calculateRoundFee(m)) * K;

        /// Compute the amount out.
        (_baseOut, ) = _computeDeltaBase(_metaNftId, false, roundInAfterFee);

        /// Apply the fee.
        _baseOut -= LibTradingFee._calculateBaseFee(_baseOut);
    }

    /// @notice Quotes for selling round tokens with a given number of base tokens.
    ///
    /// @param  _metaNftId  The pair identifier.
    /// @param  _baseOut    The amount of base tokens to get a quote.
    ///
    /// @return _roundIn    The amount of round tokens willing to sell.
    ///
    /// @custom:warning     This method may return incorrect results. USE IT AT YOUR OWN RISK.
    ///
    function quoteSellWithExactBases(
        uint256 _metaNftId,
        uint128 _baseOut
    ) public view listed(_metaNftId) returns (
        uint128 _roundIn
    ) {
        /// Input validation.
        (uint256 baseReserve, uint256 roundReserve) = LibGetters._getPairReserves(_metaNftId);
        require(_baseOut > 0);

        /// Apply the fee.
        uint256 baseOutBeforeFee = _baseOut + LibTradingFee._calculateBaseFeeInverse(_baseOut);
        require(baseOutBeforeFee <= LibGetters._getActualBaseReserve(_metaNftId));

        /// (x + k) y
        uint256 temp = uint256(roundReserve + K) * baseReserve;

        /// lg(((x + k) y) / ((x + k) y - N (2x + k))) / 2logDenom
        uint256 frac = temp * 1 ether / (temp - (baseOutBeforeFee * (2 * roundReserve + K)));
        uint128 m = uint128(Math.log2(frac) * 1 ether / LOG_DENOM);

        /// ceil(m)
        m = LibTradingFee._divCeil(m, 1 ether);

        /// Apply the fee.
        _roundIn = (m + LibTradingFee._calculateRoundFeeInverse(m)) * K;
    }

    function _buy(
        uint256 _metaNftId,
        uint128 _baseIn,
        uint128 _virtualBaseIn,
        uint128 _baseFee,
        uint128 _roundOut,
        uint128 _roundFee
    ) private {
        address baseToken = LibGetters._getPairInfo(_metaNftId).baseToken;
        uint256 beforeBalance = IERC20(baseToken).balanceOf(address(this));

        /// Transfer base tokens from the caller.
        require(
            IERC20(baseToken).transferFrom(msg.sender, address(this), _baseIn + _baseFee)
        );
        /// Check whether balance is as expected.
        require(
            beforeBalance + _baseIn + _baseFee == IERC20(baseToken).balanceOf(address(this))
        );

        s.cumulativeFees[baseToken] += _baseFee;

        /// Mint base tokens.
        _modifyBaseReserve(_metaNftId, true, _baseIn, _virtualBaseIn);

        /// Mint round tokens.
        LibRoundToken._mint(_metaNftId, msg.sender, _roundOut);
        LibRoundToken._mint(_metaNftId, IERC721(s.metaNFT).ownerOf(_metaNftId), _roundFee);

        /// Calculate PIL reward
        LibDistribution._updateReserve(_baseIn + _baseFee, _roundOut + _roundFee, true, _metaNftId, msg.sender);

        /// Emit the swap event.
        emit Swap(_metaNftId, msg.sender, _baseIn, _baseFee, 0, 0, 0, 0, _roundOut, _roundFee);
    }

    function _buyExactRoundsWithBases(
        uint256 _metaNftId,
        uint128 _maxBaseIn,
        uint128 _roundOut
    ) private lockInner(_metaNftId) returns (
        uint128 _baseInFinal,
        uint128 _roundOutFinal
    ) {
        /// Input validation.
        uint128 m = _roundOut / K;
        require(m > 0);

        /// The whole amount out is the final amount out.
        _roundOutFinal = m * K;

        /// Apply the fee.
        uint128 roundFee = LibTradingFee._calculateRoundFeeInverse(m) * K;
        uint128 roundOutBeforeFee = _roundOutFinal + roundFee;

        /// Compute the amount in before fee.
        (uint128 _baseIn, uint128 _virtualBaseIn) = _computeDeltaBase(_metaNftId, true, roundOutBeforeFee);

        /// Fee.
        uint128 baseFee = LibTradingFee._calculateBaseFeeInverse(_baseIn);

        /// It's caller's requirement.
        _baseInFinal = _baseIn + baseFee;
        require(_baseInFinal <= _maxBaseIn);

        /// Swap.
        _buy(_metaNftId, _baseIn, _virtualBaseIn, baseFee, _roundOutFinal, roundFee);
    }

    /// @notice Exchanges base tokens for an exact number of round tokens.
    ///
    /// @param  _metaNftId      The pair identifier.
    /// @param  _maxBaseIn      The maximum amount of base tokens willing to pay.
    /// @param  _roundOut       The amount of round tokens desired.
    /// @param  _deadline       The Unix timestamp that this transaction needs to succeed. The transaction reverts past
    ///                         this time.
    ///
    /// @return _baseInFinal    The final amount of base tokens spent for the transaction.
    /// @return _roundOutFinal  The final amount of rounds purchased in the transaction.
    ///
    function buyExactRoundsWithBases(
        uint256 _metaNftId,
        uint128 _maxBaseIn,
        uint128 _roundOut,
        uint64 _deadline
    ) public ensure(_deadline) onlyOneBlock returns (
        uint128 _baseInFinal,
        uint128 _roundOutFinal
    ) {
        return _buyExactRoundsWithBases(_metaNftId, _maxBaseIn, _roundOut);
    }

    /// @notice Exchanges an exact number of base tokens for round tokens.
    ///
    /// @param  _metaNftId      The pair identifier.
    /// @param  _baseIn         The amount of base tokens to purchase round tokens.
    /// @param  _minRoundOut    The minimum amount of round tokens desired.
    /// @param  _deadline       The Unix timestamp that this transaction needs to succeed. The transaction reverts past
    ///                         this time.
    ///
    /// @return _baseInFinal    The final amount of base tokens spent for the transaction.
    /// @return _roundOutFinal  The final amount of rounds purchased in the transaction.
    ///
    /// @custom:warning         This method may return incorrect results. USE IT AT YOUR OWN RISK.
    ///
    function buyRoundsWithExactBases(
        uint256 _metaNftId,
        uint128 _baseIn,
        uint128 _minRoundOut,
        uint64 _deadline
    ) external ensure(_deadline) lockOuter(_metaNftId) onlyOneBlock returns ( /// TODO when should we lock?
        uint128 _baseInFinal,
        uint128 _roundOutFinal
    ) {
        /// Compute the amount out.
        _roundOutFinal = quoteBuyWithExactBases(_metaNftId, _baseIn);

        /// It's caller's requirement.
        require(_roundOutFinal >= _minRoundOut);

        /// With exact round out final, swap with buyExactRopundsWithBases().
        return _buyExactRoundsWithBases(_metaNftId, _baseIn, _roundOutFinal);
    }

    function _sell(
        uint256 _metaNftId,
        uint128 _baseOut,
        uint128 _virtualBaseOut,
        uint128 _baseFee,
        uint128 _roundIn,
        uint128 _roundFee
    ) private {
        /// Burn round tokens.
        LibRoundToken._burn(_metaNftId, msg.sender, _roundIn);

        LibRoundToken._transfer(_metaNftId, msg.sender, IERC721(s.metaNFT).ownerOf(_metaNftId), _roundFee);

        /// Burn base tokens.
        _modifyBaseReserve(_metaNftId, false, _baseOut + _baseFee, _virtualBaseOut);

        address baseToken = LibGetters._getPairInfo(_metaNftId).baseToken;

        /// Transfer base tokens to msg.sender.
        require(IERC20(baseToken).transfer(msg.sender, _baseOut));

        s.cumulativeFees[baseToken] += _baseFee;

        LibDistribution._updateReserve(_baseOut, _roundIn, false, _metaNftId, msg.sender);

        /// Emit the swap event.
        emit Swap(_metaNftId, msg.sender, 0, 0, _roundIn, _roundFee, _baseOut, _baseFee, 0, 0);
    }

    function _sellExactRoundsWithBases(
        uint256 _metaNftId,
        uint128 _roundIn,
        uint128 _minBaseOut
    ) private lockInner(_metaNftId) returns (
        uint128 _roundInFinal,
        uint128 _baseOutFinal
    ) {
        /// Input validation.
        uint128 m = _roundIn / K;
        require(m > 0);

        /// The whole amount in is the final amount in.
        _roundInFinal = m * K;

        /// Apply the fee => r - ceil(r / fee_denominator) * fee_numerator
        uint128 roundFee = LibTradingFee._calculateRoundFee(m) * K;

        /// Compute the amount out before fee.
        (uint128 _amountBaseOut, uint128 _amountVirtualOut) = _computeDeltaBase(_metaNftId, false, _roundInFinal - roundFee);

        /// Fee.
        uint128 baseFee = LibTradingFee._calculateBaseFee(_amountBaseOut);

        /// It's caller's requirement.
        _baseOutFinal = _amountBaseOut - baseFee;
        require(_baseOutFinal >= _minBaseOut);

        /// Swap.
        _sell(_metaNftId, _baseOutFinal, _amountVirtualOut, baseFee, _roundInFinal - roundFee, roundFee);
    }

    /// @notice Exchanges an exact number of round tokens for base tokens.
    ///
    /// @param  _metaNftId      The pair identifier.
    /// @param  _roundIn        The amount of round tokens to sell.
    /// @param  _minBaseOut     The minimum amount of base tokens desired.
    /// @param  _deadline       The Unix timestamp that this transaction needs to succeed. The transaction reverts past
    ///                         this time.
    ///
    /// @return _roundInFinal   The final amount of rounds spent for the transaction.
    /// @return _baseOutFinal   The final amount of base tokens purchased in the transaction.
    ///
    function sellExactRoundsWithBases(
        uint256 _metaNftId,
        uint128 _roundIn,
        uint128 _minBaseOut,
        uint64 _deadline
    ) public ensure(_deadline) onlyOneBlock returns (
        uint128 _roundInFinal,
        uint128 _baseOutFinal
    ) {
        return _sellExactRoundsWithBases(_metaNftId, _roundIn, _minBaseOut);
    }

    /// @notice Exchanges round tokens for an exact number of base tokens.
    ///
    /// @param  _metaNftId      The pair identifier.
    /// @param  _maxRoundIn     The maximum amount of base tokens willing to sell.
    /// @param  _baseOut        The amount of base tokens desired.
    /// @param  _deadline       The Unix timestamp that this transaction needs to succeed. The transaction reverts past
    ///                         this time.
    ///
    /// @return _roundInFinal   The final amount of rounds spent for the transaction.
    /// @return _baseOutFinal   The final amount of base tokens purchased in the transaction.
    ///
    /// @custom:warning         This method may return incorrect results. USE IT AT YOUR OWN RISK.
    ///
    function sellRoundsWithExactBases(
        uint256 _metaNftId,
        uint128 _maxRoundIn,
        uint128 _baseOut,
        uint64 _deadline
    ) external ensure(_deadline) lockOuter(_metaNftId) onlyOneBlock returns (
        uint128 _roundInFinal,
        uint128 _baseOutFinal
    ) {
        /// Compute the amount in
        _roundInFinal = quoteSellWithExactBases(_metaNftId, _baseOutFinal);

        /// It's caller's requirement
        require(_roundInFinal <= _maxRoundIn);

        return _sellExactRoundsWithBases(_metaNftId, _roundInFinal, _baseOut);
    }

    function withdrawFees(address _baseToken) public {
        uint256 amount = s.cumulativeFees[_baseToken];
        s.cumulativeFees[_baseToken] = 0;
        require(IERC20(_baseToken).transfer(s.stakingContract, amount));
    }
}
