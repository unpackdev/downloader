// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ILendFacet.sol";

contract LendFacet is ILendFacet{
     bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.LendFacet.diamond.storage");
     struct Lend{
        mapping(address =>LendInfo)  debtorLendInfos;
        mapping(address =>address[])   loanerLendInfos;
        bytes32  domainHash;
        address  lendFeePlatformRecipient;
        mapping(address => StakeInfo)  borrowerStakeInfos;
        mapping(address => address[])  lenderStakeInfos;
     }

      function diamondStorage() internal pure returns (Lend storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
      }
      

      function setDebtorLendInfo(address _debtor,LendInfo memory _lendInfo) external {
         Lend storage ds = diamondStorage();  
         ds.debtorLendInfos[_debtor]=_lendInfo;
      }

      function deleteDebtorLendInfo(address _debtor) external {
         Lend storage ds = diamondStorage();
         delete ds.debtorLendInfos[_debtor];
      }

      function getDebtorLendInfo(address _debtor) external view returns(LendInfo memory){
          Lend storage ds = diamondStorage();  
          return ds.debtorLendInfos[_debtor];
      }


      function setLoanerLendInfo(address _loaner,address _debtor) external{
           Lend storage ds = diamondStorage();  
           ds.loanerLendInfos[_loaner].push(_debtor);
      }

      function getLoanerLendInfo(address _loaner) external view returns(address[] memory){
            Lend storage ds = diamondStorage();  
            return ds.loanerLendInfos[_loaner];
      }

      function getLoanerLendInfoLength(address _loaner) external view returns(uint256){
          Lend storage ds = diamondStorage();  
          return ds.loanerLendInfos[_loaner].length;         
      }

      function deleteLoanerLendInfo(address _loaner,uint256 _index) external {
           Lend storage ds = diamondStorage();  
           uint256 lastIndex=ds.loanerLendInfos[_loaner].length-1;
           if(lastIndex != _index){
            address lastAddr=ds.loanerLendInfos[_loaner][lastIndex];
            ds.debtorLendInfos[lastAddr].index=_index;
            ds.loanerLendInfos[_loaner][_index]=lastAddr;
           }
           ds.loanerLendInfos[_loaner].pop();
      }
      //-----
      function setDomainHash(bytes32 _domainHash) external {
          Lend storage ds = diamondStorage();  
          ds.domainHash=_domainHash;
      }

      function getDomainHash() external view returns(bytes32){
           Lend storage ds = diamondStorage(); 
           return  ds.domainHash;
      }

      function setLendFeePlatformRecipient(address _lendFeePlatformRecipient) external {
           Lend storage ds = diamondStorage(); 
           ds.lendFeePlatformRecipient=_lendFeePlatformRecipient;
      }

      function getLendFeePlatformRecipient() external view returns(address){
           Lend storage ds = diamondStorage(); 
           return ds.lendFeePlatformRecipient;
      }
      //-----
      function setBorrowerStakeInfo(address _borrower,StakeInfo memory _stakeInfo) external {
          Lend storage ds = diamondStorage(); 
          ds.borrowerStakeInfos[_borrower]=_stakeInfo;
      }

      function deleteBorrowerStakeInfo(address _borrower) external {
          Lend storage ds = diamondStorage();
          delete ds.borrowerStakeInfos[_borrower];
      }

      function getBorrowerStakeInfo(address _borrower) external view returns(StakeInfo memory){
          Lend storage ds = diamondStorage();  
          return ds.borrowerStakeInfos[_borrower];
      }

      function setLenderStakeInfo(address _lender,address _borrower) external{
           Lend storage ds = diamondStorage();  
           ds.lenderStakeInfos[_lender].push(_borrower);
      }

      function getBorrowers(address _lender) external view returns(address[] memory){
            Lend storage ds = diamondStorage();  
            return ds.lenderStakeInfos[_lender];
      }

      function getBorrowersLength(address _lender) external view returns(uint256){
          Lend storage ds = diamondStorage();  
          return ds.lenderStakeInfos[_lender].length;
      }

      function deleteBorrowerStakeInfo(address _lender,uint256 _index) external {
           Lend storage ds = diamondStorage();  
           uint256 lastIndex=ds.lenderStakeInfos[_lender].length-1;
           if(lastIndex != _index){
            address lastAddr=ds.lenderStakeInfos[_lender][lastIndex];
            ds.borrowerStakeInfos[lastAddr].index=_index;
            ds.lenderStakeInfos[_lender][_index]=lastAddr;
           }
           ds.lenderStakeInfos[_lender].pop();
      }
    
}