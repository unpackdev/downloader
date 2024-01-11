// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./errors.sol";
import "./ImplBase.sol";
import "./cbridge.sol";

/**
@title Celer L2 Implementation.
@notice This is the L2 implementation, so this is used when transferring from
l2 to supported l2s or L1.
Called by the registry if the selected bridge is Celer bridge.
@dev Follows the interface of ImplBase.
@author Socket.
*/

contract CelerImplL1L2 is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    ICBridge public immutable router;

    /**
    @notice Constructor sets the router address and registry address.
    @dev Celer Bridge address is constant. so no setter function required.
    */
    constructor(ICBridge _router, address _registry) ImplBase(_registry) {
        router = _router;
    }

    /**
    @notice function responsible for calling cross chain transfer using celer bridge.
    @dev the token to be passed on to the celer bridge.
    @param _amount amount to be sent.
    @param _from sender address. 
    @param _receiverAddress receivers address.
    @param _token this is the main token address on the source chain. 
    @param _toChainId destination chain Id
    @param _data data contains nonce and the maxSlippage.
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory _data
    ) external payable override onlyRegistry nonReentrant {
        (uint64 nonce, uint32 maxSlippage) = abi.decode(
            _data,
            (uint64, uint32)
        );
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == _amount, MovrErrors.VALUE_NOT_EQUAL_TO_AMOUNT);
            router.sendNative{value: _amount}(
                _receiverAddress,
                _amount,
                uint64(_toChainId),
                nonce,
                maxSlippage
            );
        } else {
            require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
            IERC20(_token).safeIncreaseAllowance(address(router), _amount);
            router.send(
                _receiverAddress,
                _token,
                _amount,
                uint64(_toChainId),
                nonce,
                maxSlippage
            );
        }
    }
}
