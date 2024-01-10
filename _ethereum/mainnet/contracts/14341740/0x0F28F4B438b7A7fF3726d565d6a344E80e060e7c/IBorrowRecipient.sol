pragma solidity 0.5.16;

interface IBorrowRecipient {

  function pullLoan(uint256 _amount) external;

}
