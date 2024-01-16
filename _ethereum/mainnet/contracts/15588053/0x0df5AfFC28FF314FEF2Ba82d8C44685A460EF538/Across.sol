// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./errors.sol";
import "./ImplBase.sol";
import "./across.sol";

contract AcrossImplV2 is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    SpokePool public immutable spokePool;

    /**
    @notice Constructor sets the router address and registry address.
    @dev depositBox so no setter function required.
    */
    constructor(SpokePool _spokePool, address _registry) ImplBase(_registry) {
        spokePool = _spokePool;
    }

    /**
    @notice function responsible for calling l2 -> l1 transfer using across bridge.
    @dev the token to be passed on to anyswap function is supposed to be the wrapper token
    address.
    @param _amount amount to be sent.
    @param _from sender address. 
    @param _receiverAddress receivers address.
    @param _token this is the main token address on the source chain. 
    @param _extraData data contains extra data for the bridge
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 toChainId,
        bytes memory _extraData
    ) external payable override onlyRegistry nonReentrant {
        (
            address _originToken,
            uint64 relayerFeePct,
            uint32 _quoteTimestamp
        ) = abi.decode(_extraData, (address, uint64, uint32));

        if (_token == NATIVE_TOKEN_ADDRESS) {
            // check if value passed is not 0
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            spokePool.deposit{value: _amount}(
                _receiverAddress,
                _originToken,
                _amount,
                toChainId,
                relayerFeePct,
                _quoteTimestamp
            );
            return;
        }

        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(address(spokePool), _amount);

        spokePool.deposit(
            _receiverAddress,
            _originToken,
            _amount,
            toChainId,
            relayerFeePct,
            _quoteTimestamp
        );
    }
}
