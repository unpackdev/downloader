pragma solidity ^0.6.0;


interface CToken {
    function underlying() external view returns(address);
    function exchangeRateCurrent() external view returns (uint);
}


contract cTest {
     // get compound rate 
  function getCTokenExchangeRateCurrent(
    address _cToken
  )
    public
    view
    returns (uint)
  {
    return CToken(_cToken).exchangeRateCurrent();
  }
  

  // get underlying by cToken
  function getCTokenUnderlying(address _cToken) external view returns(address){
    return CToken(_cToken).underlying();
  }

}