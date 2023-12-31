//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal doughMemory = MemoryInterface(0xeb18D0972d36FD090E586F1ee1201dA6E30f3311);

  /**
   * @dev Return DoughList address
   */
  ListInterface internal constant doughList = ListInterface(0x770777aB1A361194790568aE463290e3b10e5dF3);

  /**
	 * @dev Return connectors registry address
	 */
	DoughConnectors internal constant doughConnectors = DoughConnectors(0x32D48A96fA5552998F524EC72f31D732B66b4f9E);
  
  /**
   * @dev Get Uint value from DoughMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : doughMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in DoughMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) doughMemory.setUint(setId, val);
  }

}
