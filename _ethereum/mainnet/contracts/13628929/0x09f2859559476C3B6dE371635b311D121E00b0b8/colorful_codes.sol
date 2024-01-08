// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ColorfulCodes is ERC721, ERC721Enumerable, Ownable {
    uint256 public constant NFT_PRICE = 0.04 ether;
    uint public constant MAX_NFT_PURCHASE = 10;
    uint256 public constant MAX_SUPPLY = 1337;
    bool public saleIsActive = false;
    bool public isMetadataLocked = false;

    string private _baseURIExtended;

    constructor() ERC721("colorful.codes","CODES") {}

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function lockMetadata() public onlyOwner {
        isMetadataLocked = true;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "SALE_NOT_STARTED");
        require(numberOfTokens > 0, "INVALID_TOKEN_AMOUNT");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "SUPPLY_EXCEEDED");
        require(numberOfTokens <= MAX_NFT_PURCHASE,"MAX_TOKEN_AMOUNT_EXCEEDED");
        require(msg.value >= NFT_PRICE * numberOfTokens, "PRICE_NOT_MET");

        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function mintOwner(address destination) public onlyOwner {
        require(totalSupply() + 1 <= MAX_SUPPLY, "SUPPLY_EXCEEDED");

        _safeMint(destination, totalSupply());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        require(!isMetadataLocked,"Metadata is locked");
        _baseURIExtended = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();

        if (bytes(base).length == 0) {
            return Strings.toString(tokenId);
        }

        return string(abi.encodePacked(base, Strings.toString(tokenId), '.json'));
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
