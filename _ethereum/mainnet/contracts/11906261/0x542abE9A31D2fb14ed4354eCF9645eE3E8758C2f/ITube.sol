//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface ITube {
  function depositFee() external view returns (uint256);

  function depositTo(address _token, address _to, uint256 _amount) external payable;
}
