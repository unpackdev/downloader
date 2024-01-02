// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";

import "./IReceiverVerifier.sol";
import "./Structs.sol";
import "./IERC1155Router.sol";
import "./IERC1155LockerProxy.sol";

contract ERC1155LockerProxy is
    IERC1155LockerProxy,
    IReceiverVerifier,
    Ownable,
    ERC1155Holder
{
    /// @notice Address of ERC1155 contract.
    IERC1155 public immutable erc1155;

    /// @notice Router contract that send off cross chain message.
    address public router;

    /**
     * @param _router Router address
     * @param _erc1155 Erc1155 address
     */
    constructor(address _router, IERC1155 _erc1155) {
        router = _router;
        erc1155 = _erc1155;
    }

    receive() external payable {}

    /**
     * @notice Bridges over asset from the src address to destination address to destination chain.
     * @dev User has to setApprovalForAll to this contract first
     * @param _from The address that is bridging assets
     * @param _dstChainId Destination chain id
     * @param _to Destination address that will receive the assets
     * @param _tokenId Token id being bridged
     * @param _amount Amount of the token id being bridged
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        address _to,
        uint _tokenId,
        uint _amount
    ) external payable {
        _sendFrom(
            _from,
            _dstChainId,
            _to,
            _toSingletonArray(_tokenId),
            _toSingletonArray(_amount)
        );
    }

    /**
     * @notice Bridges over assets from the src address to destination address to destination chain.
     * @dev User has to setApprovalForAll to this contract first
     * @param _from The address that is bridging assets
     * @param _dstChainId Destination chain id
     * @param _to Destination address that will receive the assets
     * @param _tokenIds Token ids being bridged
     * @param _amounts Amounts of each token id being bridged
     */
    function sendBatchFrom(
        address _from,
        uint16 _dstChainId,
        address _to,
        uint[] memory _tokenIds,
        uint[] memory _amounts
    ) external payable {
        _sendFrom(_from, _dstChainId, _to, _tokenIds, _amounts);
    }

    /**
     * @notice Invoke handler
     * @param _from The address that is bridging assets
     * @param _ethValue Eth amount being passed in
     * @param _tokenIds Token ids to bridge
     * @param _tokenQuantities Amounts of each token id
     * @param _data arbitrary data that contains destination address and chain
     */
    function handleInvoke(
        address _from,
        RouterEndpoint calldata,
        uint256 _ethValue,
        uint256,
        uint256[] calldata _tokenIds,
        uint256[] calldata _tokenQuantities,
        bytes memory _data
    ) external {
        if (msg.sender != address(erc1155)) revert InvalidCaller();

        (address to, uint16 dstChainId) = abi.decode(_data, (address, uint16));

        _routerSend(
            _from,
            dstChainId,
            to,
            _tokenIds,
            _tokenQuantities,
            _ethValue
        );
    }

    /**
     * @notice Called by the Router when a message is received
     * @param _to The address that will have its tokens unlocked
     * @param _tokenIds TokenIds to unlock
     * @param _amounts Amount of tokens to unlock
     */
    function unlock(
        address _to,
        uint16 _srcChainId,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external {
        if (msg.sender != router) revert InvalidCaller();

        erc1155.safeBatchTransferFrom(
            address(this),
            _to,
            _tokenIds,
            _amounts,
            ""
        );

        emit AssetsUnlocked(_to, _srcChainId, _tokenIds, _amounts);
    }

    /**
     * @notice Sets new router address
     * @dev Only callable by the owner.
     * @param _router new router address
     */
    function setRouter(address _router) external onlyOwner {
        router = _router;
        emit RouterSet(_router);
    }

    /**
     * @notice Helper function that checks for approval
     * @param _from The address that is bridging assets
     * @param _dstChainId Destination chain id
     * @param _to Destination address that will receive the assets
     * @param _tokenIds Token ids being bridged
     * @param _amounts Amounts of each token id being bridged
     */
    function _sendFrom(
        address _from,
        uint16 _dstChainId,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) internal {
        if (
            _from != _msgSender() &&
            !erc1155.isApprovedForAll(_from, _msgSender())
        ) {
            revert InvalidCaller();
        }

        erc1155.safeBatchTransferFrom(
            _from,
            address(this),
            _tokenIds,
            _amounts,
            ""
        );

        _routerSend(_from, _dstChainId, _to, _tokenIds, _amounts, msg.value);
    }

    /**
     * @notice Helper function that calls the router
     * @param _from The address that is bridging assets
     * @param _dstChainId Destination chain id
     * @param _to Destination address that will receive the assets
     * @param _tokenIds Token ids being bridged
     * @param _amounts Amounts of each token id being bridged
     * @param _ethValue The amount of eth passed for paying bridging fees
     */
    function _routerSend(
        address _from,
        uint16 _dstChainId,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256 _ethValue
    ) internal {
        IERC1155Router(router).send{ value: _ethValue }(
            _from,
            _to,
            _dstChainId,
            _tokenIds,
            _amounts
        );

        emit AssetsLocked(_from, _to, _dstChainId, _tokenIds, _amounts);
    }

    /**
     * @notice Helper function to convert an element to a singleton list
     * @param _element The element to convert
     */
    function _toSingletonArray(
        uint256 _element
    ) internal pure returns (uint[] memory) {
        uint[] memory array = new uint[](1);
        array[0] = _element;
        return array;
    }
}
