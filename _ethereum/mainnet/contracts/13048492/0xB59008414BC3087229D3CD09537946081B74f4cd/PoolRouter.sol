// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ISovWrapper.sol";
import "./ISmartPool.sol";
import "./IMintableERC20.sol";

import "./console.sol";

contract PoolRouter {
    using SafeMath for uint256;

    uint256 public constant LIQ_FEE_DECIMALS = 1000000; // 6 decimals
    uint256 public constant PROTOCOL_FEE_DECIMALS = 100000; // 5 decimals
    uint256 public constant MAX_OUT_RATIO = (uint256(10**18) / 3) + 1;

    uint256 public protocolFee = 99950; // 100% - 0.050%

    ISmartPool public smartPool;
    ISovWrapper public wrappingContract;
    IMintableERC20 public sovToken;

    address public treasury;

    constructor(
        address _smartPool,
        address _wrappingContract,
        address _treasury,
        address _sovToken,
        uint256 _protocolFee
    ) {
        smartPool = ISmartPool(_smartPool);
        wrappingContract = ISovWrapper(_wrappingContract);
        sovToken = IMintableERC20(_sovToken);
        treasury = _treasury;
        protocolFee = _protocolFee;
    }

    /**
        This methods performs the following actions:
            1. pull token for user
            2. joinswap into balancer pool, recieving lp
            3. stake lp tokens into Wrapping Contrat which mints SOV to User
    */
    function deposit(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut,
        uint256 liquidationFee
    ) public {
        // pull underlying token here
        IERC20(tokenIn).transferFrom(msg.sender, address(this), tokenAmountIn);

        //take fee before swap
        uint256 amountMinusFee = tokenAmountIn.mul(protocolFee).div(
            PROTOCOL_FEE_DECIMALS
        );

        uint256 poolAmountMinusFee = minPoolAmountOut.mul(protocolFee).div(
            PROTOCOL_FEE_DECIMALS
        );

        IERC20(tokenIn).approve(address(smartPool), amountMinusFee);

        // swap underlying token for LP
        smartPool.joinswapExternAmountIn(
            tokenIn,
            amountMinusFee,
            poolAmountMinusFee
        );

        // deposit LP for sender
        uint256 balance = smartPool.balanceOf(address(this));
        smartPool.approve(address(wrappingContract), balance);
        wrappingContract.deposit(msg.sender, balance, liquidationFee);

        // mint SOV
        sovToken.mint(msg.sender, balance);
    }

    /**
        This methods performs the following actions:
            1. pull tokens for user
            2. join into balancer pool, recieving lp
            3. stake lp tokens into Wrapping Contrat which mints SOV to User
    */
    function depositAll(
        uint256 poolAmountOut,
        uint256[] calldata maxTokensAmountIn,
        uint256 liquidationFee
    ) public {
        address[] memory tokens = getPoolTokens();
        uint256[] memory amountsIn = _getTokensAmountIn(
            poolAmountOut,
            maxTokensAmountIn
        );

        uint256[] memory amountsInMinusFee = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenIn = tokens[i];
            uint256 tokenAmountIn = amountsIn[i];
            // pull underlying token here
            IERC20(tokenIn).transferFrom(
                msg.sender,
                address(this),
                tokenAmountIn
            );

            //take fee before swap
            uint256 amountMinusFee = tokenAmountIn.mul(protocolFee).div(
                PROTOCOL_FEE_DECIMALS
            );

            amountsInMinusFee[i] = amountMinusFee;

            IERC20(tokenIn).approve(address(smartPool), amountMinusFee);
        }

        uint256 poolAmountMinusFee = poolAmountOut.mul(protocolFee).div(
            PROTOCOL_FEE_DECIMALS
        );

        // swap underlying token for LP
        smartPool.joinPool(poolAmountMinusFee, amountsInMinusFee);

        // deposit LP for sender
        uint256 balance = smartPool.balanceOf(address(this));
        smartPool.approve(address(wrappingContract), balance);
        wrappingContract.deposit(msg.sender, balance, liquidationFee);

        // mint SOV
        sovToken.mint(msg.sender, balance);
    }

    /**
        This methods performs the following actions:
            1. burn SOV from user and unstake lp
            2. exitswap lp into one of the underlyings
            3. send the underlying to the User
    */
    function withdraw(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) public {
        require(
            sovToken.balanceOf(msg.sender) >= poolAmountIn,
            "Not enought SOV tokens"
        );
        // burns SOV from sender
        sovToken.burn(msg.sender, poolAmountIn);

        //recieve LP from sender to here
        wrappingContract.withdraw(msg.sender, poolAmountIn);

        //get balance before exitswap
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        //swaps LP for underlying
        smartPool.exitswapPoolAmountIn(tokenOut, poolAmountIn, minAmountOut);

        //get balance after exitswap
        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));

        //take fee before transfer out
        uint256 amountMinusFee = (balanceAfter.sub(balanceBefore))
            .mul(protocolFee)
            .div(PROTOCOL_FEE_DECIMALS);

        IERC20(tokenOut).transfer(msg.sender, amountMinusFee);
    }

    /**
        This methods performs the following actions:
            1. burn SOV from user and unstake lp
            2. exitswap lp into all of the underlyings
            3. send the underlyings to the User
    */
    function withdrawAll(uint256 poolAmountIn, uint256[] memory minAmountsOut)
        public
    {
        address[] memory tokens = getPoolTokens();

        uint256[] memory balancesBefore = new uint256[](tokens.length);

        require(
            sovToken.balanceOf(msg.sender) >= poolAmountIn,
            "Not enought SOV tokens"
        );
        // burns SOV from sender
        sovToken.burn(msg.sender, poolAmountIn);

        //recieve LP from sender to here
        wrappingContract.withdraw(msg.sender, poolAmountIn);

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenOut = tokens[i];

            //get balance before exitswap
            balancesBefore[i] = IERC20(tokenOut).balanceOf(address(this));
        }

        //swaps LP for underlying
        smartPool.exitPool(poolAmountIn, minAmountsOut);

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenOut = tokens[i];

            //get balance after exitswap
            uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));

            //take fee before transfer out
            uint256 amountMinusFee = (balanceAfter.sub(balancesBefore[i]))
                .mul(protocolFee)
                .div(PROTOCOL_FEE_DECIMALS);

            IERC20(tokenOut).transfer(msg.sender, amountMinusFee);
        }
    }

    /**
        This methods performs the following actions:
            1. burn SOV from caller and unstake lp of liquidatedUser
            2. exitswap lp into one of the underlyings
            3. send the underlying to the caller
            4. transfer fee from caller to liquidatedUser
    */
    function liquidate(
        address liquidatedUser,
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) public {
        require(
            sovToken.balanceOf(msg.sender) >= poolAmountIn,
            "Not enought SOV tokens"
        );
        // burns SOV from sender
        sovToken.burn(msg.sender, poolAmountIn);

        // recieve LP to here
        wrappingContract.liquidate(msg.sender, liquidatedUser, poolAmountIn);

        //get balance before exitswap
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        //swaps LP for underlying
        smartPool.exitswapPoolAmountIn(tokenOut, poolAmountIn, minAmountOut);

        //get balance after exitswap
        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));

        //take protocol fee before transfer
        uint256 amountMinusFee = (balanceAfter.sub(balanceBefore))
            .mul(protocolFee)
            .div(100000);

        IERC20(tokenOut).transfer(msg.sender, amountMinusFee);

        // liquidation fee is paid in tokenOut tokens, it is set by lpOwner at deposit
        uint256 liquidationFeeAmount = (balanceAfter.sub(balanceBefore))
            .mul(wrappingContract.liquidationFee(liquidatedUser))
            .div(LIQ_FEE_DECIMALS);

        require(
            IERC20(tokenOut).allowance(msg.sender, address(this)) >=
                liquidationFeeAmount,
            "Insuffiecient allowance for liquidation Fee"
        );

        // transfer liquidation fee from liquidator to original owner
        IERC20(tokenOut).transferFrom(
            msg.sender,
            liquidatedUser,
            liquidationFeeAmount
        );
    }

    // transfer the entire fees collected in this contract to DAO treasury
    function collectFeesToDAO(address token) public {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(treasury, balance);
    }

    /**
        VIEWS
     */

    // gets all tokens currently in the pool
    function getPoolTokens() public view returns (address[] memory) {
        BPool bPool = smartPool.bPool();
        return bPool.getCurrentTokens();
    }

    // gets all tokens currently in the pool
    function getTokenWeights() public view returns (uint256[] memory) {
        address[] memory tokens = getPoolTokens();
        uint256[] memory weights = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            weights[i] = smartPool.getDenormalizedWeight(tokens[i]);
        }
        return weights;
    }

    // gets current LP exchange rate for single Asset
    function getSovAmountOutSingle(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) public view returns (uint256 poolAmountOut) {
        BPool bPool = smartPool.bPool();
        require(bPool.isBound(tokenIn), "ERR_NOT_BOUND");

        //apply protocol fee
        uint256 tokenAmountInAdj = tokenAmountIn.mul(protocolFee).div(
            PROTOCOL_FEE_DECIMALS
        );

        poolAmountOut = bPool.calcPoolOutGivenSingleIn(
            bPool.getBalance(tokenIn),
            bPool.getDenormalizedWeight(tokenIn),
            smartPool.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            tokenAmountInAdj,
            bPool.getSwapFee()
        );
        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_IN");
    }

    // gets current LP exchange rate for single Asset
    function getTokensAmountIn(
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) public view returns (uint256[] memory actualAmountsIn) {
        BPool bPool = smartPool.bPool();
        uint256 poolAmountOutAdj = poolAmountOut.mul(protocolFee).div(
            PROTOCOL_FEE_DECIMALS
        );

        address[] memory tokens = bPool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint256 poolTotal = smartPool.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint256 ratio = SafeMath.div(
            poolAmountOutAdj.mul(10**18),
            SafeMath.sub(poolTotal, 1)
        );

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint256[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 bal = bPool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint256 tokenAmountIn = SafeMath
                .mul(ratio, SafeMath.add(bal, 1))
                .div(10**18);

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    // gets current LP exchange rate for single token
    function getSovAmountInSingle(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) public view returns (uint256 poolAmountIn) {
        BPool bPool = smartPool.bPool();
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");

        //apply protocol fee
        uint256 tokenAmountOutAdj = tokenAmountOut.mul(protocolFee).div(
            PROTOCOL_FEE_DECIMALS
        );

        require(
            tokenAmountOutAdj <=
                SafeMath.mul(bPool.getBalance(tokenOut), MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );
        poolAmountIn = bPool.calcPoolInGivenSingleOut(
            bPool.getBalance(tokenOut),
            bPool.getDenormalizedWeight(tokenOut),
            smartPool.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            tokenAmountOutAdj,
            bPool.getSwapFee()
        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");
    }

    // gets current LP exchange rate for single token
    function getTokenAmountOutSingle(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minTokenAmountOut
    ) public view returns (uint256 tokenAmountOut) {
        BPool bPool = smartPool.bPool();
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");

        //apply protocol fee
        uint256 poolAmountInAdj = poolAmountIn.mul(protocolFee).div(
            PROTOCOL_FEE_DECIMALS
        );

        tokenAmountOut = bPool.calcSingleOutGivenPoolIn(
            bPool.getBalance(tokenOut),
            bPool.getDenormalizedWeight(tokenOut),
            smartPool.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            poolAmountInAdj,
            bPool.getSwapFee()
        );

        require(tokenAmountOut >= minTokenAmountOut, "ERR_LIMIT_OUT");
        require(
            tokenAmountOut <= bPool.getBalance(tokenOut).mul(MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );
    }

    // gets current LP exchange rate for all
    function getTokensAmountOut(
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    ) public view returns (uint256[] memory actualAmountsOut) {
        BPool bPool = smartPool.bPool();
        address[] memory tokens = bPool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint256 poolTotal = smartPool.totalSupply();

        uint256 ratio = SafeMath.div(
            poolAmountIn.mul(10**18),
            SafeMath.add(poolTotal, 1)
        );

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint256[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 bal = bPool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint256 tokenAmountOut = SafeMath
                .mul(ratio, SafeMath.sub(bal, 1))
                .div(10**18);

            //apply protocol fee
            tokenAmountOut = tokenAmountOut.mul(protocolFee).div(
                PROTOCOL_FEE_DECIMALS
            );

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    // gets current LP exchange rate for single Asset
    function _getTokensAmountIn(
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) internal view returns (uint256[] memory actualAmountsIn) {
        address manager = smartPool.getSmartPoolManagerVersion();
        return
            SmartPoolManager(manager).joinPool(
                ConfigurableRightsPool(address(smartPool)),
                smartPool.bPool(),
                poolAmountOut,
                maxAmountsIn
            );
    }
}
