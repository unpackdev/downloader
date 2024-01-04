// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

interface IBlissToken is IERC20 {
  function setFeeHandler(address feeHandlerAddress) external;
  function setTxFee(uint256 txFee) external;
}

contract BlissOwnerWrapper is Ownable {

  // Bliss token address that this wrapper is associated with
  address public blissToken;

  constructor(address _blissToken) public {
    blissToken = _blissToken;
  }

  /** @dev Change the fee handler location
   */
  function setFeeHandler(address _newAddr) external onlyOwner {
    IBlissToken(blissToken).setFeeHandler(_newAddr);
  }

  /** @dev Change the tx fee, 1000 = 10%
   */
  function setTxFee(uint256 _newFee) external onlyOwner {
    require(_newFee < 1000, "fee must be < 10%");
    IBlissToken(blissToken).setTxFee(_newFee);
  }

  /** @dev Set the contract address for Bliss token
  */
  function setBlissTokenAddress(address _blissTokenAddress) external onlyOwner {
    blissToken = _blissTokenAddress;
  }
}
