// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// interfaces
import "./IERC20.sol";
import "./IMintableBurnable.sol";

// imported contracts and libraries
import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./errors.sol";
import "./types.sol";

/**
 * @title Teleport
 * @notice This contract is the erc20 token teleport between the native chain and a foreign chain
 * @dev This contract is upgradeable in the future to add new features.
 */
contract Teleport is OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when a token is added to the teleport registry
    event Supported(address token, uint256 chainId, address chainToken);

    /// @notice emitted when a wallet beams tokens from one chain to another chain
    event Beam(
        address from, address token, uint256 chainId, address chainToken, address chainRecipient, uint256 amount, bytes32 nonce
    );

    /// @notice emitted when a beam arrives and is reassembled
    event Assembled(address token, address recipient, uint256 amount, bytes32 nonce);

    /*///////////////////////////////////////////////////////////////
                          State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @notice mapping of supported chains for a given token
    ///         mapping token => chainId => chain token address
    mapping(address => mapping(uint256 => address)) public supported;

    /// @notice mapping of beams
    mapping(bytes32 => BeamDetails) public beams;

    /*///////////////////////////////////////////////////////////////
                             Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) public initializer {
        if (_owner == address(0)) revert BadAddress();

        _transferOwnership(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal virtual override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets support for beaming tokens to other chains
     * @param _token is the address of token to beam
     * @param _chainId is the destination chain id
     * @param _chainToken is the token address on the destination chain
     */
    function setSupported(address _token, uint256 _chainId, address _chainToken) external {
        _checkOwner();

        // reverting if already set
        if (supported[_token][_chainId] == _chainToken) revert();

        supported[_token][_chainId] = _chainToken;

        emit Supported(_token, _chainId, _chainToken);
    }

    /**
     * @notice Beams token to other chain
     * @dev requires token approval, only allows one beam per msg.sender per block
     * @param _token is the address of token to beam
     * @param _chainId is the destination chain id
     * @param _chainRecipient is the wallet to receive the chainToken on the destination chain
     * @param _amount is the amount of token to beam
     */
    function disassembler(address _token, uint256 _chainId, address _chainRecipient, uint256 _amount) external nonReentrant {
        if (_amount == 0) revert BadAmount();
        if (_chainRecipient == address(0)) revert BadAddress();

        address chainToken = supported[_token][_chainId];

        // zero address means it is not supported
        if (chainToken == address(0)) revert NotSupported();

        // transfer to teleporter
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        // teleporter burns tokens
        IMintableBurnable(_token).burn(_amount);

        bytes32 nonce = keccak256(abi.encode(block.chainid, blockhash(block.number - 1), msg.sender));

        if (beams[nonce].sender != address(0)) revert NonceUsed();
        beams[nonce] = BeamDetails({
            sender: msg.sender,
            token: _token,
            chainId: _chainId,
            chainToken: chainToken,
            chainRecipient: _chainRecipient,
            amount: _amount
        });

        emit Beam(msg.sender, _token, _chainId, chainToken, _chainRecipient, _amount, nonce);
    }

    /**
     * @notice Reassembles Beam and mint tokens
     * @dev only callable by contract owner
     * @param _token is the address of token to mint
     * @param _recipient is the wallet to receive the token
     * @param _amount is the amount of token to mint
     * @param _nonce to prevent replay attacks
     */
    function reassembler(address _token, address _recipient, uint256 _amount, bytes32 _nonce) external nonReentrant {
        _checkOwner();

        if (beams[_nonce].sender != address(0)) revert NonceUsed();
        beams[_nonce] = BeamDetails({
            sender: msg.sender,
            token: _token,
            chainId: block.chainid,
            chainToken: _token,
            chainRecipient: _recipient,
            amount: _amount
        });

        IMintableBurnable(_token).mint(_recipient, _amount);

        emit Assembled(_token, _recipient, _amount, _nonce);
    }
}
