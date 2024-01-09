//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

import "./IRegistry.sol";
import "./IFederation.sol";

interface IBridgeOutbound {
    // function tokenRegistry() external returns (IRegistry);
    function bridgeTokenAt(
        uint256 dstChainID,
        address srcChainTokenAddress,
        uint256 amount,
        address dstReceiverAddress
    ) external;
    function bridgeToken(
        uint256 dstChainID,
        address srcChainTokenAddress,
        uint256 amount
    ) external;
    event Cross(
        address indexed srcChainSenderAddress,
        address indexed srcChainTokenAddress,
        uint256 indexed dstChainID,
        address dstChainTokenAddress,
        address dstChainReceiverAddr,
        uint256 amountToCross,
        uint256 feeCollected
    );
}
