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

import "./IConfig.sol";
import "./IRegistry.sol";
import "./IPortal.sol";
import "./ISocketRegistry.sol";
import "./XCC.sol";

contract Portal is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPortal
{
    using XCC for IRegistry.Integration[];
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    IConfig public override config;

    function _initialize(IConfig c) external initializer {
        require(address(c) != address(0), "PT1");
        config = c;
        OwnableUpgradeable.__Ownable_init();
    }

    // non payable as we only handle stablecoins
    function outboundERC20TransferTo(
        ISocketRegistry.UserRequest calldata request,
        ISmartAccount.ExecuteParams calldata execParams,
        uint256 toAmount
    ) external override nonReentrant {
        require(request.receiverAddress != address(0), "PT2");
        require(request.toChainId != 0, "PT3");
        require(request.amount > 0, "PT4");
        IRegistry reg = config.registry();
        ISocketRegistry socketReg = config.socketRegistry();
        uint256 routeId = request.middlewareRequest.id == 0
            ? request.bridgeRequest.id
            : request.middlewareRequest.id;
        ISocketRegistry.RouteData memory rdata = socketReg.routes(routeId);
        address approveAddr = rdata.route;

        // check against registry
        IRegistry.Integration[] memory itgxn = reg.getIntegrations(
            request.toChainId
        );
        for (uint256 i; i < execParams.operations.length; i++) {
            (bool exist, , ) = itgxn.findIntegration(
                execParams.operations[i].integration
            );
            require(exist, "PT5");
        }

        IERC20MetadataUpgradeable(request.middlewareRequest.inputToken)
            .safeTransferFrom(msg.sender, address(this), request.amount);

        IERC20MetadataUpgradeable(request.middlewareRequest.inputToken)
            .safeIncreaseAllowance(approveAddr, request.amount);

        // TODO check to make sure outboundTransferTo always reverts if outbound is not successful
        socketReg.outboundTransferTo(request);
        emit Outbound(
            request.toChainId,
            request.receiverAddress,
            request,
            execParams,
            toAmount
        );
    }

    function outboundNativeTransferTo(
        ISocketRegistry.UserRequest calldata request,
        ISmartAccount.ExecuteParams calldata execParams
    ) external payable override nonReentrant {
        revert("PT6");
        // require(request.receiverAddress != address(0), "PT2");
        // require(request.toChainId != 0, "PT3");
        // require(request.amount > 0, "PT4");
        // IRegistry reg = config.registry();
        // ISocketRegistry socketReg = config.socketRegistry();
        // // check against registry
        // IRegistry.Integration[] memory itgxn = reg.getIntegrations(
        //     request.toChainId
        // );
        // for (uint256 i; i < execParams.operations.length; i++) {
        //     (bool exist, , ) = itgxn.findIntegration(
        //         execParams.operations[i].integration
        //     );
        //     require(exist, "PT5");
        // }
        // // TODO check to make sure outboundTransferTo always reverts if outbound is not successful
        // socketReg.outboundTransferTo{value: msg.value}(request);
        // emit Outbound(
        //     request.toChainId,
        //     request.receiverAddress,
        //     request,
        //     execParams
        // );
    }
}
