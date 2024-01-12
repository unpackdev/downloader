// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

contract BullzShiet is ERC721A, Ownable, ReentrancyGuard {

    bool public minting = false;
    string public uri = "";
    uint256 public maxTotalSupply = 7000;
    uint256 public walletLimit = 5;
    mapping(address => uint256) public minted;

    constructor () ERC721A("CopeBullzOfficial", "CBO") {}

    function mint(uint256 _quantity) public payable {
        require(minting, "Mint Is Not Live.");
        require(_quantity > 0, "Must Mint Atleast One.");
        require(totalSupply() + _quantity <= maxTotalSupply, "Sold Out!");
        require(minted[msg.sender] + _quantity <= walletLimit, "Wallet Limit Reached.");
        minted[msg.sender] += _quantity;
        _safeMint(_msgSender(), _quantity);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function setUri(string memory _newUri) public onlyOwner {
        uri = _newUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMint(bool _status) public onlyOwner {
        minting = _status;
    }

    function setWalletLimit(uint256 _newLimit) public onlyOwner {
        walletLimit = _newLimit;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token unavailable.");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI,  _toString(tokenId), ".json"))
            : '';
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, "Withdraw Failed");
    }
}