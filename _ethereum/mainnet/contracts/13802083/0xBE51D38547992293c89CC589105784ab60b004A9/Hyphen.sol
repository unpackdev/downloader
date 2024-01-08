// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./errors.sol";
import "./ImplBase.sol";
import "./hyphen.sol";

/**
// @title Hyphen L2 Implementation.
// @notice This is the L1 implementation, so this is used when transferring from l1 to
// supported l2s.
// Called by the registry if the selected bridge is Hyphen Bridge.
// @dev Follows the interface of ImplBase.
// @author Movr Network.
*/
contract HyphenImplL1 is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    HyphenLiquidityPoolManager public immutable liquidityPoolManager;

    /// @notice Liquidity pool manager address and registry address required.
    constructor(
        HyphenLiquidityPoolManager _liquidityPoolManager,
        address _registry
    ) ImplBase(_registry) {
        liquidityPoolManager = _liquidityPoolManager;
    }

    /**
    // @notice Function responsible for cross chain transfer of supported assets from l1
    // to supported l2 chains. 
    // @dev Liquidity should be checked before calling this function. 
    // @param _amount amount to be sent.
    // @param _from senders address.
    // @param _receiverAddress receivers address.
    // @param _token token address on the source chain. 
    // @param _toChainId destination chain id
    // param _data extra data that is required, not required in the case of Hyphen. 
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory // _data
    ) external payable override onlyRegistry nonReentrant {
        if (_token == NATIVE_TOKEN_ADDRESS) {
            // check if value passed is not 0
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            liquidityPoolManager.depositNative{value: _amount}(
                _receiverAddress,
                _toChainId
            );
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(
            address(liquidityPoolManager),
            _amount
        );
        liquidityPoolManager.depositErc20(
            _token,
            _receiverAddress,
            _amount,
            _toChainId
        );
    }
}
