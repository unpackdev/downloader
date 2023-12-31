// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./Types.sol";

interface IGoodsExchangeUpgradeable {
    error IGoodsExchange__NotAuthorized();
    error IGoodsExchange__InvalidSignatures();

    function claimGoods(Types.Claim calldata claim_, Types.Signature[] calldata signatures_) external;
}
