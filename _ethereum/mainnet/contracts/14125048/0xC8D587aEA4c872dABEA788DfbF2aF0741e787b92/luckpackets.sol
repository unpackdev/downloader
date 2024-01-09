// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";


contract LuckyPackets is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;

    uint256 public constant MAX_NFT_SUPPLY = 2888;
    uint256 public constant MAX_FREE = 888;
    uint256 public constant PRICE = 0.018 ether;
    uint256 public constant DISCOUNTEDMAXTX = 0.108 ether;
    uint public maxPerTx = 8;
    

    constructor() ERC721("Lucky Packets", "LPKT") {
        _contractUri = "https://gateway.pinata.cloud/ipfs/QmXaeifEjnxL3j2woeY9r4vDLt2ZHqXqKTFf2ePE2A8bgx";
    }

    function freeMint() external {
        require(totalSupply() < MAX_FREE, "theres no free mints remaining");
        
        safeMint(msg.sender);
    }

    function mint(uint256 _count) external payable {
        require(totalSupply() + _count <= MAX_NFT_SUPPLY, "no more packets to be minted");
        require(_count <= maxPerTx, "can only mint 8 per tx");

        if (_count == 8) {
            require(msg.value >= DISCOUNTEDMAXTX);

            for (uint i = 0; i < _count; i++) {
                safeMint(msg.sender);
            }
        }

        else {
            require(msg.value == PRICE * _count, "ETH sent is incorrect");
            for (uint i = 0; i < _count; i++) {
                safeMint(msg.sender);
            }
        }
    
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

    }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}