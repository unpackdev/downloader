// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC165.sol";
import "./ERC721Structs.sol";

interface IOmniseaPortal is IERC165 {
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, address indexed _sender, bytes _toAddress, uint _tokenId);
    event ReceiveFromChain(uint16 indexed _srcChainId, bytes indexed _srcAddress, address indexed _toAddress, uint _tokenId);
    event CreatedOnDestination(address indexed collection, bytes32 collectionId);
    event SuccessReceiverCall(address indexed receiver, uint16 indexed _srcChainId, EncodedSendParams _sendParams);
    event FailedReceiverCall(address indexed receiver, uint16 indexed _srcChainId, EncodedSendParams _sendParams);

    function sendFrom(address _collection, uint _tokenId, bytes calldata _signature, LzParams memory _lzParams, SendParams memory _sendParams) external payable;

    function estimateSendFee(address _collection, uint16 _dstChainId, uint _tokenId, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    function circulatingSupply(address _collection) external view returns (uint);
}
