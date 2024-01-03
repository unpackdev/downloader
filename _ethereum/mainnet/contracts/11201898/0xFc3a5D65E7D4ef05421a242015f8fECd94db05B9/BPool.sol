// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.6;

import "./BToken.sol";
import "./BMath.sol";

// Core contract; can't be changed. So disable solhint (reminder for v2)

/* solhint-disable func-order */
/* solhint-disable event-name-camelcase */

contract BPool is BBronze, BToken, BMath {

    struct Record {
        bool bound;   // is token bound to pool
        uint index;   // private
        uint denorm;  // denormalized weight
        uint balance;
    }

    event LOG_SWAP(
        address indexed caller,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256         tokenAmountIn,
        uint256         tokenAmountOut
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
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "ERR_REENTRY");
        _;
    }

    bool private _mutex;

    address private _factory;    // BFactory address to push token exitFee to
    address private _controller; // has CONTROL role
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint private _swapFee;
    uint private _exitFee;
    bool private _finalized;

    address[] private _tokens;
    mapping(address=>Record) private  _records;
    uint private _totalWeight;

    // fraction of the pool that has accrued due to fees since last fee harvest
    uint private _fracPoolFees;

    constructor() public {
        _controller = msg.sender;
        _factory = msg.sender;
        _swapFee = MIN_FEE;
        _publicSwap = false;
        _finalized = false;
    }

    function isPublicSwap()
        external view
        returns (bool)
    {
        return _publicSwap;
    }

    function isFinalized()
        external view
        returns (bool)
    {
        return _finalized;
    }

    function isBound(address t)
        external view
        returns (bool)
    {
        return _records[t].bound;
    }

    function getNumTokens()
        external view
        returns (uint) 
    {
        return _tokens.length;
    }

    function getCurrentTokens()
        external view _viewlock_
        returns (address[] memory tokens)
    {
        return _tokens;
    }

    function getFinalTokens()
        external view
        _viewlock_
        returns (address[] memory tokens)
    {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    function getDenormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight()
        external view
        _viewlock_
        returns (uint)
    {
        return _totalWeight;
    }

    function getNormalizedWeight(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
        uint denorm = _records[token].denorm;
        return bdiv(denorm, _totalWeight);
    }

    function getBalance(address token)
        external view
        _viewlock_
        returns (uint)
    {

        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function getSwapFee()
        external view
        _viewlock_
        returns (uint)
    {
        return _swapFee;
    }

    function getFracPoolFees()
        external view
        _viewlock_
        returns (uint)
    {
        return _fracPoolFees;
    }

    function getController()
        external view
        _viewlock_
        returns (address)
    {
        return _controller;
    }

    function setSwapFee(uint swapFee)
        external
        _logs_
        _lock_
    { 
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
        _swapFee = swapFee;
    }

    function setExitFee(uint exitFee)
        external
        _logs_
        _lock_
    {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(exitFee <= MAX_FEE, "ERR_MAX_FEE");
        _exitFee = exitFee;
    }

    function getExitFee()
        external view
        _viewlock_
        returns (uint)
    {
        return _exitFee;
    }

    function setController(address manager)
        external
        _logs_
        _lock_
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _controller = manager;
    }

    function setPublicSwap(bool public_)
        external
        _logs_
        _lock_
    {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _publicSwap = public_;
    }

    // Not needed for ConfigurableRightsPool
    // function finalize()
    //     external
    //     _logs_
    //     _lock_
    // {
    //     require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
    //     require(!_finalized, "ERR_IS_FINALIZED");
    //     require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");

    //     _finalized = true;
    //     _publicSwap = true;

    //     _mintPoolShare(INIT_POOL_SUPPLY);
    //     _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    // }


    function bind(address token, uint balance, uint denorm)
        external
        _logs_
        // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        // No bound on max tokens in Alpaca
        // Governance determines how many and which tokens are included
        // require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0,    // balance and denorm will be validated
            balance: 0   // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    function rebind(address token, uint balance, uint denorm)
        public
        _logs_
        _lock_
    {

        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
        require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        } else if (denorm < oldWeight) {
            _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
        }        
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            // In this case liquidity is being withdrawn, so charge EXIT_FEE
            uint tokenBalanceWithdrawn = bsub(oldBalance, balance);
            // uint tokenExitFee = bmul(tokenBalanceWithdrawn, EXIT_FEE);
            // uint tokenExitFee = bmul(tokenBalanceWithdrawn, _exitFee);
            uint tokenExitFee = 0;
            _pushUnderlying(token, msg.sender, bsub(tokenBalanceWithdrawn, tokenExitFee));
            // _pushUnderlying(token, _factory, tokenExitFee);
            // _pushUnderlying(token, msg.sender, tokenBalanceWithdrawn);
        }
    }

    function unbind(address token)
        external
        _logs_
        _lock_
    {

        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        uint tokenBalance = _records[token].balance;
        // uint tokenExitFee = bmul(tokenBalance, EXIT_FEE);
        // uint tokenExitFee = bmul(tokenBalance, _exitFee);
        uint tokenExitFee = 0;

        _totalWeight = bsub(_totalWeight, _records[token].denorm);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint index = _records[token].index;
        uint last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({
            bound: false,
            index: 0,
            denorm: 0,
            balance: 0
        });

        _pushUnderlying(token, msg.sender, bsub(tokenBalance, tokenExitFee));
        _pushUnderlying(token, _factory, tokenExitFee);
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token)
        external
        _logs_
        _lock_
    {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = IERC20(token).balanceOf(address(this));
    }

    function getSpotPrice(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, _swapFee);
    }

    function getSpotPriceSansFee(address tokenIn, address tokenOut)
        external view
        _viewlock_
        returns (uint spotPrice)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        Record storage inRecord = _records[tokenIn];
        Record storage outRecord = _records[tokenOut];
        return calcSpotPrice(inRecord.balance, inRecord.denorm, outRecord.balance, outRecord.denorm, 0);
    }

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external
        _logs_
        _lock_
    {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    // function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
    //     external
    //     _logs_
    //     _lock_
    // {
    //     require(_finalized, "ERR_NOT_FINALIZED");

    //     uint poolTotal = totalSupply();
    //     // uint exitFee = bmul(poolAmountIn, EXIT_FEE);
    //     uint exitFee = bmul(poolAmountIn, _exitFee);
    //     uint pAiAfterExitFee = bsub(poolAmountIn, exitFee);
    //     uint ratio = bdiv(pAiAfterExitFee, poolTotal);
    //     require(ratio != 0, "ERR_MATH_APPROX");

    //     _pullPoolShare(msg.sender, poolAmountIn);
    //     _pushPoolShare(_factory, exitFee);
    //     _burnPoolShare(pAiAfterExitFee);

    //     for (uint i = 0; i < _tokens.length; i++) {
    //         address t = _tokens[i];
    //         uint bal = _records[t].balance;
    //         uint tokenAmountOut = bmul(ratio, bal);
    //         require(tokenAmountOut != 0, "ERR_MATH_APPROX");
    //         require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
    //         _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
    //         emit LOG_EXIT(msg.sender, t, tokenAmountOut);
    //         _pushUnderlying(t, msg.sender, tokenAmountOut);
    //     }
    // }


    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut,
        uint maxPrice
    )
        external
        _logs_
        _lock_
        returns (uint tokenAmountOut, uint spotPriceAfter)
    {

        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountIn <= bmul(inRecord.balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountOut = calcOutGivenIn(
                            inRecord.balance,
                            inRecord.denorm,
                            outRecord.balance,
                            outRecord.denorm,
                            tokenAmountIn,
                            _swapFee
                        );
        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                _swapFee
                            );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");     
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        uint fracPoolFeesTrade = calcFracPoolFeesFromSwap(tokenIn, tokenAmountIn);
        _updateFracPoolFees(fracPoolFeesTrade);

        return (tokenAmountOut, spotPriceAfter);
    }

    function swapExactAmountOut(
        address tokenIn,
        uint maxAmountIn,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPrice
    )
        external
        _logs_
        _lock_ 
        returns (uint tokenAmountIn, uint spotPriceAfter)
    {
        require(_records[tokenIn].bound, "ERR_NOT_BOUND");
        require(_records[tokenOut].bound, "ERR_NOT_BOUND");
        require(_publicSwap, "ERR_SWAP_NOT_PUBLIC");

        Record storage inRecord = _records[address(tokenIn)];
        Record storage outRecord = _records[address(tokenOut)];

        require(tokenAmountOut <= bmul(outRecord.balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

        uint spotPriceBefore = calcSpotPrice(
                                    inRecord.balance,
                                    inRecord.denorm,
                                    outRecord.balance,
                                    outRecord.denorm,
                                    _swapFee
                                );
        require(spotPriceBefore <= maxPrice, "ERR_BAD_LIMIT_PRICE");

        tokenAmountIn = calcInGivenOut(
                            inRecord.balance,
                            inRecord.denorm,
                            outRecord.balance,
                            outRecord.denorm,
                            tokenAmountOut,
                            _swapFee
                        );
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        inRecord.balance = badd(inRecord.balance, tokenAmountIn);
        outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

        spotPriceAfter = calcSpotPrice(
                                inRecord.balance,
                                inRecord.denorm,
                                outRecord.balance,
                                outRecord.denorm,
                                _swapFee
                            );
        require(spotPriceAfter >= spotPriceBefore, "ERR_MATH_APPROX");
        require(spotPriceAfter <= maxPrice, "ERR_LIMIT_PRICE");
        require(spotPriceBefore <= bdiv(tokenAmountIn, tokenAmountOut), "ERR_MATH_APPROX");

        emit LOG_SWAP(msg.sender, tokenIn, tokenOut, tokenAmountIn, tokenAmountOut);

        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        // Update the running fraction of the pool attributable to accumulated fees
        uint fracPoolFeesTrade = calcFracPoolFeesFromSwap(tokenIn, tokenAmountIn);
        _updateFracPoolFees(fracPoolFeesTrade);

        return (tokenAmountIn, spotPriceAfter);
    }


    /* 
        Unused functions in CRP - disable to keep size of BFactory down
    */

    // function joinswapExternAmountIn(address tokenIn, uint tokenAmountIn, uint minPoolAmountOut)
    //     external
    //     _logs_
    //     _lock_
    //     returns (uint poolAmountOut)

    // {
    //     require(_finalized, "ERR_NOT_FINALIZED");
    //     require(_records[tokenIn].bound, "ERR_NOT_BOUND");
    //     require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

    //     Record storage inRecord = _records[tokenIn];

    //     poolAmountOut = calcPoolOutGivenSingleIn(
    //                         inRecord.balance,
    //                         inRecord.denorm,
    //                         _totalSupply,
    //                         _totalWeight,
    //                         tokenAmountIn,
    //                         _swapFee
    //                     );

    //     require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");

    //     inRecord.balance = badd(inRecord.balance, tokenAmountIn);

    //     emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

    //     _mintPoolShare(poolAmountOut);
    //     _pushPoolShare(msg.sender, poolAmountOut);
    //     _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

    //     // Update the running fraction of the pool attributable to accumulated fees
    //     uint fracPoolFeesTrade = calcFracPoolFeesFromPoolJoin(tokenIn, tokenAmountIn);
    //     _updateFracPoolFees(fracPoolFeesTrade);
        
    //     return poolAmountOut;
    // }

    // function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn)
    //     external
    //     _logs_
    //     _lock_
    //     returns (uint tokenAmountIn)
    // {
    //     require(_finalized, "ERR_NOT_FINALIZED");
    //     require(_records[tokenIn].bound, "ERR_NOT_BOUND");

    //     Record storage inRecord = _records[tokenIn];

    //     tokenAmountIn = calcSingleInGivenPoolOut(
    //                         inRecord.balance,
    //                         inRecord.denorm,
    //                         _totalSupply,
    //                         _totalWeight,
    //                         poolAmountOut,
    //                         _swapFee
    //                     );

    //     require(tokenAmountIn != 0, "ERR_MATH_APPROX");
    //     require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");
        
    //     require(tokenAmountIn <= bmul(_records[tokenIn].balance, MAX_IN_RATIO), "ERR_MAX_IN_RATIO");

    //     inRecord.balance = badd(inRecord.balance, tokenAmountIn);

    //     emit LOG_JOIN(msg.sender, tokenIn, tokenAmountIn);

    //     _mintPoolShare(poolAmountOut);
    //     _pushPoolShare(msg.sender, poolAmountOut);
    //     _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

    //     // Update the running fraction of the pool attributable to accumulated fees
    //     uint fracPoolFeesTrade = calcFracPoolFeesFromPoolJoin(tokenIn, tokenAmountIn);
    //     _updateFracPoolFees(fracPoolFeesTrade);

    //     return tokenAmountIn;
    // }

    // function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut)
    //     external
    //     _logs_
    //     _lock_
    //     returns (uint tokenAmountOut)
    // {
    //     require(_finalized, "ERR_NOT_FINALIZED");
    //     require(_records[tokenOut].bound, "ERR_NOT_BOUND");

    //     Record storage outRecord = _records[tokenOut];

    //     tokenAmountOut = calcSingleOutGivenPoolIn(
    //                         outRecord.balance,
    //                         outRecord.denorm,
    //                         _totalSupply,
    //                         _totalWeight,
    //                         poolAmountIn,
    //                         _swapFee,
    //                         _exitFee
    //                     );

    //     require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        
    //     require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

    //     outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

    //     // uint exitFee = bmul(poolAmountIn, EXIT_FEE);
    //     uint exitFee = bmul(poolAmountIn, _exitFee);

    //     emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    //     _pullPoolShare(msg.sender, poolAmountIn);
    //     _burnPoolShare(bsub(poolAmountIn, exitFee));
    //     _pushPoolShare(_factory, exitFee);
    //     _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

    //     // Update the running fraction of the pool attributable to accumulated fees
    //     uint fracPoolFeesTrade = calcFracPoolFeesFromPoolExit(tokenOut, tokenAmountOut);
    //     _updateFracPoolFees(fracPoolFeesTrade);

    //     return tokenAmountOut;
    // }

    // function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn)
    //     external
    //     _logs_
    //     _lock_
    //     returns (uint poolAmountIn)
    // {
    //     require(_finalized, "ERR_NOT_FINALIZED");
    //     require(_records[tokenOut].bound, "ERR_NOT_BOUND");
    //     require(tokenAmountOut <= bmul(_records[tokenOut].balance, MAX_OUT_RATIO), "ERR_MAX_OUT_RATIO");

    //     Record storage outRecord = _records[tokenOut];

    //     poolAmountIn = calcPoolInGivenSingleOut(
    //                         outRecord.balance,
    //                         outRecord.denorm,
    //                         _totalSupply,
    //                         _totalWeight,
    //                         tokenAmountOut,
    //                         _swapFee,
    //                         _exitFee
    //                     );

    //     require(poolAmountIn != 0, "ERR_MATH_APPROX");
    //     require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

    //     outRecord.balance = bsub(outRecord.balance, tokenAmountOut);

    //     // uint exitFee = bmul(poolAmountIn, EXIT_FEE);
    //     uint exitFee = bmul(poolAmountIn, _exitFee);

    //     emit LOG_EXIT(msg.sender, tokenOut, tokenAmountOut);

    //     _pullPoolShare(msg.sender, poolAmountIn);
    //     _burnPoolShare(bsub(poolAmountIn, exitFee));
    //     _pushPoolShare(_factory, exitFee);
    //     _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);        

    //     // Update the running fraction of the pool attributable to accumulated fees
    //     uint fracPoolFeesTrade = calcFracPoolFeesFromPoolExit(tokenOut, tokenAmountOut);
    //     _updateFracPoolFees(fracPoolFeesTrade);
        
    //     return poolAmountIn;
    // }


    /*
        Internal function to upate the running fraction of the pool attributable to accumulated fees

        Fee value as a percentage of the portfolio value at after trade t 
        (that is, the one that brings us from state T=t-1 to T=t) 
        if the input asset is i is:

        F_{t,t} = w_i * (f * D_{i,t}) / B_{i,t}

        where

        f = fee
        D_{i,t} = amount of the input asset traded in to the pool for trade t
        f * D_{i,t} = the value of the fee for trade t in terms of asset i
        B_{i,t} = amount of input asset in the pool after trade t
        w_i = weight of input asset
        and V_t = B_{i,t} / w_i = the value of the poot after trade t in terms of asset i

        For the total fee earned between T=0 and T=t, 
        we need to dilute the previous total amount by the new fee ownership

        That is, let G_{t} be the total accumulated fees between T=0 and T=t.  
        
        Then 

        G_{t+1} = G_{t} * (1 - F_{t+1,t+1}) + F_{t+1,t+1}

        So after each trade t, we need to:

        1. Retrieve G_{t-1} from global storage
        2. Calculate F_{t,t}
        3. Calculate G_{t}
        4. Store G_{t} in global storage
    */
    function calcFracPoolFeesFromSwap(
        address tokenIn,
        uint tokenAmountIn
    )
        public
        view
        returns (uint fracPoolFeesTrade)
    {
        uint balT = _records[tokenIn].balance;
        uint denorm = _records[tokenIn].denorm;
        uint weight = bdiv(denorm, _totalWeight);       // norm weight for tokenIn

        uint feeAmt = bmul(_swapFee, tokenAmountIn);    // fee size in terms of tokenIn
        fracPoolFeesTrade = bmul(weight, bdiv(feeAmt, balT));
        
        // uint fracPoolFeesPrev = _fracPoolFees;
        // uint dilutionFactor = bsub(BONE, fracPoolFeesTrade);
        // uint fracPoolFeesCurr = badd(bmul(fracPoolFeesPrev, dilutionFactor), fracPoolFeesTrade);
        // _fracPoolFees = fracPoolFeesCurr;
        
        return fracPoolFeesTrade;
    }

    /*
        Same as above, but for single-token pool joins (i.e. token in => pool shares out)
        Fees are only assessed on the fraction of the input token that is traded, i.e. (1-weight)
        See BMath.sol for more detail
    */
    function calcFracPoolFeesFromPoolJoin(
        address tokenIn,
        uint tokenAmountIn
    )
        public
        view
        returns (uint fracPoolFeesTrade)
    {
        uint balT = _records[tokenIn].balance;
        uint denorm = _records[tokenIn].denorm;
        uint weight = bdiv(denorm, _totalWeight);       // norm weight for tokenIn
        uint tokenAmountInTraded = bmul(tokenAmountIn, bsub(BONE, weight));

        uint feeAmt = bmul(_swapFee, tokenAmountInTraded);    // fee size in terms of tokenIn
        fracPoolFeesTrade = bmul(weight, bdiv(feeAmt, balT));
        
        // uint fracPoolFeesPrev = _fracPoolFees;
        // uint dilutionFactor = bsub(BONE, fracPoolFeesTrade);
        // uint fracPoolFeesCurr = badd(bmul(fracPoolFeesPrev, dilutionFactor), fracPoolFeesTrade);
        // _fracPoolFees = fracPoolFeesCurr;
        
        return fracPoolFeesTrade;
    }

    /*
        Same as above, but for single-token pool exits (i.e. pool shares in => token out)
        Swap fees are charged on the output token side
        See BMath.sol for more detail
        Note: Disregards exit fees
        
        Math:
        tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee)
        feeAmt = tAoBeforeSwapFee - tAo
               = tAo * [1 / (1 - (1-weightTo) * swapFee) - 1]
               = tAo * ((1-weightTo) * swapFee) / (1 - (1-weightTo) * swapFee)
    */
    function calcFracPoolFeesFromPoolExit(
        address tokenOut,
        uint tokenAmountOutAfterFees
    )
        public
        view
        returns (uint fracPoolFeesTrade)
    {
        uint balT = _records[tokenOut].balance;
        uint denorm = _records[tokenOut].denorm;
        uint weight = bdiv(denorm, _totalWeight);       // norm weight for tokenOut
        
        // fee size in terms of tokenOut
        uint fracTokenOutTradedTimesFee = bmul(bsub(BONE, weight), _swapFee);   // gas savings
        uint feeAmt = bmul(tokenAmountOutAfterFees, bdiv(fracTokenOutTradedTimesFee, bsub(BONE, fracTokenOutTradedTimesFee)));
        
        fracPoolFeesTrade = bmul(weight, bdiv(feeAmt, balT));
        
        // uint fracPoolFeesPrev = _fracPoolFees;
        // uint dilutionFactor = bsub(BONE, fracPoolFeesTrade);
        // uint fracPoolFeesCurr = badd(bmul(fracPoolFeesPrev, dilutionFactor), fracPoolFeesTrade);
        // _fracPoolFees = fracPoolFeesCurr;

        return fracPoolFeesTrade;
    }


    /* 
        Update the fraction of pool fees based on previous trade
        See above function comment for explanation
    */
    function _updateFracPoolFees(
        uint fracPoolFeesTrade
    )
        internal
    {
        uint fracPoolFeesPrev = _fracPoolFees;
        uint dilutionFactor = bsub(BONE, fracPoolFeesTrade);
        uint fracPoolFeesCurr = badd(bmul(fracPoolFeesPrev, dilutionFactor), fracPoolFeesTrade);
        _fracPoolFees = fracPoolFeesCurr;
    }
    
    // External wrapper function to be called by ConfigurableRightsPool owner
    function updateFracPoolFees(
        uint fracPoolFeesTrade
    )
        external
        _logs_
        _lock_
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _updateFracPoolFees(fracPoolFeesTrade);
    }


    /* 
        Reset the running fraction of the pool attributable to accumulated fees
        Must be called any time fees are distributed externally
    */
    function resetFracPoolFees()
        external
        _logs_
        _lock_
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _fracPoolFees = 0;
    }


    // ==
    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety

    function _pullUnderlying(address erc20, address from, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pushUnderlying(address erc20, address to, uint amount)
        internal
    {
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

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

}
