// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract DeezKnots is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    string baseTokenURI;
    uint256 public constant MAX_NFTS = 50;
    uint256 public constant MAX_PER_MINT = 1;
    uint256 public constant PRICE_PUBLIC_SALE = 100000000000000000; // 0.1 Ether
    address public constant projectAddress = 0x1bf8404DbD26EBbf28Ba44A0cD993a9Aa1eFE363;

    uint256 private pricePublicSale = PRICE_PUBLIC_SALE;
    // public access to nfts minted
    uint256 private numNftsMinted;

    // store addresses of owners
    mapping(address => uint256) private _totalClaimed;
    event Minted(uint256 totalMinted);
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("DeezKnots", "DK") {}


    modifier ifNotSoldOut() {
        require(
            totalSupply() + 1 <= MAX_NFTS,
            "Transaction will exceed maximum supply of Knots"
        );
        _;
    }


    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function totalSupply() public view returns (uint256) {
        return numNftsMinted;
    }


    function safeMint(address recipient, string memory uri) 
        external 
        payable
        ifNotSoldOut() 
    {
        // require(totalSupply() < MAX_NFTS, "All Knots Have Been Minted");
        require(msg.value >= PRICE_PUBLIC_SALE, "Not Enough ETH");
        _tokenIdCounter.increment();

        uint256 tokenId = _tokenIdCounter.current();
        numNftsMinted = _tokenIdCounter.current(); 

        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);
        emit Minted(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        _widthdraw(projectAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }
}