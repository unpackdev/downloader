// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./AggregatorV3Interface.sol";

import "./IERC20Checkouter.sol";
import "./console.sol";

abstract contract ERC20Checkouter is IERC20Checkouter, Context, Ownable {
    using Address for address;
    using SafeMath for uint256;

    address[] tokenList;
    mapping(address => TokenInfo) tokenInfoMapper;

    modifier onlySupportedToken(address token) {
        require(_tokenCheckouterRegistered(token), "token unsupport");
        _;
    }
    
    function addTokenCheckouter(address token, TokenInfo memory tokenInfo) public override onlyOwner {
        require(token.isContract() && !_tokenCheckouterRegistered(token), "token should be a contract");

        tokenList.push(token);
        tokenInfoMapper[token] = tokenInfo;
    }

    function removeTokenCheckouter(address token) public override onlyOwner onlySupportedToken(token) {
        uint8 index = 0;
        for (uint8 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == token) {
                index = i;
            }
        }
        address[] memory newTokenList = new address[](tokenList.length-1);
        for (uint8 j = 0; j < newTokenList.length; j++) {
            if (j < index) {
                newTokenList[j] = tokenList[j];
            } else {
                newTokenList[j] = tokenList[j + 1];
            }
        }
        tokenList = newTokenList;
        delete tokenInfoMapper[token];
    }

    function _tokenCheckouterRegistered(address token) private view returns (bool registered) {
        for (uint8 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == token) {
                registered = true;
            }
        }
    }

    function tokenFiatAnchoredAmount(address token, uint256 amount) public view override onlySupportedToken(token) returns (uint256 anchoredAmount) {
        TokenInfo memory tokenInfo = tokenInfoMapper[token];
        if (tokenInfo.fiatOracle != address(0)) {   // only consider one fiat oracle.
            AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenInfo.fiatOracle);
            (
                /*uint80 roundID*/,
                int price,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = priceFeed.latestRoundData();
            anchoredAmount = amount.mul(tokenInfo.fiatDecimals).div(tokenInfo.decimals).div(uint256(price));
        } else if (tokenInfo.swapPair != address(0)) {   // only consider one swap(uniswap/pancakeswap) abi recently
            //TODO
        }
        require(anchoredAmount > 0, "cannot find enough info to get the anchored amount");
    }

    function tokenPurchase(address token, address from, uint256 amount, BillingType billingType) public override onlySupportedToken(token) {
        if (billingType == BillingType.FIXED_AMOUNT) {
            // console.log("token purchasing _msgSender(): %s, from: %s", _msgSender(), from);
            IERC20(token).transferFrom(from, address(this), amount);
        } else if (billingType == BillingType.FIAT_ANCHORED) {
            IERC20(token).transferFrom(from, address(this), tokenFiatAnchoredAmount(token, amount));
        }
    }

    function withdrawToken(address token, address to) public override onlyOwner {
        IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
    }
}