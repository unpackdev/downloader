// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";

interface IERC20Metadata {
    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract PriceOracle is Ownable {
    /**
     * @dev please take care token decimal
     * e.x ethPrice[uno_address] = 123456 means 1 UNO = 123456 / (10 ** 18 eth)
     */
    mapping(address => uint256) ethPrices;
    uint256 private ethPriceUsd;

    event AssetPriceUpdated(address _asset, uint256 _price, uint256 timestamp);
    event EthPriceUpdated(uint256 _price, uint256 timestamp);

    function getEthUsdPrice() external view returns (uint256) {
        return ethPriceUsd;
    }

    function setEthUsdPrice(uint256 _price) external onlyOwner {
        ethPriceUsd = _price;
        emit EthPriceUpdated(_price, block.timestamp);
    }

    function getAssetEthPrice(address _asset) external view returns (uint256) {
        return ethPrices[_asset];
    }

    function setAssetEthPrice(address _asset, uint256 _price) external onlyOwner {
        ethPrices[_asset] = _price;
        emit AssetPriceUpdated(_asset, _price, block.timestamp);
    }

    /**
     * returns the tokenB amount for tokenA
     */
    function consult(
        address tokenA,
        address tokenB,
        uint256 amountA
    ) external view returns (uint256) {
        require(ethPrices[tokenA] != 0 && ethPrices[tokenB] != 0, "PO: Prices of boht tokens should be set");

        // amountA * ethPrices[tokenA] / IERC20Metadata(tokenA).decimals() / ethPrices[tokenB] * IERC20Metadata(tokenB).decimals()
        return
            (amountA * ethPrices[tokenA] * (10**IERC20Metadata(tokenB).decimals())) /
            (10**IERC20Metadata(tokenA).decimals() * ethPrices[tokenB]);
    }
}
