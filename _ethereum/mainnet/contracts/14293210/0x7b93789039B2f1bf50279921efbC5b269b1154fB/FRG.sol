// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract FRG is ERC721Enumerable, Pausable, Ownable {

    string private __baseURI;
    bool public URILocked;

    bool public whitelistEnabled;
    mapping (address => bool) public whitelist;

    uint256 public allowedToExist;
    uint256 private _price = 80000000000000000;

    constructor(string memory baseURI_) ERC721("Fatal Racing Garage", "FRG") {
        __baseURI = baseURI_;
    }

    function addToWhitelist(address[] calldata _accounts) external onlyOwner {
        for (uint256 i; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata _accounts) external onlyOwner {
        for (uint256 i; i < _accounts.length; i++) {
            whitelist[_accounts[i]] = false;
        }
    }

    function enableWhitelist() external onlyOwner {
        whitelistEnabled = true;
    }

    function disableWhitelist() external onlyOwner {
        whitelistEnabled = false;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPrice(uint256 price_) external onlyOwner {
        _price = price_;
    }

    function setAllowedToExist(uint256 amount) external onlyOwner {
        allowedToExist = amount;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        require(!URILocked, "URI already locked");
        __baseURI = baseURI_;
    }

    function lockBaseURI() external onlyOwner {
        URILocked = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function getETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function mintAsOwner(address[] calldata accounts) external onlyOwner {
        require(totalSupply() + accounts.length <= 100000, "Cannot mint this much");
        for (uint256 i; i < accounts.length; i++) {
            _safeMint(accounts[i], totalSupply());
        }
    }

    function buy(uint256 amount) external payable whenNotPaused {
        require(!whitelistEnabled || whitelist[_msgSender()], "Not whitelisted");
        uint256 toExist = totalSupply() + amount;
        require((toExist <= allowedToExist) && (toExist <= 100000), "Cannot buy this much");
        require(msg.value >= price() * amount, "Invalid payment amount");
        uint256 toReturn = (msg.value - (price() * amount));
        for (amount; amount > 0; amount--) {
            _safeMint(_msgSender(), totalSupply());
        }
        if (toReturn > 0) {
            payable(_msgSender()).transfer(toReturn);
        }
    }

    function price() public view returns(uint256) {
        return _price;
    }


}


