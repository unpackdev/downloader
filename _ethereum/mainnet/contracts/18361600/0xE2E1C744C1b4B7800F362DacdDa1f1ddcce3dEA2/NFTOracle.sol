// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./OwnableUpgradeable.sol";

struct IResponse {
    uint80 roundId;
    int answer;
    uint startedAt;
    uint updatedAt;
    uint80 answeredInRound;
}

interface IChainlinkPriceOracle {
    function latestRoundData() external view returns(IResponse memory res);
}

contract NFTOracle is OwnableUpgradeable {

    mapping(address => address) public nftOracleMap;

    mapping(address => int) public cacheData;

    function initialize() external initializer {
        __Ownable_init();
    }

    function initializeOracleMap(address[] calldata _nfts, address[] calldata _oracles) external onlyOwner {
        require(_nfts.length > 0 && (_nfts.length == _oracles.length), 'bad data');

        uint len = _nfts.length;

        for(uint idx; idx < len;) {
            updateNFTOracle(_nfts[idx], _oracles[idx]);
            unchecked {idx++;}
        }
    }

    function updateNFTOracle(address _nft, address _oracle) public onlyOwner {
        nftOracleMap[_nft] = _oracle;
    } 

    function getPrice(address _nft) external returns(int) {
        address oracle = nftOracleMap[_nft];
        require(oracle != address(0), 'not initialize');
        IResponse memory res = IChainlinkPriceOracle(oracle).latestRoundData();
        cacheData[_nft] = res.answer;
        return res.answer;
    }

    function getPrice_view(address _nft) external view returns(int) {
        return cacheData[_nft];
    }
}

