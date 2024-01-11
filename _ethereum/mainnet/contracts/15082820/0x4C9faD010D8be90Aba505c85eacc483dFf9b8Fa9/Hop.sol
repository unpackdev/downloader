// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ImplBase.sol";
import "./errors.sol";
import "./IHopL1Bridge.sol";

/**
// @title Hop Protocol Implementation.
// @notice This is the L1 implementation, so this is used when transferring from l1 to supported l2s
//         Called by the registry if the selected bridge is HOP.
// @dev Follows the interface of ImplBase.
// @author Movr Network.
*/
contract HopImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    event HopBridgeSend(
        uint256 indexed integratorId
    );

    // solhint-disable-next-line
    constructor(address _registry) ImplBase(_registry) {}

    struct HopExtraData {
        address _l1bridgeAddr;
        address _relayer;
        uint256 _amountOutMin;
        uint256 _relayerFee;
        uint256 _deadline;
        uint256 integratorId;
    }

    /**
    // @notice Function responsible for cross chain transfers from L1 to L2. 
    // @dev When calling the registry the allowance should be given to this contract, 
    //      that is the implementation contract for HOP.
    // @param _amount amount to be transferred to L2.
    // @param _from userAddress or address from which the transfer was made.
    // @param _receiverAddress address that will receive the funds on the destination chain.
    // @param _token address of the token to be used for cross chain transfer.
    // @param _toChainId chain Id for the destination chain 
    // @param _extraData parameters required to call the hop function in bytes 
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes calldata _extraData
    ) external payable override onlyRegistry nonReentrant {
        // decode extra data
        (
            HopExtraData memory _hopExtraData
        ) = abi.decode(
                _extraData,
                (HopExtraData)
            );
        emit HopBridgeSend(_hopExtraData.integratorId);
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == _amount, MovrErrors.VALUE_NOT_EQUAL_TO_AMOUNT);
            IHopL1Bridge(_hopExtraData._l1bridgeAddr).sendToL2{value: _amount}(
                _toChainId,
                _receiverAddress,
                _amount,
                _hopExtraData._amountOutMin,
                _hopExtraData._deadline,
                _hopExtraData._relayer,
                _hopExtraData._relayerFee
            );
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(_hopExtraData._l1bridgeAddr, _amount);

        // perform bridging
        IHopL1Bridge(_hopExtraData._l1bridgeAddr).sendToL2(
            _toChainId,
            _receiverAddress,
            _amount,
            _hopExtraData._amountOutMin,
            _hopExtraData._deadline,
            _hopExtraData._relayer,
            _hopExtraData._relayerFee
        );
    }
}
