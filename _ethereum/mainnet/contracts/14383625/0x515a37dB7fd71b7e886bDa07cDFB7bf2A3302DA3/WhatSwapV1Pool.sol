// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./Math.sol";
import "./SafeMath.sol";
import "./IWhatSwapFactoryV1.sol";
import "./SafeERC20.sol";

import "./ReentrancyGuard.sol";
import "./IFlashLoanReceiver.sol";

import "./WhatSwapV1ERC20.sol";

contract WhatSwapV1Pool is ERC20, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public token;
    address public factory;
    bool initialized;

    event Sync(uint reserve0, uint reserve1);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event FlashLoan(
        address indexed _target,
        address indexed _reserve,
        uint256 _amount,
        uint256 _totalFee,
        uint256 _protocolFee,
        uint256 _timestamp
    );

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'WhatSwapV1: EXPIRED');
        _;
    }

    constructor() { 
        
    }

    function initialize(address _token) external {
        require(!initialized, 'WhatSwapV1: ALREADY_INITIALIZED');

        initialized = true;
        factory = msg.sender;
        token = _token;
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'WhatSwapV1: ETH_TXN_FAILED');
    }

    function token0() external pure returns (address _token) {
        _token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function token1() external view returns (address _token) {
        _token = token;
    }

    function reserve0() external view returns (uint _reserve0) {
        _reserve0 = address(this).balance;
    }

    function reserve1() external view returns (uint _reserve1) {
        _reserve1 = IERC20(token).balanceOf(address(this));
    }

    function getReserves() external view returns(uint _reserve0, uint _reserve1, uint _blockTimestampLast) {
        return (
            address(this).balance,
            IERC20(token).balanceOf(address(this)),
            block.timestamp
        );
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'WhatSwapV1: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        require(amountOut > 0, 'WhatSwapV1: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function swapExactETHForTokens(uint amount1min, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint amount1) {
        address _token = token;        // gas savings
        uint reserve0_ = (address(this).balance).sub(msg.value);
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        
        amount1 = getAmountOut(msg.value, reserve0_, reserve1_);
        require(amount1min <= amount1, 'WhatSwapV1: SLIPPAGE_REACHED');
        IERC20(_token).safeTransfer(to, amount1);

        emit Swap(msg.sender, msg.value, 0, 0, amount1, to);
        emit Sync(reserve0_.add(msg.value), reserve1_.sub(amount1));
    }
    
    function swapETHForExactTokens(uint amount1, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint amount0) {
        address _token = token;        // gas savings
        uint reserve0_ = (address(this).balance).sub(msg.value);
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        
        amount0 = getAmountIn(amount1, reserve0_, reserve1_);
        require(amount0 <= msg.value, 'WhatSwapV1: SLIPPAGE_REACHED');
        IERC20(_token).safeTransfer(to, amount1);

        if(msg.value > amount0){ safeTransferETH(msg.sender, msg.value.sub(amount0)); }

        emit Swap(msg.sender, amount0, 0, 0, amount1, to);
        emit Sync(reserve0_.add(amount0), reserve1_.sub(amount1));
    }

    function swapExactTokensForETH(uint amount1, uint amount0min, address to, uint deadline) external ensure(deadline) nonReentrant returns (uint amount0) {
        address _token = token;        // gas savings
        uint reserve0_ = address(this).balance;
        uint reserve1_ = IERC20(_token).balanceOf(address(this));

        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount1);
        amount1 = (IERC20(_token).balanceOf(address(this))).sub(reserve1_);
        amount0 = getAmountOut(amount1, reserve1_, reserve0_);
        require(amount0min <= amount0, 'WhatSwapV1: SLIPPAGE_REACHED');
        
        safeTransferETH(to, amount0);

        emit Swap(msg.sender, 0, amount1, amount0, 0, to);
        emit Sync(reserve0_.sub(amount0), reserve1_.add(amount1));
    }

    function swapTokensForExactETH(uint amount0, uint amount1max, address to, uint deadline) external ensure(deadline) nonReentrant returns (uint amount1) {
        address _token = token;        // gas savings
        uint reserve0_ = address(this).balance;
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        
        amount1 = getAmountIn(amount0, reserve1_, reserve0_);
        require(amount1 <= amount1max, 'WhatSwapV1: SLIPPAGE_REACHED');
        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount1);
        require(amount1 == (IERC20(_token).balanceOf(address(this))).sub(reserve1_), 'WhatSwapV1: DEFLATIONARY_TOKEN_USE_EXACT_TOKENS');
        
        safeTransferETH(to, amount0);

        emit Swap(msg.sender, 0, amount1, amount0, 0, to);
        emit Sync(reserve0_.sub(amount0), reserve1_.add(amount1));
    }

    function _addLPinternal(uint amount0min, uint amount1, address from, address to) internal returns (uint lpAmount) {
        require(msg.value > 0 && amount1 > 0, 'WhatSwapV1: INVALID_AMOUNT');
        address _token = token;        // gas savings
        uint reserve0_ = (address(this).balance).sub(msg.value);
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        uint _totalSupply = totalSupply;

        IERC20(_token).safeTransferFrom(from, address(this), amount1);
        amount1 = (IERC20(_token).balanceOf(address(this))).sub(reserve1_);

        uint amount0;
        if(_totalSupply > 0){
            amount0 = ( amount1.mul( reserve0_ ) ).div(reserve1_);
            require(amount0 <= msg.value, 'WhatSwapV1: SLIPPAGE_REACHED_DESIRED');
            require(amount0 >= amount0min, 'WhatSwapV1: SLIPPAGE_REACHED_MIN');
        } 
        else {
            amount0 = msg.value;
        }

        if (_totalSupply == 0) {
            lpAmount = Math.sqrt(amount0.mul(amount1)).sub(10**3);
           _mint(address(0), 10**3);
        } else {
            lpAmount = Math.min(amount0.mul(_totalSupply) / reserve0_, amount1.mul(_totalSupply) / reserve1_);
        }

        require(lpAmount > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY_MINTED');

        // refund only if value is > 1000 wei
        if(msg.value > amount0.add(1000)){
            safeTransferETH(from, msg.value.sub(amount0));
        }

        uint _fee = IWhatSwapV1Factory(factory).lpFee();
        if(_fee > 0){
            uint _feeAmount = ( lpAmount.mul(_fee) ).div(10**4);
            _mint(IWhatSwapV1Factory(factory).feeTo(), _feeAmount);
            lpAmount = lpAmount.sub(_feeAmount);
        }

        _mint(to, lpAmount);

        emit Mint(from, amount0, amount1);
        emit Sync(reserve0_.add(amount0), reserve1_.add(amount1));
    }

    function addLPfromFactory(uint amount0min, uint amount1, address from, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint lpAmount) {
        require(msg.sender == factory, 'WhatSwapV1: FORBIDDEN');
        lpAmount = _addLPinternal(amount0min, amount1, from, to);
    }

    function addLP(uint amount0min, uint amount1, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint lpAmount) {
        lpAmount = _addLPinternal(amount0min, amount1, msg.sender, to);
    }

    function removeLiquidity(uint lpAmount, address to, uint deadline) external ensure(deadline) nonReentrant returns (uint amount0, uint amount1) {
        require(lpAmount > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY');
        address _token = token;        // gas savings

        uint reserve0_ = address(this).balance;
        uint reserve1_ = IERC20(_token).balanceOf(address(this));

        uint _totalSupply = totalSupply; 
        amount0 = lpAmount.mul(reserve0_) / _totalSupply; 
        amount1 = lpAmount.mul(reserve1_) / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, 'WhatSwapV1: INSUFFICIENT_LIQUIDITY_BURNED');

        _burn(msg.sender, lpAmount);

        IERC20(_token).safeTransfer(to, amount1);
        safeTransferETH(to, amount0);

        emit Burn(msg.sender, amount0, amount1, to);
        emit Sync(reserve0_.sub(amount0), reserve1_.sub(amount1));
    }

    function transferFlashLoanProtocolFeeInternal(address _token, uint256 _amount, bool isEth) internal {
        address distributorAddress = IWhatSwapV1Factory(factory).feeTo();
        if (isEth) {
            safeTransferETH(distributorAddress, _amount);
        } else {
            IERC20(_token).safeTransfer(distributorAddress, _amount);
        }
    }
    
    function flashLoan(address _receiver, bool _takeEth, uint _amount, bytes calldata _params) external nonReentrant {
        require(_amount > 0, "Amount must be greater than 0");
        address _token = token;        // gas savings

        //check that the reserve has enough available liquidity
        uint256 availableLiquidityBefore = _takeEth
            ? address(this).balance
            : IERC20(_token).balanceOf(address(this));

        require(
            availableLiquidityBefore >= _amount,
            "There is not enough liquidity available to borrow"
        );

        (uint256 totalFeeBips, uint256 protocolFeeBips) = IWhatSwapV1Factory(factory).getFlashLoanFeesInBips();
        //calculate amount fee
        uint256 amountFee = _amount.mul(totalFeeBips).div(10000);
        //protocol fee is the part of the amountFee reserved for the protocol - the rest goes to depositors
        uint256 protocolFee = amountFee.mul(protocolFeeBips).div(10000);
        require(
            amountFee > 0 && protocolFee > 0,
            "The requested amount is too small for a flashLoan."
        );
        
        //transfer funds to the receiver
        if (_takeEth) {
            safeTransferETH(_receiver, _amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }

        //execute action of the receiver
        if (_takeEth) {
            IFlashLoanReceiver(_receiver).executeOperation(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, _amount, amountFee, _params);
        } else {
            IFlashLoanReceiver(_receiver).executeOperation(_token, _amount, amountFee, _params);
        }

        //check that the actual balance of the core contract includes the returned amount
        uint256 availableLiquidityAfter = _takeEth
            ? address(this).balance
            : IERC20(_token).balanceOf(address(this));

        require(
            availableLiquidityAfter >= availableLiquidityBefore.add(amountFee),
            "The actual balance of the protocol is inconsistent"
        );
        
        transferFlashLoanProtocolFeeInternal(_token, protocolFee, _takeEth);

        //solium-disable-next-line
        emit FlashLoan(_receiver, _token, _amount, amountFee, protocolFee, block.timestamp);
        emit Sync(address(this).balance, IERC20(_token).balanceOf(address(this)));
    }
}