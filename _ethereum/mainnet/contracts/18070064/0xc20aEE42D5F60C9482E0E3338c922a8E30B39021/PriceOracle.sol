// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Initializable.sol";
import "./IPriceFeed.sol";
import "./Ownable.sol";

import "./RoboFiAddress.sol";

contract PriceOracle is Context, Ownable, Initializable {

    using RoboFiAddress for address;

    IPriceFeed public _defaultPriceFeed;
    mapping(address => IPriceFeed) internal  _priceFeedMap;

    function initialize(IPriceFeed defaultPriceFeed) external payable initializer {
        _defaultPriceFeed = defaultPriceFeed;
    }

    function setDefaultPriceFeed(IPriceFeed priceFeed) external onlyOwner {
        _defaultPriceFeed = priceFeed;
    }

    function setPriceFeed(address asset, IPriceFeed priceFeed) external onlyOwner {
        _priceFeedMap[asset] = priceFeed;
    }

    function getPriceFeed(address asset) public view returns(IPriceFeed priceFeed) {
        priceFeed = _priceFeedMap[asset];
        if (address(priceFeed) == address(0))
            priceFeed = _defaultPriceFeed;
    }

    function getAssetPrice(address asset) public view returns(uint) {
        if (!asset.isNativeAsset()) {
            if (asset.isCertToken()) {
                IDABotCertToken certToken = IDABotCertToken(asset);
                uint rate = certToken.value(1e18);
                address underlyAsset = address(certToken.asset());
                return getAssetPrice(underlyAsset) * rate / 1e18;
            }

            if (asset.isGovernToken()) {
                IDABotGovernToken gToken = IDABotGovernToken(asset);
                uint rate = gToken.value(1e18);
                address underlyAsset = address(gToken.asset());
                return getAssetPrice(underlyAsset) * rate / 1e18;
            }

            if (asset.isTreasuryAsset()) {
                asset = address(ITreasuryAsset(asset).asset());
            }
        }
        IPriceFeed priceFeed = getPriceFeed(asset);
        return priceFeed.getAssetPrice(asset);  
    }
}