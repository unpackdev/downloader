// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ERC721URIStorage.sol";

/// @title Web3ProfilePic
/// @author @0xNeon and Nullpntr
/// @notice Easily create your own NFT!
contract Web3ProfilePic is ERC721URIStorage, Ownable {
    uint256 public tokenCounter;
    uint256 public price;
    string public baseURI;
    address payable public payoutAddress;

    event Minted(address receiver, uint256 tokenCounter);

    modifier hasMintPrice(uint256 givenEther) {
        require(givenEther >= price);
        _;
    }

    constructor(uint256 _price, string memory _base_URI, address _payoutAddress) ERC721("Web3ProfilePic", "W3PFP") {
        price = _price;
        baseURI = _base_URI;
        payoutAddress = payable(_payoutAddress);
    }

    function totalSupply() public view returns (uint256) {
        return tokenCounter;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setPayoutAddress(address newPayoutAddress) public onlyOwner {
        payoutAddress = payable(newPayoutAddress);
    }

    function mint()
        external
        payable
        hasMintPrice(msg.value)
    {
        _safeMint(msg.sender, tokenCounter);
        emit Minted(msg.sender, tokenCounter);
        tokenCounter += 1;
    }

    function withdraw() public {
        uint256 balance = address(this).balance;

        Address.sendValue(payoutAddress, balance);
    }
}
