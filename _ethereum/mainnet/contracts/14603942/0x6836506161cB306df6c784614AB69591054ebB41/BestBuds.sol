//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";

contract BestBuds is ERC721AQueryable, Ownable {

    uint256 public constant maxSupply = 4200;
    uint256 public tokenPrice = 0.01 ether;
    uint256 public maxTokenPurchase = 10;
    bool public saleIsActive = false;
    bool public hidden = true;
    string public nope = "Nope";
    string public hiddenURI = "ipfs://Qme6AtahdjGkMPwNEWHzwJDYY8aiSMkZRKPaXksdQ6e43S/";
    string public baseURI = "";

    constructor() ERC721A("BestBuds", "BUDS") {}

    function mint(uint256 quantity) external payable {
        require(saleIsActive, nope);
        require(quantity + totalSupply() <= maxSupply, nope);
        require(quantity > 0 && quantity <= maxTokenPurchase, nope);
        require(msg.value >= quantity * tokenPrice, nope);
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), nope);

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        if (hidden) {
            return string(abi.encodePacked(hiddenURI, _toString((tokenId % 10) + 1)));
        } else {
            return string(abi.encodePacked(baseURI, _toString(tokenId)));
        }
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }


    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function flipHidden() external onlyOwner {
        hidden = !hidden;
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setHiddenURI(string memory _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    function setPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }
}