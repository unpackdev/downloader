// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./Router.sol";
import "./Token.sol";

/// @custom:security-contact security@tenset.io
contract AbacusBridge is Router {
    address public token;

    constructor(
        address _abacusConnectionManager,
        address _interchainGasPaymaster
    ) {
        _transferOwnership(msg.sender);
        _setAbacusConnectionManager(_abacusConnectionManager);
        _setInterchainGasPaymaster(_interchainGasPaymaster);
    }

    function bridgeTo(
        uint32 destination,
        address to,
        uint256 amount
    ) external payable {
        require(token != address(0), 'Please set the token address first');
        require(
            Token(token).balanceOf(msg.sender) >= amount,
            'not enough balance'
        );
        Token(token).bridgeBurn(msg.sender, amount);
        _dispatchWithGas(destination, abi.encode(to, amount), msg.value);
    }

    /**
     * @notice Handles a message from a remote router.
     * @dev Only called for messages sent from a remote router, as enforced by Router.sol.
     * @param _message The message body.
     */
    function _handle(
        uint32, /* origin */
        bytes32, /* _sender */
        bytes memory _message
    ) internal override {
        /* 
        Right now anyone can send a message to this smart contract and mint any token amount they want.
        Validate the sender address for a given origin.
        TODO validate origin and sender
        */
        require(token != address(0), 'Please set the token address first');
        (address to, uint256 amount) = abi.decode(_message, (address, uint256));
        Token(token).mint(to, amount);
    }

    function setToken(address token_) external onlyOwner {
        token = token_;
    }
}
