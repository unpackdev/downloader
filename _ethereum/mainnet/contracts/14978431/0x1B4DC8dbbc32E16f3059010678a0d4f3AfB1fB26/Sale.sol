// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./OwnerOrAdmin.sol";
import "./IWeedWarsERC721.sol";

contract Sale is OwnerOrAdmin {

    IWeedWarsERC721 public warriorsERC721;
    IWeedWarsERC721 public synthsERC721;

    uint8 public maxMintCountPerTx = 5;

    // private sale

    mapping(address => bool) public winners;
    uint8 public maxPrivateSaleMintCount = 3;
    mapping(address => uint8) public privateSaleMintCount;
    uint public privateSalePrice = 0.1 ether;
    bool public isPrivateSaleOpen;

    //public sale

    uint public publicSalePrice = 0.2 ether;
    bool public isPublicSaleOpen;

    // constructor

    constructor(address warriorsERC721_, address synthsERC721_, bool _isPrivateSaleOpen, bool _isPublicSaleOpen) {
        warriorsERC721 = IWeedWarsERC721(warriorsERC721_);
        synthsERC721 = IWeedWarsERC721(synthsERC721_);
        isPrivateSaleOpen = _isPrivateSaleOpen;
        isPublicSaleOpen = _isPublicSaleOpen;
    }

    // modifiers

    modifier privateMint(uint256 _claimQty) {
        (bool canMintPrivate, uint8 count) = getPrivateMintInfo();
        require(canMintPrivate, "Sale: can't mint private");
        require(_claimQty <= count, "Sale: can't mint that match");
        require(msg.value >= privateSalePrice * _claimQty, "Sale: not enough funds sent" );
        _;
        privateSaleMintCount[msg.sender] = uint8(privateSaleMintCount[msg.sender] + _claimQty);
    }

    modifier publicMint(uint256 _claimQty) {
        require(isPublicSaleOpen, "Sale: public sale is not open");
        require(_claimQty <= maxMintCountPerTx, "Sale: can't mint that match");
        require(msg.value >= publicSalePrice * _claimQty, "Sale: not enough funds sent");
        _;
    }

    // only owner

    function addWinners(address[] memory _users, bool _enabled) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _users.length; i++) {
            winners[_users[i]] = _enabled;
        }
    }

    function setSaleOpen(bool _isPrivateSaleOpen, bool _isPublicSaleOpen) external onlyOwnerOrAdmin {
        isPrivateSaleOpen = _isPrivateSaleOpen;
        isPublicSaleOpen = _isPublicSaleOpen;
    }

    function setSalePrice(uint256 _privateSalePrice, uint256 _publicSalePrice) external onlyOwnerOrAdmin {
        privateSalePrice = _privateSalePrice;
        publicSalePrice = _publicSalePrice;
    }

    function setMintRestrictions(uint8 _maxMintCountPerTx, uint8 _maxPrivateSaleMintCount) external onlyOwnerOrAdmin {
        require(_maxPrivateSaleMintCount <= _maxMintCountPerTx);
        maxMintCountPerTx = _maxMintCountPerTx;
        maxPrivateSaleMintCount = _maxPrivateSaleMintCount;
    }

    function withdraw(address _receiver) external onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }

    // user

    function getPrivateMintInfo() public view returns (bool canMintPrivate_, uint8 count_) {
        if (winners[msg.sender] == true) {
            uint8 minted = privateSaleMintCount[msg.sender];
            if (minted >= maxPrivateSaleMintCount) {
                count_ = 0;
            } else {
                count_ =  maxPrivateSaleMintCount - privateSaleMintCount[msg.sender];
            }
        }
        if (isPrivateSaleOpen) {
            canMintPrivate_ = true;
        }
        if (count_ == 0) {
            canMintPrivate_ = false;
        }
    }

    function mintWarriorPrivate(uint256 _claimQty) external payable privateMint(_claimQty) {
        warriorsERC721.mint(_claimQty, msg.sender);
    }

    function mintSynthPrivate(uint256 _claimQty) external payable privateMint(_claimQty) {
        synthsERC721.mint(_claimQty, msg.sender);
    }

    function mintWarriorPublic(uint256 _claimQty) external payable publicMint(_claimQty) {
        warriorsERC721.mint(_claimQty, msg.sender);
    }

    function mintSynthPublic(uint256 _claimQty) external payable publicMint(_claimQty) {
        synthsERC721.mint(_claimQty, msg.sender);
    }
}
