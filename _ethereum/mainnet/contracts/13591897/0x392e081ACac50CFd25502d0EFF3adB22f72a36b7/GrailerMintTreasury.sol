// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IGrailer {
    function mintPublic(uint numberOfTokens) external payable;
    function flipSaleStatus() external;
    function transferOwnership(address newOwner) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function balanceOf(address owner) external returns (uint256);
    function ownerOf(uint256 tokenId) external returns (address);
    function withdraw() external;
}

contract GrailerMintTreasury is Ownable {

    event Buy(
        address indexed owner,
        uint256 numberOfTokens,
        uint256 totalPrice,
        bool grailerOnly
    );

    IGrailer public Grailer;
    address public daoAddress;
    address public nftContract;

    bool public saleIsActive;
    bool public saleIsActiveGrailerOnly;
    uint256 public maxByMint;
    uint256 public fixedPrice;
    uint256 public trancheStart;
    uint256 public trancheEnd;
    uint256 public prevTokenId;

    constructor(address _nftContract) {
        nftContract = _nftContract;
        daoAddress = 0x63fE60e3373De8480eBe56Db5B153baB1A431E38;
        maxByMint = 10;
        fixedPrice = 1.25 ether;
        Grailer = IGrailer(nftContract);
    }

    function mintBatch(uint numberOfBatches, uint batchSize) external payable onlyOwner {
        Grailer.flipSaleStatus();
        for(uint i=1; i<=numberOfBatches; i++) {
            Grailer.mintPublic{ value: msg.value / numberOfBatches }(batchSize);
        }
        Grailer.flipSaleStatus();
    }

    function withdrawNft(uint _start, uint _end) external onlyOwner {
        for(uint i=_start; i <= _end; i++) {
            Grailer.safeTransferFrom(address(this), daoAddress, i);
        }
    }

    function transferNftOwnership(address _address) external onlyOwner {
        Grailer.transferOwnership(_address);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        _withdraw(daoAddress, balance);
    }
 
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx failed");
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function flipSaleStatus() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipSaleGrailerOnlyStatus() external onlyOwner {
        saleIsActiveGrailerOnly = !saleIsActiveGrailerOnly;
    }

    function setFixedPrice(uint256 _fixedPrice) external onlyOwner {
        fixedPrice = _fixedPrice;
    }

    function setMaxByMint(uint256 _maxByMint) external onlyOwner {
        maxByMint = _maxByMint;
    }

    function setTranche(uint256 _trancheStart, uint256 _trancheEnd) external onlyOwner {
        require(
            Grailer.ownerOf(_trancheStart) == address(this) 
            && Grailer.ownerOf(_trancheEnd) == address(this),
            "Not owned"
        );
        trancheStart = _trancheStart;
        trancheEnd = _trancheEnd;
        prevTokenId = _trancheStart-1;
    }

    function buyPublic(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale not active");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        _transfer(numberOfTokens);
        emit Buy(msg.sender, numberOfTokens, msg.value, false);
    }

    function buyGrailerOnly(uint numberOfTokens) external payable {
        require(saleIsActiveGrailerOnly, "Grailer sale not active");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        require(Grailer.balanceOf(msg.sender) > 0, "Must be a Grailer");
        _transfer(numberOfTokens);
        emit Buy(msg.sender, numberOfTokens, msg.value, true);
    }

    function _transfer(uint numberOfTokens) private {
        require(numberOfTokens <= maxByMint, "Max per buy exceeded");
        require(prevTokenId + numberOfTokens <= trancheEnd, "No more available");
        for(uint i = 1; i <= numberOfTokens; i++) {
            Grailer.safeTransferFrom(address(this), msg.sender, prevTokenId + 1);
            prevTokenId = prevTokenId + 1;
        }
    }

    function withdrawFromGrailer() external onlyOwner {
        Grailer.withdraw();
    }

}