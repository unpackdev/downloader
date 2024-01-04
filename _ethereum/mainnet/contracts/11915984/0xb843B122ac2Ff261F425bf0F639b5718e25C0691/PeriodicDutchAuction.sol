// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./IERC20.sol";

import "./SigToken.sol";

/**
 * @title FeeAdminV1DutchAuction
 * @notice Sells admin fees from xsigma3pool for SigToken and burns it.
 * Sell happens via Dutch Auction periodically from highest price to lowest one.
 * Owner can change the auction settings.
 */
contract PeriodicDutchAuction is Ownable {
    using SafeMath for uint256;

    SigToken public sigToken;
    address[] public coins;
    /*
        the price of the auction works like this:
        from the block {startBlock} every {term} any of {coins} avaliable on balance
        can be bought by Sig token using current sigPrice(currBlock).
        the price(t) == a*t + b every term,
        i.e. t = (currBlock - startBlock) % term,
        so the highest price is b, and the lowest price is b - a*term
    */
    uint256 public startBlock = 1e18; // INF at the beginning
    uint256 public periodBlocks;
    uint256 public a;
    uint256 public b;

    event SetSettings(
        uint256 _startBlock,
        uint256 _auctionPeriodBlocks,
        uint256 _lowestSig1e18Price,
        uint256 _highestSig1e18Price
    );
    event Bought(
        address msg_sender,
        uint256 sellSigAmount,
        uint256 buyTokenId,
        uint256 minBuyAmount,
        uint256 outputAmount
    );


    constructor(
        SigToken _sigToken,
        address[3] memory _coins
    ) public {
        sigToken = _sigToken;
        for (uint256 i = 0; i < 3; i++) {
            require(_coins[i] != address(0));
            coins.push(_coins[i]);
        }
    }

    /**
     * @notice Set parameters for Dutch Auction as SigToken price.
     * @param _startBlock - before this block number getPriceSig which revert
     * @param _auctionPeriodBlocks - auction will happens every _term blocks from _startBlock
     * @param _lowestSig1e18Price - start lowest price of Sig in usd,
     *                              so if you want to start from 1 SigToken == 0.01 DAI,
     *                              it should be 0.01*1e18.
     *                              All stablecoins in the pool are considered worth of $1.
     * @param _highestSig1e18Price - the last/highest SIG price on the auction
     */
    function setAuctionSettings(
        uint256 _startBlock, 
        uint256 _auctionPeriodBlocks,
        uint256 _lowestSig1e18Price,
        uint256 _highestSig1e18Price
    ) public onlyOwner {
        startBlock = _startBlock;
        periodBlocks = _auctionPeriodBlocks;
        b = _lowestSig1e18Price;
        a = _highestSig1e18Price.sub(_lowestSig1e18Price).div(periodBlocks.sub(1));
        emit SetSettings(_startBlock, _auctionPeriodBlocks, _lowestSig1e18Price, _highestSig1e18Price);
    }

    /**
    * @notice price for SIG token in USD * 1e18 at currBlock
    */
    function getSig1e18Price(uint256 currBlock, uint256 tokenId) public view returns (uint256) {
        require(startBlock <= currBlock, "Auction hasn't started yet");
        uint256 t = (currBlock - startBlock) % periodBlocks;

        uint256 price;
        if (tokenId == 0) {
            // i = 0 => DAI with 1e18 precision
            price = b.add(a.mul(t));
        } else {
            // i = 1 || 2, => USDC/USDT with 1e6 precision
            price = b.add(a.mul(t)).div(1e12);
        }
        return price;
    }

    /**
    * @notice Try to exchange SIG token for one of stablecoins
    * @param sellSigAmount - amount of SigToken
    * @param buyTokenId - number of stablecoins, by default 0,1 or 2 for DAI, USDC or USDT
    * @param buyAtLeastAmount - if there's not enough balance, buy at least specified amount of stablecoin
    *                           if it's 0 - transaction will be reverted if there's no enough coins
    */
    function sellSigForStablecoin(uint256 sellSigAmount, uint256 buyTokenId, uint256 buyAtLeastAmount) public {
        // how much stablecoins should we give
        uint256 sig1e18Price = getSig1e18Price(block.number, buyTokenId);
        uint256 outputAmount = sellSigAmount.mul(sig1e18Price).div(1e18);
        // maybe the contract has less stablecoins, but it's still enough to satisfy user request
        if (IERC20(coins[buyTokenId]).balanceOf(address(this)) < outputAmount) {
            //
            if (buyAtLeastAmount == 0) {
                revert("not enough stablecoins to buy");
            }
            // trying to buy as much as we can for current price
            sellSigAmount = buyAtLeastAmount.mul(1e18).div(sig1e18Price);
            outputAmount = buyAtLeastAmount;
        }
        // take Sig and burn
        sigToken.burnFrom(msg.sender, sellSigAmount);
        // return fee token
        IERC20(coins[buyTokenId]).transfer(msg.sender, outputAmount);

        emit Bought(msg.sender, sellSigAmount, buyTokenId, buyAtLeastAmount, outputAmount);
    }
}
