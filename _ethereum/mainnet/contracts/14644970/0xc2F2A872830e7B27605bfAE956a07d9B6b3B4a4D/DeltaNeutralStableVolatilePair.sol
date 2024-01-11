pragma solidity 0.8.6;

// TODO License
// SPDX-License-Identifier: UNLICENSED

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Math.sol";

import "./IDeltaNeutralFactory.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IComptroller.sol";
import "./ICErc20.sol";
import "./IDeltaNeutralStableVolatilePair.sol";

import "./console.sol";

// TODO replace all "IDEX" and "ILendingPlatform" names to a better ones?

/**
* @title    DeltaNeutralPair
* @notice   TODO
* @author   Quantaf1re (James Key)
*/
contract DeltaNeutralStableVolatilePair is IDeltaNeutralStableVolatilePair, ERC20, Ownable, ReentrancyGuard {

    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    uint public constant FULL_BPS = 10000;

    address payable public immutable registry;
    address public immutable userFeeVeriForwarder;

    IDeltaNeutralFactory public factory;

    address public stable;
    address public cStable;
    address public vol;
    address public cVol;
    address public uniLp;
    address public cUniLp;

    uint public minBps;
    uint public maxBps;
    // TODO put most of the above vars into a struct so it can be tightly packed to save gas when reading

    // TODO add checks on the return values of all Compound fncs for error msgs and revert if not 0, with the code in the revert reason

    event Deposited(uint amountStable, uint amountVol, uint amountUniLp, uint amountStableSwap, uint amountMinted); // TODO check args
    event Withdrawn(); // TODO

    // TODO in testing, test that changing the order of https://github.com/Uniswap/v2-core/blob/4dd59067c76dea4a0e8e4bfdda41877a6b16dedc/contracts/UniswapV2Factory.sol#L25 doesn't change anything
    constructor(
        address stable_,
        address vol_,
        string memory name_,
        string memory symbol_,
        address payable registry_,
        address userFeeVeriForwarder_,
        uint minBps_,
        uint maxBps_
    ) ERC20(name_, symbol_) Ownable() {
        factory = IDeltaNeutralFactory(msg.sender);
        stable = stable_;
        vol = vol_;
        registry = registry_;
        userFeeVeriForwarder = userFeeVeriForwarder_;
        minBps = minBps_;
        maxBps = maxBps_;

        uniLp = IUniswapV2Factory(factory.uniV2Factory()).getPair(stable, vol);

        IComptroller comptroller = IComptroller(factory.comptroller());
        cVol = comptroller.cTokensByUnderlying(vol);
        cStable = comptroller.cTokensByUnderlying(stable);
        cUniLp = comptroller.cTokensByUnderlying(uniLp);

        address[] memory cTokens = new address[](3);
        cTokens[0] = cUniLp;
        cTokens[1] = cVol;
        cTokens[2] = cStable;
        uint[] memory results = comptroller.enterMarkets(cTokens);
        require(results[0] == 0 && results[1] == 0 && results[2] == 0, "DNPair: unable to enter markets");
    }

    // Need to be able to receive ETH when borrowing it
    receive() external payable {}

    function deposit(
        uint amountStableDesired,
        uint amountVolDesired,
        UniArgs calldata uniArgs,
        address to
    ) external payable override nonReentrant {
        require(
            uniArgs.swapPath[0] == vol && uniArgs.swapPath[uniArgs.swapPath.length-1] == stable,
            "DNPair: swap path invalid"
        );

        transferApproveUnapproved(stable, factory.uniV2Router(), amountStableDesired, msg.sender, address(this));
        transferApproveUnapproved(vol, factory.uniV2Router(), amountVolDesired, msg.sender, address(this));

        (uint amountStable, uint amountVol, uint amountUniLp) = IUniswapV2Router02(factory.uniV2Router()).addLiquidity(
            stable,
            vol,
            amountStableDesired,
            amountVolDesired,
            uniArgs.amountStableMin,
            uniArgs.amountVolMin,
            address(this),
            uniArgs.deadline
        );

        // transfer not used tokens back to user
        if (amountStableDesired > amountStable) {
            IERC20(stable).transfer(msg.sender, amountStableDesired - amountStable);
        }
        if (amountVolDesired > amountVol) {
            IERC20(vol).transfer(msg.sender, amountVolDesired - amountVol);
        }

        // Mint meta-LP tokens to the user. Need to do this after LPing so we know the exact amount of
        // assets that are LP'd with, but before affecting any of the borrowing so it simplifies those
        // calculations.
        uint liquidity = _mintLiquidity(to, amountStable, amountVol, amountUniLp);

        // Use LP token as collateral
        approveUnapproved(uniLp, cUniLp, amountUniLp);
        uint code = ICErc20(cUniLp).mint(amountUniLp);
        require(code == 0, string(abi.encodePacked("DNPair: fuse LP mint ", Strings.toString(code)))); // TODO

        // Borrow the volatile token
        code = ICErc20(cVol).borrow(amountVol);
        require(code == 0, string(abi.encodePacked("DNPair: fuse borrow ", Strings.toString(code))));

        // Swap the volatile token for the stable token
        approveUnapproved(vol, factory.uniV2Router(), amountVol);
        uint[] memory amounts = IUniswapV2Router02(factory.uniV2Router()).swapExactTokensForTokens(
            amountVol, uniArgs.swapAmountOutMin, uniArgs.swapPath, address(this), block.timestamp
        );

        // Lend out the stable token again
        approveUnapproved(stable, cStable, amounts[amounts.length-1]);
        console.log("deposit cStable.mint", amounts[amounts.length-1]); // TODO
        code = ICErc20(cStable).mint(amounts[amounts.length-1]);

        require(code == 0, string(abi.encodePacked("DNPair: fuse stable mint ", Strings.toString(code))));

        // TODO check if things need rebalancing already, because by trading the volatile token for the stable token, we moved the market
        // rebalance(5 * 10**9);

        emit Deposited(amountStable, amountVol, amountUniLp, amounts[amounts.length-1], liquidity);
    }

    // function withdraw(
    //     uint liquidity,
    //     UniArgs calldata uniArgs
    // ) external {
    //     require(
    //         uniArgs.swapPath[0] == stable && uniArgs.swapPath[uniArgs.swapPath.length-1] == vol,
    //         "DNPair: swap path invalid"
    //     );
    //     // Get the user's portion of the assets in Uniswap
    //     uint totalSupply = this.totalSupply();
    //     uint amountUniLp = ICErc20(cUniLp).balanceOfUnderlying(address(this)) * liquidity / totalSupply;

    //     // It's safe to redeem these without paying some of the borrowed volatile tokens first because the borrow
    //     // position is collateralised 200% initially (although this isn't safe if the amount withdrawn is a large enough
    //     // % of the pool that redeeming puts the collateral % too low temporarily).
    //     // It's advantageous to get the underlying assets 1st instead of doing the `deposit` fcn in reverse
    //     // because if the interest rate for the volatile asset is larger than the stable asset, then we'd need a
    //     // source of the volatile asset to cover the deficit in funds needed to pay back enough borrowed volatile
    //     // to match the Uniswap position.

    //     uint code = ICErc20(cUniLp).redeemUnderlying(amountUniLp);
    //     require(code == 0, string(abi.encodePacked("DNPair: fuse LP redeem ", Strings.toString(code))));

    //     approveUnapproved(uniLp, factory.uniV2Router(), amountUniLp);
    //     (uint amountStableFromDex, uint amountVolFromDex) = IUniswapV2Router02(factory.uniV2Router()).removeLiquidity(
    //         stable,
    //         vol,
    //         amountUniLp,
    //         uniArgs.amountStableMin,
    //         uniArgs.amountVolMin,
    //         address(this),
    //         uniArgs.deadline
    //     );

    //     // Get the stables lent out and convert them back into the volatile token
    //     uint amountStableFromLending = ICErc20(cStable).balanceOfUnderlying(address(this)) * liquidity / totalSupply;
    //     console.log("withdraw amountStableFromLending", amountStableFromLending); // TODO
    //     console.log("withdraw liquidity", liquidity);
    //     console.log("withdraw totalSupply", totalSupply);
    //     console.log("withdraw liquidity / totalSupply", liquidity / totalSupply);
    //     code = ICErc20(cStable).redeemUnderlying(amountStableFromLending);
    //     require(code == 0, string(abi.encodePacked("DNPair: fuse stable redeem ", Strings.toString(code))));

    //     uint[] memory amountsStableToVolatile = IUniswapV2Router02(factory.uniV2Router()).swapExactTokensForTokens(
    //         amountStableFromLending, uniArgs.swapAmountOutMin, uniArgs.swapPath, address(this), block.timestamp
    //     );

    //     // Pay back the borrowed volatile
    //     uint amountVolToRepay = ICErc20(cVol).borrowBalanceCurrent(address(this)) * liquidity / totalSupply;
    //     require(
    //         amountVolFromDex + amountsStableToVolatile[amountsStableToVolatile.length-1] >= amountVolToRepay,
    //         "DNPair: not enough to repay debt"
    //     );
    //     approveUnapproved(vol, cVol, amountVolToRepay);
    //     code = ICErc20(cVol).repayBorrow(amountVolToRepay);
    //     require(code == 0, string(abi.encodePacked("DNPair: fuse vol repay ", Strings.toString(code))));

    //     uint liquidityCopy = liquidity;

    //     // Send the remaining assets to the user and burn their meta-LP tokens
    //     IERC20(stable).transfer(msg.sender, amountStableFromDex);
    //     IERC20(vol).transfer(msg.sender, amountVolFromDex + amountsStableToVolatile[amountsStableToVolatile.length-1] - amountVolToRepay);

    //     _burn(msg.sender, liquidityCopy);

    //     emit Withdrawn(); // TODO
    // }

    function withdraw(
        uint liquidity,
        UniArgs calldata uniArgs
    ) external override {
        require(
            uniArgs.swapPath[0] == stable && uniArgs.swapPath[uniArgs.swapPath.length-1] == vol,
            "DNPair: swap path invalid"
        );
        // Get the user's portion of the assets in Uniswap
        uint totalSupply = this.totalSupply();
        uint code;

        // Get the stables lent out and convert them back into the volatile token
        uint amountStableFromLending = ICErc20(cStable).balanceOfUnderlying(address(this)) * liquidity / totalSupply;
        code = ICErc20(cStable).redeemUnderlying(amountStableFromLending);
        require(code == 0, string(abi.encodePacked("DNPair: fuse stable redeem ", Strings.toString(code))));

        uint amountVolFromStable = IUniswapV2Router02(factory.uniV2Router()).swapExactTokensForTokens(
            amountStableFromLending, uniArgs.swapAmountOutMin, uniArgs.swapPath, address(this), block.timestamp
        )[uniArgs.swapPath.length-1];

        // Pay back the borrowed volatile
        uint amountVolToRepay = ICErc20(cVol).borrowBalanceCurrent(address(this)) * liquidity / totalSupply;
        approveUnapproved(vol, cVol, amountVolToRepay);

        // Repay the borrowed volatile depending on how much we have
        if (amountVolToRepay <= amountVolFromStable) {
            code = ICErc20(cVol).repayBorrow(amountVolToRepay);
        } else {
            // If we don't have enough, pay with what we have and account for the difference later after getting enough
            // assets back from the DEX
            code = ICErc20(cVol).repayBorrow(amountVolFromStable);
        }

        require(code == 0, string(abi.encodePacked("DNPair: fuse vol repay ", Strings.toString(code))));
        uint amountUniLp = ICErc20(cUniLp).balanceOfUnderlying(address(this)) * liquidity / totalSupply;

        approveUnapproved(uniLp, factory.uniV2Router(), amountUniLp);
        if (amountVolToRepay <= amountVolFromStable) {
            // Redeem everything and remove all liquidity from Uniswap
            code = ICErc20(cUniLp).redeemUnderlying(amountUniLp);
            require(code == 0, string(abi.encodePacked("DNPair: fuse LP redeem ", Strings.toString(code))));

            IUniswapV2Router02(factory.uniV2Router()).removeLiquidity(
                stable,
                vol,
                amountUniLp,
                uniArgs.amountStableMin,
                uniArgs.amountVolMin,
                msg.sender,
                uniArgs.deadline
            );
        } else {
            // Redeem enough from Fuse so that we can then remove enough liquidity from Uniswap to cover the
            // remaining owed volatile amount, then redeem the remaining amount from Fuse and remove the
            // remaining amount from Uniswap
            
            // Redeem an amount of the Uniswap LP token, proportional to the amount of
            // the volatile we could get from stables compared to how much is needed, so
            // that it's impossible (?) to redeem too much and be undercollateralised
            uint amountUniLpPaidFirst = amountUniLp * amountVolFromStable / amountVolToRepay;
            code = ICErc20(cUniLp).redeemUnderlying(amountUniLpPaidFirst);
            require(code == 0, string(abi.encodePacked("DNPair: fuse LP redeem 1 ", Strings.toString(code))));
            
            // To avoid stack too deep
            UniArgs memory uniArgs = uniArgs;

            (, uint amountVolFromDex) = IUniswapV2Router02(factory.uniV2Router()).removeLiquidity(
                stable,
                vol,
                amountUniLpPaidFirst,
                uniArgs.amountStableMin * amountUniLpPaidFirst / amountUniLp,
                uniArgs.amountVolMin * amountUniLpPaidFirst / amountUniLp,
                address(this),
                uniArgs.deadline
            );
            require(amountVolFromDex > amountVolToRepay - amountVolFromStable, "DNPair: vol cant cover defecit");

            code = ICErc20(cUniLp).redeemUnderlying(amountUniLp - amountUniLpPaidFirst);
            require(code == 0, string(abi.encodePacked("DNPair: fuse LP redeem 2 ", Strings.toString(code))));

            IUniswapV2Router02(factory.uniV2Router()).removeLiquidity(
                stable,
                vol,
                amountUniLp - amountUniLpPaidFirst,
                uniArgs.amountStableMin * (amountUniLp - amountUniLpPaidFirst) / amountUniLp,
                uniArgs.amountVolMin * (amountUniLp - amountUniLpPaidFirst) / amountUniLp,
                address(this),
                uniArgs.deadline
            );

            IERC20(vol).transfer(msg.sender, IERC20(vol).balanceOf(address(this)));
            IERC20(stable).transfer(msg.sender, IERC20(stable).balanceOf(address(this)));
        }


//         UniArgs memory uniArgs = uniArgs;

//         // The only way this can fail is if the borrowing cost of the volatile is so much more than
//         // the lending interest revenue that the difference approaches the size of the underlying assets,
//         // which is so unlikely that we can just ignore it. However, black swans do happen, so that's why
//         // this contract will be made upgradable


//         // uint liquidityCopy = liquidity;

// //         // User gets the profit difference between the lending rate of the stable and borrowing rate of the volatile
// //         // IERC20(vol).transfer(msg.sender, amountVolFromStable-amountVolToRepay);

//         // // Send the remaining assets to the user and burn their meta-LP tokens
//         // IERC20(stable).transfer(msg.sender, amountStableFromDex);
//         // IERC20(vol).transfer(msg.sender, amountVolFromDex + amountVolFromStable - amountVolToRepay);

        _burn(msg.sender, liquidity);

        emit Withdrawn(); // TODO
    }

    function _mintLiquidity(address to, uint amountStable, uint amountVol, uint amountUniLp) private returns (uint liquidity) {
        (uint reserveStable, uint reserveVol, uint _totalSupply) = getReserves(amountStable, amountVol, amountUniLp);
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amountStable.mul(amountVol)).sub(MINIMUM_LIQUIDITY); // TODO ?
           _mint(address(this), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amountStable.mul(_totalSupply) / reserveStable, amountVol.mul(_totalSupply) / reserveVol);
        }
        require(liquidity > 0, 'DNPair: INSUFFICIENT_LIQUIDITY_MINTED');
        console.log('_mintLiquidity', liquidity);
        _mint(to, liquidity);
    }

    // TODO return token addresses
    function getReserves(uint amountStable, uint amountVol, uint amountUniLp) public override returns (uint, uint, uint) {

        address _stable = stable; // gas savings
        address _vol = vol; // gas savings
        uint dexLiquidity = ICErc20(cUniLp).balanceOfUnderlying(address(this)) + amountUniLp;
        uint totalDexLiquidity = IERC20(uniLp).totalSupply();

        uint reserveStable;
        uint dexBalVol;
        if (dexLiquidity - amountUniLp > 0) { // avoid underflow
            reserveStable = (IERC20(_stable).balanceOf(uniLp) * dexLiquidity / totalDexLiquidity) - amountStable;
            dexBalVol = (IERC20(_vol).balanceOf(uniLp) * dexLiquidity / totalDexLiquidity) - amountVol;
        }

        // Need to calculate how much of the volatile asset we'd be left with if we liquidated and
        // withdrew everything, tho TODO: could simplify this greatly and only consider the stable above
        uint amountStableLentOut = ICErc20(cStable).balanceOfUnderlying(address(this));
        uint amountVolFromStable;
        if (amountStableLentOut > 0) {
            uint[] memory amountsVolFromStable = IUniswapV2Router02(factory.uniV2Router()).getAmountsOut(
                amountStableLentOut,
                newPath(stable, vol)
            );
            amountVolFromStable = amountsVolFromStable[amountsVolFromStable.length-1];
        }

        // The balance in Uniswap, plus the amount of stables lent out with interest, minus the debt with interest
        uint reserveVol = dexBalVol + amountVolFromStable - ICErc20(cVol).borrowBalanceCurrent(address(this));

        console.log("getReserves", reserveStable, reserveVol, this.totalSupply());

        return (reserveStable, reserveVol, this.totalSupply());
    }

    /**
     * @notice  Checks how much of the non-stablecoin asset we have being LP'd with on IDEX (amount X) and
     *          how much debt we have in that asset at ILendingPlatform, and borrows/repays the debt to be equal to X,
     *          if and only if the difference is more than 1%.
     *          This function is what is automatically called by Autonomy.
     */
    function rebalanceAuto(
        address user,
        uint feeAmount,
        uint maxGasPrice
    ) public override gasPriceCheck(maxGasPrice) userFeeVerified {
        
    }

