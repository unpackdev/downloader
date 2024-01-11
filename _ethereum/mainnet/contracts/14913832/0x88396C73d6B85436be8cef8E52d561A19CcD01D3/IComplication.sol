// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./OrderTypes.sol";

interface IComplication {
  function canExecMatchOrder(
    OrderTypes.MakerOrder calldata sell,
    OrderTypes.MakerOrder calldata buy,
    OrderTypes.OrderItem[] calldata constructedNfts
  ) external view returns (bool, uint256);

  function canExecMatchOneToMany(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.MakerOrder[] calldata manyMakerOrders)
    external
    view
    returns (bool);

  function canExecMatchOneToOne(OrderTypes.MakerOrder calldata makerOrder1, OrderTypes.MakerOrder calldata makerOrder2)
    external
    view
    returns (bool);

  function canExecTakeOrder(OrderTypes.MakerOrder calldata makerOrder, OrderTypes.TakerOrder calldata takerOrder)
    external
    view
    returns (bool);

  function getProtocolFee() external view returns (uint256);
}
