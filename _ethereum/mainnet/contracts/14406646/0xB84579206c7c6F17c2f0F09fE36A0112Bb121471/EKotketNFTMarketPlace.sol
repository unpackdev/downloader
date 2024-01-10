// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


import "./EKotketNFTPurchaseBase.sol";
import "./EKotketNFTInterface.sol";
import "./EKotketTokenInterface.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract EKotketNFTMarketPlace is EKotketNFTPurchaseBase, ReentrancyGuard{
    using SafeMath for uint256;

    struct SaleItemInfo {
        address owner;    
        uint uKotketTokenPrice;
        uint eWeiPrice;     
    }

    mapping (uint => SaleItemInfo) public saleItemInfoMap;

    uint256 public serviceCommission = 50;


    event ServiceCommissionChanged(uint256 serviceCommission, address setter);
    event ItemForSale(uint256 indexed id, address indexed owner, uint uKotketTokenPrice, uint eWeiPrice);
    event UpdateItemForSale(uint256 indexed id, address indexed owner, uint uKotketTokenPrice, uint eWeiPrice);
    event WithdrawalItemForSale(uint256 indexed id, address indexed owner);
    event ItemSold(uint256 indexed id, address indexed owner, address indexed purchaser, address beneficiary, uint uKotketTokenPrice, uint eWeiPrice);

    constructor(address _governanceAdress) EKotketNFTPurchaseBase(_governanceAdress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function updateServiceCommission(uint256 _serviceCommission) public onlyAdminPermission{
        require(_serviceCommission <= 1000, "Invalid Commission");
        serviceCommission = _serviceCommission;     
        emit ServiceCommissionChanged(serviceCommission, _msgSender());   
    }

    function sendItemForSale( uint256 _tokenId, uint256 _uKotketTokenPrice, uint256 _eWeiPrice) public {
        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        require(kotketNFT.tokenExisted(_tokenId), "Invalid Token Id");
        require(kotketNFT.ownerOf(_tokenId) == _msgSender(), "Not Owner Of Token");
        require(kotketNFT.getApproved(_tokenId) == address(this), "Contract does not have approval from owner");
       
        kotketNFT.safeTransferFrom(_msgSender(), governance.kotketWallet(), _tokenId);
        saleItemInfoMap[_tokenId].owner = _msgSender();
        saleItemInfoMap[_tokenId].uKotketTokenPrice = _uKotketTokenPrice;
        saleItemInfoMap[_tokenId].eWeiPrice = _eWeiPrice;

        emit ItemForSale(_tokenId, _msgSender(), _uKotketTokenPrice, _eWeiPrice);
    }

    function changeItemPrice( uint256 _tokenId, uint256 _uKotketTokenPrice, uint256 _eWeiPrice) public {
        require(saleItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");
       
        saleItemInfoMap[_tokenId].uKotketTokenPrice = _uKotketTokenPrice;
        saleItemInfoMap[_tokenId].eWeiPrice = _eWeiPrice;

        emit UpdateItemForSale(_tokenId, _msgSender(), _uKotketTokenPrice, _eWeiPrice);
    }

    function withdrawalItem( uint256 _tokenId) public {
        require(saleItemInfoMap[_tokenId].owner == _msgSender(), "Not Owner Of Token");
       
        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        require(kotketNFT.isApprovedForAll(governance.kotketWallet(), address(this)), "Contract does not have approval from kotketWallet");
        kotketNFT.safeTransferFrom(governance.kotketWallet(), _msgSender(), _tokenId);

        delete saleItemInfoMap[_tokenId]; 

        emit WithdrawalItemForSale(_tokenId, _msgSender());
    }

    function buyItemWithWei( uint256 _tokenId, address _beneficiary) public nonReentrant payable {
        require(allowedWeiPurchase, "Not allowed wei purchase");

        require(saleItemInfoMap[_tokenId].owner != address(0), "Invalid Token Id");

        uint256 weiAmount = msg.value;
        uint256 price = saleItemInfoMap[_tokenId].eWeiPrice;

        require(weiAmount >= price, "insufficient wei amount");

        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        require(kotketNFT.isApprovedForAll(governance.kotketWallet(), address(this)), "Contract does not have approval from kotketWallet");
        kotketNFT.safeTransferFrom(governance.kotketWallet(), _beneficiary, _tokenId);

        uint256 commissioFee = price.mul(serviceCommission).div(1000);
        
        uint256 ownerAmountReceive = price - commissioFee;
        uint256 marketAmountReceive = weiAmount - ownerAmountReceive;

        _forwardWeiFunds(saleItemInfoMap[_tokenId].owner, ownerAmountReceive);
        _forwardWeiFunds(governance.kotketWallet(), marketAmountReceive);

        delete saleItemInfoMap[_tokenId]; 

        emit ItemSold(_tokenId, saleItemInfoMap[_tokenId].owner, _msgSender(), _beneficiary, 0, weiAmount);
    }

    function _forwardWeiFunds(address _beneficiary, uint256 amount) internal virtual{
        address payable beneficiary = payable(_beneficiary);
        beneficiary.transfer(amount);
    }

    function buyItemWithKotketToken( uint256 _tokenId, address _beneficiary) public{
        require(allowedKotketTokenPurchase, "Not allowed kotket token purchase");

        require(saleItemInfoMap[_tokenId].owner != address(0), "Invalid Token Id");

        uint256 price = saleItemInfoMap[_tokenId].uKotketTokenPrice;

        EKotketTokenInterface kotketToken = EKotketTokenInterface(governance.kotketTokenAddress());
        require(kotketToken.balanceOf(_msgSender()) >= price, "Insufficient June Token Balance!");

        uint256 tokenAllowance = kotketToken.allowance(_msgSender(), address(this));
        require(tokenAllowance >= price, "Not Allow Enough Kotket Token To Buy NFT");

       
        EKotketNFTInterface kotketNFT = EKotketNFTInterface(governance.kotketNFTAddress());
        require(kotketNFT.isApprovedForAll(governance.kotketWallet(), address(this)), "Contract does not have approval from kotketWallet");
        kotketNFT.safeTransferFrom(governance.kotketWallet(), _beneficiary, _tokenId);

        uint256 commissionFee = price.mul(serviceCommission).div(1000);
        uint256 ownerAmountReceive = price - commissionFee;

        kotketToken.transferFrom(_msgSender(), governance.kotketWallet(), commissionFee);
        kotketToken.transferFrom(_msgSender(), saleItemInfoMap[_tokenId].owner, ownerAmountReceive);


        delete saleItemInfoMap[_tokenId]; 

        emit ItemSold(_tokenId, saleItemInfoMap[_tokenId].owner, _msgSender(), _beneficiary, price, 0);

    }


    receive() external payable {}
}