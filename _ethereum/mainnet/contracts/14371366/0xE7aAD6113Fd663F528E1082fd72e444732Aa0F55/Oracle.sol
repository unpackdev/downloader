// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/*

██╗   ██╗███████╗ ██████╗████████╗ ██████╗ ██████╗ ██████╗ ███████╗
██║   ██║██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚════██╗╚════██║
██║   ██║█████╗  ██║        ██║   ██║   ██║██████╔╝ █████╔╝    ██╔╝
╚██╗ ██╔╝██╔══╝  ██║        ██║   ██║   ██║██╔══██╗ ╚═══██╗   ██╔╝ 
 ╚████╔╝ ███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║██████╔╝   ██║  
  ╚═══╝  ╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═════╝    ╚═╝  
https://vetcor37.com                                                           

If you use this contract, please consider donating to support our initiatives:

* Ethereum: 0xf32d4B3A52F98E0793A40609025f450Bb98f40C5
* Polygon: 0xdCB281707B5Fedf0f3cD05e003F55C1E58c5cbd8
* Arbitrum: 0x6D380f1949Ba2D272375F94ee689ce9BaB4F1892

*/

import "./Fixidity.sol";

/// @custom:security-contact 0xdarni@pm.me
contract ChainlinkEurEthPriceOracle {
    AggregatorV3Interface internal EurUsd;
    AggregatorV3Interface internal EthUsd;

    constructor() {
        // EUR / USD
        // https://data.chain.link/ethereum/mainnet/fiat/eur-usd
        EurUsd = AggregatorV3Interface(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
        // ETH / USD
        // https://data.chain.link/ethereum/mainnet/crypto-usd/eth-usd
        EthUsd = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    }

    function getLatestPriceEthEur() public view returns (int) {
        (
            /*uint80 roundIDEurUsd*/,
            int priceEurUsd,
            /*uint startedAtEurUsd*/,
            /*uint timeStampEurUsd*/,
            /*uint80 answeredInRoundEurUsd*/
        ) = EurUsd.latestRoundData();

        (
            /*uint80 roundIDEthUsd*/,
            int priceEthUsd,
            /*uint startedAtEthUsd*/,
            /*uint timeStampEthUsd*/,
            /*uint80 answeredInRoundEthUsd*/
        ) = EthUsd.latestRoundData();
        
        int256 P1 = Fixidity.convertFixed(priceEurUsd, 8, Fixidity.digits());
        int256 P2 = Fixidity.convertFixed(priceEthUsd, 8, Fixidity.digits());

        return Fixidity.convertFixed(Fixidity.divide(P2, P1), 24, 8);
    }

    function getLatestPriceEurEth() public view returns (int) {
        (
            uint80 roundIDEurUsd,
            int priceEurUsd,
            uint startedAtEurUsd,
            uint timeStampEurUsd,
            uint80 answeredInRoundEurUsd
        ) = EurUsd.latestRoundData();

        (
            uint80 roundIDEthUsd,
            int priceEthUsd,
            uint startedAtEthUsd,
            uint timeStampEthUsd,
            uint80 answeredInRoundEthUsd
        ) = EthUsd.latestRoundData();

        int256 P1 = Fixidity.convertFixed(priceEurUsd, 8, Fixidity.digits());
        int256 P2 = Fixidity.convertFixed(priceEthUsd, 8, Fixidity.digits());

        return Fixidity.convertFixed(Fixidity.divide(P1, P2), 24, 8);
    }
}

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}