// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {CERC20} from "CERC20.sol";
import {IRecipe} from "IRecipe.sol";
import {SushiBar} from "SushiBar.sol";
import {VaultAPI} from "VaultAPI.sol";
import {IBasketFacet} from "IBasketFacet.sol";
import {IBasketLogic} from "IBasketLogic.sol";
import {ISwapRouter} from "ISwapRouter.sol";
import {ICurvePool_2Token} from "ICurvePool_2Token.sol";
import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {IUniswapV2Router01} from "IUniswapV2Router01.sol";

/// @title BasketMigrator
/// @author dantop114
/// @notice BasketDAO indexes migration contract.
contract BasketMigrator {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                    Constants and immutables
    ///////////////////////////////////////////////////////////////*/

    /// @notice BDI contract address.
    address public constant BDI = 0x0309c98B1bffA350bcb3F9fB9780970CA32a5060;

    /// @notice DEFI++ contract address.
    address public constant DPP = 0x8D1ce361eb68e9E05573443C407D4A3Bed23B033;

    /// @notice WETH contract address.
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice yvCurveLink address.
    address internal constant yvCurveLink =
        0xf2db9a7c0ACd427A680D640F02d90f6186E71725;

    /// @notice yvUNI address.
    address internal constant yvUNI =
        0xFBEB78a723b8087fD2ea7Ef1afEc93d35E8Bed42;

    /// @notice yvYFI address.
    address internal constant yvYFI =
        0xE14d13d8B3b85aF791b2AADD661cDBd5E6097Db1;

    /// @notice yvSNX address.
    address internal constant yvSNX =
        0xF29AE508698bDeF169B89834F76704C3B205aedf;

    /// @notice cCOMP address.
    address internal constant cCOMP =
        0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    /// @notice xSUSHI address.
    address internal constant xSUSHI =
        0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    /// @notice Curve Liquidity Pool LINK/sLINK
    address internal constant curvePoolLINK =
        0xF178C0b5Bb7e7aBF4e12A4838C7b7c5bA2C623c0;

    /// @notice Curve LP Token LINK/sLINK
    address internal constant crvLINK =
        0xcee60cFa923170e4f8204AE08B4fA6A3F5656F3a;

    /// @notice Governance address for this contract.
    address public immutable gov;

    /*///////////////////////////////////////////////////////////////
                    Structs declarations
    ///////////////////////////////////////////////////////////////*/

    /// @notice Swap struct.
    /// @param v3 boolean telling us if the swap is done on UniswapV3
    /// @param data abi.encode of Router and swap data.
    struct Swap {
        bool v3;
        bytes data;
    }

    /*///////////////////////////////////////////////////////////////
                    Errors definition
    ///////////////////////////////////////////////////////////////*/

    /// @notice Error emitted when users try to deposit in state != 0.
    error EntryClosed();

    /// @notice Error emitted when contract is not in state 1.
    error NotBaking();

    /// @notice Error emitted when a contract is not in state 2.
    error NotBaked();

    /// @notice Error emitted when the user did not deposit.
    error NoDeposit();

    /// @notice Error emitted when amount to deposit is zero.
    error AmountZero();

    /// @notice Error emitted when caller is not the governance address.
    error NotGovernance();

    /// @notice Error emitted when the burn of shares fails.
    error BurnFailed();

    /// @notice Error emitted when the deadline to swap is reached.
    error DeadlineReached();

    /// @notice Error emitted when the baking fails.
    error BakeFailed();

    /*///////////////////////////////////////////////////////////////
                    Events definition
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when a user deposits.
    event Entry(address indexed who, uint256 amount);

    /// @notice Event emitted when the deposits are closed.
    event Closed();

    /*///////////////////////////////////////////////////////////////
                          Storage
    ///////////////////////////////////////////////////////////////*/

    /// @notice Exchange rate at settlement.
    uint256 public rate;

    /// @notice State of the contract.
    /// @dev The state is an uint8 acting as an enum:
    ///         - 0: accepting deposits (open)
    ///         - 1: no more deposits accepted (baking)
    ///         - 2: users can withdraw (done)
    uint8 public state;

    /// @notice Total deposited in the contract.
    uint256 public totalDeposits;

    /// @notice Deposited amount per user.
    mapping(address => uint256) public deposits;

    /*///////////////////////////////////////////////////////////////
                          Constructor
    ///////////////////////////////////////////////////////////////*/

    constructor(address _gov) {
        gov = _gov;
    }

    /*///////////////////////////////////////////////////////////////
                       State changing logic
    ///////////////////////////////////////////////////////////////*/

    function closeEntry() external {
        if (msg.sender != gov) revert NotGovernance();
        if (state != 0) revert EntryClosed();

        state = 1;

        emit Closed();
    }

    /*///////////////////////////////////////////////////////////////
                    User deposit/redeem logic
    ///////////////////////////////////////////////////////////////*/

    /// @notice Let users enter the migration process.
    /// @param amount Amount of BDI to take from the user.
    function enter(uint256 amount) external {
        if (state != 0) revert EntryClosed();
        if (amount == 0) revert AmountZero();

        totalDeposits += amount;
        deposits[msg.sender] += amount;
        IERC20(BDI).safeTransferFrom(msg.sender, address(this), amount);

        emit Entry(msg.sender, amount);
    }

    /// @notice Let users withdraw their share.
    function exit() external {
        if (state != 2) revert NotBaked();

        uint256 deposited = deposits[msg.sender];

        if (deposited == 0) revert NoDeposit();

        deposits[msg.sender] = 0;
        uint256 amount = (rate * deposited) / 1e18;
        IERC20(DPP).transfer(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Burn, unwrap and swap
    ///////////////////////////////////////////////////////////////*/

    /// @notice Burns all BDI present in the contract and unwraps for underlying.
    function burnAndUnwrap() external {
        if (state != 1) revert NotBaking();
        if (msg.sender != gov) revert NotGovernance();

        // Burn BDI.
        IBasketLogic(BDI).burn(IERC20(BDI).balanceOf(address(this)));

        // Unwrap Yearn vaults' shares.
        VaultAPI(yvSNX).withdraw();
        VaultAPI(yvUNI).withdraw();
        VaultAPI(yvYFI).withdraw();
        VaultAPI(yvCurveLink).withdraw();

        // Unwrap LINK from Curve Pool
        uint256 bal = IERC20(crvLINK).balanceOf(address(this));
        ICurvePool_2Token(curvePoolLINK).remove_liquidity_one_coin(bal, 0, 0);

        // Unwrap Compound cTokens.
        CERC20(cCOMP).redeem(IERC20(cCOMP).balanceOf(address(this)));

        // Unwrap xSUSHI
        SushiBar(xSUSHI).leave(IERC20(xSUSHI).balanceOf(address(this)));
    }

    /// @notice Execute swaps.
    /// @param swaps A list of swaps (v2 or v3) encoded in structs.
    /// @param deadline A deadline for the swaps to happen.
    function execSwaps(Swap[] calldata swaps, uint256 deadline) external {
        if (state != 1) revert NotBaking();
        if (msg.sender != gov) revert NotGovernance();
        if (deadline <= block.timestamp) revert DeadlineReached();

        for (uint256 i; i < swaps.length; ) {
            if (swaps[i].v3) {
                _swapV3GivenIn(swaps[i]);
            } else {
                _swapV2GivenIn(swaps[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Bake it all.
    /// @param amountOut Amount to bake.
    /// @param maxAmountIn Maximum amount of WETH to use.
    /// @param deadline A deadline for the bake to occour.
    /// @param approvals Indicates if approvals for underlyings should be done.
    /// @param swaps Swaps from WETH to underlyings.
    function bake(
        uint256 amountOut,
        uint256 maxAmountIn,
        uint256 deadline,
        bool approvals,
        Swap[] calldata swaps
    ) external payable {
        if (state != 1) revert NotBaking();
        if (msg.sender != gov) revert NotGovernance();
        if (deadline <= block.timestamp) revert DeadlineReached();

        if (msg.value != 0) {
            // help the bake by sending some ETH
            (bool succ, ) = WETH.call{value: msg.value}("");
            if (!succ) revert();
        }

        uint256 balanceIn = IERC20(WETH).balanceOf(address(this));

        // Execute swaps
        _execSwapsGivenOut(swaps);

        // Execute approvals if needed
        if (approvals) _execApprovalsForBasket();

        // Join DEFI++
        IBasketFacet(DPP).joinPool(amountOut);

        // Check amount used is less than required
        uint256 usedIn = balanceIn - IERC20(WETH).balanceOf(address(this));

        if (usedIn >= maxAmountIn) revert BakeFailed();

        if (msg.value != 0) {
            balanceIn = IERC20(WETH).balanceOf(address(this));
            uint256 refund = (balanceIn >= msg.value) ? msg.value : balanceIn;
            if (refund != 0) IERC20(WETH).transfer(msg.sender, refund);
        }
    }

    /// @notice Settle the migration and broadcast exchange rate.
    function settle(bool finalRate) external {
        if (state != 1) revert NotBaking();
        if (msg.sender != gov) revert NotGovernance();
        if (finalRate) state = 2;

        uint256 dppBalance = IERC20(DPP).balanceOf(address(this)); // DEFI++ balance
        uint256 total = totalDeposits - IERC20(BDI).balanceOf(address(this)); // account for dust
        rate = (dppBalance * 1e18) / total; // compute rate
    }

    /*///////////////////////////////////////////////////////////////
                            Internal
    ///////////////////////////////////////////////////////////////*/

    function _execSwapsGivenOut(Swap[] calldata swaps) internal {
        for (uint256 i; i < swaps.length; ) {
            if (swaps[i].v3) {
                _swapV3GivenOut(swaps[i]);
            } else {
                _swapV2GivenOut(swaps[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    function _execApprovalsForBasket() internal {
        address[] memory tokens = IBasketFacet(DPP).getTokens();

        for (uint256 i = 0; i < tokens.length; ) {
            IERC20(tokens[i]).approve(DPP, type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    function _swapV2GivenIn(Swap memory swap) internal {
        // decode data
        (
            address router,
            address[] memory path,
            uint256 amountOut,
            uint256 amountInMin
        ) = abi.decode(swap.data, (address, address[], uint256, uint256));

        IERC20 tokenIn = IERC20(path[0]);
        if (tokenIn.allowance(address(this), router) <= amountOut) {
            tokenIn.approve(router, type(uint256).max);
        }

        IUniswapV2Router01(router).swapExactTokensForTokens(
            amountOut,
            amountInMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapV2GivenOut(Swap memory swap) internal {
        // decode data
        (
            address router,
            address[] memory path,
            uint256 amountOut,
            uint256 amountInMax
        ) = abi.decode(swap.data, (address, address[], uint256, uint256));

        IERC20 tokenIn = IERC20(path[0]);
        if (tokenIn.allowance(address(this), router) <= amountInMax) {
            tokenIn.approve(router, type(uint256).max);
        }

        IUniswapV2Router01(router).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapV3GivenIn(Swap memory swap) internal {
        // decode data
        (
            address router,
            address tokenIn,
            address tokenOut,
            uint24 fee,
            uint256 amountIn,
            uint256 amountOutMin
        ) = abi.decode(
                swap.data,
                (address, address, address, uint24, uint256, uint256)
            );

        if (IERC20(tokenIn).allowance(address(this), router) <= amountIn) {
            IERC20(tokenIn).approve(router, type(uint256).max);
        }

        ISwapRouter.ExactInputSingleParams memory params;
        params.tokenIn = tokenIn;
        params.tokenOut = tokenOut;
        params.fee = fee;
        params.recipient = address(this);
        params.deadline = block.timestamp;
        params.amountIn = amountIn;
        params.amountOutMinimum = amountOutMin;

        ISwapRouter(router).exactInputSingle(params);
    }

    function _swapV3GivenOut(Swap memory swap) internal {
        // decode data
        (
            address router,
            address tokenIn,
            address tokenOut,
            uint24 fee,
            uint256 amountOut,
            uint256 amountInMax
        ) = abi.decode(
                swap.data,
                (address, address, address, uint24, uint256, uint256)
            );

        if (IERC20(tokenIn).allowance(address(this), router) <= amountInMax) {
            IERC20(tokenIn).approve(router, type(uint256).max);
        }

        ISwapRouter.ExactOutputSingleParams memory params;
        params.tokenIn = tokenIn;
        params.tokenOut = tokenOut;
        params.fee = fee;
        params.recipient = address(this);
        params.deadline = block.timestamp;
        params.amountOut = amountOut;
        params.amountInMaximum = amountInMax;

        ISwapRouter(router).exactOutputSingle(params);
    }

    /*///////////////////////////////////////////////////////////////
                            Receive
    ///////////////////////////////////////////////////////////////*/

    receive() external payable {}
}
