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
import "./IBridge.sol";
import "./ISocketRegistry.sol";
import "./XCC.sol";

abstract contract BaseBridge is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IBridge
{
    using XCC for IRegistry.Integration[];
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    IConfig public override config;

    function _initialize(IConfig c) external initializer {
        require(address(c) != address(0), "PT1");
        config = c;
        OwnableUpgradeable.__Ownable_init();
        __child_init();
    }

    function __child_init() internal virtual onlyInitializing {}

    // non payable as we only handle stablecoins
    function outboundERC20TransferAllTo(BridgeAllUserRequest calldata request, uint256 toAmount)
        external
        override
        nonReentrant
    {
        require(request.receiverAddress != address(0), "PT2");
        require(request.toChainId != 0, "PT3");
        uint256 amount = IERC20MetadataUpgradeable(
            request.middlewareRequest.inputToken
        ).balanceOf(msg.sender);
        // TODO check to make sure outboundTransferTo always reverts if outbound is not successful
        ISocketRegistry.UserRequest memory u = ISocketRegistry.UserRequest(
            request.receiverAddress,
            request.toChainId,
            amount,
            request.middlewareRequest,
            request.bridgeRequest
        );
        _outboundERC20TransferTo(u);
        // socketReg.outboundTransferTo(request);
        emit BridgeOutbound(request.toChainId, request.receiverAddress, u, toAmount);
    }

    function _outboundERC20TransferTo(
        ISocketRegistry.UserRequest memory request
    ) internal virtual;

    function outboundNativeTransferTo(
        ISocketRegistry.UserRequest calldata request,
        uint256 toAmount
    ) external payable override nonReentrant {
        revert("PT5");
        // require(request.receiverAddress != address(0), "PT2");
        // require(request.toChainId != 0, "PT3");
        // require(request.amount > 0, "PT4");
        // // ISocketRegistry socketReg = config.socketRegistry();
        // // TODO check to make sure outboundTransferTo always reverts if outbound is not successful
        // _outboundNativeTransferTo(request);

        // // socketReg.outboundTransferTo{value: msg.value}(request);
        // emit BridgeOutbound(
        //     request.toChainId,
        //     request.receiverAddress,
        //     request,
        //     toAmount
        // );
    }

    function _outboundNativeTransferTo(
        ISocketRegistry.UserRequest memory request
    ) internal virtual;
}
