//SPDX-License-Identifier: Copyright 2022 Shipyard Software, Inc.
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./Ownable.sol";

import "./ClipperCommonExchange.sol";
import "./Sqrt.sol";

contract ClipperCove is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using Sqrt for uint256;

    mapping(address => uint256) public lastBalances;
    mapping(address => uint256) public totalDepositTokenSupply;
    mapping(address => mapping (address => uint256)) public depositTokenRegistry;

    address payable immutable public CLIPPER_EXCHANGE;
    address constant CLIPPER_ETH_SIGIL=address(0);

    uint256 constant ONE_IN_BASIS_POINTS = 10000;

    uint256 public totalClipperFees;
    uint256 public clipperFeeBps;
    uint256 public tradeFeeBps;

    event CoveSwapped(
        address indexed inAsset,
        address indexed outAsset,
        address indexed recipient,
        uint256 inAmount,
        uint256 outAmount,
        bytes32 auxiliaryData
    );

    event CoveDeposited(
        address indexed tokenAddress,
        address indexed depositor,
        uint256 poolTokens,
        uint256 poolTokensAfterDeposit
    );

    event CoveWithdrawn(
        address indexed tokenAddress,
        address indexed withdrawer,
        uint256 poolTokens,
        uint256 poolTokensAfterWithdrawal
    );

    constructor(address theExchange, uint256 tradeFee, uint256 clipperFee) {
        CLIPPER_EXCHANGE = payable(theExchange);
        tradeFeeBps = tradeFee;
        clipperFeeBps = clipperFee;
    }

    // Allows the receipt of ETH directly
    receive() external payable {
    }

    function changeFees(uint256 tradeFee, uint256 clipperFee) external onlyOwner {
        tradeFeeBps = tradeFee;
        clipperFeeBps = clipperFee;
    }

    function redeem() external onlyOwner returns (uint256 currentFees) {
        currentFees = totalClipperFees;
        totalClipperFees = 0;
        IERC20(CLIPPER_EXCHANGE).transfer(msg.sender, currentFees);
    }

    function pack256(uint256 x, uint256 y) internal pure returns (uint256 retval) {
        retval = y.toUint128();
        retval += (uint256(x.toUint128()) << 128);
    }

    function unpack256(uint256 packed) internal pure returns (uint256 x, uint256 y) {
        y = uint256(uint128(packed));
        x = packed >> 128;
    }

    function hasMarket(address token) public view returns (bool) {
        return totalDepositTokenSupply[token] > 0;
    }

    function canDeposit(address token) public view returns (bool) {
        return (token != CLIPPER_EXCHANGE) && (token != CLIPPER_ETH_SIGIL) && !ClipperCommonExchange(CLIPPER_EXCHANGE).isToken(token);
    }

    function tokenBalance(address token) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function invariant(uint256 x, uint256 y) internal pure returns (uint256){
        return (x*y).sqrt();
    }

    function lastLPAndToken(address token) internal view returns (uint256, uint256) {
        uint256 packedLPandToken = lastBalances[token];
        return unpack256(packedLPandToken);
    }

    function swapReturn(uint256 x, uint256 y, uint256 a, uint256 minBuyAmount) internal view returns (uint256 b) {
        require(a>0, "ClipperCove: No Input");
        uint256 adjA = ((ONE_IN_BASIS_POINTS-tradeFeeBps)*a)/ONE_IN_BASIS_POINTS;
        b = (adjA*y)/(adjA+x);
        if(b > y){
            b = y;
        }
        require(b>=minBuyAmount, "ClipperCove: Insufficient buy amount");
    }

    function shaveLPByFee(uint256 theLP) internal view returns (uint256) {
        return (theLP*(ONE_IN_BASIS_POINTS-clipperFeeBps))/ONE_IN_BASIS_POINTS;
    }

    function getSellQuote(address sellToken, uint256 sellAmount, address buyToken) public view returns (uint256) {
        bool _sellClipper = (sellToken==CLIPPER_EXCHANGE);
        bool _buyClipper = (buyToken==CLIPPER_EXCHANGE);
        (uint256 sellLP, uint256 sellTokenBalance) = lastLPAndToken(sellToken);
        (uint256 buyLP, uint256 buyTokenBalance) = lastLPAndToken(buyToken);

        if(!_sellClipper && !_buyClipper){
            require(hasMarket(sellToken) && hasMarket(buyToken), "ClipperCove: Not traded");
            uint256 outToBuyCove = swapReturn(sellTokenBalance, sellLP, sellAmount, 0);
            return swapReturn(buyLP, buyTokenBalance, outToBuyCove, 0);
        } else if(_sellClipper) {
            require(hasMarket(buyToken), "ClipperCove: Not traded");
            return swapReturn(buyLP, buyTokenBalance, sellAmount, 0);
        } else if(_buyClipper) {
            require(hasMarket(sellToken), "ClipperCove: Not traded");
            return swapReturn(sellTokenBalance, sellLP, sellAmount, 0);
        }
        return 0;
    }

    /*
        Three kinds of coins:
        1) "5" -> shorttail tokens traded on Clipper
        2) "ClipperLP" -> Clipper LP tokens
        3) N -> longtail tokens not on Clipper

        That means there are 8 swap operations (ClipperLP -> ClipperLP is no op)
        5 -> 5: Clipper swap, not handled here
        5 -> ClipperLP: Clipper deposit, not handled here
        5 -> N: depositForCoin function. One shot.
        ClipperLP -> 5: Clipper single-asset withdrawal, not handled here
        ClipperLP -> N: sellTokenForToken (single cove).
        N -> 5: Two txs, first do N -> ClipperLP here, then single-asset withdrawal
        N -> ClipperLP: sellTokenForToken (single cove).
        N -> N: sellTokenForToken (two coves)

    */

    function sellClipperForToken(address buyToken, uint256 sellAmount, uint256 minBuyAmount) internal returns (uint256 buyAmount) {
        require(hasMarket(buyToken), "ClipperCove: Not traded");
        (uint256 buyLP, uint256 buyTokenBalance) = lastLPAndToken(buyToken);

        buyAmount = swapReturn(buyLP, buyTokenBalance, sellAmount, minBuyAmount);
        lastBalances[buyToken] = pack256(buyLP+sellAmount, buyTokenBalance-buyAmount);
    }

    function sellTokenForClipper(address sellToken, uint256 sellAmount, uint256 minBuyAmount) internal returns (uint256 buyAmount) {
        require(hasMarket(sellToken), "ClipperCove: Not traded");
        (uint256 sellLP, uint256 sellTokenBalance) = lastLPAndToken(sellToken);

        buyAmount = swapReturn(sellTokenBalance, sellLP, sellAmount, minBuyAmount);
        lastBalances[sellToken] = pack256(sellLP-buyAmount, sellTokenBalance+sellAmount);
    }

    // Pull from msg.sender
    function transmitAndSellTokenForToken(address sellToken, uint256 sellAmount, address buyToken, uint256 minBuyAmount, address destinationAddress, bytes32 auxData) external nonReentrant returns (uint256 buyAmount) {
        bool _sellClipper = sellToken==CLIPPER_EXCHANGE;
        bool _buyClipper = buyToken==CLIPPER_EXCHANGE;
        
        IERC20(sellToken).safeTransferFrom(msg.sender, address(this), sellAmount);

        if(!_sellClipper && !_buyClipper){
            require(hasMarket(sellToken) && hasMarket(buyToken), "ClipperCove: Not traded");
            // Transfer sellToken from msg.sender to sellToken cove
            // Get LP token amount to move
            uint256 lpTokenOut;
            {
                (uint256 sellLP, uint256 sellTokenBalance) = lastLPAndToken(sellToken);
                lpTokenOut = swapReturn(sellTokenBalance, sellLP, sellAmount, 0);
                lastBalances[sellToken] = pack256(sellLP-lpTokenOut, sellTokenBalance+sellAmount);
            }

            (uint256 buyLP, uint256 buyTokenBalance) = lastLPAndToken(buyToken);
            buyAmount = swapReturn(buyLP, buyTokenBalance, lpTokenOut, minBuyAmount);
            lastBalances[buyToken] = pack256(buyLP+lpTokenOut, buyTokenBalance-buyAmount);
        } else if(_sellClipper) {
            buyAmount = sellClipperForToken(buyToken, sellAmount, minBuyAmount);
        } else if(_buyClipper) {
            buyAmount = sellTokenForClipper(sellToken, sellAmount, minBuyAmount);
        } else {
            revert();
        }
        IERC20(buyToken).safeTransfer(destinationAddress, buyAmount);

        emit CoveSwapped(sellToken, buyToken, destinationAddress, sellAmount, buyAmount, auxData);
    }

    // async, assumes sellToken has already been transferred
    // NB: sellToken cannot be Clipper LP token, since we don't track that balance
    function sellTokenForToken(address sellToken, address buyToken, uint256 minBuyAmount, address destinationAddress, bytes32 auxData) external nonReentrant returns (uint256 buyAmount){
        require(sellToken != CLIPPER_EXCHANGE, "ClipperCove: Not tradable async");
        
        (uint256 sellLP, uint256 lastTokenBalance) = lastLPAndToken(sellToken);
        uint256 _sellBalance = tokenBalance(sellToken);
        
        if(buyToken != CLIPPER_EXCHANGE){
            require(hasMarket(sellToken) && hasMarket(buyToken), "ClipperCove: Not traded");
            // Transfer sellToken from msg.sender to sellToken cove
            // Get LP token amount to move
            (uint256 buyLP, uint256 buyTokenBalance) = lastLPAndToken(buyToken);
            uint256 lpTokenOut = swapReturn(lastTokenBalance, sellLP, _sellBalance-lastTokenBalance, 0);
            buyAmount = swapReturn(buyLP, buyTokenBalance, lpTokenOut, minBuyAmount);
            
            // Update values:
            // Sell balances: [LP - lpTokenOut, token + sellToken]
            // Buy balances: [LP + lpTokenOut, token - buyAmount]
            lastBalances[sellToken] = pack256(sellLP-lpTokenOut, _sellBalance);
            lastBalances[buyToken] = pack256(buyLP+lpTokenOut, buyTokenBalance-buyAmount);
        } else {
            buyAmount = sellTokenForClipper(sellToken, _sellBalance-lastTokenBalance, minBuyAmount);
        }
        IERC20(buyToken).safeTransfer(destinationAddress, buyAmount);

        emit CoveSwapped(sellToken, buyToken, destinationAddress, _sellBalance-lastTokenBalance, buyAmount, auxData);
    }

    // Internal function to assist with deposits
    // Returns net amount deposited after fees
    // Use CLIPPER_ETH_SIGIL if depositing raw native token as msg.value
    function transferAndClipperDeposit(address clipperAsset, uint256 depositAmount, uint256 poolTokens, uint256 goodUntil, ClipperCommonExchange.Signature memory theSignature) internal returns (uint256 tokensAfterShave) {
        if(clipperAsset != CLIPPER_ETH_SIGIL){
            IERC20(clipperAsset).safeTransferFrom(msg.sender, CLIPPER_EXCHANGE, depositAmount);
        } else {
            clipperAsset = ClipperCommonExchange(CLIPPER_EXCHANGE).WRAPPER_CONTRACT();
        }
        ClipperCommonExchange(CLIPPER_EXCHANGE).depositSingleAsset{ value:msg.value }(address(this), clipperAsset, depositAmount, 0, poolTokens, goodUntil, theSignature);
        tokensAfterShave = shaveLPByFee(poolTokens);
        if(poolTokens > tokensAfterShave){
            totalClipperFees += poolTokens-tokensAfterShave;
        }
    }

    // One-shot 5 -> N swap. Clipper fees get charged.
    function depositForCoin(address buyToken, uint256 minBuyAmount, address clipperAsset, uint256 depositAmount, uint256 poolTokens, uint256 goodUntil, ClipperCommonExchange.Signature calldata theSignature, bytes32 auxData) external payable nonReentrant returns (uint256 buyAmount) {
        uint256 netDepositedTokens = transferAndClipperDeposit(clipperAsset, depositAmount, poolTokens, goodUntil, theSignature);
        
        buyAmount = sellClipperForToken(buyToken, netDepositedTokens, minBuyAmount);

        IERC20(buyToken).safeTransfer(msg.sender, buyAmount);
        emit CoveSwapped(clipperAsset, buyToken, msg.sender, depositAmount, buyAmount, auxData);
    }

    function _mint(address coin, address user, uint256 amount) internal {
        depositTokenRegistry[coin][user] += amount;
        totalDepositTokenSupply[coin] += amount;
    }

    function _burn(address coin, address user, uint256 amount) internal {
        // reverts on underflow
        require(depositTokenRegistry[coin][user] >= amount, "ClipperCove: Burn amount exceeds user balance");
        unchecked {
            depositTokenRegistry[coin][user] -= amount;
        }
        totalDepositTokenSupply[coin] -= amount;
    }

    function _mintHandler(address coin, uint256 nextInvariant, uint256 lastInvariant) internal returns (uint256 toMint) {
        if(lastInvariant > 0){
            uint256 lastSupply = totalDepositTokenSupply[coin];
            toMint = ((nextInvariant - lastInvariant)*lastSupply)/lastInvariant;
        } else {
            toMint = 1e8 * nextInvariant;
        }
        // Mint coins for msg.sender
        _mint(coin, msg.sender, toMint);
        emit CoveDeposited(coin, msg.sender, toMint, totalDepositTokenSupply[coin]);
    }

    // Pulls from msg.sender. Can omit deposit of either Clipper or Coin
    function transmitAndDeposit(address coin, uint256 coinDepositAmount, address clipperAsset, uint256 clipperDepositAmount, uint256 poolTokens, uint256 goodUntil, ClipperCommonExchange.Signature calldata theSignature) external payable nonReentrant returns (uint256) {
        require(canDeposit(coin), "ClipperCove: Cannot deposit");

        (uint256 lastLP, uint256 lastToken) = lastLPAndToken(coin);
        uint256 lastInvariant = invariant(lastLP, lastToken);

        uint256 netDepositedTokens = 0;
        if(clipperDepositAmount>0 && poolTokens>0){
            netDepositedTokens = transferAndClipperDeposit(clipperAsset, clipperDepositAmount, poolTokens, goodUntil, theSignature);
        }
        // Transfer coins to the cove, if relevant
        if(coinDepositAmount > 0){
            IERC20(coin).safeTransferFrom(msg.sender, address(this), coinDepositAmount);            
        }
        /* Deleted for local stack...
        uint256 nextLP = lastLP + netDepositedTokens;
        uint256 nextToken = lastToken + coinDepositAmount;
        */

        uint256 nextInvariant = invariant(lastLP + netDepositedTokens, lastToken + coinDepositAmount);
        require(nextInvariant > lastInvariant);
        // Update balances
        lastBalances[coin] = pack256(lastLP + netDepositedTokens, lastToken + coinDepositAmount);
        return _mintHandler(coin, nextInvariant, lastInvariant);
    }

    // Burn to Withdraw
    function burnToWithdraw(address coin, uint256 tokenAmount) external nonReentrant {
        require(hasMarket(coin), "ClipperCove: Not traded");
        uint256 fractionBurntInDefaultDecimals = (tokenAmount*(1 ether))/totalDepositTokenSupply[coin];
        _burn(coin, msg.sender, tokenAmount);
        (uint256 lastLP, uint256 lastToken) = lastLPAndToken(coin);
        uint256 lpToSend = (fractionBurntInDefaultDecimals*lastLP)/(1 ether);
        uint256 tokenToSend = (fractionBurntInDefaultDecimals*lastToken)/(1 ether);

        lastBalances[coin] = pack256(lastLP - lpToSend, lastToken - tokenToSend);
        IERC20(CLIPPER_EXCHANGE).safeTransfer(msg.sender, lpToSend);
        IERC20(coin).safeTransfer(msg.sender, tokenToSend);

        emit CoveWithdrawn(coin, msg.sender, tokenAmount, totalDepositTokenSupply[coin]);
    }

}