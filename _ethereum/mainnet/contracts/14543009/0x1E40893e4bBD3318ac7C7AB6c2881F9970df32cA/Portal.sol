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
import "./IPortal.sol";
import "./ISocketRegistry.sol";

contract Portal is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IPortal
{
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
        emit Outbound(
            request.toChainId,
            request.receiverAddress,
            request,
            execParams,
            toAmount
        );
    }
}
