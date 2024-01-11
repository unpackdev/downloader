// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Twitchers is ERC721Enumerable, Ownable, ReentrancyGuard {

    uint16 public constant PERCENT_DENOMINATOR = 10000;
    uint16[3] public TOTAL_AMOUNTS = [12566, 1444, 434];

    uint16[2] public discounts = [1000, 2000];
    uint16[3] public allowedToExist;
    uint16[3] public exists;
    uint256[3] public price = [100000000000000000, 1000000000000000000, 3000000000000000000];

    bool public URILocked;
    string private __baseURI;

    event Mint(uint8 rarity, uint16 amount, uint256 totalSupply);
    event Reveal();

    constructor(string memory baseURI_) ERC721("Twitchers", "TWITCHERS") {
        __baseURI = baseURI_;
    }

    function mint(uint8 rarity, uint8 amount) external payable nonReentrant {
        require(rarity < 3, "Wrong rarity specified");
        require((rarity == 0 && (amount == 1 || amount == 3 || amount == 5)) || (rarity > 0 && amount > 0 && amount < 3), "Wrong amount specified");
        require(msg.value == calculatePrice(rarity, amount), "Wrong payment amount");
        exists[rarity] += amount;
        require(exists[rarity] <= allowedToExist[rarity], "Cannot mint more than allowed to exist");
        require(exists[rarity] <= TOTAL_AMOUNTS[rarity], "Collection exhausted");
        for (uint8 i; i < amount; i++) {
            _safeMint(_msgSender(), totalSupply());
        }
        emit Mint(rarity, amount, totalSupply());
    }

    function setPrice(uint256[3] calldata _price) external onlyOwner {
        price = _price;
    }

    function setDiscounts(uint16[2] calldata _discounts) external onlyOwner {
        for (uint8 i; i < 2; i++) {
            require(_discounts[i] <= 10000, "Cannot set discount higher than 100%");
            discounts[i] = _discounts[i];
        }
    }

    function setAllowedToExist(uint16[3] calldata _allowedToExist) external onlyOwner {
        require(_allowedToExist[0] <= TOTAL_AMOUNTS[0] && _allowedToExist[1] <= TOTAL_AMOUNTS[1] && _allowedToExist[2] <= TOTAL_AMOUNTS[2], "Cannot set allowed to exist higher than total amounts");
        allowedToExist = _allowedToExist;
    }

    function reveal() external onlyOwner {
        emit Reveal();
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        require(!URILocked, "URI already locked");
        __baseURI = baseURI_;
    }

    function lockBaseURI() external onlyOwner {
        URILocked = true;
    }

    function getETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function mintAsOwner(uint8 rarity, uint16 amount) external onlyOwner {
        require(rarity < 3, "Wrong rarity specified");
        exists[rarity] += amount;
        require(exists[rarity] <= TOTAL_AMOUNTS[rarity], "Collection exhausted");
        for (uint16 i; i < amount; i++) {
            _safeMint(_msgSender(), totalSupply());
        }
        emit Mint(rarity, amount, totalSupply());
    }

    function calculatePrice(uint8 rarity, uint8 amount) public view returns(uint256) {
        uint256 fullPrice = price[rarity] * amount;
        if (amount == 3) {
            return fullPrice - ((fullPrice * discounts[0]) / PERCENT_DENOMINATOR);
        }
        else if (amount == 5) {
            return fullPrice - ((fullPrice * discounts[1]) / PERCENT_DENOMINATOR);
        }
        return fullPrice;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }
}