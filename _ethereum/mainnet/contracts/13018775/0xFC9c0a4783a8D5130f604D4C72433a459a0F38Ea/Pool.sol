// SPDX-License-Identifier: Unlicensed
pragma solidity 0.7.6;

// ============ Contract information ============

/**
 * @title  Interest Rate Swaps V1
 * @notice A pool for Interest Rate Swaps
 * @author Greenwood Labs
 */

// ============ Imports ============

import "./SafeMath.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IPool.sol";
import "./IAdapter.sol";
import "./IGreenwoodERC20.sol";
import "./GreenwoodERC20.sol";


contract Pool is IPool, GreenwoodERC20 {
    // ============ Import usage ============

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Immutable storage ============

    address private constant GOVERNANCE = 0xe3D5260Cd7F8a4207f41C3B2aC87882489f97213;

    uint256 private constant TEN_EXP_18 = 1000000000000000000;
    uint256 private constant STANDARD_DECIMALS = 18;
    uint256 private constant BLOCKS_PER_DAY = 6570; // 13.15 seconds per block
    uint256 private constant MAX_TO_PAY_BUFFER_NUMERATOR = 10;
    uint256 private constant MAX_TO_PAY_BUFFER_DENOMINATOR = 100;
    uint256 private constant DAYS_PER_YEAR = 360;

    // ============ Mutable storage ============

    address private factory;
    address public adapter0;
    address public adapter1;
    address public underlier;

    uint256 public protocol0;
    uint256 public protocol1;
    uint256 public totalSwapCollateral;
    uint256 public totalSupplementaryCollateral;
    uint256 public totalActiveLiquidity;
    uint256 public totalAvailableLiquidity;
    uint256 public utilization;
    uint256 public totalFees;
    uint256 public fee;
    uint256 public direction;
    uint256 public durationInDays;
    uint256 public underlierDecimals;
    uint256 public decimalDifference;
    uint256 public rateLimit;
    uint256 public rateSensitivity;
    uint256 public utilizationInflection;
    uint256 public rateMultiplier;
    uint256 public maxDepositLimit;

    mapping(bytes32 => Swap) public swaps;
    mapping(address => uint256) public swapNumbers;
    mapping(address => uint256) public liquidityProviderLastDeposit;

    // ============ Structs ============
  
    struct Swap {
        address user;
        bool isClosed;
        uint256 notional;
        uint256 swapCollateral;
        uint256 activeLiquidity;
        uint256 openBlock;
        uint256 underlierProtocol0BorrowIndex;
        uint256 underlierProtocol1BorrowIndex;
    }

    // ============ Modifiers ============
    // None

    // ============ Events ============

    event OpenSwap(address indexed user, uint256 notional, uint256 activeLiquidity, uint256 swapFee);
    event CloseSwap(address indexed user, uint256 notional, uint256 userToPay, uint256 ammToPay);
    event DepositLiquidity(address indexed user, uint256 liquidityAmount);
    event WithdrawLiquidity(address indexed user, uint256 liquidityAmount, uint256 feesAccrued);
    event Liquidate(address indexed liquidator, address indexed user, uint256 swapNumber, uint256 liquidatorReward);
    event Mint(address indexed user, uint256 underlyingTokenAmount, uint256 liquidityTokenAmount);
    event Burn(address indexed user, uint256 underlyingTokenAmount, uint256 liquidityTokenAmount);
    
    // ============ Constructor ============

    constructor(
        address _underlier,
        uint256 _underlierDecimals,
        address _adapter0,
        address _adapter1,
        uint256 _protocol0,
        uint256 _protocol1,
        uint256 _direction,
        uint256 _durationInDays,
        uint256 _initialDeposit,
        uint256 _rateLimit,
        uint256 _rateSensitivity,
        uint256 _utilizationInflection,
        uint256 _rateMultiplier,
        address _poolDeployer
    ) {
        // assert that the pool can be initialized with a non-zero amount
        require(_initialDeposit > 0, 'Initial token amount must be greater than 0');

        // initialize the pool
        factory = msg.sender;
        underlier = _underlier;
        underlierDecimals = _underlierDecimals;
        direction = _direction;
        durationInDays = _durationInDays;
        adapter0 = _adapter0;
        adapter1 = _adapter1;
        protocol0 = _protocol0;
        protocol1 = _protocol1;

        // calculate difference in decimals between underlier and STANDARD_DECIMALS
        decimalDifference = _calculatedDecimalDifference(underlierDecimals, STANDARD_DECIMALS);

        // adjust the token decimals to the standard number
        uint256 adjustedInitialDeposit = _convertToStandardDecimal(_initialDeposit);

        totalAvailableLiquidity = adjustedInitialDeposit;
        rateLimit = _rateLimit;
        rateSensitivity = _rateSensitivity;
        utilizationInflection = _utilizationInflection;
        rateMultiplier = _rateMultiplier;
        maxDepositLimit = 1000000000000000000000000;

        // calculate the initial swap fee
        fee = _calculateFee();

        // Update the pool deployer's deposit block number
        liquidityProviderLastDeposit[_poolDeployer] = block.number;

        // mint LP tokens to the pool deployer
        _mintLPTokens(_poolDeployer, adjustedInitialDeposit);
    }


    // ============ Opens a new basis swap ============

    function openSwap(uint256 _notional) external override returns (bool) {
        // assert that a swap is opened with an non-zero notional
        require(_notional > 0, '9');

        // adjust notional to standard decimal places
        uint256 adjustedNotional = _convertToStandardDecimal(_notional);

        // calculate the swap collateral and trade active liquidity based off the notional
        (uint256 swapCollateral, uint256 activeLiquidity) = _calculateSwapCollateralAndActiveLiquidity(adjustedNotional);

        // assert that there is sufficient liquidity to open this swap
        require(activeLiquidity <= totalAvailableLiquidity, '10');

        // assign the supplementary collateral
        uint256 supplementaryCollateral = activeLiquidity;

        // calculate the fee based on swap collateral
        uint256 swapFee = swapCollateral.mul(fee).div(TEN_EXP_18);

        // calculate the current borrow index for the underlier on protocol 0
        uint256 underlierProtocol0BorrowIndex = IAdapter(adapter0).getBorrowIndex(underlier);

        // calculate the current borrow index for the underlier on protocol 1
        uint256 underlierProtocol1BorrowIndex = IAdapter(adapter1).getBorrowIndex(underlier);

        // create the swap struct
        Swap memory swap = Swap(
            msg.sender,
            false,
            adjustedNotional,
            swapCollateral,
            activeLiquidity,
            block.number,
            underlierProtocol0BorrowIndex,
            underlierProtocol1BorrowIndex
        );
        
        // create a swap key by hashing together the user and their current swap number
        bytes32 swapKey = keccak256(abi.encode(msg.sender, swapNumbers[msg.sender]));
        swaps[swapKey] = swap;

        // update the user's swap number
        swapNumbers[msg.sender] = swapNumbers[msg.sender].add(1);

        // update the total active liquidity
        totalActiveLiquidity = totalActiveLiquidity.add(activeLiquidity);

        // update the total swap collateral
        totalSwapCollateral = totalSwapCollateral.add(swapCollateral);

        // update the total supplementary collateral
        totalSupplementaryCollateral = totalSupplementaryCollateral.add(supplementaryCollateral);

        // update the total available liquidity
        totalAvailableLiquidity = totalAvailableLiquidity.sub(activeLiquidity);

        // update the total fees accrued
        totalFees = totalFees.add(swapFee);

        // the total amount to debit the user (swap collateral + fee + the supplementary collateral)
        uint256 amountToDebit = swapCollateral.add(fee).add(supplementaryCollateral);

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fixed interest rate
        fee = _calculateFee();

        // transfer underlier from the user
        IERC20(underlier).safeTransferFrom(
            msg.sender,
            address(this),
            _convertToUnderlierDecimal(amountToDebit)
        );

        // emit an open swap event
        emit OpenSwap(msg.sender, adjustedNotional, activeLiquidity, swapFee);

        // return true on successful open swap
        return true;
    }


    // ============ Closes an interest rate swap ============

    function closeSwap(uint256 _swapNumber) external override returns (bool) {
        // the key of the swap
        bytes32 swapKey = keccak256(abi.encode(msg.sender, _swapNumber));

        // assert that a swap exists for this user
        require(swaps[swapKey].user == msg.sender, '11');

        // assert that this swap has not already been closed
        require(!swaps[swapKey].isClosed, '12');

        // get the swap to be closed
        Swap memory swap = swaps[swapKey];

        // the amounts that the user and the AMM will pay on this swap, depending on the direction of the swap
        (uint256 userToPay, uint256 ammToPay) = _calculateInterestAccrued(swap);

        // assert that the swap cannot be closed in the same block that it was opened
        require(block.number > swap.openBlock, '13');

        // the total payout for this swap
        uint256 payout = userToPay > ammToPay ? userToPay.sub(ammToPay) : ammToPay.sub(userToPay);

        // the supplementary collateral of this swap
        uint256 supplementaryCollateral = swap.activeLiquidity;

        // the active liquidity recovered upon closure of this swap
        uint256 activeLiquidityRecovered;

        // the amount to reward the user upon closing of the swap
        uint256 redeemableFunds;

        // the user won the swap
        if (ammToPay > userToPay) {
            // ensure the payout does not exceed the active liquidity for this swap
            payout = Math.min(payout, swap.activeLiquidity);

            // active liquidity recovered is the the total active liquidity reduced by the user's payout
            activeLiquidityRecovered = swap.activeLiquidity.sub(payout);

            // User can redeem all of swap collateral, all of supplementary collateral, and the payout
            redeemableFunds = swap.swapCollateral.add(supplementaryCollateral).add(payout);
        }

        // the AMM won the swap
        else if (ammToPay < userToPay) {
            // ensure the payout does not exceed the swap collateral for this swap
            payout = Math.min(payout, swap.swapCollateral);

            // active liquidity recovered is the the total active liquidity increased by the amm's payout
            activeLiquidityRecovered = swap.activeLiquidity.add(payout);

            // user can redeem all of swap collateral, all of supplementary collateral, with the payout subtracted
            redeemableFunds = swap.swapCollateral.add(supplementaryCollateral).sub(payout);
        }

        // neither party won the swap
        else {
            // active liquidity recovered is the the initial active liquidity for the trade
            activeLiquidityRecovered = swap.activeLiquidity;

            // user can redeem all of swap collateral and all of supplementary collateral
            redeemableFunds = swap.swapCollateral.add(supplementaryCollateral);
        }

        // update the total active liquidity
        totalActiveLiquidity = totalActiveLiquidity.sub(swap.activeLiquidity);

        // update the total swap collateral
        totalSwapCollateral = totalSwapCollateral.sub(swap.swapCollateral);

        // update the total supplementary collateral
        totalSupplementaryCollateral = totalSupplementaryCollateral.sub(supplementaryCollateral);

        // update the total available liquidity
        totalAvailableLiquidity = totalAvailableLiquidity.add(activeLiquidityRecovered);

        // close the swap
        swaps[swapKey].isClosed = true;

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fee
        fee = _calculateFee();

        // transfer redeemable funds to the user
        IERC20(underlier).safeTransfer(
            msg.sender, 
            _convertToUnderlierDecimal(redeemableFunds)
        );

        // emit a close swap event
        emit CloseSwap(msg.sender, swap.notional, userToPay, ammToPay);

        return true;
    }

    // ============ Deposit liquidity into the pool ============

    function depositLiquidity(uint256 _liquidityAmount) external override returns (bool) {

        // adjust liquidity amount to standard decimals
        uint256 adjustedLiquidityAmount = _convertToStandardDecimal(_liquidityAmount);

        // asert that liquidity amount must be greater than 0 and amount to less than the max deposit limit
        require(adjustedLiquidityAmount > 0 && adjustedLiquidityAmount.add(totalActiveLiquidity).add(totalAvailableLiquidity) <= maxDepositLimit, '14');

        // transfer the specified amount of underlier into the pool
        IERC20(underlier).safeTransferFrom(msg.sender, address(this), _liquidityAmount);

        // add to the total available liquidity in the pool
        totalAvailableLiquidity = totalAvailableLiquidity.add(adjustedLiquidityAmount);

        // update the most recent deposit block of the liquidity provider
        liquidityProviderLastDeposit[msg.sender] = block.number;

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fee
        fee = _calculateFee();

        // mint LP tokens to the liiquidity provider
        _mintLPTokens(msg.sender, adjustedLiquidityAmount);

        // emit deposit liquidity event
        emit DepositLiquidity(msg.sender, adjustedLiquidityAmount);

        return true;
    }


    // ============ Withdraw liquidity from the pool ============

    function withdrawLiquidity(uint256 _liquidityTokenAmount) external override returns (bool) {
        // assert that withdrawal does not occur in the same block as a deposit
        require(liquidityProviderLastDeposit[msg.sender] < block.number, '19');

        // asert that liquidity amount must be greater than 0
        require(_liquidityTokenAmount > 0, '14');

        // transfer the liquidity tokens from sender to the pool
        IERC20(address(this)).safeTransferFrom(msg.sender, address(this), _liquidityTokenAmount);

        // determine the amount of underlying tokens that the liquidity tokens can be redeemed for
        uint256 redeemableUnderlyingTokens = calculateLiquidityTokenValue(_liquidityTokenAmount);

        // assert that there is enough available liquidity to safely withdraw this amount
        require(totalAvailableLiquidity >= redeemableUnderlyingTokens, '10');

        // the fees that this withdraw will yield (total fees accrued * withdraw amount / total liquidity provided)
        uint256 feeShare = totalFees.mul(redeemableUnderlyingTokens).div(totalActiveLiquidity.add(totalAvailableLiquidity));

        // update the total fees remaining in the pool
        totalFees = totalFees.sub(feeShare);

        // remove the withdrawn amount from  the total available liquidity in the pool
        totalAvailableLiquidity = totalAvailableLiquidity.sub(redeemableUnderlyingTokens);

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fee
        fee = _calculateFee();

        // mint LP tokens to the liiquidity provider
        _burnLPTokens(msg.sender, _liquidityTokenAmount);

        // emit withdraw liquidity event
        emit WithdrawLiquidity(msg.sender, redeemableUnderlyingTokens, feeShare);

        return true;
    }

    // ============ Liquidate a swap that has expired ============
    
    function liquidate(address _user, uint256 _swapNumber) external override returns (bool) {
        // the key of the swap
        bytes32 swapKey = keccak256(abi.encode(_user, _swapNumber));

        // assert that a swap exists for this user
        require(swaps[swapKey].user == _user, '11');

        // get the swap to be liquidated
        Swap memory swap = swaps[swapKey];

        // assert that the swap has not already been closed
        require(!swap.isClosed, '12');

        // the expiration block of the swap
        uint256 expirationBlock = swap.openBlock.add(durationInDays.mul(BLOCKS_PER_DAY));

        // assert that the swap has eclipsed the expiration block
        require(block.number >= expirationBlock, '17');
        
        // transfer trade active liquidity from the liquidator
        IERC20(underlier).safeTransferFrom(
            msg.sender,
            address(this),
            _convertToUnderlierDecimal(swap.activeLiquidity)
        );

        // the amounts that the user and the AMM will pay on this swap, depending on the direction of the swap
        (uint256 userToPay, uint256 ammToPay) =_calculateInterestAccrued(swap);

        // the total payout for this swap
        uint256 payout = userToPay > ammToPay ? userToPay.sub(ammToPay) : ammToPay.sub(userToPay);

        // the supplementary collateral of this swap
        uint256 supplementaryCollateral = swap.activeLiquidity;

        // the active liquidity recovered upon liquidation of this swap
        uint256 activeLiquidityRecovered;

        // the amount to reward the liquidator upon liquidation of the swap
        uint256 liquidatorReward;

        // the user won the swap
        if (ammToPay > userToPay) {
            // ensure the payout does not exceed the active liquidity for this swap
            payout = Math.min(payout, swap.activeLiquidity);

            // active liquidity recovered is the the total active liquidity increased by the user's unclaimed payout
            activeLiquidityRecovered = swap.activeLiquidity.add(payout);

            // liquidator is rewarded the supplementary collateral and the difference between the swap collateral and the payout
            liquidatorReward = supplementaryCollateral.add(swap.swapCollateral).sub(payout);
        }

        // the AMM won the swap
        else if (ammToPay < userToPay) {
            // ensure the payout does not exceed the swap collateral for this swap
            payout = Math.min(payout, swap.swapCollateral);

            // active liquidity recovered is the the total active liquidity increased by the entire swap collateral
            activeLiquidityRecovered = swap.activeLiquidity.add(swap.swapCollateral);

            // liquidator is rewarded all of the supplementary collateral
            liquidatorReward = supplementaryCollateral;
        }

        // neither party won the swap
        else {
            // active liquidity recovered is the the total active liquidity for this swap
            activeLiquidityRecovered = swap.activeLiquidity;

            // liquidator is rewarded all of the supplementary collateral and the swap collateral
            liquidatorReward = supplementaryCollateral.add(swap.swapCollateral);
        }

        // update the total active liquidity
        totalActiveLiquidity = totalActiveLiquidity.sub(swap.activeLiquidity);

        // update the total swap collateral
        totalSwapCollateral = totalSwapCollateral.sub(swap.swapCollateral);

        // update the total supplementary collateral
        totalSupplementaryCollateral = totalSupplementaryCollateral.sub(supplementaryCollateral);

        // update the total available liquidity
        totalAvailableLiquidity = totalAvailableLiquidity.add(activeLiquidityRecovered);

        // close the swap
        swaps[swapKey].isClosed = true;

        // calculate the new pool utilization
        utilization = _calculateUtilization();

        // calculate the new fee
        fee = _calculateFee();

        // transfer liquidation reward to the liquidator
        IERC20(underlier).safeTransfer(
            msg.sender, 
            _convertToUnderlierDecimal(liquidatorReward)
        );

        // emit liquidate event
        emit Liquidate(msg.sender, _user, _swapNumber, liquidatorReward);

        return true;
    }

    // ============ External view for the interest accrued on a variable rate ============

    function calculateVariableInterestAccrued(uint256 _notional, uint256 _protocol, uint256 _borrowIndex) external view override returns (uint256) {
        return _calculateVariableInterestAccrued(_notional, _protocol, _borrowIndex);
    }

    // ============ Calculates the current variable rate for the underlier on a particular protocol ============

    function calculateVariableRate(uint256 _protocol) external view returns (uint256) {
        // the adapter to use given the particular protocol
        address adapter = _protocol == protocol0 ? adapter0 : adapter1;

        // use the current variable rate for the underlying token
        uint256 variableRate = IAdapter(adapter).getBorrowRate(underlier);
        
        return variableRate;
    }

    function changeMaxDepositLimit(uint256 _limit) external {

        // assert that only governance can adjust the deposit limit
        require(msg.sender == GOVERNANCE, '18');

        // change the deposit limit
        maxDepositLimit = _limit;
    }

    // ============ Calculates the current approximate value of liquidity tokens denoted in the underlying token ============

    function calculateLiquidityTokenValue(uint256 liquidityTokenAmount) public view returns (uint256 redeemableUnderlyingTokens) {

        // get the total underlying token balance in this pool with supplementary and swap collateral amounts excluded
        uint256 adjustedUnderlyingTokenBalance = _convertToStandardDecimal(IERC20(underlier).balanceOf(address(this)))
                                                    .sub(totalSwapCollateral)
                                                    .sub(totalSupplementaryCollateral);

        // the total supply of LP tokens in circulation
        uint256 _totalSupply = totalSupply();

        // determine the amount of underlying tokens that the liquidity tokens can be redeemed for
        redeemableUnderlyingTokens = liquidityTokenAmount.mul(adjustedUnderlyingTokenBalance).div(_totalSupply);
    }

    // ============ Calculates the max variable rate to pay ============

    function calculateMaxVariableRate(address adapter) external view returns (uint256) {
        return _calculateMaxVariableRate(adapter);
    }

    // ============ Internal methods ============

    // ============ Mints LP tokens to users that deposit liquidity to the protocol ============

    function _mintLPTokens(address to, uint256 underlyingTokenAmount) internal {

        // the total supply of LP tokens in circulation
        uint256 _totalSupply = totalSupply();

        // determine the amount of LP tokens to mint
        uint256 mintableLiquidity;

        if (_totalSupply == 0) {
            // initialize the supply of LP tokens
            mintableLiquidity = underlyingTokenAmount;
        } 
        
        else {
            // get the total underlying token balance in this pool
            uint256 underlyingTokenBalance = _convertToStandardDecimal(IERC20(underlier).balanceOf(address(this)));
                                                
            // adjust the underlying token balance to standardize the decimals
            // the supplementary collateral, swap collateral, and newly added liquidity amounts are excluded
            uint256 adjustedUnderlyingTokenBalance = underlyingTokenBalance
                                                        .sub(totalSwapCollateral)
                                                        .sub(totalSupplementaryCollateral)
                                                        .sub(underlyingTokenAmount);

            // mint a proportional amount of LP tokens
            mintableLiquidity = underlyingTokenAmount.mul(_totalSupply).div(adjustedUnderlyingTokenBalance);
        }

        // assert that enough liquidity tokens are available to be minted
        require(mintableLiquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

        // mint the tokens directly to the LP
        _mint(to, mintableLiquidity);

        // emit minting of LP token event
        emit Mint(to, underlyingTokenAmount, mintableLiquidity);
    }

    // ============ Burns LP tokens and sends users the equivalent underlying tokens in return ============

    function _burnLPTokens(address to, uint256 liquidityTokenAmount) internal {

        // determine the amount of underlying tokens that the liquidity tokens can be redeemed for
        uint256 redeemableUnderlyingTokens = calculateLiquidityTokenValue(liquidityTokenAmount);

        // assert that enough underlying tokens are available to send to the redeemer
        require(redeemableUnderlyingTokens > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');

        // burn the liquidity tokens
        _burn(address(this), liquidityTokenAmount);

        // transfer the underlying tokens
        IERC20(underlier).safeTransfer(to, _convertToUnderlierDecimal(redeemableUnderlyingTokens));

        // emit burning of LP token event
        emit Mint(to, redeemableUnderlyingTokens, liquidityTokenAmount);
    }

    // ============ Calculate the current pool fee ============

    function _calculateFee() internal view returns (uint256) {

        // the new fee based on updated pool utilization
        uint256 newFee;

        // the fee offered before the utilization inflection is hit  
        // (utilization * rate sensitivity) + rate limit
        int256 preInflectionLeg = int256(utilization.mul(rateSensitivity).div(TEN_EXP_18).add(rateLimit));
     
        // pool utilization is below the inflection
        if (utilization < utilizationInflection) {
            // assert that the leg is positive before converting to uint256
            require(preInflectionLeg > 0);

            newFee = uint256(preInflectionLeg);
        }

        // pool utilization is at or above the inflection
        else {
            // The additional change in the rate after the utilization inflection is hit
            // rate multiplier * (utilization - utilization inflection)
            int256 postInflectionLeg = int256(rateMultiplier.mul(utilization.sub(utilizationInflection)).div(TEN_EXP_18));

            // assert that the addition of the legs is positive before converting to uint256
            require(preInflectionLeg + postInflectionLeg > 0);

            newFee = uint256(preInflectionLeg + postInflectionLeg);
        }

        // adjust the fee value as a percentage
        return newFee.div(100);
    }

    // ============ Calculates the pool utilization ============

    function _calculateUtilization() internal view returns (uint256) {

        // get the total liquidity of this pool
        uint256 totalPoolLiquidity = totalActiveLiquidity.add(totalAvailableLiquidity);

        // pool utilization is the total active liquidity / total pool liquidity
        uint256 newUtilization = totalActiveLiquidity.mul(TEN_EXP_18).div(totalPoolLiquidity);

        // adjust utilization to be an integer between 0 and 100
        uint256 adjustedUtilization = newUtilization * 100;

        return adjustedUtilization;
    }

    // ============ Calculates the swap collateral and active liquidity needed for a given notional ============

    function _calculateSwapCollateralAndActiveLiquidity(uint256 _notional) internal view returns (uint256, uint256) {
        // The maximum rate the user will pay on a swap
        uint256 userMaxRateToPay = direction == 0 ? _calculateMaxVariableRate(adapter0) : _calculateMaxVariableRate(adapter1);

        // the maximum rate the AMM will pay on a swap
        uint256 ammMaxRateToPay = direction == 1 ? _calculateMaxVariableRate(adapter0) : _calculateMaxVariableRate(adapter1);

        // notional * maximum rate to pay * (swap duration in days / days per year)
        uint256 swapCollateral = _calculateMaxAmountToPay(_notional, userMaxRateToPay);
        uint256 activeLiquidity = _calculateMaxAmountToPay(_notional, ammMaxRateToPay);

        return (swapCollateral, activeLiquidity);
    }

    // ============ Calculates the maximum amount to pay over a specific time window with a given notional and rate ============

    function _calculateMaxAmountToPay(uint256 _notional, uint256 _rate) internal view returns (uint256) {
        // the period by which to adjust the rate
        uint256 period = DAYS_PER_YEAR.div(durationInDays);

        // notional * maximum rate to pay / (days per year / swap duration in days)
        return _notional.mul(_rate).div(TEN_EXP_18).div(period);
    }

    // ============ Calculates the maximum variable rate ============

    function _calculateMaxVariableRate(address _adapter) internal view returns (uint256) {

        // use the current variable rate for the underlying token
        uint256 variableRate = IAdapter(_adapter).getBorrowRate(underlier);

        // calculate a variable rate buffer 
        uint256 maxBuffer = MAX_TO_PAY_BUFFER_NUMERATOR.mul(TEN_EXP_18).div(MAX_TO_PAY_BUFFER_DENOMINATOR);
        
        // add the buffer to the current variable rate
        return variableRate.add(maxBuffer);
    }

    // ============ Calculates the interest accrued for both parties on a swap ============

    function _calculateInterestAccrued(Swap memory _swap) internal view returns (uint256, uint256) {
        // the amounts that the user and the AMM will pay on this swap, depending on the direction of the swap
        uint256 userToPay;
        uint256 ammToPay;

        // the fixed interest accrued on this swap
        uint256 protocol0VariableInterestAccrued = _calculateVariableInterestAccrued(_swap.notional, protocol0, _swap.underlierProtocol0BorrowIndex);

        // the variable interest accrued on this swap
        uint256 protocol1VariableInterestAccrued = _calculateVariableInterestAccrued(_swap.notional, protocol1, _swap.underlierProtocol1BorrowIndex);

        // user went long on the variable rate
        if (direction == 0) {
            userToPay = protocol0VariableInterestAccrued;
            ammToPay = protocol1VariableInterestAccrued;
        } 

        // user went short on the variable rate
        else {
            userToPay = protocol1VariableInterestAccrued;
            ammToPay = protocol0VariableInterestAccrued;
        }

        return (userToPay, ammToPay);
    }

    // ============ Calculates the interest accrued on a variable rate ============

    function _calculateVariableInterestAccrued(uint256 _notional, uint256 _protocol, uint256 _openSwapBorrowIndex) internal view returns (uint256) {
        // the adapter to use based on the protocol
        address adapter = _protocol == protocol0 ? adapter0 : adapter1;

        // get the current borrow index of the underlying asset
        uint256 currentBorrowIndex = IAdapter(adapter).getBorrowIndex(underlier);

        // The ratio between the current borrow index and the borrow index at time of open swap
        uint256 indexRatio = currentBorrowIndex.mul(TEN_EXP_18).div(_openSwapBorrowIndex);

        // notional * (current borrow index / borrow index when swap was opened) - notional
        return _notional.mul(indexRatio).div(TEN_EXP_18).sub(_notional);
    }

    // ============ Converts an amount to have the contract standard numfalse,ber of decimals ============

    function _convertToStandardDecimal(uint256 _amount) internal view returns (uint256) {

        // set adjustment direction to false to convert to standard pool decimals
        return _convertToDecimal(_amount, true);
    }


    // ============ Converts an amount to have the underlying token's number of decimals ============

    function _convertToUnderlierDecimal(uint256 _amount) internal view returns (uint256) {

        // set adjustment direction to true to convert to underlier decimals
        return _convertToDecimal(_amount, false);
    }

    // ============ Converts an amount to have a particular number of decimals ============

    
    function _convertToDecimal(uint256 _amount, bool _adjustmentDirection) internal view returns (uint256) {
        // the amount after it has been converted to have the underlier number of decimals
        uint256 convertedAmount;

        // the underlying token has less decimal places
        if (underlierDecimals < STANDARD_DECIMALS) {
            convertedAmount = _adjustmentDirection ? _amount.mul(10 ** decimalDifference) : _amount.div(10 ** decimalDifference);
        }

        // there is no difference in the decimal places
        else {
            convertedAmount = _amount;
        }

        return convertedAmount;
    }

    // ============ Calculates the difference between the underlying decimals and the standard decimals ============

    function _calculatedDecimalDifference(uint256 _x_decimal, uint256 _y_decimal) internal pure returns (uint256) {
        // the difference in decimals
        uint256 difference;

        // the second decimal is greater
        if (_x_decimal < _y_decimal) {
            difference = _y_decimal.sub(_x_decimal);
        }

        return difference;
    }

}