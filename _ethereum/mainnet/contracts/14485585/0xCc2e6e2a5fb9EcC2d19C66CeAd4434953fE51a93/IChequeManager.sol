// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IChequeManager {
  event Issue(
    address indexed from,
    address indexed to,
    address indexed referer,
    uint256 optionId,
    uint256 tokenId,
    uint256 amount
  );

  event Redeem(
    address indexed by,
    uint256 optionId,
    uint256 tokenId,
    uint256 amount
  );

  event Claim(
    address indexed by,
    uint256 amount
  );

  function setTrustedRelayer(address relayer) external;

  function setRewardAmount(uint256 optionId, uint256 reward) external;

  function setGasDepositAmount(uint256 optionId, uint256 gas) external;

  function addChequeOption(address chequeAddress, uint256 fee, uint256 reward, uint256 gasDeposit) external;

  function issueWithReferrer(uint256 checkOptionId, address toAddress, uint256 unlockAt, address referrer) payable external; 

  function issue(uint256 checkOptionId, address toAddress) payable external;

  function issueWithUnlock(uint256 checkOptionId, address toAddress, uint256 unlockAt) payable external;
  
  // function redeem(uint256 checkOptionId, uint256 checkTokenId, uint256 amount) external;

  function redeemAll(uint256 checkOptionId, uint256 checkTokenId) external;

  function balanceOf(uint256 checkOptionId, uint256 checkTokenId) view external returns (uint256);

  function numOfCardIssued() external view returns (uint256);

  function unlockAt(uint256 checkOptionId, uint256 checkTokenId) view external returns (uint256);

  function issuedBy(uint256 checkOptionId, uint256 checkTokenId) view external returns (address);

  function issueFee(uint256 checkOptionId) view external returns (uint256);

  function issuedAt(uint256 checkOptionId, uint256 checkTokenId) view external returns (uint256);

  function claimableAmount() view external returns (uint256);

  function claim() external;
}
