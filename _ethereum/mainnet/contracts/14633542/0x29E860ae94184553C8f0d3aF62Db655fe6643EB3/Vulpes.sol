//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract Vulpes is ERC721A, Ownable {
    // ====== Variables ======
    string private baseURI;
    uint256 private MAX_SUPPLY = 5000;
    bool public mintActive = false;
    uint256 public mintLimit = 10;
    uint256 public mintPrice = 0.1 ether;
    uint256 public discount = 0.01 ether;
    mapping(address => bool) public allowList;
    bool public reveal = false;
    bool public publicMint = false;

    constructor() ERC721A("Vulpes", "VULPES") {
    }

    // ====== Basic Setup ======
    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setReveal() external onlyOwner {
        reveal = true;
    }

    // ====== Mint Settings ======
    function setMintStatus(bool _status) external onlyOwner {
        mintActive = _status;
    }

     function setMintLimit(uint256 _limit) external onlyOwner {
        mintLimit = _limit;
    }

     function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setToPublicMint(bool _status) external onlyOwner {
        publicMint = _status;
    }

    // ====== Allow List Settings ======
    function modifyAllowList(address[] calldata _addresses, bool allowType) external onlyOwner {
        require(_addresses.length <= 5000, "Too many addresses called.");
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowList[_addresses[i]] = allowType; // allowType = true / false
        }
    }

    // ====== Minting ======
    function isAllowedToMint (address _address) public view returns (bool) {
        if (publicMint) {
            return true;
        }

        if (allowList[_address]) {
            return true;
        }
        return false;
    }

    function checkPrice (uint256 _value, uint256 _quantity) public view returns (bool) {
        uint256 requiredPrice = mintPrice * _quantity;
        uint256 discountPrice = 0;
        // *** With Discount -  n ( n + 1 ) / 2 is the formula ***
        if (_quantity >= 2) {
            discountPrice = (((_quantity - 1) * (_quantity - 1 + 1)) / 2) * discount;
        }

        if (_value >= (requiredPrice - discountPrice)) {
            return true;
        }
    
        return false;
    }

    function mint (uint256 _quantity) external payable {
        // *** Checking conditions ***
        require(mintActive, "Minting is not active yet.");
        (bool isInAllowList) = isAllowedToMint(msg.sender);
        require(isInAllowList, "Not allow to mint.");
        require(_quantity <= mintLimit, "Reach maximum minting limit.");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reach maximum supply.");
        (bool isPriceEnough) = checkPrice(msg.value, _quantity);
        require(isPriceEnough, "Not enough ETH to mint.");
        
        // *** _safeMint's second argument now takes in a quality but not tokenID ***
        _safeMint(msg.sender, _quantity);
    }

    function ownerMint (uint256 _quantity) external payable onlyOwner {
        // *** Checking conditions ***
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reach maximum supply.");
        
        // *** _safeMint's second argument now takes in a quality but not tokenID ***
        _safeMint(msg.sender, _quantity);
    }

    // ====== Token URI ======
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token ID is not exist.");
        if (!reveal) {
            return string(abi.encodePacked(baseURI, "box"));
        }
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    // ====== Withdraw ======
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw fail.");
    }
}
