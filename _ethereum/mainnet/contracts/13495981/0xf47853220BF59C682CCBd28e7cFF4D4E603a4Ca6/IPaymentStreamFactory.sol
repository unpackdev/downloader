//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPaymentStreamFactory {
  event StreamCreated(
    uint256 id,
    address indexed stream,
    address indexed payer,
    address indexed payee,
    uint256 usdAmount
  );

  event CustomFeedMappingUpdated(
    address indexed token,
    address indexed tokenDenomination
  );

  event FeedRegistryUpdated(
    address indexed previousFeedRegistry,
    address indexed newFeedRegistry
  );

  function updateFeedRegistry(address newAddress) external;

  function usdToTokenAmount(address _token, uint256 _amount)
    external
    view
    returns (uint256);

  function ours(address _a) external view returns (bool);

  function getStreamsCount() external view returns (uint256);

  function getStream(uint256 _idx) external view returns (address);
}
