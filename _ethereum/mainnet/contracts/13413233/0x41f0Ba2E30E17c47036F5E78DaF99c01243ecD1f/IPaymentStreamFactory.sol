//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IPaymentStreamFactory {
  struct TokenSupport {
    address[] path;
    uint256 dex;
  }

  event StreamCreated(
    uint256 id,
    address indexed stream,
    address indexed payer,
    address indexed payee,
    uint256 usdAmount
  );

  event TokenAdded(address indexed tokenAddress);

  event SwapManagerUpdated(
    address indexed previousSwapManager,
    address indexed newSwapManager
  );

  function updateSwapManager(address newAddress) external;

  function addToken(
    address _tokenAddress,
    uint8 _dex,
    address[] memory _path
  ) external;

  function updateOracles(address token) external;

  function usdToTokenAmount(address _token, uint256 _amount)
    external
    view
    returns (uint256);

  function ours(address _a) external view returns (bool);

  function getStreamsCount() external view returns (uint256);

  function getStream(uint256 _idx) external view returns (address);
}
