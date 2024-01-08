pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IExchangeRates.sol";
import "./IIssuer.sol";
import "./MixinSystemSettings.sol";
import "./Owned.sol";
import "./SafeDecimalMath.sol";

contract SynthetixSandboxAMM is Owned, MixinSystemSettings {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    using SafeERC20 for IERC20;

    bytes32 internal constant sUSD = "sUSD";

    struct ExchangeVolumeAtPeriod {
        uint64 time;
        uint192 volume;
    }

    ExchangeVolumeAtPeriod public lastAtomicVolume;

    constructor(address _owner, address _resolver) public Owned(_owner) MixinSystemSettings(_resolver) {}

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */

    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";

    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](2);
        newAddresses[0] = CONTRACT_EXRATES;
        newAddresses[1] = CONTRACT_ISSUER;
        addresses = combineArrays(existingAddresses, newAddresses);
    }

    function flexibleStoragePublic() public view returns (address) {
        return address(flexibleStorage());
    }

    function exchangeRates() public view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function issuer() public view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    /* ========== OWNERSHIP FUNCTIONS ========== */

    function sweep(address token, uint amount) external onlyOwner {
        IERC20(token).safeTransfer(owner, amount);
    }

    function sweepAll(address[] calldata tokens) external onlyOwner {
        for (uint i = 0; i < tokens.length; ++i) {
            IERC20 token = IERC20(tokens[i]);
            token.safeTransfer(owner, token.balanceOf(address(this)));
        }
    }

    function sweepEth() external onlyOwner {
        address payable payableOwner = address(uint160(owner));
        payableOwner.transfer(address(this).balance);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function exchangeAtomically(
        /*
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress,
        bytes32 trackingCode
        */
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived) {
        address from = msg.sender;
        address destinationAddress = msg.sender;

        uint fee;
        (amountReceived, fee) = _exchangeAtomically(
            from,
            sourceCurrencyKey,
            sourceAmount,
            destinationCurrencyKey,
            destinationAddress
        );

        /*
        _processTradingRewards(fee, destinationAddress);

        if (trackingCode != bytes32(0)) {
            _emitTrackingEvent(trackingCode, destinationCurrencyKey, amountReceived, fee);
        }
        */
    }

    /* ========== SETTINGS ========== */

    function atomicMaxVolumePerBlock() external view returns (uint) {
        return getAtomicMaxVolumePerBlock();
    }

    function atomicTwapWindow() external view returns (uint) {
        return getAtomicTwapWindow();
    }

    function atomicEquivalentForDexPricing(bytes32 currencyKey) external view returns (address) {
        return getAtomicEquivalentForDexPricing(currencyKey);
    }

    function atomicExchangeFeeRate(bytes32 currencyKey) external view returns (uint) {
        return getAtomicExchangeFeeRate(currencyKey);
    }

    function atomicPriceBuffer(bytes32 currencyKey) external view returns (uint) {
        return getAtomicPriceBuffer(currencyKey);
    }

    function atomicVolatilityConsiderationWindow(bytes32 currencyKey) external view returns (uint) {
        return getAtomicVolatilityConsiderationWindow(currencyKey);
    }

    function atomicVolatilityUpdateThreshold(bytes32 currencyKey) external view returns (uint) {
        return getAtomicVolatilityUpdateThreshold(currencyKey);
    }

    function feeRateForAtomicExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        external
        view
        returns (uint exchangeFeeRate)
    {
        exchangeFeeRate = _feeRateForAtomicExchange(sourceCurrencyKey, destinationCurrencyKey);
    }

    function getAmountsForAtomicExchange(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate
        )
    {
        (amountReceived, fee, exchangeFeeRate, , , ) = _getAmountsForAtomicExchangeMinusFees(
            sourceAmount,
            sourceCurrencyKey,
            destinationCurrencyKey
        );
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /// @dev See inline comments for replaced/mocked functionality from SIP-120
    function _exchangeAtomically(
        address from,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address destinationAddress
    ) internal returns (uint amountReceived, uint fee) {
        /*
        _ensureCanExchange(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);
        */

        // One of src/dest synth must be sUSD (checked below for gas optimization reasons)
        require(
            !exchangeRates().synthTooVolatileForAtomicExchange(
                sourceCurrencyKey == sUSD ? destinationCurrencyKey : sourceCurrencyKey
            ),
            "Src/dest synth too volatile"
        );

        /*
        uint sourceAmountAfterSettlement = _settleAndCalcSourceAmountRemaining(sourceAmount, from, sourceCurrencyKey);
        */
        uint sourceAmountAfterSettlement = sourceAmount;

        // If, after settlement the user has no balance left (highly unlikely), then return to prevent
        // emitting events of 0 and don't revert so as to ensure the settlement queue is emptied
        if (sourceAmountAfterSettlement == 0) {
            return (0, 0);
        }

        uint exchangeFeeRate;
        uint systemConvertedAmount;
        uint systemSourceRate;
        uint systemDestinationRate;

        // Note: also ensures the given synths are allowed to be atomically exchanged
        (
            amountReceived, // output amount with fee taken out (denominated in dest currency)
            fee, // fee amount (denominated in dest currency)
            exchangeFeeRate, // applied fee rate
            systemConvertedAmount, // current system value without fees (denominated in dest currency)
            systemSourceRate, // current system rate for src currency
            systemDestinationRate // current system rate for dest currency
        ) = _getAmountsForAtomicExchangeMinusFees(sourceAmountAfterSettlement, sourceCurrencyKey, destinationCurrencyKey);

        /*
        // SIP-65: Decentralized Circuit Breaker (checking current system rates)
        if (
            _suspendIfRateInvalid(sourceCurrencyKey, systemSourceRate) ||
            _suspendIfRateInvalid(destinationCurrencyKey, systemDestinationRate)
        ) {
            return (0, 0);
        }
        */

        // Sanity check atomic output's value against current system value (checking atomic rates)
        require(
            !_isDeviationAboveThreshold(systemConvertedAmount, amountReceived.add(fee)),
            "Atomic rate deviates too much"
        );

        // Ensure src/dest synth is sUSD and determine sUSD value of exchange
        uint sourceSusdValue;
        if (sourceCurrencyKey == sUSD) {
            // Use after-settled amount as this is amount converted (not sourceAmount)
            sourceSusdValue = sourceAmountAfterSettlement;
        } else if (destinationCurrencyKey == sUSD) {
            // In this case the systemConvertedAmount would be the fee-free sUSD value of the source synth
            sourceSusdValue = systemConvertedAmount;
        } else {
            revert("Src/dest synth must be sUSD");
        }

        // Check and update atomic volume limit
        _checkAndUpdateAtomicVolume(sourceSusdValue);

        /*
        // Note: We don't need to check their balance as the _convert() below will do a safe subtraction which requires
        // the subtraction to not overflow, which would happen if their balance is not sufficient.

        _convert(
            sourceCurrencyKey,
            from,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress,
            false // no vsynths
        );
        */
        _swap(
            sourceCurrencyKey,
            from,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress
        );

        // Note: we accrue the fee within this contract's own token balances, similar to other AMM pools

        /*
        // Remit the fee if required
        if (fee > 0) {
            // Normalize fee to sUSD
            // Note: `fee` is being reused to avoid stack too deep errors.
            fee = exchangeRates().effectiveValue(destinationCurrencyKey, fee, sUSD);

            // Remit the fee in sUSDs
            issuer().synths(sUSD).issue(feePool().FEE_ADDRESS(), fee);

            // Tell the fee pool about this
            feePool().recordFeePaid(fee);
        }

        // Note: As of this point, `fee` is denominated in sUSD.

        // Note: this update of the debt snapshot will not be accurate because the atomic exchange
        // was executed with a different rate than the system rate. To be perfect, issuance data,
        // priced in system rates, should have been adjusted on the src and dest synth.
        // The debt pool is expected to be deprecated soon, and so we don't bother with being
        // perfect here. For now, an inaccuracy will slowly accrue over time with increasing atomic
        // exchange volume.
        _updateSNXIssuedDebtOnExchange(
            [sourceCurrencyKey, destinationCurrencyKey],
            [systemSourceRate, systemDestinationRate]
        );

        // Let the DApps know there was a Synth exchange
        ISynthetixInternal(address(synthetix())).emitSynthExchange(
            from,
            sourceCurrencyKey,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress
        );

        // Emit separate event to track atomic exchanges
        ISynthetixInternal(address(synthetix())).emitAtomicSynthExchange(
            from,
            sourceCurrencyKey,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress
        );

        // No need to persist any exchange information, as no settlement is required for atomic exchanges
        */

        emit AtomicSynthExchange(
            from,
            sourceCurrencyKey,
            sourceAmountAfterSettlement,
            destinationCurrencyKey,
            amountReceived,
            destinationAddress
        );
    }

    function _swap(
        bytes32 sourceCurrencyKey,
        address from,
        uint sourceAmountAfterSettlement,
        bytes32 destinationCurrencyKey,
        uint amountReceived,
        address recipient
    ) internal {
        IERC20(address(issuer().synths(sourceCurrencyKey))).safeTransferFrom(
            from,
            address(this),
            sourceAmountAfterSettlement
        );
        IERC20(address(issuer().synths(destinationCurrencyKey))).safeTransfer(recipient, amountReceived);
    }

    function _checkAndUpdateAtomicVolume(uint sourceSusdValue) internal {
        uint currentVolume = uint(lastAtomicVolume.time) == block.timestamp
            ? uint(lastAtomicVolume.volume).add(sourceSusdValue)
            : sourceSusdValue;
        require(currentVolume <= getAtomicMaxVolumePerBlock(), "Surpassed volume limit");
        lastAtomicVolume.time = uint64(block.timestamp);
        lastAtomicVolume.volume = uint192(currentVolume); // Protected by volume limit check above
    }

    function _feeRateForAtomicExchange(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey)
        internal
        view
        returns (uint)
    {
        // Get the exchange fee rate as per destination currencyKey
        uint baseRate = getAtomicExchangeFeeRate(destinationCurrencyKey);
        if (baseRate == 0) {
            // If no atomic rate was set, fallback to the regular exchange rate
            baseRate = getExchangeFeeRate(destinationCurrencyKey);
        }

        return _calculateFeeRateFromExchangeSynths(baseRate, sourceCurrencyKey, destinationCurrencyKey);
    }

    function _calculateFeeRateFromExchangeSynths(
        uint exchangeFeeRate,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    ) internal pure returns (uint) {
        if (sourceCurrencyKey == sUSD || destinationCurrencyKey == sUSD) {
            return exchangeFeeRate;
        }

        // Is this a swing trade? long to short or short to long skipping sUSD.
        if (
            (sourceCurrencyKey[0] == 0x73 && destinationCurrencyKey[0] == 0x69) ||
            (sourceCurrencyKey[0] == 0x69 && destinationCurrencyKey[0] == 0x73)
        ) {
            // Double the exchange fee
            return exchangeFeeRate.mul(2);
        }

        return exchangeFeeRate;
    }

    function _getAmountsForAtomicExchangeMinusFees(
        uint sourceAmount,
        bytes32 sourceCurrencyKey,
        bytes32 destinationCurrencyKey
    )
        internal
        view
        returns (
            uint amountReceived,
            uint fee,
            uint exchangeFeeRate,
            uint systemConvertedAmount,
            uint systemSourceRate,
            uint systemDestinationRate
        )
    {
        uint destinationAmount;
        (destinationAmount, systemConvertedAmount, systemSourceRate, systemDestinationRate) = exchangeRates()
            .effectiveAtomicValueAndRates(sourceCurrencyKey, sourceAmount, destinationCurrencyKey);

        exchangeFeeRate = _feeRateForAtomicExchange(sourceCurrencyKey, destinationCurrencyKey);
        amountReceived = _deductFeesFromAmount(destinationAmount, exchangeFeeRate);
        fee = destinationAmount.sub(amountReceived);
    }

    function _deductFeesFromAmount(uint destinationAmount, uint exchangeFeeRate)
        internal
        pure
        returns (uint amountReceived)
    {
        amountReceived = destinationAmount.multiplyDecimal(SafeDecimalMath.unit().sub(exchangeFeeRate));
    }

    function _isDeviationAboveThreshold(uint base, uint comparison) internal view returns (bool) {
        if (base == 0 || comparison == 0) {
            return true;
        }

        uint factor;
        if (comparison > base) {
            factor = comparison.divideDecimal(base);
        } else {
            factor = base.divideDecimal(comparison);
        }

        return factor >= getPriceDeviationThresholdFactor();
    }

    event AtomicSynthExchange(
        address indexed account,
        bytes32 fromCurrencyKey,
        uint256 fromAmount,
        bytes32 toCurrencyKey,
        uint256 toAmount,
        address toAddress
    );
}
