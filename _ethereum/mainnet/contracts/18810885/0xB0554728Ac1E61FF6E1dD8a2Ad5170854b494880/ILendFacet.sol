// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ILendFacet{
     enum CollateralNftType{
         UnUsed,
         UniswapV3
     }

     struct PutOrder{
        uint256 orderId;
        address lender;
        address borrower;
        address recipient;
        /**
          if collateralAssetType==0  collateralAsset is Token
          if collateralAssetType==1  collateralAsset  is nft
         */
        address collateralAsset;
        /**
          if collateralAssetType==0  collateralAmount is Token amount
          if collateralAssetType==1  collateralAsset  is liquidity
         */
        uint256 collateralAmount;
        address borrowAsset;
        uint256 borrowMinAmount;
        uint256 borrowAmount;
        uint256 expirationDate;
        uint256 platformFee;
        uint256 index;
        uint256 collateralAssetType;
        uint256 collateralNftId;
    }
    struct CallOrder{
        uint256 orderId;
        address borrower;
        address lender;
        address recipient;
        address collateralAsset;
        uint256 collateralAmount;     
        address borrowAsset;
        uint256 borrowNowAmount;
        uint256 borrowNowMinAmount;
        uint256 interestAmount;
        uint256 borrowLaterMinAmount;
        uint256 borrowLaterAmount;
        uint256 expirationDate;
        uint256 platformFee;
        uint256 index; 
        uint256 collateralAssetType;
        uint256 collateralNftId;
    }
    event SetCollateralNft(address _nft,CollateralNftType _type);
    event SetLendFeePlatformRecipient(address _recipient);
    event SetDomainHash(bytes32 _domainHash);
    function setBorrowerPutOrder(address _borrower,PutOrder memory _putOrder) external;
    function deleteBorrowerPutOrder(address _borrower) external;
    function getBorrowerPutOrder(address _borrower) external view returns(PutOrder memory);

    function setLenderPutOrder(address _lender,address _borrower) external;
    function getLenderPutOrder(address _lender) external view returns(address[] memory);
    function getLenderPutOrderLength(address _lender) external view returns(uint256);
    function deleteLenderPutOrder(address _lender,uint256 _index) external;
    function setBorrowerPutOrderNftInfo(address _borrower,uint256 _collateralNftId,uint256 _newLiquidity) external;
    //----
    function setDomainHash(bytes32 _domainHash) external;
    function getDomainHash() external view returns(bytes32);
    function setLendFeePlatformRecipient(address _lendFeePlatformRecipient) external;
    function getLendFeePlatformRecipient() external view returns(address);
    //-----
    function setLenderCallOrder(address _lender,CallOrder memory _callOrder) external;
    function deleteLenderCallOrder(address _lender) external;
    function getLenderCallOrder(address _lender) external view returns(CallOrder memory);
    function setBorrowerCallOrder(address _borrower,address _lender) external;
    function getBorrowerCallOrderLength(address _borrower) external view returns(uint256);
    function getBorrowerCallOrder(address _borrower) external view returns(address[] memory);
    function deleteLenderCallOrder(address _borrower,uint256 _index) external;
    function setLenderCallOrderNftInfo(address _lender,uint256 _collateralNftId,uint256 _newLiquidity) external;
    //----
    function setCollateralNft(address _nft,CollateralNftType _type) external;
    function getCollateralNft(address _nft) external view returns(CollateralNftType);
}