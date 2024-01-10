//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";

contract Settings is Ownable {
    event RoyaltyInfoUpdated(address indexed receiver, uint256 royaltyPercentBips);
    event ProtocolFeeUpdated(address indexed receiver, uint256 protocolFeeBips);
    event MarketplaceAdminUpdated(address indexed marketplaceAdmin);

    // royalties on LP tokens
    uint256 public royaltyPercentBips; // ie 250 = 2.5%
    address public royaltyReceiver; 

    // protocol fee on flashmints
    uint256 public protocolFeeBips; 
    address public protocolFeeReceiver;

    // some NFT marketplaces want NFTs to have an `owner()` function
    address public marketplaceAdmin;

    string public baseURI;

    // royalties, protocol fee are 0 unless turned on
    constructor() {
        baseURI = "http://flashmint.ooo/api/tokenURI/";
    }

    function setRoyaltyPercentBips(uint256 _royaltyPercentBips) external onlyOwner {
        require(_royaltyPercentBips < 1000, "royalties: cmon"); // force prevent high royalties
        royaltyPercentBips = _royaltyPercentBips;
        
        emit RoyaltyInfoUpdated(royaltyReceiver, _royaltyPercentBips);
    }

    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
        emit RoyaltyInfoUpdated(_royaltyReceiver, royaltyPercentBips);
    }

    function setProtocolFee(uint256 _protocolFeeBips) external onlyOwner {
        require(_protocolFeeBips < 5000, "fee: cmon");
        protocolFeeBips = _protocolFeeBips;
        emit ProtocolFeeUpdated(protocolFeeReceiver, _protocolFeeBips);
    }

    function setProtocolFeeReceiver(address _protocolFeeReceiver) external onlyOwner {
        protocolFeeReceiver = _protocolFeeReceiver;
        emit ProtocolFeeUpdated(_protocolFeeReceiver, protocolFeeBips);
    }

    function setMarketplaceAdmin(address _marketplaceAdmin) external onlyOwner {
        marketplaceAdmin = _marketplaceAdmin;
        emit MarketplaceAdminUpdated(_marketplaceAdmin);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
}