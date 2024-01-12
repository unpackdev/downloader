pragma solidity >=0.4.21 <0.6.0;
import "./Ownable.sol";

contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools is Ownable{
  TrustListInterface public trustlist;

  modifier is_trusted(address addr){
    require(trustlist != TrustListInterface(0x0), "trustlist is 0x0");
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

  event ChangeTrustList(address _old, address _new);
  function changeTrustList(address _addr) public onlyOwner{
    address old = address(trustlist);
    trustlist = TrustListInterface(_addr);
    emit ChangeTrustList(old, _addr);
  }

}
