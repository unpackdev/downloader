// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract weSHIBA is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 555;
    uint256 public MAX_PUBLIC_MINT = 5;
    uint256 public SALE_PRICE = .002 ether;
    bool public mintStarted = false;

    string public baseURI = "ipfs://QmNjzBhUzZoP7rDoKQsW6JKyameXW7xveNneGkYCwqGtRR/";
    mapping(address => uint256) public walletMintCount;

    constructor() ERC721A("weSHIBA", "WS") {}

    function mint(uint256 _quantity) external payable {
        require(mintStarted, "Minting is not live yet.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Beyond max supply."
        );
        require(
            (walletMintCount[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,
            "Wrong mint amount."
        );
        require(msg.value >= (SALE_PRICE * _quantity), "Wrong mint price.");

        walletMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 mintAmount) external onlyOwner {
        _safeMint(msg.sender, mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function saleStateToggle() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        SALE_PRICE = _newPrice;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}
