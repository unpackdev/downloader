pragma solidity 0.6.12;


contract checkContract {

    function isContract(address _addr) public view returns(bool){
      uint32 size;
      address a = _addr;
      assembly {
        size := extcodesize(a)
      }
      return (size > 0);
    }

}