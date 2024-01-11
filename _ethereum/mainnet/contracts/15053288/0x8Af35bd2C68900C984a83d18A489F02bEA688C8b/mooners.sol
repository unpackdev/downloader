// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

error HadClaimed();
error OutofMaxSupply();

contract mooners is ERC721A, Ownable {
    using Strings for uint256;

    mapping(address => bool) public claimed;

    bool freeMintActive = false;

    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public cost = 0.009 ether;

    string public baseUrl = "ipfs://QmebyvK9dRNDqn7EwTWQQ36ghYLeQhWTk5Gs77tNfuQwp6";

    constructor() ERC721A("mooners", "moon") {}

    function freeMint(uint256 _amount) external payable {
        require(freeMintActive, "Free mint closed");
        if(totalSupply() + _amount > MAX_SUPPLY) revert OutofMaxSupply();
    
        if(claimed[msg.sender]) {
            require(msg.value >= _amount * cost, "Insufficient funds");
        } else {
            require(msg.value >= (_amount - 1) * cost, "Insufficient funds");
        }

        claimed[msg.sender] = true;
        _safeMint(msg.sender, _amount);
    }

    function revive() external payable {
        require(!freeMintActive, "Free mint is open");
        require(msg.value >= cost, "Insufficient funds");
        if(totalSupply() + 1 > MAX_SUPPLY) revert OutofMaxSupply();
        _safeMint(msg.sender, 1);
    }
    
    function ownerBatchMint(uint256 amount) external onlyOwner {
        if(totalSupply() + amount > MAX_SUPPLY) revert OutofMaxSupply();
        _safeMint(msg.sender, amount);
    }

    function batchBurn(uint256[] memory tokenids) external onlyOwner {
        uint256 len = tokenids.length;
        for (uint256 i; i < len; i++) {
            _burn(tokenids[i]);
        }
    }

    function toggleFreeMint(bool _state) external onlyOwner {
        freeMintActive = _state;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function setBaseURI(string memory url) external onlyOwner {
        baseUrl = url;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : '';
    }

   function _baseURI() internal view virtual override returns (string memory) {
        return baseUrl;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}