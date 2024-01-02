// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC1155Router {
    event SendBatchToChain(
        uint16 indexed dstChainId,
        address indexed from,
        address indexed toAddress,
        uint[] tokenIds,
        uint[] amounts
    );
    event ReceiveBatchFromChain(
        uint16 indexed _srcChainId,
        address indexed _srcAddress,
        address indexed _toAddress,
        uint[] _tokenIds,
        uint[] _amounts
    );
    event LockerProxySet(address indexed lockerProxy);

    /**
     * @dev Raised when called by invalid caller
     */
    error InvalidCaller();

    error Unauthorized();

    function send(
        address _from,
        address _to,
        uint16 _dstChainId,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external payable;
}
