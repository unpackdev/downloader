pragma experimental ABIEncoderV2;
pragma solidity ^0.5.0;

import "./ProxyWalletLib.sol";

interface IProxyWalletFactory {
  function proxy(ProxyWalletLib.ProxyCall[] calldata /* calls */) external payable returns (bytes[] memory /* returnValues */);
  function getImplementation() external view returns (address);
}
