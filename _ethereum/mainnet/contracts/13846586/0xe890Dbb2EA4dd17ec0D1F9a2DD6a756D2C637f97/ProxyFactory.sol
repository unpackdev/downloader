// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./ERC1167.sol";

contract ProxyFactory {
  using ERC1167 for address;

  event ProxyCreated(address indexed prototype, address indexed proxy);

  /**
   * @notice Create proxy contract by prototype.
   * @param prototype Address of prototype contract.
   * @param args Encoded call to the init function.
   */
  function create(address prototype, bytes memory args) external returns (address proxy) {
    proxy = prototype.clone();

    if (args.length > 0) {
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = proxy.call(args);
      require(success, "ProxyFactory::create: proxy initialization failed");
    }

    emit ProxyCreated(prototype, proxy);
  }
}
