// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


import "./Ownable.sol";
import "./ERC1155.sol";
import "./Strings.sol";
import "./ERC1155Supply.sol";


contract TheIssueOf is Ownable, ERC1155Supply {
    using Strings for uint256;

    uint256 public constant TOTAL_SUPPLY = 1991; // Total amount of Hearts
    uint256 public constant PRICE = 0.03 ether;

    string private _baseTokenURI;

    constructor() ERC1155("") {}

    function mint(uint256 quantity)
        external
        payable
    {
        require(totalSupply(0) < TOTAL_SUPPLY, "SOLD_OUT");
        require(totalSupply(0) + quantity <= TOTAL_SUPPLY, "EXCEEDS_TOTAL_SUPPLY");
        require(PRICE * quantity == msg.value, "INVALID_ETH_AMOUNT");

        _mint(msg.sender, 0, quantity, "");
    }

    function setUri(string memory _newUri) external onlyOwner {
        _baseTokenURI = _newUri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    function withdraw() external onlyOwner {
        payable(0xEB134951Cae708a4EafBb5AE0C9bB7200b924b13).transfer(address(this).balance);
    }
}