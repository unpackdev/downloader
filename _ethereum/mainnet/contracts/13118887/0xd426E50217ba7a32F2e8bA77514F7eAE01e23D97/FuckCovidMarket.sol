/*

  ______ _    _  _____ _  __   _____ ______      _______ _____  
 |  ____| |  | |/ ____| |/ /  / ____/ __ \ \    / /_   _|  __ \ 
 | |__  | |  | | |    | ' /  | |   | |  | \ \  / /  | | | |  | |
 |  __| | |  | | |    |  <   | |   | |  | |\ \/ /   | | | |  | |
 | |    | |__| | |____| . \  | |___| |__| | \  /   _| |_| |__| |
 |_|     \____/ \_____|_|\_\  \_____\____/   \/   |_____|_____/ 

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IFuckCovidMarket.sol";
import "./FuckCovid.sol";
import "./Withdrawable.sol";

contract FuckCovidMarket is IFuckCovidMarket, FuckCovid, Withdrawable {
    uint256 override public tokenPrice;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _stubURI,
        string memory _contractURI,
        uint64 _timestamp,
        uint16 _maxTotalSupply,
        address _proxyRegistry,
        uint256 _tokenPrice
    )
        FuckCovid(
            _name,
            _symbol,
            _baseUri,
            _stubURI,
            _contractURI,
            _timestamp,
            _maxTotalSupply,
            _proxyRegistry
        )
    {
        tokenPrice = _tokenPrice;
    }

    function buyToken(address _to) external payable override returns (uint16) {
        require(
            msg.value >= tokenPrice,
            "FuckCovidMarket: Not enough ETH to buy this NFT"
        );
        return _mintToken(_to);
    }

    function buyTokens(address _to, uint16 _amount)
        external
        payable
        override
        returns (uint16)
    {
        require(
            msg.value >= _amount * tokenPrice,
            "FuckCovidMarket: Not enough ETH to buy this amount of NFT"
        );

        return _mintTokens(_to, _amount);
    }

    function setTokenPrice(uint256 _tokenPrice) external override onlyOwner {
        tokenPrice = _tokenPrice;
    }
}
