// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./DataTypes.sol";
import "./Errors.sol";
import "./OrderTypes.sol";
import "./SeaportInterface.sol";
import "./ILooksRareExchange.sol";
import "./SignatureChecker.sol";
import "./ConsiderationStructs.sol";
import "./ConsiderationStructs.sol";
import "./Address.sol";
import "./IERC1271.sol";

interface IMarketplace {
    function getAskOrderInfo(
        bytes memory data
    ) external view returns (DataTypes.OrderInfo memory orderInfo);

    function getBidOrderInfo(
        bytes memory data
    ) external view returns (DataTypes.OrderInfo memory orderInfo);

    function matchAskWithTakerBid(
        address marketplace,
        bytes calldata data,
        uint256 value
    ) external payable returns (bytes memory);

    function matchBidWithTakerAsk(
        address marketplace,
        bytes calldata data
    ) external returns (bytes memory);
}
