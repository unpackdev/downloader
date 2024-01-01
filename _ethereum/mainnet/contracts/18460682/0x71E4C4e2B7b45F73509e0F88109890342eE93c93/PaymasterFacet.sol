// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./IPaymasterFacet.sol";

contract PaymasterFacet  is IPaymasterFacet{
      bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.Paymaster.diamond.storage");
      struct Paymaster{
           //paymaster balance
           mapping(address=> uint256) walletPaymasterBalance;     
           address payer;
           mapping(address => uint256) quotaWhiteList;

      }
      function diamondStorage() internal pure returns (Paymaster storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
      }
      
      //-paymaster
      function setWalletPaymasterBalance(address _wallet,uint256 _amount,bool _type) external {
             Paymaster storage ds=diamondStorage();
             if(_type){
                ds.walletPaymasterBalance[_wallet]+=_amount;
             }else{
                require( ds.walletPaymasterBalance[_wallet]>=_amount,"Paymaster:balance not enough");  
                ds.walletPaymasterBalance[_wallet]-=_amount;
             }     
      }
      function getWalletPaymasterBalance(address _wallet) external view returns(uint256){
             Paymaster storage ds=diamondStorage();
             return  ds.walletPaymasterBalance[_wallet];
      }

      function setPayer(address _payer) external{
             Paymaster storage ds=diamondStorage();
             ds.payer=_payer;
      }
      function getPayer() external view returns(address){
             Paymaster storage ds=diamondStorage();
             return ds.payer;
      }

      function setQuotaWhiteList(address _target,uint256 _amount,bool _type) external {
              Paymaster storage ds=diamondStorage();
              if(_type){
                ds.quotaWhiteList[_target]+=_amount;
              }else{
                require( ds.quotaWhiteList[_target]>=_amount,"Paymaster:quota not enough");  
                ds.quotaWhiteList[_target]-=_amount;
              }     
      }

      function getQuota(address _target) external view returns(uint256){
             Paymaster storage ds=diamondStorage();
             return ds.quotaWhiteList[_target];
      }

}     