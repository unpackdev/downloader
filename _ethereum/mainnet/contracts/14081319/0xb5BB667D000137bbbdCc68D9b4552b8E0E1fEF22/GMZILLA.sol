// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";


contract GMZILLA is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint public constant TOTAL_SUPPLY = 10000;
    uint public constant GMZILLAPERTX = 10;
    uint public constant PREMINT = 350;
    uint public constant SALE_OPEN = 1643223599; //26th JAN 7pm UTC

    uint public premintCounter = 0;
    uint public price =  0.05 ether;

    string public baseURI;

    event Withdraw(address _to, uint256 _withdrawalAmount);
    event SetBaseURI(string);

    constructor() ERC721("GMZILLA", "GMZ") {}
    function preMint(uint countOf) public onlyOwner{
        
        for(uint i = 0; i < countOf; i++) {
           uint256 tokenId = _tokenIdCounter.current();
           
           require(premintCounter < PREMINT, "Exceeded Premint");
           require(tokenId < TOTAL_SUPPLY, "Exceed supply");

           _safeMint(msg.sender, tokenId);
           premintCounter++;
           _tokenIdCounter.increment();
        }
    }


    function safeMint(uint amountOfGmzillas) payable public {
        require(block.timestamp >= SALE_OPEN, "Sale is not open");
        require(amountOfGmzillas <= GMZILLAPERTX, "Max mint exceeded!");
        require(msg.value >= amountOfGmzillas * price, "Not enough fees");
        
        for(uint i = 0; i < amountOfGmzillas; i++) {
           uint256 tokenId = _tokenIdCounter.current();
           require(tokenId < TOTAL_SUPPLY, "Exceed supply");
           _safeMint(msg.sender, tokenId);
           _tokenIdCounter.increment();
        }
        
        uint changes = msg.value - amountOfGmzillas * price;
        if(changes > 0){
            payable(msg.sender).transfer(changes);
        }
    }

    function withdraw(address payable _to, uint256 _withdrawalAmount) external onlyOwner {
        require(_to != address(0), "receiver can not be empty address");

        emit Withdraw(_to, _withdrawalAmount);
        _to.transfer(_withdrawalAmount);
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
        emit SetBaseURI(__baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
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