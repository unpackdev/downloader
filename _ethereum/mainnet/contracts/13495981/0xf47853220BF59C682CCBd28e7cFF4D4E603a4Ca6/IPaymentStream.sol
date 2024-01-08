//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPaymentStream {
  event Claimed(uint256 usdAmount, uint256 tokenAmount);
  event StreamPaused();
  event StreamUnpaused();
  event StreamUpdated(uint256 usdAmount, uint256 endTime);

  event FundingAddressUpdated(
    address indexed previousFundingAddress,
    address indexed newFundingAddress
  );
  event PayeeUpdated(address indexed previousPayee, address indexed newPayee);

  function claim() external;

  function pauseStream() external;

  function unpauseStream() external;

  function delegatePausable(address delegate) external;

  function revokePausable(address delegate) external;

  function updateFundingRate(uint256 usdAmount, uint256 endTime) external;

  function updateFundingAddress(address newFundingAddress) external;

  function updatePayee(address newPayee) external;

  function claimableToken() external view returns (uint256);

  function claimable() external view returns (uint256);
}
