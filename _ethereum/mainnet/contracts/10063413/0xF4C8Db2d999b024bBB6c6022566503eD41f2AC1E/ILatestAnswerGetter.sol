pragma solidity ^0.6.6;

interface ILatestAnswerGetter {
  function latestAnswer() external view returns (int256);
}