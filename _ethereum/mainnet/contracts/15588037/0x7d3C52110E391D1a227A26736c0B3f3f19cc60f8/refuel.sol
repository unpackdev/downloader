// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./refuel.sol";
import "./errors.sol";
import "./ImplBase.sol";


contract RefuelBridgeImpl is ImplBase, ReentrancyGuard {
    IRefuel public router;

    /**
    @notice Constructor sets the router address and registry address.
    */
    constructor(IRefuel _router, address _registry)
        ImplBase(_registry)
    {
        router = _router;
    }

    /**
    @notice function responsible for calling cross chain transfer using refuel bridge.
    @param _receiverAddress receivers address.
    @param _toChainId destination chain Id
    */
    function outboundTransferTo(
        uint256,
        address,
        address _receiverAddress,
        address,
        uint256 _toChainId,
        bytes calldata
    ) external payable override onlyRegistry nonReentrant {
        require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
        router.depositNativeToken{value: msg.value}(
                _toChainId,
                _receiverAddress
        );
    }
}
