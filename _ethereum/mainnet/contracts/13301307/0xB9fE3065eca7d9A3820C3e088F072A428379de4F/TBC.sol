// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;


import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract TBC is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;


    uint256 public immutable NFT_PRICE;
    uint public immutable MAX_NFT_PURCHASE;
    uint256 public maxSupply;
    bool public saleIsActive = false;

    string private _baseURIExtended;
    mapping (uint256 => string) _tokenURIs;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 price,
        uint256 maxPurchase,
        uint256 maxSupply_
    )
        ERC721(name_, symbol_)
    {
        NFT_PRICE = price;
        MAX_NFT_PURCHASE = maxPurchase;
        maxSupply = maxSupply_;
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reserveTokens(uint256 num) public onlyOwner {
        uint supply = totalSupply() + 1;
        uint i;
        for (i = 0; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint(uint numberOfTokens) public payable {

        uint256 currentTotal = totalSupply();

        require(saleIsActive, "Sale is not active at the moment");
        require(numberOfTokens > 0, "Number of tokens can not be less than or equal to 0");
        require(currentTotal.add(numberOfTokens) <= maxSupply, "Purchase would exceed max supply");
        require(numberOfTokens <= MAX_NFT_PURCHASE,"Can only mint up to MAX_NFT_PURCHASE per transaction");
        require(NFT_PRICE.mul(numberOfTokens) == msg.value, "Sent ether value is incorrect");

        for (uint i = 1; i < (numberOfTokens + 1); i++) {
            _safeMint(msg.sender, currentTotal + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, (tokenId).toString()));
    }
}