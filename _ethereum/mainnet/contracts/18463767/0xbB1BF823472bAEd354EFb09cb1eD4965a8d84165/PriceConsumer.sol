// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./FeedRegistryInterface.sol";
import "./Denominations.sol";

import "./IPriceConsumer.sol";

contract PriceConsumer is IPriceConsumer{

    FeedRegistryInterface private _registry;
    
    address[18] private _currencies = [
        Denominations.USD, Denominations.GBP, Denominations.EUR, Denominations.JPY, Denominations.KRW, Denominations.CNY,
        Denominations.AUD, Denominations.CAD, Denominations.CHF, Denominations.ARS, Denominations.PHP, Denominations.NZD,
        Denominations.SGD, Denominations.NGN, Denominations.ZAR, Denominations.RUB, Denominations.INR, Denominations.BRL
    ];

    /**
     * Network: Ethereum Mainnet
     * Feed Registry: 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf
     */

    function _setFeedRegistry(address registry_) internal {
        _registry = FeedRegistryInterface(registry_);
    }

    function getFeedRegistryAddress() external view returns (address) {
        return address(_registry);
    }

    function decimals(address quote) public view returns (uint8) {
        return _registry.decimals(Denominations.ETH, quote);
    }

    function getCentPriceInWei(uint seqOfCurrency) public view returns (uint) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = _registry.latestRoundData(Denominations.ETH, _currencies[seqOfCurrency]);

        uint dec = decimals(_currencies[seqOfCurrency]);

        return 10 ** (16 + dec) / uint(price); 
    }

}
