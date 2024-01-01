// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ILendFacet{
     struct LendInfo{
        uint256 orderId;
        address loaner;
        address debtor;
        address recipient;
        address collateralAsset;
        uint256 collateralAmount;
        address borrowAsset;
        uint256 borrowMinAmount;
        uint256 borrowAmount;
        uint256 maturity;
        uint256 platformFee;
        uint256 index;
    }

    struct StakeInfo{
        uint256 orderId;
        address borrower;
        address lender;
        address recipient;
        address borrowAsset;
        uint256 borrowAmount;
        address lendAsset;
        uint256 payNowAmount;
        uint256 payNowMinAmount;
        uint256 interestAmount;
        uint256 payLaterMinAmount;
        uint256 payLaterAmount;
        uint256 maturity;
        uint256 platformFee;
        uint256 index; 
    }

    event SetCollateralNft(address _nft,bool _type);

    function setDebtorLendInfo(address _debtor,LendInfo memory _lendInfo) external;
    function deleteDebtorLendInfo(address _debtor) external;
    function getDebtorLendInfo(address _debtor) external view returns(LendInfo memory);

    function setLoanerLendInfo(address _loaner,address _debtor) external;
    function getLoanerLendInfo(address _loaner) external view returns(address[] memory);
    function getLoanerLendInfoLength(address _loaner) external view returns(uint256);
    function deleteLoanerLendInfo(address _loaner,uint256 _index) external;


    function setDomainHash(bytes32 _domainHash) external;
    function getDomainHash() external view returns(bytes32);
    function setLendFeePlatformRecipient(address _lendFeePlatformRecipient) external;
    function getLendFeePlatformRecipient() external view returns(address);

    //-----
    function setBorrowerStakeInfo(address _borrower,StakeInfo memory _stakeInfo) external;
    function deleteBorrowerStakeInfo(address _borrower) external;
    function getBorrowerStakeInfo(address _borrower) external view returns(StakeInfo memory);
    function setLenderStakeInfo(address _lender,address _borrower) external;
    function getBorrowers(address _lender) external view returns(address[] memory);
    function getBorrowersLength(address _lender) external view returns(uint256);
    function deleteBorrowerStakeInfo(address _lender,uint256 _index) external;
}