//     // TODO: need to account for when there isn't enough stablecoins being lent out to repay
//     // TODO: use a constant for the timestamp to reduce gas
//    function rebalance(uint feeAmount) public {
//        (uint ownedAmountVol, uint debtAmountVol, uint debtBps) = getDebtBps();
//        // If there's ETH in this contract, then it's for the purpose of subsidising the
//        // automation fee, and so we don't need to get funds from elsewhere to pay it
//        bool payFeeFromBal = feeAmount >= address(this).balance;
//        address[] memory pathStableToVol = newPath(stable, vol);
//        address[] memory pathVolToStable = newPath(vol, stable);

//        if (debtBps >= maxBps) {
//            // Repay some debt
//            uint amountVolToRepay = debtAmountVol - ownedAmountVol;
//            uint[] memory amountsForVol = IUniswapV2Router02(factory.uniV2Router()).getAmountsIn(amountVolToRepay, pathStableToVol);
//            uint amountStableToRedeem = amountsForVol[0];
//            address[] memory pathFee;

//            if (feeAmount > 0 && !payFeeFromBal) {
//                if (feeAmount > address(this).balance) {
//                    registry.transfer(feeAmount);
//                } else {
//                    pathFee = newPath(stable, IUniswapV2Factory(factory.uniV2Factory()).WETH());
//                    uint[] memory amountsForFee = IUniswapV2Router02(factory.uniV2Router()).getAmountsIn(feeAmount, pathFee);
//                    amountStableToRedeem += amountsForFee[0];
//                }
//            }

