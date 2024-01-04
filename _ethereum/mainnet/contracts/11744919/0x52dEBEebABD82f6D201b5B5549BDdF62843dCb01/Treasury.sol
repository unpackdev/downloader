// SPDX-License-Identifier: MIT

pragma solidity ^0.6.10;

import "./Math.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./ICustomERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapOracle.sol";
import "./IUniswapV2Router02.sol";
import "./IBoardroom.sol";
import "./IBasisAsset.sol";
import "./ISimpleERCFund.sol";
import "./Operator.sol";
import "./Epoch.sol";
import "./ContractGuard.sol";

import "./TreasuryHelpers.sol";

/**
 * @title ARTH Treasury contract
 * @notice Monetary policy logic to adjust supplies of basis cash assets
 * @author Steven Enamakel & Yash Agrawal. Original code written by Summer Smith & Rick Sanchez
 */
contract Treasury is TreasuryHelpers {
    using SafeERC20 for ICustomERC20;

    constructor(
        // tokens
        address _dai,
        address _cash,
        address _bond,
        address _share,
        // oracles
        address _bondOracle,
        address _arthMahaOracle,
        address _seigniorageOracle,
        address _gmuOracle,
        // boardrooms
        address _arthLiquidityBoardroom,
        address _mahaLiquidityBoardroom,
        address _arthBoardroom,
        // ecosystem fund
        address _fund,
        // uniswap router
        address _uniswapRouter,
        uint256 _startTime,
        uint256 _period,
        uint256 _startEpoch
    )
        public
        TreasuryHelpers(
            _dai,
            _cash,
            _bond,
            _share,
            _bondOracle,
            _arthMahaOracle,
            _seigniorageOracle,
            _gmuOracle,
            _arthLiquidityBoardroom,
            _mahaLiquidityBoardroom,
            _arthBoardroom,
            _fund,
            _uniswapRouter,
            _startTime,
            _period,
            _startEpoch
        )
    {}

    function initialize() public checkOperator {
        require(!initialized, '!initialized');

        // set accumulatedSeigniorage to the treasury's balance
        accumulatedSeigniorage = IERC20(cash).balanceOf(address(this));

        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function buyBonds(uint256 amountInDai, uint256 targetPrice)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
        updatePrice
        returns (uint256)
    {
        require(amountInDai > 0, 'zero amount');

        // Update the price to latest before using.
        uint256 cash1hPrice = getBondOraclePrice();

        require(cash1hPrice <= targetPrice, 'cash price moved');
        require(
            cash1hPrice <= getBondPurchasePrice(), // price < $0.95
            'cash price not eligible'
        );
        require(cashToBondConversionLimit > 0, 'no more bonds');

        // Find the expected amount recieved when swapping the following
        // tokens on uniswap.
        address[] memory path = new address[](2);
        path[0] = address(dai);
        path[1] = address(cash);

        uint256[] memory amountsOut =
            IUniswapV2Router02(uniswapRouter).getAmountsOut(amountInDai, path);
        uint256 expectedCashAmount = amountsOut[1];

        // 1. Take Dai from the user
        ICustomERC20(dai).safeTransferFrom(
            msg.sender,
            address(this),
            amountInDai
        );

        // 2. Approve dai for trade on uniswap
        ICustomERC20(dai).safeApprove(uniswapRouter, amountInDai);

        // 3. Swap dai for ARTH from uniswap and send the ARTH to the sender
        // we send the ARTH back to the sender just in case there is some slippage
        // in our calculations and we end up with more ARTH than what is needed.
        uint256[] memory output =
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
                amountInDai,
                expectedCashAmount,
                path,
                msg.sender,
                block.timestamp
            );

        // set approve to 0 after transfer
        ICustomERC20(dai).safeApprove(uniswapRouter, 0);

        // we do this to understand how much ARTH was bought back as without this, we
        // could witness a flash loan attack. (given that the minted amount of ARTHB
        // minted is based how much ARTH was received)
        uint256 boughtBackCash = Math.min(output[1], expectedCashAmount);

        // basis the amount of ARTH being bought back; understand how much of it
        // can we convert to bond tokens by looking at the conversion limits
        uint256 cashToConvert =
            Math.min(
                boughtBackCash,
                cashToBondConversionLimit.sub(accumulatedBonds)
            );

        // if all good then mint ARTHB, burn ARTH and update the counters
        require(cashToConvert > 0, 'no more bond limit');

        uint256 bondsToIssue =
            cashToConvert.mul(uint256(100).add(bondDiscount)).div(100);
        accumulatedBonds = accumulatedBonds.add(bondsToIssue);

        // 3. Burn bought ARTH cash and mint bonds at the discounted price.
        // TODO: Set the minting amount according to bond price.
        // TODO: calculate premium basis size of the trade
        IBasisAsset(cash).burnFrom(msg.sender, cashToConvert);
        IBasisAsset(bond).mint(msg.sender, bondsToIssue);

        emit BoughtBonds(msg.sender, amountInDai, cashToConvert, bondsToIssue);

        return bondsToIssue;
    }

    /**
     * Redeeming bonds happen when
     */
    function redeemBonds(uint256 amount, bool sellForDai)
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkOperator
        updatePrice
    {
        require(amount > 0, 'zero amount');

        uint256 cashPrice = _getCashPrice(bondOracle);
        require(
            cashPrice > getBondRedemtionPrice(), // price > $1.05
            'cashPrice less than ceiling'
        );

        require(
            ICustomERC20(cash).balanceOf(address(this)) >= amount,
            'treasury has not enough budget'
        );

        amount = Math.min(accumulatedSeigniorage, amount);

        // charge stabilty fees in MAHA
        if (stabilityFee > 0) {
            uint256 stabilityFeeInARTH = amount.mul(stabilityFee).div(100);
            uint256 stabilityFeeInMAHA =
                getArthMahaOraclePrice().mul(stabilityFeeInARTH).div(1e18);

            // charge the stability fee
            ICustomERC20(share).burnFrom(msg.sender, stabilityFeeInMAHA);

            emit StabilityFeesCharged(msg.sender, stabilityFeeInMAHA);
        }

        accumulatedSeigniorage = accumulatedSeigniorage.sub(amount);
        IBasisAsset(bond).burnFrom(msg.sender, amount);

        // sell the ARTH for Dai right away
        if (sellForDai) {
            // calculate how much DAI will we get from Uniswap by selling ARTH
            address[] memory path = new address[](2);
            path[0] = address(cash);
            path[1] = address(dai);
            uint256[] memory amountsOut =
                IUniswapV2Router02(uniswapRouter).getAmountsOut(amount, path);
            uint256 expectedDaiAmount = amountsOut[1];

            // TODO: write some checkes over here

            // send it!
            ICustomERC20(cash).safeApprove(uniswapRouter, amount);
            IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
                amount,
                expectedDaiAmount,
                path,
                msg.sender,
                block.timestamp
            );
            // set approve to 0 after transfer
            ICustomERC20(cash).safeApprove(uniswapRouter, 0);
        } else {
            // or just hand over the ARTH directly
            ICustomERC20(cash).safeTransfer(msg.sender, amount);
        }

        emit RedeemedBonds(msg.sender, amount, sellForDai);
    }

    function allocateSeigniorage()
        external
        onlyOneBlock
        checkMigration
        checkStartTime
        checkEpoch
        checkOperator
    {
        _updateCashPrice();
        uint256 cash12hPrice = getSeigniorageOraclePrice();

        // send 200 ARTH reward to the person advancing the epoch to compensate for gas
        IBasisAsset(cash).mint(msg.sender, uint256(200).mul(1e18));

        // update the bond limits
        _updateConversionLimit(cash12hPrice);

        if (cash12hPrice <= cashTargetPrice) {
            return; // just advance epoch instead revert
        }

        if (cash12hPrice <= getExpansionLimitPrice()) {
            // if we are below the ceiling price (or expansion limit price) but
            // above the target price, then we try to pay off all the bond holders
            // as much as possible.

            // calculate how much seigniorage should be minted basis deviation from target price
            uint256 seigniorage = estimateSeignorageToMint(cash12hPrice);

            // if we don't have to pay bond holders anything then simply return.
            if (seigniorage == 0) return;

            // we have to pay them some amount; so mint, distribute and return
            IBasisAsset(cash).mint(address(this), seigniorage);
            emit SeigniorageMinted(seigniorage);

            _allocateToBondHolders(seigniorage);
            return;
        }

        uint256 seigniorage = estimateSeignorageToMint(cash12hPrice);
        if (seigniorage == 0) return;

        IBasisAsset(cash).mint(address(this), seigniorage);
        emit SeigniorageMinted(seigniorage);

        // send funds to the community development fund
        uint256 ecosystemReserve = _allocateToEcosystemFund(seigniorage);
        seigniorage = seigniorage.sub(ecosystemReserve);

        // keep 90% of the funds to bond token holders; and send the remaining to the boardroom
        uint256 allocatedForBondHolders =
            seigniorage.mul(bondSeigniorageRate).div(100);
        uint256 treasuryReserve =
            _allocateToBondHolders(allocatedForBondHolders);
        seigniorage = seigniorage.sub(treasuryReserve);

        // allocate everything else to the boardroom
        _allocateToBoardrooms(seigniorage);
    }
}
