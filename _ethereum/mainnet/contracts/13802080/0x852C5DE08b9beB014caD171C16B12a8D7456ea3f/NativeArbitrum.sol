// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ImplBase.sol";
import "./errors.sol";
import "./arbitrum.sol";

/**
// @title Native Arbitrum Bridge Implementation.
// @notice This is the L1 implementation, 
//          so this is used when transferring from ethereum to arbitrum via their native bridge.
// Called by the registry if the selected bridge is Native Arbitrum.
// @dev Follows the interface of ImplBase. This is only used for depositing tokens.
// @author Movr Network.
*/
contract NativeArbitrumImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public router;
    address public inbox;
    event UpdateArbitrumRouter(address indexed routerAddress);
    event UpdateArbitrumInbox(address indexed inbox);

    /// @notice registry and L1 gateway router address required.
    constructor(
        address _registry,
        address _router,
        address _inbox
    ) ImplBase(_registry) {
        router = _router;
        inbox = _inbox;
    }

    /// @notice setter function for the L1 gateway router address
    function setInbox(address _inbox) public onlyOwner {
        inbox = _inbox;
        emit UpdateArbitrumInbox(_inbox);
    }

    /// @notice setter function for the L1 gateway router address
    function setRouter(address _router) public onlyOwner {
        router = _router;
        emit UpdateArbitrumRouter(_router);
    }

    /**
    // @notice function responsible for the native arbitrum deposits from ethereum. 
    // @dev gateway address is the address where the first deposit is made. 
    //      It holds max submission price and further data.
    // @param _amount amount to be sent. 
    // @param _from senders address 
    // @param _receiverAddress receivers address
    // @param _token token address on the source chain that is L1. 
    // param _toChainId not required, follows the impl base.
    // @param _extraData extradata required for calling the l1 router function. Explain above. 
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256, // _toChainId
        bytes memory _extraData
    ) external payable override onlyRegistry nonReentrant {
        IERC20 token = IERC20(_token);
        (
            address _gatewayAddress,
            uint256 _maxGas,
            uint256 _gasPriceBid,
            bytes memory _data
        ) = abi.decode(_extraData, (address, uint256, uint256, bytes));

        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            Inbox(inbox).depositEth{value: _amount}(_maxGas);
            return;
        }
        // @notice here we dont provide a 0 value check
        // since arbitrum may need native token as well along
        // with ERC20
        token.safeTransferFrom(_from, address(this), _amount);
        token.safeIncreaseAllowance(_gatewayAddress, _amount);
        L1GatewayRouter(router).outboundTransfer{value: msg.value}(
            _token,
            _receiverAddress,
            _amount,
            _maxGas,
            _gasPriceBid,
            _data
        );
    }
}
