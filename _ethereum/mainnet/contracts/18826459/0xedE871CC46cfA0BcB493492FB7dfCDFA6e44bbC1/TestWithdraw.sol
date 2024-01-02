// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract TestWithdraw {
    address payable private mainnetProxyAddress;
    address payable private masterCopy;

    constructor() {

        mainnetProxyAddress = payable(0x229946a96C34edD89c06d23DCcbFA259E9752a7c);

        masterCopy = payable(0x3de1e7312Bc701B4b5Bd4C4C0854d690Fe0e7516);

    }

    function test() public {

        bool res;
      
        (res,) =  mainnetProxyAddress.call{ value: 0.0001 ether}("");

        require(res, "call failed 1");
        
        
        (res,)  = masterCopy.call(abi.encodeWithSignature("withdraw()"));

        require(res, "call failed 2");
    }

    function setMasterCopy(address payable _masterCopy) public {
        masterCopy = _masterCopy;
    }

    receive() external payable {
    }
}