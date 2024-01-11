// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "BeerCoinOrigContract.sol";
import "BeerCoinHolder.sol";


contract BCTest is ERC721, ERC721Enumerable, Ownable {

    event Wrapped(uint256 indexed pairId, address indexed owner);
    event Unwrapped(uint256 indexed pairId, address indexed owner);

    BeerCoinOrigContract bcContract = BeerCoinOrigContract(0x74C1E4b8caE59269ec1D85D3D4F324396048F4ac);

    uint256 constant numPairs = 2;
    struct bcPair {
        address debtor;
        address creditor;
        uint256 numBeers;
        address holderAddr;
        bool wrapped;
    }
    mapping(uint256 => bcPair) public pairs;
    mapping(address => mapping(address => uint256)) public indexes;
    
    constructor() ERC721("BCTest", "BCT") {

        // set up list of debtor-creditor pairs   
        pairs[1] = bcPair(0x790A7eB0F1A96A05E7d492CeB373552e1b7eAa15, 0x46261e6C61B29fb62b1ddBD6FB496797F5E6f801, 1, address(0), false);
        pairs[2] = bcPair(0xb8E0198e1886C60266115830DDBfbA6308535a1E, 0xFC49E32CBD9f4E8d5C9846Bf252954d3A9b8558A, 7, address(0), false);                  
        
        // establish mapping from debtor-creditor pair to ID
        for (uint256 i = 1; i <= numPairs; i++) {
            indexes[pairs[i].debtor][pairs[i].creditor] = i;
        }
    }

    function Wrap(address debtor) public {
        uint256 pairId = indexes[debtor][msg.sender];  

        require(pairId != 0, "Invalid debtor-creditor pair.");
        require(!_exists(pairId), "Token already exists.");

        bcPair storage pair = pairs[pairId]; 
 
        require(!pair.wrapped, "Cannot wrap more than once.");        
        require(bcContract.allowance(msg.sender, address(this)) >= pair.numBeers, "You did not give wrapper transfer permission.");
        require(bcContract.balanceOf(msg.sender, debtor) >= pair.numBeers, "Original IOU no longer exists.");
        
        // create holder for the IOU
        BeerCoinHolder bcHolder = new BeerCoinHolder(address(this), pair.numBeers);
        pair.holderAddr = address(bcHolder);

        require(bcContract.allowance(pair.holderAddr, address(this)) >= pair.numBeers, "Holder did not give wrapper transfer permission.");
        require(bcContract.maximumCredit(pair.holderAddr) >= pair.numBeers, "Holder does not have enough credit.");
        
        // transfer IOU to the holder
        if (bcContract.transferOtherFrom(msg.sender, pair.holderAddr, debtor, pair.numBeers)) {
            _mint(msg.sender, pairId);
            pairs[pairId].wrapped = true;
            emit Wrapped(pairId, msg.sender);
        }
    }

    function Unwrap(uint256 pairId) public {
        require(_exists(pairId), "Token does not exist.");
        require(msg.sender == ownerOf(pairId), "You are not the owner.");
        
        bcPair storage pair = pairs[pairId];

        require(bcContract.maximumCredit(msg.sender) >= pair.numBeers, "You do not have enough credit.");
        
        // transfer IOU from the holder
        if (bcContract.transferOtherFrom(pair.holderAddr, msg.sender, pair.debtor, pair.numBeers)) {
            _burn(pairId);
            emit Unwrapped(pairId, msg.sender);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://spaces.beerious.io/";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}