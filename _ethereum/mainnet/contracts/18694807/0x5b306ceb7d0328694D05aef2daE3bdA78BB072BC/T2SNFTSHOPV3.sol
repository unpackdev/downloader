// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./T2SNFTSHOPV2.sol";
import "./AggregatorV3Interface.sol";

contract T2SNFTSHOPV3 is T2SNFTSHOPV2 {
    AggregatorV3Interface private ethToUsdFeed; //ChainLink Feed

    constructor(INFT _nftAddress, myIERC20[] memory _stablecoinsAddress,address _ethToUsdFeed) T2SNFTSHOPV2(_nftAddress, _stablecoinsAddress) {
        ethToUsdFeed = AggregatorV3Interface(_ethToUsdFeed);
}

    /**
        * @dev Buy NFT with ETH with a 0.8% slippage
     */
    function buyInETH(
        uint256 _tokenId,
        address _to,
        uint256 _amount
    ) public payable {
        require(
            fundsRecipient[_tokenId] != address(0),
            "Shop: recipient is address 0"
        );
        require(isSellAllowed[_tokenId], "Shop: sell not allowed");

        uint256 ethPrice = getNFTPriceInETH(_tokenId);
        require(
            msg.value > ((992 * ethPrice)) * _amount / 1000 &&
            msg.value < ((1008 * ethPrice)) * _amount / 1000,
            "bad ETH amount"
        );

        // The value is immediately transferred to the funds recipient
        (bool sent,) = payable(fundsRecipient[_tokenId]).call{value : msg.value}("");
        require(sent, "Failed to send Ether");
        _mint(_to, _tokenId, _amount, "");
    }

    /**
     * @dev Return the price in ETH of the specified NFTID
     * decimals of Chainlink feeds are NOT with 18 decimals.
     */
    function getNFTPriceInETH(
        uint256 _nftId
    ) public view returns (uint256 priceInETH) {
        uint256 priceInUsd = USDPrice[_nftId];
        uint256 ethToUsd = _getETHtoUSDPrice();
        // Convert price in ETH for US Dollar price
        priceInETH =
            (priceInUsd * 10 ** ethToUsdFeed.decimals() * 10 ** 18) /
            ethToUsd;
    }

    /**
  * @dev Get current rate of ETH to US Dollar
     */
    function _getETHtoUSDPrice() private view returns (uint256) {
        (, int256 price, , ,) = ethToUsdFeed.latestRoundData();
        return uint256(price);
    }
}