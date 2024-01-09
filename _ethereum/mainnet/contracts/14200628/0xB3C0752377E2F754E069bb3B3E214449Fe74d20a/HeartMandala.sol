// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/// @custom:security-contact hi@pixmandala.art
contract HeartMandala is ERC721, Ownable {
    
    // Counter of tokens id
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Maximum amount of NFT
    uint public mintVolume;

    constructor() ERC721("HeartMandala", "HeartM") {
        mintVolume = 14141;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmWSzoegYPKbqT3vxPaNpUtqM5G8o6qUqAPZEgcKTwc3GL/";
    }

    /**
     * @dev Minting
     */
    function mint(address to, uint256 count) public onlyOwner {
        uint256 tokenId;
              
        for (uint256 i=0; i<=count; i++) {
            tokenId = _tokenIdCounter.current();

            require(tokenId<=mintVolume, "HeartMandala: Limit of mint count");

            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    /**
     * @dev Withdraw of money from contract
     */
    function withdraw() public onlyOwner {
        uint _balance = address(this).balance;
        address payable _reciver = payable(msg.sender);
        _reciver.transfer(_balance);
    }
}