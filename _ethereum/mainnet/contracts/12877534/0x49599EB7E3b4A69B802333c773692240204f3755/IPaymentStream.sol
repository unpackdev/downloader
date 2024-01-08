//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

struct Stream {
  address payee;
  uint256 usdAmount;
  address token;
  address fundingAddress;
  address payer;
  bool paused;
  uint256 startTime;
  uint256 secs;
  uint256 usdPerSec;
  uint256 claimed;
}

interface IPaymentStream {
  event StreamCreated(
    uint256 id,
    address indexed payer,
    address payee,
    uint256 usdAmount
  );
  event TokenAdded(address indexed tokenAddress);
  event SwapManagerUpdated(
    address indexed previousSwapManager,
    address indexed newSwapManager
  );
  event Claimed(uint256 indexed id, uint256 usdAmount, uint256 tokenAmount);
  event StreamPaused(uint256 indexed id);
  event StreamUnpaused(uint256 indexed id);
  event StreamUpdated(uint256 indexed id, uint256 usdAmount, uint256 endTime);
  event FundingAddressUpdated(
    uint256 indexed id,
    address indexed previousFundingAddress,
    address indexed newFundingAddress
  );
  event PayeeUpdated(uint256 indexed id, address newPayee);

  function createStream(
    address payee,
    uint256 usdAmount,
    address token,
    address fundingAddress,
    uint256 endTime
  ) external returns (uint256);

  function addToken(
    address _tokenAddress,
    uint8 _dex,
    address[] memory _path
  ) external;

  function claim(uint256 streamId) external;

  function updateSwapManager(address newAddress) external;

  function pauseStream(uint256 streamId) external;

  function unpauseStream(uint256 streamId) external;

  function delegatePausable(uint256 streamId, address delegate) external;

  function revokePausable(uint256 streamId, address delegate) external;

  function updateFundingRate(
    uint256 streamId,
    uint256 usdAmount,
    uint256 endTime
  ) external;

  function updateFundingAddress(uint256 streamId, address newFundingAddress)
    external;

  function updatePayee(uint256 streamId, address newPayee) external;

  function claimableToken(uint256 streamId) external view returns (uint256);

  function claimable(uint256 streamId) external view returns (uint256);

  function getStreamsCount() external view returns (uint256);
}
