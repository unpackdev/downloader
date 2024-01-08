// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./BaseRelayRecipient.sol";
import "./IERC20.sol";
import "./ERC1155Receiver.sol";
import "./IERC721Receiver.sol";
import "./ERC777Receiver.sol";
import "./IERC677Receiver.sol";
import "./BytesLib.sol";
import "./IERC3156FlashBorrower.sol";

//generalized batching solution
//mainnet:0xcF47Edc5454759F594A6D3A4B17457C36ea8e047

//TODO: add a way to check the ineqaylity of state (balances of tokens/ETH)
//see https://github.com/kendricktan/mev-briber/blob/main/contracts/FlashbotsCheckAndSend.sol#L74
contract Upkaran is
    Ownable,
    BaseRelayRecipient,
    ERC1155Receiver,
    IERC721Receiver,
    IERC3156FlashBorrower,
    ERC777Receiver,
    IERC677Receiver
{
    using BytesLib for bytes;

    struct Call {
        address to;
        bytes data;
        uint256 value;
    }

    constructor(address forwarder) public {
        //0x150b7a02 is ERC-165 identifier for function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
        _registerInterface(0x150b7a02);
        trustedForwarder = forwarder;
    }

    function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
        trustedForwarder = _trustedForwarder;
    }

    function versionRecipient() external view override returns (string memory) {
        return '1';
    }

    //receive eth
    receive() external payable {}

    function batch(Call[] memory calls) public payable {
        // external with ABIEncoderV2 Struct is not supported in solidity < 0.6.4
        for (uint256 i = 0; i < calls.length; i++) {
            _call(calls[i].to, calls[i].value, calls[i].data);
        }
    }

    //send eth to miner
    function sendToCoinbaseETH() public payable {
        block.coinbase.transfer(msg.value);
    }

    function _msgSender()
        internal
        view
        override(Context, BaseRelayRecipient)
        returns (address payable)
    {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, BaseRelayRecipient)
        returns (bytes memory)
    {
        return BaseRelayRecipient._msgData();
    }

    function _call(
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        //require that if data is equal to transferFrom function signature then "from" is equal to msg.sender
        if (data.toBytes4(0) == IERC20(0).transferFrom.selector) {
            require(
                data.toAddress(16) == _msgSender(), // 16+4(the function selector) = 20
                'Upkaran/transferFrom-not-allowed'
            );
        }
        (bool success, ) = to.call{value: value}(data);
        // (bool success, ) = to.call.value(value)(data);
        if (!success) {
            assembly {
                let returnDataSize := returndatasize()
                returndatacopy(0, 0, returnDataSize)
                revert(0, returnDataSize)
            }
        }
    }

    function _decodeAndCall(bytes calldata data) internal {
        if (!data.equal('')) {
            Call[] memory calls = abi.decode(data, (Call[]));
            batch(calls);
        }
    }

    /**
     * @dev Receive a flash loan.
     * unUsedParam initiator The initiator of the loan.*
     * unUsedParam token The loan currency.
     * unUsedParam amount The amount of tokens lent.
     * unUsedParam fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address, /*initiator*/
        address, /*token*/
        uint256, /*amount*/
        uint256, /*fee*/
        bytes calldata data
    ) external override returns (bytes32) {
        _decodeAndCall(data);
        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        unUsedParam operator The address which initiated the transfer (i.e. _msgSender())
        unUsedParam from The address which previously owned the token
        unUsedParam id The ID of the token being transferred
        unUsedParam value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata data
    ) external override returns (bytes4) {
        _decodeAndCall(data);
        return ERC1155Receiver(0).onERC1155Received.selector;
    }

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        unUsedParam operator The address which initiated the batch transfer (i.e. _msgSender())
        unUsedParam from The address which previously owned the token
        unUsedParam ids An array containing ids of each token being transferred (order and length must match values array)
        unUsedParam values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata data
    ) external override returns (bytes4) {
        _decodeAndCall(data);
        return ERC1155Receiver(0).onERC1155BatchReceived.selector;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*tokenId*/
        bytes calldata data
    ) external override returns (bytes4) {
        _decodeAndCall(data);
        return IERC721Receiver.onERC721Received.selector;
    }

    function _tokensReceived(bytes calldata data) internal override {
        _decodeAndCall(data);
    }

    function onTokenTransfer(
        address, /*from*/
        uint256, /*amount*/
        bytes calldata data
    ) external override returns (bool success) {
        _decodeAndCall(data);
        return true;
    }
}
