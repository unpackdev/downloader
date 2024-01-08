// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.7.6;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20Metadata.sol";
import "./EIP20NonStandardInterface.sol";
import "./TokenMetadataGenerator.sol";

import "./Token.sol";
import "./Math.sol";
import "./IRepricer.sol";
import "./IDynamicFee.sol";
import "./IVault.sol";

contract Pool is Ownable, Pausable, Bronze, Token, Math, TokenMetadataGenerator {

    struct Record {
        uint leverage;
        uint balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         tokenAmountIn,
        uint256         tokenAmountOut,
        uint256         fee,
        uint256         tokenBalanceIn,
        uint256         tokenBalanceOut,
        uint256         tokenLeverageIn,
        uint256         tokenLeverageOut
    );

    event LOG_JOIN(
        address indexed caller,
        address indexed tokenIn,
        uint256         tokenAmountIn
    );

    event LOG_EXIT(
        address indexed caller,
        address indexed tokenOut,
        uint256         tokenAmountOut
    );

    event LOG_REPRICE(
        uint256         repricingBlock,
        uint256         balancePrimary,
        uint256         balanceComplement,
        uint256         leveragePrimary,
        uint256         leverageComplement,
        uint256         newLeveragePrimary,
        uint256         newLeverageComplement,
        int256          estPricePrimary,
        int256          estPriceComplement,
        int256          liveUnderlingValue
    );

    event LOG_CALL(
        bytes4  indexed sig,
        address indexed caller,
        bytes           data
    ) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        requireLock();
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        requireLock();
        _;
    }

    modifier onlyFinalized() {
        require(_finalized, "NOT_FINALIZED");
        _;
    }

    modifier onlyLiveDerivative() {
        require(
            block.timestamp < derivativeVault.settleTime(),
            "SETTLED"
        );
        _;
    }

    function requireLock() internal view
    {
        require(!_mutex, "REENTRY");
    }

    bool private _mutex;

    address private controller; // has CONTROL role

    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    bool private _finalized;

    uint public constant BOUND_TOKENS  = 2;
    address[BOUND_TOKENS] private _tokens;
    mapping(address => Record) internal _records;

    uint public repricingBlock;

    uint public baseFee;
    uint public feeAmp;
    uint public maxFee;

    uint public pMin;
    uint public qMin;
    uint public exposureLimit;
    uint public volatility;

    IVault public derivativeVault;
    IDynamicFee public dynamicFee;
    IRepricer public repricer;

    constructor(
        address _derivativeVault,
        address _dynamicFee,
        address _repricer,
        uint _baseFee,
        uint _maxFee,
        uint _feeAmp,
        address _controller
    )
        public
    {
        require(_derivativeVault != address(0), "NOT_D_VAULT");
        derivativeVault = IVault(_derivativeVault);

        require(_dynamicFee != address(0), "NOT_FEE");
        dynamicFee = IDynamicFee(_dynamicFee);

        require(_repricer != address(0), "NOT_REPRICER");
        repricer = IRepricer(_repricer);

        baseFee = _baseFee;
        feeAmp = _feeAmp;
        maxFee = _maxFee;

        require(_controller != address(0), "NOT_CONTROLLER");
        controller = _controller;

        string memory settlementDate = formatDate(derivativeVault.settleTime());

        setName(makeTokenName(derivativeVault.derivativeSpecification().name(), settlementDate, " LP"));
        setSymbol(makeTokenSymbol(derivativeVault.derivativeSpecification().symbol(), settlementDate, "-LP"));
    }

    function pause() external onlyOwner
    {
        _pause();
    }
    function unpause() external onlyOwner
    {
        _unpause();
    }

    function isFinalized()
        external view
        returns (bool)
    {
        return _finalized;
    }

    function getTokens()
        external view _viewlock_
        returns (address[BOUND_TOKENS] memory tokens)
    {
        return _tokens;
    }

    function getLeverage(address token)
        external view
        _viewlock_
        returns (uint)
    {

        return _records[token].leverage;
    }

    function getBalance(address token)
        external view
        _viewlock_
        returns (uint)
    {

        return _records[token].balance;
    }

    function finalize(
        uint _primaryBalance,
        uint _primaryLeverage,
        uint _complementBalance,
        uint _complementLeverage,
        uint _exposureLimit,
        uint _volatility,
        uint _pMin,
        uint _qMin
    )
        external
        _logs_
        _lock_
        onlyLiveDerivative
    {
        require(!_finalized, "IS_FINALIZED");
        require(msg.sender == controller, "NOT_CONTROLLER");

        require(_primaryBalance == _complementBalance, "NOT_SYMMETRIC");

        pMin = _pMin;
        qMin = _qMin;
        exposureLimit = _exposureLimit;
        volatility = _volatility;

        _finalized = true;

        bind(0, address(derivativeVault.primaryToken()), _primaryBalance, _primaryLeverage);
        bind(1, address(derivativeVault.complementToken()), _complementBalance, _complementLeverage);

        uint initPoolSupply = getDerivativeDenomination() * _primaryBalance;

        uint collateralDecimals = uint(IERC20Metadata(address(derivativeVault.collateralToken())).decimals());
        if(collateralDecimals >= 0 && collateralDecimals < 18) {
            initPoolSupply = initPoolSupply * (10 ** (18 - collateralDecimals));
        }

        _mintPoolShare(initPoolSupply);
        _pushPoolShare(msg.sender, initPoolSupply);
    }

    function bind(uint index, address token, uint balance, uint leverage)
    internal
    {
        require(balance >= qMin, "MIN_BALANCE");
        require(leverage > 0, "ZERO_LEVERAGE");

        _records[token] = Record({
            leverage: leverage,
            balance: balance
        });

        _tokens[index] = token;

        _pullUnderlying(token, msg.sender, balance);
    }

    function joinPool(uint poolAmountOut, uint[2] calldata maxAmountsIn)
        external
        _logs_
        _lock_
        onlyFinalized
    {

        uint poolTotal = totalSupply();
        uint ratio = div(poolAmountOut, poolTotal);
        require(ratio != 0, "MATH_APPROX");

        for (uint i = 0; i < BOUND_TOKENS; i++) {
            address token = _tokens[i];
            uint bal = _records[token].balance;
            require(bal > 0, "NO_BALANCE");
            uint tokenAmountIn = mul(ratio, bal);
            require(tokenAmountIn <= maxAmountsIn[i], "LIMIT_IN");
            _records[token].balance = add(_records[token].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, token, tokenAmountIn);
            _pullUnderlying(token, msg.sender, tokenAmountIn);
        }

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint poolAmountIn, uint[2] calldata minAmountsOut)
        external
        _logs_
        _lock_
        onlyFinalized
    {

        uint poolTotal = totalSupply();
        uint ratio = div(poolAmountIn, poolTotal);
        require(ratio != 0, "MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn);

        for (uint i = 0; i < BOUND_TOKENS; i++) {
            address token = _tokens[i];
            uint bal = _records[token].balance;
            require(bal > 0, "NO_BALANCE");
            uint tokenAmountOut = mul(ratio, bal);
            require(tokenAmountOut >= minAmountsOut[i], "LIMIT_OUT");
            _records[token].balance = sub(_records[token].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, token, tokenAmountOut);
            _pushUnderlying(token, msg.sender, tokenAmountOut);
        }
    }

    function reprice()
        internal virtual
    {
        if(repricingBlock == block.number) return;
        repricingBlock = block.number;

        Record storage primaryRecord = _records[_getPrimaryDerivativeAddress()];
        Record storage complementRecord = _records[_getComplementDerivativeAddress()];

        uint256[2] memory primaryParams = [primaryRecord.balance, primaryRecord.leverage];
        uint256[2] memory complementParams = [complementRecord.balance, complementRecord.leverage];

        (
            uint newPrimaryLeverage,
            uint newComplementLeverage,
            int estPricePrimary,
            int estPriceComplement
        ) = repricer.reprice(
            pMin,
            int(volatility),
            derivativeVault,
            primaryParams,
            complementParams,
            derivativeVault.underlyingStarts(0)
        );

        emit LOG_REPRICE(
            repricingBlock,
            primaryParams[0],
            complementParams[0],
            primaryParams[1],
            complementParams[1],
            newPrimaryLeverage,
            newComplementLeverage,
            estPricePrimary,
            estPriceComplement,
            derivativeVault.underlyingStarts(0)
        );

        primaryRecord.leverage = newPrimaryLeverage;
        complementRecord.leverage = newComplementLeverage;
    }

    function calcFee(
        Record memory inRecord,
        uint tokenAmountIn,
        Record memory outRecord,
        uint tokenAmountOut
    )
    internal
    returns (uint fee, int expStart)
    {
        int ifee;
        (ifee, expStart) = dynamicFee.calc(
            [int(inRecord.balance), int(inRecord.leverage), int(tokenAmountIn)],
            [int(outRecord.balance), int(outRecord.leverage), int(tokenAmountOut)],
            int(baseFee),
            int(feeAmp),
            int(maxFee)
        );
        require(ifee > 0, "BAD_FEE");
        fee = uint(ifee);
    }

    function calcExpStart(
        int _inBalance,
        int _outBalance
    )
    internal pure
    returns(int) {
        return (_inBalance - _outBalance) * iBONE / (_inBalance + _outBalance);
    }

    function performSwap(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint spotPriceBefore,
        uint fee
    )
    internal returns(uint spotPriceAfter)
    {
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];

        requireBoundaryConditions(inRecord, tokenAmountIn, outRecord, tokenAmountOut);

        updateLeverages(inRecord, tokenAmountIn, outRecord, tokenAmountOut);

        inRecord.balance = add(inRecord.balance, tokenAmountIn);
        outRecord.balance = sub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            dynamicFee.calcSpotFee(
                calcExpStart(
                    int(inRecord.balance),
                    int(outRecord.balance)
                ),
                baseFee,
                feeAmp,
                maxFee
            )
        );

        require(spotPriceAfter >= spotPriceBefore, "MATH_APPROX");
        require(spotPriceBefore <= div(tokenAmountIn, tokenAmountOut), "MATH_APPROX_OTHER");

        emit LOG_SWAP(
            msg.sender,
            tokenIn,
            tokenOut,
            tokenAmountIn,
            tokenAmountOut,
            fee,
            inRecord.balance,
            outRecord.balance,
            inRecord.leverage,
            outRecord.leverage
        );

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);
    }

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut
    )
        external
        _logs_
        _lock_
        whenNotPaused
        onlyFinalized
        onlyLiveDerivative
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {

        require(tokenIn != tokenOut, "SAME_TOKEN");
        require(tokenAmountIn >= qMin, "MIN_TOKEN_IN");

        reprice();

        Record memory inRecord = _records[tokenIn];
        Record memory outRecord = _records[tokenOut];

        require(tokenAmountIn <= mul(min(getLeveragedBalance(inRecord), inRecord.balance), MAX_IN_RATIO), "MAX_IN_RATIO");

        tokenAmountOut = calcOutGivenIn(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            tokenAmountIn,
            0
        );

        uint fee;
        int expStart;
        (fee, expStart) = calcFee(
            inRecord,
            tokenAmountIn,
            outRecord,
            tokenAmountOut
        );

        uint spotPriceBefore = calcSpotPrice(
                                    getLeveragedBalance(inRecord),
                                    getLeveragedBalance(outRecord),
                                    dynamicFee.calcSpotFee(expStart, baseFee, feeAmp, maxFee)
                                );

        tokenAmountOut = calcOutGivenIn(
                            getLeveragedBalance(inRecord),
                            getLeveragedBalance(outRecord),
                            tokenAmountIn,
                            fee
                        );
        require(tokenAmountOut >= minAmountOut, "LIMIT_OUT");

        spotPriceAfter = performSwap(
            tokenIn,
            tokenAmountIn,
            tokenOut,
            tokenAmountOut,
            spotPriceBefore,
            fee
        );
    }

    // Method temporary is not available for external usage.
    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut
    )
        private
        _logs_
        _lock_
        whenNotPaused
        onlyFinalized
        onlyLiveDerivative
        returns (uint tokenAmountIn, uint spotPriceAfter)
    {
        require(tokenIn != tokenOut, "SAME_TOKEN");
        require(tokenAmountOut >= qMin, "MIN_TOKEN_OUT");

        reprice();

        Record memory inRecord = _records[tokenIn];
        Record memory outRecord = _records[tokenOut];

        require(tokenAmountOut <= mul(min(getLeveragedBalance(outRecord), outRecord.balance), MAX_OUT_RATIO), "MAX_OUT_RATIO");

        tokenAmountIn = calcInGivenOut(
            getLeveragedBalance(inRecord),
            getLeveragedBalance(outRecord),
            tokenAmountOut,
            0
        );

        uint fee;
        int expStart;
        (fee, expStart) = calcFee(
            inRecord,
            tokenAmountIn,
            outRecord,
            tokenAmountOut
        );

        uint spotPriceBefore = calcSpotPrice(
                                    getLeveragedBalance(inRecord),
                                    getLeveragedBalance(outRecord),
                                    dynamicFee.calcSpotFee(expStart, baseFee, feeAmp, maxFee)
                                );

        tokenAmountIn = calcInGivenOut(
                            getLeveragedBalance(inRecord),
                            getLeveragedBalance(outRecord),
                            tokenAmountOut,
                            fee
                        );

        require(tokenAmountIn <= maxAmountIn, "LIMIT_IN");

        spotPriceAfter = performSwap(
            tokenIn,
            tokenAmountIn,
            tokenOut,
            tokenAmountOut,
            spotPriceBefore,
            fee
        );
    }

    function getLeveragedBalance(
        Record memory r
    )
    internal pure
    returns(uint)
    {
        return mul(r.balance, r.leverage);
    }

    function requireBoundaryConditions(
        Record storage inToken,
        uint tokenAmountIn,
        Record storage outToken,
        uint tokenAmountOut
    )
    internal view
    {

        require( sub(getLeveragedBalance(outToken), tokenAmountOut) > qMin, "BOUNDARY_LEVERAGED");
        require( sub(outToken.balance, tokenAmountOut) > qMin, "BOUNDARY_NON_LEVERAGED");

        uint denomination = getDerivativeDenomination() * BONE;
        uint lowerBound = div(pMin, sub(denomination, pMin));
        uint upperBound = div(sub(denomination, pMin), pMin);
        uint value = div(add(getLeveragedBalance(inToken), tokenAmountIn), sub(getLeveragedBalance(outToken), tokenAmountOut));

        require(lowerBound < value, "BOUNDARY_LOWER");
        require(value < upperBound, "BOUNDARY_UPPER");

        uint numerator;
        (numerator,) = subSign(add(add(inToken.balance, tokenAmountIn), tokenAmountOut), outToken.balance);

        uint denominator = sub(add(add(inToken.balance, tokenAmountIn), outToken.balance), tokenAmountOut);
        require(div(numerator, denominator) < exposureLimit, "BOUNDARY_EXPOSURE");
    }

    function updateLeverages(
        Record storage inToken,
        uint tokenAmountIn,
        Record storage outToken,
        uint tokenAmountOut
    )
    internal
    {
        outToken.leverage = div(
            sub(getLeveragedBalance(outToken), tokenAmountOut),
            sub(outToken.balance, tokenAmountOut)
        );
        require(outToken.leverage > 0, "ZERO_OUT_LEVERAGE");

        inToken.leverage = div(
            add(getLeveragedBalance(inToken), tokenAmountIn),
            add(inToken.balance, tokenAmountIn)
        );
        require(inToken.leverage > 0, "ZERO_IN_LEVERAGE");
    }

    function getDerivativeDenomination()
    internal view
    returns(uint denomination)
    {
        denomination =
            derivativeVault.derivativeSpecification().primaryNominalValue() +
            derivativeVault.derivativeSpecification().complementNominalValue();
    }

    function _getPrimaryDerivativeAddress()
    internal view
    returns(address)
    {
        return _tokens[0];
    }

    function _getComplementDerivativeAddress()
    internal view
    returns(address)
    {
        return _tokens[1];
    }

    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullPoolShare(address from, uint amount)
        internal
    {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint amount)
        internal
    {
        _push(to, amount);
    }

    function _mintPoolShare(uint amount)
        internal
    {
        _mint(amount);
    }

    function _burnPoolShare(uint amount)
        internal
    {
        _burn(amount);
    }

    /// @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
    /// This will revert due to insufficient balance or insufficient allowance.
    /// This function returns the actual amount received,
    /// which may be less than `amount` if there is a fee attached to the transfer.
    /// @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    /// See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    function _pullUnderlying(address erc20, address from, uint256 amount)
    internal
    returns (uint256)
    {
        uint256 balanceBefore = IERC20(erc20).balanceOf(address(this));
        EIP20NonStandardInterface(erc20).transferFrom(
            from,
            address(this),
            amount
        );

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
            // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
            // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
            // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(erc20).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /// @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
    /// error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
    /// insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
    /// it is >= amount, this should not revert in normal conditions.
    /// @notice This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    /// See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    function _pushUnderlying(address erc20, address to, uint256 amount) internal {
        EIP20NonStandardInterface(erc20).transfer(
            to,
            amount
        );

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
            // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
            // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
            // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
}
