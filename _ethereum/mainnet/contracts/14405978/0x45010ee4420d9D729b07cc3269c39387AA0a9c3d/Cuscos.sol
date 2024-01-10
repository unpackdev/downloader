// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "ERC721Enumerable.sol";

contract Cuscos is ERC721, ERC721Enumerable, Ownable {
    bool public saleIsActive = false;

    uint256 public currentLimit = 150;
    uint256 public currentPrice = 1 ether;
    uint256 public currentPerUserMax = 2;

    uint256 public constant MAX_SUPPLY = 7500;

    address[] private _purchasers;
    mapping(address => bool) private _addedToPurchasers;
    mapping(address => uint256) private _purchasedDuringStage;

    string private _baseURIextended;

    constructor() ERC721("Cuscos", "CUSCO") {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + n <= MAX_SUPPLY, "Can't reserve more than max");

        uint256 i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setSaleIsActive(bool _saleIsActive) external onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function setCurrentLimit(uint256 _currentLimit) external onlyOwner {
        require(_currentLimit <= MAX_SUPPLY, "Limit must be less than max");
        currentLimit = _currentLimit;
    }

    function setCurrentPrice(uint256 _currentPrice) external onlyOwner {
        currentPrice = _currentPrice;
    }

    function setCurrentPerUserMax(uint256 _currentPerUserMax)
        external
        onlyOwner
    {
        currentPerUserMax = _currentPerUserMax;
    }

    function resetPurchased() external onlyOwner {
        for (uint256 i = 0; i < _purchasers.length; i++) {
            delete _purchasedDuringStage[_purchasers[i]];
            delete _addedToPurchasers[_purchasers[i]];
        }
        delete _purchasers;
    }

    // This is a backup in case _purchasers gets too long to iterate over.
    // After calling this, resetPurchased() must also be called.
    function backupResetPurchased(uint256 _resetNumber) external onlyOwner {
        for (uint256 i = 0; i < _resetNumber; i++) {
            delete _purchasedDuringStage[_purchasers[i]];
            delete _addedToPurchasers[_purchasers[i]];
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(
            numberOfTokens + _purchasedDuringStage[msg.sender] <=
                currentPerUserMax,
            "Exceeded maximum per user"
        );
        require(
            ts + numberOfTokens <= currentLimit,
            "Purchase would exceed limit"
        );
        require(
            currentPrice * numberOfTokens <= msg.value,
            "Ether value sent is incorrect"
        );

        _purchasedDuringStage[msg.sender] += numberOfTokens;
        if (!_addedToPurchasers[msg.sender]) {
            _purchasers.push(msg.sender);
            _addedToPurchasers[msg.sender] = true;
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
