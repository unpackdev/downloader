// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./NonblockingLzApp.sol";

import "./IERC1155Router.sol";
import "./IERC1155LockerProxy.sol";

contract ONFT1155Router is IERC1155Router, NonblockingLzApp {
    /// @notice Contract that locks the assets
    address public lockerProxy;

    /// @notice base gas limit for the router
    uint256 public baseGasLimit = 150000;

    /// @notice gas limit per token
    uint256 public gasPerToken = 50000;

    event BaseGasLimitSet(uint256 baseGasLimit);
    event GasPerTokenSet(uint256 gasPerToken);

    /**
     * @param _lzEndpoint Layer Zero endpoint_lzEndpoint
     * @param _lockerProxy Locker proxy address
     */
    constructor(
        address _lzEndpoint,
        address _lockerProxy
    ) NonblockingLzApp(_lzEndpoint) {
        lockerProxy = _lockerProxy;
    }

    /**
     * @notice Sends a batch of ERC1155 tokens to another chain
     * @param _from The address that will have its tokens bridged
     * @param _to The address that will receive the tokens
     * @param _dstChainId The destination chain identifier
     * @param _tokenIds TokenIds to bridge
     * @param _amounts Amount of tokens to bridge
     */
    function send(
        address _from,
        address _to,
        uint16 _dstChainId,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external payable {
        if (msg.sender != lockerProxy) revert Unauthorized();

        bytes memory payload = abi.encode(
            abi.encodePacked(_to),
            _tokenIds,
            _amounts
        );

        _lzSend(
            _dstChainId,
            payload,
            payable(_from),
            address(0),
            abi.encodePacked(
                uint16(1),
                uint256(baseGasLimit + gasPerToken * _tokenIds.length)
            ),
            msg.value
        );

        emit SendBatchToChain(_dstChainId, _from, _to, _tokenIds, _amounts);
    }

    /**
     * @notice Sets new locker proxy address
     * @dev Only callable by the owner.
     * @param _lockerProxy new locker proxy address
     */
    function setLockerProxy(address _lockerProxy) external onlyOwner {
        lockerProxy = _lockerProxy;
        emit LockerProxySet(lockerProxy);
    }

    /**
     * @notice Sets new base gas limit
     * @dev Only callable by the owner.
     * @param _baseGasLimit new base gas limit
     */
    function setBaseGasLimit(uint256 _baseGasLimit) external onlyOwner {
        baseGasLimit = _baseGasLimit;
        emit BaseGasLimitSet(baseGasLimit);
    }

    /**
     * @notice Sets new gas per token
     * @dev Only callable by the owner.
     * @param _gasPerToken new gas per token
     */
    function setGasPerToken(uint256 _gasPerToken) external onlyOwner {
        gasPerToken = _gasPerToken;
        emit GasPerTokenSet(gasPerToken);
    }

    /**
     * @notice Called by the LayerZero endpoint when a message is received
     * @param _srcChainId The source chain identifier
     * @param _srcAddress The address that sent the message
     * @param _payload The message payload
     */
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64,
        bytes memory _payload
    ) internal virtual override {
        (
            bytes memory toAddressBytes,
            uint256[] memory tokenIds,
            uint256[] memory amounts
        ) = abi.decode(_payload, (bytes, uint256[], uint256[]));

        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        IERC1155LockerProxy(lockerProxy).unlock(
            toAddress,
            _srcChainId,
            tokenIds,
            amounts
        );

        address srcAddress;
        assembly {
            srcAddress := mload(add(_srcAddress, 20))
        }

        emit ReceiveBatchFromChain(
            _srcChainId,
            srcAddress,
            toAddress,
            tokenIds,
            amounts
        );
    }
}
