// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ISwapExchange.sol";
import "./SwapUtils.sol";
import "./MathUtils.sol";
import "./FeeUtils.sol";
import "./Constants.sol";
import "./Errors.sol";
import "./TransferUtils.sol";
import "./TransferHelper.sol";
import "./FeeData.sol";

contract SwapExchange is ISwapExchange, TransferHelper, FeeData, ReentrancyGuardUpgradeable, PausableUpgradeable {

    mapping(uint256 => SwapUtils.Swap) public swaps;
    uint256 public recordCount;

    function initialize(address rewardAddress, uint256 fixedFee, address[] calldata feeTokenAddresses) public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        TransferHelper.initializeTransferData(rewardAddress);
        FeeData.initializeFeeData(fixedFee, feeTokenAddresses);
        recordCount = 1;
    }

    //Getter functions
    /// @notice Get swap data for an identifier
    /// @param swapId - the specific swap identifier
    /// @return Swap struct
    function getSwap(uint256 swapId) external view returns (SwapUtils.Swap memory) {
        return swaps[swapId];
    }

    /// @notice The maximum number of swaps in sequence that can be claimed using the claimMultiSwap function.
    /// @return the maximum hops value
    function getMaxHops() external view returns (uint256) {
        return _maxHops;
    }

    /// @notice The maximum number of individual swaps that can be claimed using the claimSwaps function.
    /// @return the maximum swap value
    function getMaxSwaps() external view returns (uint256) {
        return _maxSwaps;
    }

    /// @notice The fixed fee amount for swaps where neither token is a fee currency (Fee Type 0)
    /// @return the fixed fee in native currency (ETH for example)
    function getFixedFee() external view returns (uint256) {
        return _fixedFee;
    }

    /// @notice The fee values used to calculate the fee as a fraction of an amount, e.g. amount * feeNumerator / feeDenominator
    /// @return feeValues
    function getFeeValues() external view returns (uint256[2] memory feeValues) {
        return [_feeNumerator, _feeDenominator];
    }

    /// @notice An array of all the fee currency addresses used to determine the fee type for a swap.
    /// @return array of addresses
    function getFeeTokens() external view returns (address[] memory) {
        return feeTokenKeys;
    }

    // Calculation functions
    /**
    * @notice Util to calculate the fee type based on the two swap tokens. There are 3 distinct fee types:
    * Fee Type 2: Token B is a fee currency, the fee is added to the amount the Taker must provide.
    * Fee Type 1: ONLY Token A is a fee currency, the fee is deducted from the Token A amount received by the Taker
    * Fee Type 0: Neither token is a fee currency, the fee is a fixed native currency amount sent by the Taker e.g. ETH
    * The fee token is then either Token B, Token A or the address representing the native currency.
    * @param tokenA - the token A address
    * @param tokenB - the token B address
    * @return feeType
    * @return feeToken
    */
    function calculateFeeType(address tokenA, address tokenB) external view returns (uint8 feeType, address feeToken) {
        return _calculateFeeType(tokenA, tokenB);
    }

    /// @notice Calculate the swap values for a particular A amount (includes fee if Fee Type 1)
    /// @param swapId - the swap identifier
    /// @param amountA - the amount of A
    /// @return a SwapCalculation struct.
    function calculateSwapA(uint256 swapId, uint256 amountA) external view returns (SwapUtils.SwapCalculation memory) {
        SwapUtils.Swap memory swap = swaps[swapId];
        return SwapUtils._calculateSwapA(swap, amountA, _feeNumerator, _feeDenominator, _fixedFee);
    }

    /// @notice Calculate the swap values for a particular given net B amount, e.g. not including the fee in the amount
    /// @param swapId - the swap identifier
    /// @param netAmountB - the net amount of B
    /// @return a SwapCalculation struct.
    function calculateSwapNetB(uint256 swapId, uint256 netAmountB) external view returns (SwapUtils.SwapCalculation memory) {
        SwapUtils.Swap memory swap = swaps[swapId];
        return SwapUtils._calculateSwapNetB(swap, netAmountB, _feeNumerator, _feeDenominator, _fixedFee);
    }

    /// @notice Calculate the swap values for a particular given gross B amount, e.g. the fee is included in the amount
    /// @param swapId - the swap identifier
    /// @param grossAmountB - the gross amount of B
    /// @return a SwapCalculation struct.
    function calculateSwapGrossB(uint256 swapId, uint256 grossAmountB) external view returns (SwapUtils.SwapCalculation memory) {
        SwapUtils.Swap memory swap = swaps[swapId];
        return SwapUtils._calculateSwapGrossB(swap, grossAmountB, _feeNumerator, _feeDenominator, _fixedFee);
    }

    /// @notice Calculate the swap values for a particular complete swap, e.g. taking all the available amountA for the required amountB
    /// @param swapId - the swap identifier
    /// @return a SwapCalculation struct.
    function calculateCompleteSwap(uint256 swapId) external view returns (SwapUtils.SwapCalculation memory) {
        SwapUtils.Swap memory swap = swaps[swapId];
        return SwapUtils._calculateCompleteSwap(swap, _feeNumerator, _feeDenominator, _fixedFee);
    }

    /// @notice Calculate the swap values for an array of ClaimInput structs. Each input is used for a calculation for a swap based on a net B amount.
    /// @param claimInputs - ClaimInput struct array
    /// @return a SwapCalculation array
    /// @return a value representing the total amount of native currency required to be sent (can be 0).
    function calculateSwaps(SwapUtils.ClaimInput[] calldata claimInputs) external view returns (SwapUtils.SwapCalculation[] memory, uint256) {
        uint256 length = claimInputs.length;
        if (length == 0 || length > _maxSwaps) revert Errors.InvalidSwapCount(_maxSwaps, length);
        SwapUtils.SwapCalculation[] memory array = new SwapUtils.SwapCalculation[](length);
        SwapUtils.ClaimInput calldata claimInput;
        uint256 totalNativeSendAmount;
        for (uint256 i; i < length; ++i) {
            claimInput = claimInputs[i];
            SwapUtils.Swap memory swap = swaps[claimInput.swapId];
            SwapUtils.SwapCalculation memory calculation = SwapUtils._calculateSwapNetB(swap, claimInput.amountB, _feeNumerator, _feeDenominator, _fixedFee);
            totalNativeSendAmount += calculation.nativeSendAmount;
            array[i] = calculation;
        }
        return (array, totalNativeSendAmount);
    }

    /**
     * @notice Calculate the swap values for a MultiClaimInput struct. The struct contains the Token A address, Token B address,
     * the net amount of B and an array of swap identifiers in reverse order.
     * Reverse order implies fulfilling each swap in turn, starting with supplying Token B and using each received Token A
     * to supply the next subsequent swap in the chain, finally receiving Token A.
     * The fee type is determined based on the Token A and Token B input address values. The fee types of the individual
     * swaps in the chain are not used.
     * @param multiClaimInput  - MultiClaimInput struct.
     * @return a SwapCalculation struct.
     */
    function calculateMultiSwap(SwapUtils.MultiClaimInput calldata multiClaimInput) external view returns (SwapUtils.SwapCalculation memory) {
        uint256 swapIdCount = multiClaimInput.swapIds.length;
        if (swapIdCount == 0 || swapIdCount > _maxHops) revert Errors.InvalidMultiClaimSwapCount(_maxHops, swapIdCount);
        if (swapIdCount == 1) {
            SwapUtils.Swap memory swap = swaps[multiClaimInput.swapIds[0]];
            return SwapUtils._calculateSwapNetB(swap, multiClaimInput.amountB, _feeNumerator, _feeDenominator, _fixedFee);
        }
        uint256 matchAmount = multiClaimInput.amountB;
        address matchToken = multiClaimInput.tokenB;
        uint256 swapId;
        bool complete = true;
        for (uint256 i; i < swapIdCount; ++i) {
            swapId = multiClaimInput.swapIds[i];
            SwapUtils.Swap memory swap = swaps[swapId];
            if (swap.tokenB != matchToken) revert Errors.NonMatchingToken();
            if (swap.amountB < matchAmount) revert Errors.NonMatchingAmount();
            if (matchAmount < swap.amountB) {
                if (!swap.isPartial) revert Errors.NotPartialSwap();
                matchAmount = MathUtils._mulDiv(swap.amountA, matchAmount, swap.amountB);
                complete = false;
            }
            else {
                matchAmount = swap.amountA;
            }
            matchToken = swap.tokenA;
        }
        if (matchToken != multiClaimInput.tokenA) revert Errors.NonMatchingToken();
        (uint8 feeType,) = _calculateFeeType(multiClaimInput.tokenA, multiClaimInput.tokenB);
        uint256 fee = FeeUtils._calculateFees(matchAmount, multiClaimInput.amountB, feeType, swapIdCount, _feeNumerator, _feeDenominator, _fixedFee);
        SwapUtils.SwapCalculation memory calculation;
        calculation.amountA = matchAmount;
        calculation.amountB = multiClaimInput.amountB;
        calculation.fee = fee;
        calculation.feeType = feeType;
        calculation.isTokenBNative = multiClaimInput.tokenB == Constants.NATIVE_ADDRESS;
        calculation.isComplete = complete;
        calculation.nativeSendAmount = SwapUtils._calculateNativeSendAmount(calculation.amountB, calculation.fee, calculation.feeType, calculation.isTokenBNative);
        return calculation;
    }

    /// @notice Create a new swap between tokens
    /// @param tokenA - the address of token A
    /// @param tokenB - the address of token B
    /// @param amountA - the total amount of A being offered to swap
    /// @param amountB - the total amount of B being requested
    /// @param duration - the number of seconds the swap will remain active
    /// @param partialSwap - true if only part of the swap can be fulfilled
    /// @return explicitly returns true if succeeds
    function createSwap(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint32 duration, bool partialSwap)
    whenNotPaused nonReentrant external payable returns (bool) {
        SwapUtils._checkSwap(tokenA, amountA, tokenB, amountB);
        if (tokenA == Constants.NATIVE_ADDRESS) {
            if (amountA != msg.value) revert Errors.IncorrectNativeAmountSent(amountA, msg.value);
        } else {
            TransferUtils._transferFromERC20(tokenA, msg.sender, address(this), amountA);
        }
        uint32 start = uint32(block.timestamp);
        uint32 expiration = start + duration;
        (uint8 feeType,) = _calculateFeeType(tokenA, tokenB);
        uint256 swapId = recordCount;
        unchecked { ++recordCount; }
        swaps[swapId] = SwapUtils.Swap({
            amountA: amountA,
            amountB: amountB,
            isPartial: partialSwap,
            feeType: feeType,
            start: start,
            expiration: expiration,
            maker: msg.sender,
            tokenA: tokenA,
            tokenB: tokenB
        });
        emit SwapCreated(swapId, msg.sender, tokenA, tokenB, amountA, amountB, feeType, start, expiration, partialSwap);
        return true;
    }

    /// @notice Claim a single swap atomically, specifying the Token A and Token B amounts. The Taker cannot be the Maker of the swap.
    /// @param swapId - the swap identifier
    /// @param amountA - the gross amount of A
    /// @param amountB - the net amount of B
    /// @return explicitly returns true if succeeds
    function claimSwap(uint256 swapId, uint256 amountA, uint256 amountB) whenNotPaused nonReentrant external payable returns (bool) {
        address taker = msg.sender;
        uint256 value = msg.value;
        _claimSwap(taker, value, swapId, amountA, amountB);
        return true;
    }

    /// @notice Claim multiple swaps individually as one atomic transaction. There is a limit to how many can be claimed at once (see getMaxSwaps)
    /// @param claims - an array of Claim structs
    /// @return explicitly returns true if succeeds
    function claimSwaps(SwapUtils.Claim[] calldata claims) whenNotPaused nonReentrant external payable returns (bool) {
        uint256 length = claims.length;
        if (length == 0 || length > _maxSwaps) revert Errors.InvalidSwapCount(_maxSwaps, length);
        address taker = msg.sender;
        uint256 value = msg.value;
        SwapUtils.Claim calldata claim;
        uint256 totalNativeSendAmount;
        for (uint256 i; i < length; ++i) {
            claim = claims[i];
            SwapUtils.Swap memory swap = swaps[claim.swapId];
            SwapUtils._checkIsValid(swap, taker, block.timestamp);
            SwapUtils.SwapCalculation memory calculation = SwapUtils._calculateSwapNetB(swap, claim.amountB, _feeNumerator, _feeDenominator, _fixedFee);
            if (!swap.isPartial && !calculation.isComplete) revert Errors.NotPartialSwap();
            if (calculation.amountA != claim.amountA || calculation.amountB != claim.amountB) revert Errors.InvalidClaimAmounts();
            unchecked { totalNativeSendAmount += calculation.nativeSendAmount; }
            if (totalNativeSendAmount > value) revert Errors.IncorrectNativeAmountSent(totalNativeSendAmount, value);
            _performSwap(taker, claim.swapId, swap, calculation);
        }
        if (totalNativeSendAmount != value) revert Errors.IncorrectNativeAmountSent(totalNativeSendAmount, value);
        return true;
    }

    /// @notice Cancel an individual swap. Only available to the Maker of the swap.
    /// @param swapId - the identifier of the swap
    /// @return explicitly returns true if succeeds
    function cancelSwap(uint256 swapId) nonReentrant external payable returns (bool) {
        SwapUtils.Swap memory swap = swaps[swapId];
        if (swap.maker != msg.sender) revert Errors.UnauthorizedAccess();
        if (swap.amountA <= 0 || swap.amountB <= 0) revert Errors.ZeroAmount();
        _deleteSwap(swapId);
        TransferUtils._transfer(swap.tokenA, msg.sender, swap.amountA);
        emit SwapCancelled(swapId);
        return true;
    }

    /**
     * @notice Claim a sequence of swaps based on a MultiClaim struct atomically. The struct contains the Token A address, Token B address,
     * the gross amount of B, the gross amount of A and an array of swap identifiers in reverse order.
     * These input values can be exactly calculated using calculateMultiSwap. If the actual values resulting from the swap
     * are not exactly equal to the input amounts the swap will fail. You cannot be the Maker of any swaps in the sequence.
     * @param multiClaim struct.
     * @return true explicitly if it succeeds.
     */
    function claimMultiSwap(SwapUtils.MultiClaim calldata multiClaim) whenNotPaused nonReentrant external payable returns (bool) {
        address taker = msg.sender;
        uint256 value = msg.value;
        _claimMultiSwap(taker, value, multiClaim);
        return true;
    }

    //Internal implementation functions
    function _calculateFeeType(address tokenA, address tokenB) internal view returns (uint8 feeType, address feeToken) {
        if (tokenB == Constants.NATIVE_ADDRESS) {
            return (Constants.FEE_TYPE_TOKEN_B, tokenB);
        }
        if (tokenA == Constants.NATIVE_ADDRESS) {
            return (Constants.FEE_TYPE_TOKEN_A, tokenA);
        }
        if (feeTokenMap[tokenB] == 1) {
            return (Constants.FEE_TYPE_TOKEN_B, tokenB);
        }
        if (feeTokenMap[tokenA] == 1) {
            return (Constants.FEE_TYPE_TOKEN_A, tokenA);
        }
        return (Constants.FEE_TYPE_ETH_FIXED, Constants.NATIVE_ADDRESS);
    }

    function _claimSwap(address taker, uint256 value, uint256 swapId, uint256 amountA, uint256 amountB) internal {
        SwapUtils.Swap memory swap = swaps[swapId];
        SwapUtils._checkIsValid(swap, taker, block.timestamp);
        SwapUtils.SwapCalculation memory calculation = SwapUtils._calculateSwapNetB(swap, amountB, _feeNumerator, _feeDenominator, _fixedFee);
        if (!swap.isPartial && !calculation.isComplete) revert Errors.NotPartialSwap();
        if (calculation.nativeSendAmount != value) revert Errors.IncorrectNativeAmountSent(calculation.nativeSendAmount, value);
        if (calculation.amountA != amountA || calculation.amountB != amountB) revert Errors.InvalidClaimAmounts();
        _performSwap(taker, swapId, swap, calculation);
    }

    function _performSwap(address taker, uint256 swapId, SwapUtils.Swap memory swap, SwapUtils.SwapCalculation memory calculation) internal {
        if (calculation.isComplete) {
            _deleteSwap(swapId);
            _transferClaim(swap.maker, taker, swap.tokenA, swap.tokenB, calculation.amountA, calculation.amountB, calculation.fee, calculation.feeType);
            emit SwapClaimed(swapId, taker, calculation.amountA, calculation.amountB, calculation.fee, calculation.feeType);
        }
        else {
            swaps[swapId].amountA = swap.amountA - calculation.amountA;
            swaps[swapId].amountB = swap.amountB - calculation.amountB;
            _transferClaim(swap.maker, taker, swap.tokenA, swap.tokenB, calculation.amountA, calculation.amountB, calculation.fee, calculation.feeType);
            emit SwapPartialClaimed(swapId, taker, calculation.amountA, calculation.amountB, calculation.fee, calculation.feeType);
        }
    }

    function _claimMultiSwap(address taker, uint256 value, SwapUtils.MultiClaim calldata multiClaim) internal {
        SwapUtils._checkMultiClaim(multiClaim, _maxHops);
        uint256 swapIdCount = multiClaim.swapIds.length;
        if (swapIdCount == 1) {
            _claimSwap(taker, value, multiClaim.swapIds[0], multiClaim.amountA, multiClaim.amountB);
            return;
        }
        (uint8 feeType, address feeToken) = _calculateFeeType(multiClaim.tokenA, multiClaim.tokenB);
        uint256 fee = FeeUtils._calculateFees(multiClaim.amountA, multiClaim.amountB, feeType, swapIdCount, _feeNumerator, _feeDenominator, _fixedFee);
        SwapUtils._checkIsValueSent(value, multiClaim.tokenB, multiClaim.amountB, fee, feeType);
        uint256 timestamp = block.timestamp;
        uint256 matchAmount = multiClaim.amountB;
        address matchToken = multiClaim.tokenB;
        uint256 swapId;
        uint256 amountA;
        for (uint256 i; i < swapIdCount; ++i) {
            swapId = multiClaim.swapIds[i];
            SwapUtils.Swap memory swap = swaps[swapId];
            SwapUtils._checkIsValid(swap, taker, timestamp);
            if (matchToken != swap.tokenB) revert Errors.NonMatchingToken();
            if (matchAmount > swap.amountB) revert Errors.NonMatchingAmount();
            if (matchAmount < swap.amountB) {
                if (!swap.isPartial) revert Errors.NotPartialSwap();
                amountA = MathUtils._mulDiv(swap.amountA, matchAmount, swap.amountB);
                swaps[swapId].amountA = swap.amountA - amountA;
                swaps[swapId].amountB = swap.amountB - matchAmount;
                emit SwapPartialClaimed(swapId, address(this), amountA, matchAmount, 0, swap.feeType);
            }
            else {
                amountA = swap.amountA;
                _deleteSwap(swapId);
                emit SwapClaimed(swapId, address(this), amountA, matchAmount, 0, swap.feeType);
            }
            if (i != 0) {
                TransferUtils._transfer(matchToken, swap.maker, matchAmount);
            }
            else { // First time only
                TransferUtils._transferFrom(matchToken, taker, swap.maker, matchAmount);
            }
            matchAmount = amountA;
            matchToken = swap.tokenA;
        }
        if (multiClaim.tokenA != matchToken) revert Errors.NonMatchingToken();
        if (multiClaim.amountA != matchAmount) revert Errors.NonMatchingAmount();
        uint256 netAmountA = (feeType != Constants.FEE_TYPE_TOKEN_A) ? matchAmount : matchAmount - fee;
        _transferFee(taker, feeToken, fee, feeType);
        TransferUtils._transfer(multiClaim.tokenA, taker, netAmountA);
        emit SwapMultiClaimed(taker, multiClaim.tokenA, multiClaim.tokenB, multiClaim.amountA, multiClaim.amountB, fee, feeType);
    }

    function _deleteSwap(uint256 swapId) internal {
        delete swaps[swapId];
    }

    // Owner Administration Functions

    /// @notice An administration function to expire a swap by setting its expiration value to 0.
    /// @param swapId - the identifier of swap
    function expireSwap(uint256 swapId) nonReentrant external onlyOwner {
        swaps[swapId].expiration = 0;
        emit SwapCancelled(swapId);
    }

    /// @notice Administration function to recover swaps that are at least 2 years old and unclaimed.
    /// @param token - the token address to recover
    /// @param swapIds - an array of swap identifiers
    /// @param recoveryAddress - teh address to send the recovered amount
    function recoverSwaps(address token, uint256[] calldata swapIds, address recoveryAddress) nonReentrant external payable onlyOwner {
        if (recoveryAddress == address(0)) revert Errors.InvalidAddress();
        uint256 abandonedStart = block.timestamp - Constants.TWO_YEARS_SECONDS;
        uint256 total;
        uint256 swapId;
        uint256 length = swapIds.length;
        for (uint256 i; i < length; ++i) {
            swapId = swapIds[i];
            SwapUtils.Swap memory swap = swaps[swapId];
            if (swap.tokenA != token || swap.start > abandonedStart) continue;
            unchecked { total += swap.amountA; }
            _deleteSwap(swapId);
            emit SwapCancelled(swapId);
        }
        TransferUtils._transfer(token, recoveryAddress, total);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}

