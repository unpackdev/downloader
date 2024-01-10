pragma solidity 0.5.16;

interface IBorrowRecipient {

  function approveBack(uint256 _amount) external;

  function pullLoan(uint256 _amount) external;

}