//            ICErc20(cStable).redeem(amountStableToRedeem);
//            approveUnapproved(stable, factory.uniV2Router(), amountStableToRedeem);
//            IUniswapV2Router02(factory.uniV2Router()).swapTokensForExactTokens(amountVolToRepay, amountsForVol[0], pathStableToVol, address(this), block.timestamp);
//            ICErc20(cVol).repayBorrow(amountVolToRepay);

//            if (feeAmount > 0 && !payFeeFromBal) {
//                IUniswapV2Router02(factory.uniV2Router()).swapTokensForExactETH(feeAmount, amountStableToRedeem-amountsForVol[0], pathFee, registry, block.timestamp);
//            }
//        } else if (debtBps <= minBps) {
//            // Borrow more
//            uint amountVolBorrow = ownedAmountVol - debtAmountVol;
//            ICErc20(cVol).borrow(amountVolBorrow);

//            if (feeAmount > 0 && !payFeeFromBal) {
//                address[] memory pathFee = newPath(vol, IUniswapV2Factory(factory.uniV2Factory()).WETH());
//                uint[] memory amountsVolToEthForFee = IUniswapV2Router02(factory.uniV2Router()).getAmountsIn(feeAmount, pathFee);

//                if (amountsVolToEthForFee[0] < amountVolBorrow) {
//                    // Pay the fee
//                    IUniswapV2Router02(factory.uniV2Router()).swapTokensForExactETH(feeAmount, amountsVolToEthForFee[0], pathFee, registry, block.timestamp);
//                    // Swap the rest to stablecoins and lend them out
//                    uint[] memory amountsVolToStable = IUniswapV2Router02(factory.uniV2Router()).swapExactTokensForTokens(amountVolBorrow-amountsVolToEthForFee[0], 1, pathVolToStable, address(this), block.timestamp);
//                    ICErc20(cStable).mint(amountsVolToStable[amountsVolToStable.length-1]);
//                } else if (amountsVolToEthForFee[0] > amountVolBorrow) {
//                    // Get the missing volatile tokens needed for the fee from the lent out stablecoins
//                    uint amountVolNeeded = amountsVolToEthForFee[0] - amountVolBorrow;
//                    uint[] memory amountsStableToVolForFee = IUniswapV2Router02(factory.uniV2Router()).getAmountsIn(amountVolNeeded, pathStableToVol);
//                    ICErc20(cStable).redeem(amountsStableToVolForFee[0]);
//                    IUniswapV2Router02(factory.uniV2Router()).swapTokensForExactTokens(amountVolNeeded, amountsStableToVolForFee[0], pathStableToVol, address(this), block.timestamp);
//                    IUniswapV2Router02(factory.uniV2Router()).swapTokensForExactETH(feeAmount, amountsVolToEthForFee[0], pathFee, registry, block.timestamp);
//                } else {
//                    IUniswapV2Router02(factory.uniV2Router()).swapTokensForExactETH(feeAmount, amountVolBorrow, pathFee, registry, block.timestamp);
//                }
//            }
//        } else {
//            require(false, "DNPair: debt within range");
//        }

