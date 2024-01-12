// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./NonblockingLzApp.sol";
import "./Token.sol";

/// @custom:security-contact security@tenset.io
contract LayerZeroBridge is NonblockingLzApp {
    Token public token;

    constructor(address token_, address _endpoint) NonblockingLzApp(_endpoint) {
        token = Token(token_);
    }

    receive() external payable {}

    /**
    @notice bridge tokens to another chain
    @param destinationChainId destination LayerZero chainId
    @param bridgeAddress bridge address on the destination chain
    @param to asset recipient address on the destination chain
    @param amount asset amount to transfer
    */
    function bridgeTo(
        uint16 destinationChainId,
        address bridgeAddress,
        address to,
        uint256 amount
    ) external payable {
        require(
            address(token) != address(0),
            'Please set the token address first'
        );
        require(token.balanceOf(msg.sender) >= amount, 'not enough balance');
        lzEndpoint.send{value: msg.value}(
            destinationChainId,
            abi.encodePacked(bridgeAddress),
            abi.encode(to, amount),
            payable(msg.sender), // refund address
            address(0x0),
            bytes('')
        );
        token.bridgeBurn(msg.sender, amount);
    }

    function estimateFee(
        uint16 destinationChainId,
        address bridgeAddress,
        address to,
        uint256 amount
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        return
            lzEndpoint.estimateFees(
                destinationChainId,
                bridgeAddress,
                abi.encode(to, amount),
                false,
                bytes('')
            );
    }

    function _nonblockingLzReceive(
        uint16, /* _srcChainId */
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal override {
        address srcAddress;
        assembly {
            srcAddress := mload(add(_srcAddress, 20))
        }

        (address to, uint256 amount) = abi.decode(_payload, (address, uint256));
        Token(token).mint(to, amount);
    }
}
