// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
interface IPaymasterFacet{
    struct DepositInfo{
        address wallet;
        string protocol;
        uint256 positionType;
        address sendAsset; 
        address receiveAsset;  
        uint256 adapterType;  
        uint256 amountIn;
        uint256 amountLimit;
        uint256 approveAmount;
        bytes adapterData;  
    }
    function setWalletPaymasterBalance(address _wallet,uint256 _amount,bool _type) external;
    function getWalletPaymasterBalance(address _wallet) external view returns(uint256);
    function setPayer(address _payer) external;
    function getPayer() external view returns(address);
    function setQuotaWhiteList(address _target,uint256 _amount,bool _type) external;
    function getQuota(address _target) external view returns(uint256);
}