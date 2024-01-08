// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract Hero is Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    
    // Maximum supply of this NFT
    uint16 constant public MAX_SUPPLY = 2**9;

    // Sale price
    uint256 constant public UNIT_PRICE = 0.08 ether;
    
    // Maximum mints per transaction
    uint8 constant public MAX_PER_TX = 10;

    // Where the metadata stored
    string private baseURI;
    
    // Randomness
    uint256 private randomness = 0;

    // Where funds should be sent to
    address payable private fundsTo;

    constructor(string memory _initialBaseURI, address _fundsTo) ERC721("CS: HERO", "H3RO") {
        baseURI = _initialBaseURI;
        fundsTo = payable(_fundsTo);
    }

    function mint(uint8 quantity) public payable {
        uint256 currentId = _tokenIdTracker.current();
        require(currentId < MAX_SUPPLY, "All minted");
        require(quantity > 0, "`amount` cannot be 0");
        require(quantity <= MAX_PER_TX, "Maximum mints per tx exceeded");
        require(currentId + quantity <= MAX_SUPPLY, "Exceeds MAX_SUPPLY");
        require(UNIT_PRICE * quantity <= msg.value, "Incorrect ether value sent");
        
        fundsTo.transfer(msg.value);
        
        for (uint16 i = 0; i < quantity; i++) {
            _mint(msg.sender, ++currentId);
            _tokenIdTracker.increment();
        }
    }
    
    function mint(address to) public onlyOwner {
        uint256 currentId = _tokenIdTracker.current();
        require(currentId < MAX_SUPPLY, "All minted");
        _mint(to, ++currentId);
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view override returns (string memory) {
        if (bytes(baseURI).length == 0) {
            return "";
        } else {
            return baseURI;
        }
    }

    function reveal() public onlyOwner {
        require(randomness == 0, "Already revealed");

        // Cheap source of randomess but should be sufficient in a pragmatic sense
        randomness = uint256(blockhash(block.number - 1)) + block.timestamp;
    }
    
    function _randomness(uint256 tokenId) internal view override returns (uint256) {
        return randomness == 0 ? 0 : (tokenId + randomness) % MAX_SUPPLY + 1;
    }
    
    receive() external payable {}
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        fundsTo.transfer(balance);
    }
}