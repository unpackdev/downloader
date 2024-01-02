// SPDX-License-Identifier: GPL-3.0-or-later

/** @notice This contract was taken from (https://github.com/balancer-labs/balancer-v2-monorepo) and used for IBalancer*/

pragma solidity ^0.8.18;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {

}
