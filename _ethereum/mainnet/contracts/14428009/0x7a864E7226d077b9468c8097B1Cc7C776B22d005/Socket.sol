// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";

import "./BaseBridge.sol";
import "./IConfig.sol";
import "./IRegistry.sol";
import "./IBridge.sol";
import "./ISocketRegistry.sol";
import "./XCC.sol";

contract Socket is BaseBridge {
    using XCC for IRegistry.Integration[];
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    // non payable as we only handle stablecoins
    function _outboundERC20TransferTo(
        ISocketRegistry.UserRequest memory request
    ) internal override {
        ISocketRegistry socketReg = config.socketRegistry();
        uint256 routeId = request.middlewareRequest.id == 0
            ? request.bridgeRequest.id
            : request.middlewareRequest.id;
        ISocketRegistry.RouteData memory rdata = socketReg.routes(routeId);
        address approveAddr = rdata.route;
        IERC20MetadataUpgradeable(request.middlewareRequest.inputToken)
            .safeTransferFrom(msg.sender, address(this), request.amount);
        IERC20MetadataUpgradeable(request.middlewareRequest.inputToken)
            .safeIncreaseAllowance(approveAddr, request.amount);

        // TODO check to make sure outboundTransferTo always reverts if outbound is not successful
        socketReg.outboundTransferTo(request);
    }

    function _outboundNativeTransferTo(
        ISocketRegistry.UserRequest memory request
    ) internal override {
        revert("BB1");
        // ISocketRegistry socketReg = config.socketRegistry();
        // // TODO check to make sure outboundTransferTo always reverts if outbound is not successful
        // socketReg.outboundTransferTo{value: msg.value}(request);
    }
}
