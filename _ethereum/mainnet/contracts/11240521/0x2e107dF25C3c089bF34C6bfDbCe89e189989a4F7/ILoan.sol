pragma solidity ^0.6.0;

interface ILoan{
    function checkPrivilege(address _user,uint256 _tokenId,uint256 _time) external view returns(bool);
    
    function checkCanSell(uint256 _tokenId,uint256 _time) external view returns(bool);
}