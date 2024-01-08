// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IKeeperSubsidyPool.sol";
import "./IUniswapRouterV2.sol";
import "./IUniswapFactory.sol";
import "./IUniswapV2Pair.sol";
import "./IEToken.sol";
import "./IEPoolPeriphery.sol";
import "./IEPool.sol";
import "./ControllerMixin.sol";
import "./TokenUtils.sol";

import "./EPoolLibrary.sol";

import "./console.sol";

contract EPoolPeriphery is ControllerMixin, IEPoolPeriphery {
    using SafeERC20 for IERC20;
    using TokenUtils for IERC20;
    using TokenUtils for IEToken;

    IUniswapV2Factory public immutable override factory;
    IUniswapV2Router01 public immutable override router;
    // Keeper subsidy pool for making rebalancing via flash swaps capital neutral for msg.sender
    IKeeperSubsidyPool public immutable override keeperSubsidyPool;
    // supported EPools by the periphery
    mapping(address => bool) public override ePools;
    // max. allowed slippage between EPool oracle and uniswap when executing a flash swap
    uint256 public override maxFlashSwapSlippage;

    event IssuedEToken(
        address indexed ePool, address indexed eToken, uint256 amount, uint256 amountA, uint256 amountB, address user
    );
    event RedeemedEToken(
        address indexed ePool, address indexed eToken, uint256 amount, uint256 amountA, uint256 amountB, address user
    );
    event SetEPoolApproval(address indexed ePool, bool approval);
    event SetMaxFlashSwapSlippage(uint256 maxFlashSwapSlippage);
    event RecoveredToken(address token, uint256 amount);

    /**
     * @param _controller Address of the controller
     * @param _factory Address of the Uniswap V2 factory
     * @param _router Address of the Uniswap V2 router
     * @param _keeperSubsidyPool Address of keeper subsidiy pool
     * @param _maxFlashSwapSlippage Max. allowed slippage between EPool oracle and uniswap
     */
    constructor(
        IController _controller,
        IUniswapV2Factory _factory,
        IUniswapV2Router01 _router,
        IKeeperSubsidyPool _keeperSubsidyPool,
        uint256 _maxFlashSwapSlippage
    ) ControllerMixin(_controller) {
        factory = _factory;
        router = _router;
        keeperSubsidyPool = _keeperSubsidyPool;
        maxFlashSwapSlippage = _maxFlashSwapSlippage; // e.g. 1.05e18 -> 5% slippage
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
    function setController(address _controller) external override onlyDao("EPoolPeriphery: not dao") returns (bool) {
        _setController(_controller);
        return true;
    }

    /**
     * @notice Give or revoke approval a EPool for the EPoolPeriphery
     * @dev Can only called by the DAO or the guardian
     * @param ePool Address of the EPool
     * @param approval Boolean on whether approval for EPool should be given or revoked
     * @return True on success
     */
    function setEPoolApproval(
        IEPool ePool,
        bool approval
    ) external override onlyDaoOrGuardian("EPoolPeriphery: not dao or guardian") returns (bool) {
        if (approval) {
            // assuming EPoolPeriphery only holds funds within calls
            ePool.tokenA().approve(address(ePool), type(uint256).max);
            ePool.tokenB().approve(address(ePool), type(uint256).max);
            ePools[address(ePool)] = true;
        } else {
            ePool.tokenA().approve(address(ePool), 0);
            ePool.tokenB().approve(address(ePool), 0);
            ePools[address(ePool)] = false;
        }
        emit SetEPoolApproval(address(ePool), approval);
        return true;
    }

    /**
     * @notice Set max. slippage between EPool oracle and uniswap when performing flash swap
     * @dev Can only be callede by the DAO or the guardian
     * @param _maxFlashSwapSlippage Max. flash swap slippage
     * @return True on success
     */
    function setMaxFlashSwapSlippage(
        uint256 _maxFlashSwapSlippage
    ) external override onlyDaoOrGuardian("EPoolPeriphery: not dao or guardian") returns (bool) {
        maxFlashSwapSlippage = _maxFlashSwapSlippage;
        emit SetMaxFlashSwapSlippage(maxFlashSwapSlippage);
        return true;
    }

    /**
     * @notice Issues an amount of EToken for maximum amount of TokenA
     * @dev Reverts if maxInputAmountA is exceeded. Unused amount of TokenA is refunded to msg.sender.
     * Requires setting allowance for TokenA.
     * @param ePool Address of the EPool
     * @param eToken Address of the EToken of the tranche
     * @param amount Amount of EToken to issue
     * @param maxInputAmountA Max. amount of TokenA to deposit
     * @param deadline Timestamp at which tx expires
     * @return True on success
     */
    function issueForMaxTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountA,
        uint256 deadline
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (IERC20 tokenA, IERC20 tokenB) = (ePool.tokenA(), ePool.tokenB());
        tokenA.safeTransferFrom(msg.sender, address(this), maxInputAmountA);
        IEPool.Tranche memory t = ePool.getTranche(eToken);
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            t, amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        // swap part of input amount for amountB
        require(maxInputAmountA >= amountA, "EPoolPeriphery: insufficient max. input");
        uint256 amountAToSwap = maxInputAmountA - amountA;
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        tokenA.approve(address(router), amountAToSwap);
        uint256[] memory amountsOut = router.swapTokensForExactTokens(
            amountB, amountAToSwap, path, address(this), deadline
        );
        // do the deposit (TokenA is already approved)
        ePool.issueExact(eToken, amount);
        // transfer EToken to msg.sender
        IERC20(eToken).safeTransfer(msg.sender, amount);
        // refund unused maxInputAmountA -= amountA + amountASwappedForAmountB
        tokenA.safeTransfer(msg.sender, maxInputAmountA - amountA - amountsOut[0]);
        emit IssuedEToken(address(ePool), eToken, amount, amountA, amountB, msg.sender);
        return true;
    }

    /**
     * @notice Issues an amount of EToken for maximum amount of TokenB
     * @dev Reverts if maxInputAmountB is exceeded. Unused amount of TokenB is refunded to msg.sender.
     * Requires setting allowance for TokenB.
     * @param ePool Address of the EPool
     * @param eToken Address of the EToken of the tranche
     * @param amount Amount of EToken to issue
     * @param maxInputAmountB Max. amount of TokenB to deposit
     * @param deadline Timestamp at which tx expires
     * @return True on success
     */
    function issueForMaxTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 maxInputAmountB,
        uint256 deadline
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (IERC20 tokenA, IERC20 tokenB) = (ePool.tokenA(), ePool.tokenB());
        tokenB.safeTransferFrom(msg.sender, address(this), maxInputAmountB);
        IEPool.Tranche memory t = ePool.getTranche(eToken);
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            t, amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        // swap part of input amount for amountB
        require(maxInputAmountB >= amountB, "EPoolPeriphery: insufficient max. input");
        uint256 amountBToSwap = maxInputAmountB - amountB;
        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);
        tokenB.approve(address(router), amountBToSwap);
        uint256[] memory amountsOut = router.swapTokensForExactTokens(
            amountA, amountBToSwap, path, address(this), deadline
        );
        // do the deposit (TokenB is already approved)
        ePool.issueExact(eToken, amount);
        // transfer EToken to msg.sender
        IERC20(eToken).safeTransfer(msg.sender, amount);
        // refund unused maxInputAmountB -= amountB + amountBSwappedForAmountA
        tokenB.safeTransfer(msg.sender, maxInputAmountB - amountB - amountsOut[0]);
        emit IssuedEToken(address(ePool), eToken, amount, amountA, amountB, msg.sender);
        return true;
    }

    /**
     * @notice Redeems an amount of EToken for a min. amount of TokenA
     * @dev Reverts if minOutputA is not met. Requires setting allowance for EToken
     * @param ePool Address of the EPool
     * @param eToken Address of the EToken of the tranche
     * @param amount Amount of EToken to redeem
     * @param minOutputA Min. amount of TokenA to withdraw
     * @param deadline Timestamp at which tx expires
     * @return True on success
     */
    function redeemForMinTokenA(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputA,
        uint256 deadline
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (IERC20 tokenA, IERC20 tokenB) = (ePool.tokenA(), ePool.tokenB());
        IERC20(eToken).safeTransferFrom(msg.sender, address(this), amount);
        // do the withdraw
        IERC20(eToken).approve(address(ePool), amount);
        (uint256 amountA, uint256 amountB) = ePool.redeemExact(eToken, amount);
        // convert amountB withdrawn from EPool into TokenA
        address[] memory path = new address[](2);
        path[0] = address(tokenB);
        path[1] = address(tokenA);
        tokenB.approve(address(router), amountB);
        uint256[] memory amountsOut = router.swapExactTokensForTokens(
            amountB, 0, path, address(this), deadline
        );
        uint256 outputA = amountA + amountsOut[1];
        require(outputA >= minOutputA, "EPoolPeriphery: insufficient output amount");
        IERC20(tokenA).safeTransfer(msg.sender, outputA);
        emit RedeemedEToken(address(ePool), eToken, amount, amountA, amountB, msg.sender);
        return true;
    }

    /**
     * @notice Redeems an amount of EToken for a min. amount of TokenB
     * @dev Reverts if minOutputB is not met. Requires setting allowance for EToken
     * @param ePool Address of the EPool
     * @param eToken Address of the EToken of the tranche
     * @param amount Amount of EToken to redeem
     * @param minOutputB Min. amount of TokenB to withdraw
     * @param deadline Timestamp at which tx expires
     * @return True on success
     */
    function redeemForMinTokenB(
        IEPool ePool,
        address eToken,
        uint256 amount,
        uint256 minOutputB,
        uint256 deadline
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (IERC20 tokenA, IERC20 tokenB) = (ePool.tokenA(), ePool.tokenB());
        IERC20(eToken).safeTransferFrom(msg.sender, address(this), amount);
        // do the withdraw
        IERC20(eToken).approve(address(ePool), amount);
        (uint256 amountA, uint256 amountB) = ePool.redeemExact(eToken, amount);
        // convert amountB withdrawn from EPool into TokenA
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        tokenA.approve(address(router), amountA);
        uint256[] memory amountsOut = router.swapExactTokensForTokens(
            amountA, 0, path, address(this), deadline
        );
        uint256 outputB = amountB + amountsOut[1];
        require(outputB >= minOutputB, "EPoolPeriphery: insufficient output amount");
        IERC20(tokenB).safeTransfer(msg.sender, outputB);
        emit RedeemedEToken(address(ePool), eToken, amount, amountA, amountB, msg.sender);
        return true;
    }

    /**
     * @notice Rebalances a EPool. Capital required for rebalancing is obtained via a flash swap.
     * The potential slippage between the EPool oracle and uniswap is covered by the KeeperSubsidyPool.
     * @dev Fails if maxFlashSwapSlippage is exceeded in uniswapV2Call
     * @param ePool Address of the EPool to rebalance
     * @param fracDelta Fraction of the delta to rebalance (1e18 for rebalancing the entire delta)
     * @return True on success
     */
    function rebalanceWithFlashSwap(
        IEPool ePool,
        uint256 fracDelta
    ) external override returns (bool) {
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        (address tokenA, address tokenB) = (address(ePool.tokenA()), address(ePool.tokenB()));
        (uint256 deltaA, uint256 deltaB, uint256 rChange, ) = EPoolLibrary.delta(
            ePool.getTranches(), ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(tokenA), address(tokenB)));
        // map deltaA, deltaB to amountOut0, amountOut1
        uint256 amountOut0; uint256 amountOut1;
        if (rChange == 0) {
            (amountOut0, amountOut1) = (address(tokenA) == pair.token0())
                ? (uint256(0), deltaB) : (deltaB, uint256(0));
        } else {
            (amountOut0, amountOut1) = (address(tokenA) == pair.token0())
                ? (deltaA, uint256(0)) : (uint256(0), deltaA);
        }
        bytes memory data = abi.encode(ePool, fracDelta);
        pair.swap(amountOut0, amountOut1, address(this), data);
        return true;
    }

    /**
     * @notice rebalanceAllWithFlashSwap callback called by the uniswap pair
     * @dev Trusts that deltas are actually forwarded by the EPool.
     * Verifies that funds are forwarded from flash swap of the uniswap pair.
     * param sender Address of the flash swap initiator
     * param amount0
     * param amount1
     * @param data Data forwarded in the flash swap
     */
    function uniswapV2Call(
        address /* sender */, // skip sender check, check for forwarded funds by flash swap is sufficient
        uint256 /* amount0 */,
        uint256 /* amount1 */,
        bytes calldata data
    ) external {
        (IEPool ePool, uint256 fracDelta) = abi.decode(data, (IEPool, uint256));
        require(ePools[address(ePool)], "EPoolPeriphery: unapproved EPool");
        // fails if no funds are forwarded in the flash swap callback from the uniswap pair
        // TokenA, TokenB are already approved
        (uint256 deltaA, uint256 deltaB, uint256 rChange, ) = ePool.rebalance(fracDelta);
        address[] memory path = new address[](2); // [0] flash swap repay token, [1] flash lent token
        uint256 amountsIn; // flash swap repay amount
        uint256 deltaOut;
        if (rChange == 0) {
            // release TokenA, add TokenB to EPool -> flash swap TokenB, repay with TokenA
            path[0] = address(ePool.tokenA()); path[1] = address(ePool.tokenB());
            (amountsIn, deltaOut) = (router.getAmountsIn(deltaB, path)[0], deltaA);
        } else {
            // add TokenA, release TokenB to EPool -> flash swap TokenA, repay with TokenB
            path[0] = address(ePool.tokenB()); path[1] = address(ePool.tokenA());
            (amountsIn, deltaOut) = (router.getAmountsIn(deltaA, path)[0], deltaB);
        }
        // if slippage is negative request subsidy, if positive top of KeeperSubsidyPool
        if (amountsIn > deltaOut) {
            require(
                amountsIn * EPoolLibrary.sFactorI / deltaOut <= maxFlashSwapSlippage,
                "EPoolPeriphery: excessive slippage"
            );
            keeperSubsidyPool.requestSubsidy(path[0], amountsIn - deltaOut);
        } else if (amountsIn < deltaOut) {
            IERC20(path[0]).safeTransfer(address(keeperSubsidyPool), deltaOut - amountsIn);
        }
        // repay flash swap by sending amountIn to pair
        IERC20(path[0]).safeTransfer(msg.sender, amountsIn);
    }

    /**
     * @notice Recovers untracked amounts
     * @dev Can only called by an authorized sender
     * @param token Address of the token
     * @param amount Amount to recover
     * @return True on success
     */
    function recover(IERC20 token, uint256 amount) external override onlyDao("EPool: not dao") returns (bool) {
        token.safeTransfer(msg.sender, amount);
        emit RecoveredToken(address(token), amount);
        return true;
    }

    /* ------------------------------------------------------------------------------------------------------- */
    /* view and pure methods                                                                                   */
    /* ------------------------------------------------------------------------------------------------------- */

    function minInputAmountAForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 minTokenA) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        address[] memory path = new address[](2);
        path[0] = address(ePool.tokenA());
        path[1] = address(ePool.tokenB());
        minTokenA = amountA + router.getAmountsIn(amountB, path)[0];
    }

    // does not include price impact, which would result in a smaller EToken amount
    function eTokenForMinInputAmountA_Unsafe(
        IEPool ePool,
        address eToken,
        uint256 minInputAmountA
    ) external view returns (uint256 amount) {
        IEPool.Tranche memory t = ePool.getTranche(eToken);
        uint256 rate = ePool.getRate();
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 ratio = EPoolLibrary.currentRatio(t, rate, sFactorA, sFactorB);
        (uint256 amountAIdeal, uint256 amountBIdeal) = EPoolLibrary.tokenATokenBForTokenA(
            minInputAmountA, ratio, rate, sFactorA, sFactorB
        );
        return EPoolLibrary.eTokenForTokenATokenB(t, amountAIdeal, amountBIdeal, rate, sFactorA, sFactorB);
    }

    function minInputAmountBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 minTokenB) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        address[] memory path = new address[](2);
        path[0] = address(ePool.tokenB());
        path[1] = address(ePool.tokenA());
        minTokenB = amountB + router.getAmountsIn(amountA, path)[0];
    }

    // does not include price impact, which would result in a smaller EToken amount
    function eTokenForMinInputAmountB_Unsafe(
        IEPool ePool,
        address eToken,
        uint256 minInputAmountB
    ) external view returns (uint256 amount) {
        IEPool.Tranche memory t = ePool.getTranche(eToken);
        uint256 rate = ePool.getRate();
        uint256 sFactorA = ePool.sFactorA();
        uint256 sFactorB = ePool.sFactorB();
        uint256 ratio = EPoolLibrary.currentRatio(t, rate, sFactorA, sFactorB);
        (uint256 amountAIdeal, uint256 amountBIdeal) = EPoolLibrary.tokenATokenBForTokenB(
            minInputAmountB, ratio, rate, sFactorA, sFactorB
        );
        return EPoolLibrary.eTokenForTokenATokenB(t, amountAIdeal, amountBIdeal, rate, sFactorA, sFactorB);
    }

    function maxOutputAmountAForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 maxTokenA) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        uint256 feeRate = ePool.feeRate();
        amountA = amountA - amountA * feeRate / EPoolLibrary.sFactorI;
        amountB = amountB - amountB * feeRate / EPoolLibrary.sFactorI;
        address[] memory path = new address[](2);
        path[0] = address(ePool.tokenB());
        path[1] = address(ePool.tokenA());
        maxTokenA = amountA + router.getAmountsOut(amountB, path)[1];
    }

    function maxOutputAmountBForEToken(
        IEPool ePool,
        address eToken,
        uint256 amount
    ) external view returns (uint256 maxTokenB) {
        (uint256 amountA, uint256 amountB) = EPoolLibrary.tokenATokenBForEToken(
            ePool.getTranche(eToken), amount, ePool.getRate(), ePool.sFactorA(), ePool.sFactorB()
        );
        uint256 feeRate = ePool.feeRate();
        amountA = amountA - amountA * feeRate / EPoolLibrary.sFactorI;
        amountB = amountB - amountB * feeRate / EPoolLibrary.sFactorI;
        address[] memory path = new address[](2);
        path[0] = address(ePool.tokenA());
        path[1] = address(ePool.tokenB());
        maxTokenB = amountB + router.getAmountsOut(amountA, path)[1];
    }
}