//        if (payFeeFromBal) {
//            registry.transfer(feeAmount);
//        }

//        (ownedAmountVol, debtAmountVol, debtBps) = getDebtBps();
//        require(debtBps >= minBps && debtBps <= maxBps, "DNPair: debt not within range");
//    }

    // TODO: mark as view, issue with balanceOfUnderlying not being view
    function getDebtBps() public override returns (uint ownedAmountVol, uint debtAmountVol, uint debtBps) {
        // ownedAmountVol = getVolAmountFromUniswap();
        ownedAmountVol = 0; // just to get this to compile
        debtAmountVol = ICErc20(cVol).balanceOfUnderlying(address(this));
        debtBps = debtAmountVol * FULL_BPS / ownedAmountVol;
    }

    function setMinBps(uint newMinBps) external override {
        minBps = newMinBps;
    }

    function setMaxBps(uint newMaxBps) external override {
        maxBps = newMaxBps;
    }

    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////
    ////                                                          ////
    ////-------------------------Helpers--------------------------////
    ////                                                          ////
    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    modifier gasPriceCheck(uint maxGasPrice) {
        require(tx.gasprice <= maxGasPrice, "LimitsStops: gasPrice too high");
        _;
    }

    function transferApproveUnapproved(
        address _token,
        address approvalRecipient,
        uint amount,
        address user,
        address to
    ) private {
        IERC20 token = approveUnapproved(_token, approvalRecipient, amount);
        token.safeTransferFrom(user, to, amount);
    }

    function approveUnapproved(address _token, address approvalRecipient, uint amount) private returns (IERC20 token) {
        token = IERC20(_token);
        if (token.allowance(address(this), approvalRecipient) < amount) {
            token.approve(approvalRecipient, factory.MAX_UINT());
        }
    }

    function newPath(address src, address dest) public pure override returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = src;
        path[1] = dest;
        return path;
    }

    modifier userFeeVerified() {
        require(msg.sender == userFeeVeriForwarder, "LimitsStops: not userFeeForw");
        _;
    }
}
