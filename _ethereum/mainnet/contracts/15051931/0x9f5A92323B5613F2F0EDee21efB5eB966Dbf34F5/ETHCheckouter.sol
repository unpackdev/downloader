// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Address.sol";
import "./AggregatorV3Interface.sol";

import "./IETHCheckouter.sol";

abstract contract ETHCheckouter is IETHCheckouter, Context, Ownable {
    using Address for address;
    using SafeMath for uint256;

    TokenInfo ethInfo; 

    function setEthInfo(TokenInfo memory _tokenInfo) public onlyOwner {
        ethInfo = _tokenInfo;
    }

    receive() external payable {}

    function fiatAnchoredAmount(uint256 amount) public view override returns (uint256 anchoredAmount) {
        if (ethInfo.fiatOracle != address(0)) {   // only consider one fiat oracle.
            AggregatorV3Interface priceFeed = AggregatorV3Interface(ethInfo.fiatOracle);
            (
                /*uint80 roundID*/,
                int price,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = priceFeed.latestRoundData();
            anchoredAmount = amount.mul(ethInfo.fiatDecimals).div(ethInfo.decimals).div(uint256(price));
        } else {
            revert("no oracle sets");
        }
        require(anchoredAmount > 0, "cannot find enough info to get the anchored amount");
    }

    function ethPurchase(uint256 amount, BillingType billingType) public override payable {
        if (billingType == BillingType.FIXED_AMOUNT) {
            require(msg.value >= amount, "not enough value");
            // payable(address(this)).transfer(amount);
            (bool sent, ) = address(this).call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else if (billingType == BillingType.FIAT_ANCHORED) {
            uint256 anchoredAmount = fiatAnchoredAmount(amount);
            require(msg.value >= anchoredAmount, "not enough value");
            (bool sent, ) = address(this).call{value: anchoredAmount}("");
            require(sent, "Failed to send Ether");
        }
    }
    
    function withdraw(address settler) public override onlyOwner {
        payable(settler).transfer(address(this).balance);
    }
}