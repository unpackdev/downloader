// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./NonblockingLzApp.sol";
import "./IOmniseaERC721.sol";
import "./OmniseaERC721Proxy.sol";
import "./IOmniseaONFTReceiver.sol";
import "./IOmniseaPortal.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Structs.sol";
import "./ERC165.sol";
import "./ECDSA.sol";

contract OmniseaPortal is NonblockingLzApp, ERC165, IOmniseaPortal, ReentrancyGuard {
    using ECDSA for bytes32;

    uint16 public constant FUNCTION_TYPE_SEND = 1;
    uint16 public immutable lzChainId;
    mapping(address => bytes32) public collectionToId;
    mapping(bytes32 => address) public idToCollection;
    uint256 public minGasToTransferAndStore; // min amount of gas required to transfer, and also store the payload
    mapping(uint16 => uint256) public dstChainIdToTransferGas; // per transfer amount of gas required to mint/transfer on the dst
    uint256 public fixedFee;
    uint256 public collectionFee; // 0.006 ETH will be used to buyback OSEA each quarter
    address internal revenueManager;
    address internal oseaRevenueManager;

    constructor(uint16 lzChainId_, address _lzEndpoint, uint256 _minGasToTransferAndStore) NonblockingLzApp(_lzEndpoint) {
        minGasToTransferAndStore = _minGasToTransferAndStore;
        revenueManager = address(0xf0E4e9310527f9917A730008bd98852A928A8d04);
        oseaRevenueManager = address(0xf0E4e9310527f9917A730008bd98852A928A8d04);
        fixedFee = 100000000000000;
        collectionFee = 0;
        lzChainId = lzChainId_;
    }

    function setFixedFee(uint256 _fee) external onlyOwner {
        fixedFee = _fee;
    }

    function setOSEAFee(uint256 _fee) external onlyOwner {
        collectionFee = _fee;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IOmniseaPortal).interfaceId || super.supportsInterface(interfaceId);
    }

    function estimateSendFee(address _collection, uint16 _dstChainId, uint _tokenId, bool _useZro, bytes calldata _adapterParams) public view virtual override returns (uint nativeFee, uint zroFee) {
        address collection = _collection;
        bytes32 collectionId = keccak256(abi.encode(msg.sender, lzChainId));
        IOmniseaERC721 collectionContract = IOmniseaERC721(collection);
        BasicCollectionParams memory collectionParams = BasicCollectionParams({
            tokenId: _tokenId,
            name: collectionContract.name(),
            symbol: collectionContract.symbol(),
            uri: collectionContract.contractURI(),
            tokenURI: collectionContract.tokenURI(_tokenId),
            owner: msg.sender
        });
        EncodedSendParams memory encodedSendParams = EncodedSendParams({
            from: abi.encode(address(this)),
            toAddress: abi.encode(address(this)),
            sender: abi.encode(address(this)),
            payloadForCall: bytes("")
        });
        bytes memory payload;
        {
            payload = abi.encode(collectionParams, collectionId, encodedSendParams);
        }
        uint16 dstChainId = _dstChainId;
        bool useZro = _useZro;
        bytes memory adapterParams = _adapterParams;
        {
            (nativeFee, zroFee) = lzEndpoint.estimateFees(dstChainId, address(this), payload, useZro, adapterParams);

            nativeFee += fixedFee;

            if (collectionToId[collection] == bytes32(0) && collectionFee > 0) {
                nativeFee += collectionFee;
            }
        }
    }

    function sendFrom(address _collection, uint _tokenId, bytes calldata _signature, LzParams memory _lzParams, SendParams memory _sendParams) public payable virtual override nonReentrant {
        // Stack too deep workaround
        address from = _sendParams.from;
        address collection = _collection;

        require(msg.sender == _sendParams.sender, "!=sender");
        {
            if (msg.sender != from) {
                _verifySignature(_tokenId, from, _signature);
            }
        }

        _send(_tokenId, collection, _lzParams, _sendParams);
    }

    function circulatingSupply(address _collection) external view returns (uint) {
        IOmniseaERC721 collection = IOmniseaERC721(_collection);

        return collection.totalSupply() - collection.balanceOf(address(this));
    }

    function _getLzParams(
        uint16 _dstChainId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal view virtual returns (LzParams memory) {
        return LzParams({
            dstChainId: _dstChainId,
            zroPaymentAddress: _zroPaymentAddress,
            adapterParams: _adapterParams,
            refundAddress: _refundAddress
        });
    }

    function _getBasicCollectionParams(address _collection, uint _tokenId) internal virtual returns (BasicCollectionParams memory) {
        IOmniseaERC721 collection = IOmniseaERC721(_collection);

        address owner_;
        {
            // Try calling owner() method
            (bool successOwner, bytes memory dataOwner) = _collection.call(abi.encodeWithSignature("owner()"));
            if (successOwner) {
                owner_ = abi.decode(dataOwner, (address));
            }
        }

        return BasicCollectionParams({
            tokenId: _tokenId,
            name: collection.name(),
            symbol: collection.symbol(),
            uri: collection.contractURI(),
            tokenURI: collection.tokenURI(_tokenId),
            owner: owner_
        });
    }

    function _send(
        uint _tokenId,
        address _collection,
        LzParams memory _lzParams,
        SendParams memory _sendParams
    ) internal virtual {
        address collection = _collection;

        BasicCollectionParams memory collectionParams = _getBasicCollectionParams(collection, _tokenId);
        bytes32 collectionId;
        bool isFirstTime;
        {
            collectionId = collectionToId[collection];
            isFirstTime = collectionId == bytes32(0);
            if (isFirstTime) {
                // First-time bridging this collection - Generate ID
                collectionId = keccak256(abi.encode(collection, lzChainId));
                idToCollection[collectionId] = collection;
                collectionToId[collection] = collectionId;
            }
        }

        // Workaround for Stack Too Deep
        uint16 dstChainId = _lzParams.dstChainId;
        address zroPaymentAddress = _lzParams.zroPaymentAddress;
        address payable refundAddress = _lzParams.refundAddress;
        bytes memory adapterParams = _lzParams.adapterParams;
        bytes memory toAddress = _sendParams.toAddress;
        address sender = _sendParams.sender;
        address from = _sendParams.from;

        _debitFrom(from, collection, collectionParams.tokenId);

        {
            EncodedSendParams memory encodedSendParams = EncodedSendParams({
                toAddress: toAddress,
                sender: abi.encode(sender),
                from: abi.encode(from),
                payloadForCall: _sendParams.payloadForCall
            });
            bytes memory payload = abi.encode(collectionParams, collectionId, encodedSendParams);
            _checkGasLimit(dstChainId, FUNCTION_TYPE_SEND, adapterParams, dstChainIdToTransferGas[dstChainId]);
            (uint nativeFee) = _payONFTFee(msg.value, isFirstTime);
            _lzSend(dstChainId, payload, refundAddress, zroPaymentAddress, adapterParams, nativeFee);
        }

        emit SendToChain(dstChainId, from, sender, toAddress, collectionParams.tokenId);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal virtual override {
        (BasicCollectionParams memory _collectionParams, bytes32 _collectionId, EncodedSendParams memory _sendParams) = abi.decode(_payload, (BasicCollectionParams, bytes32, EncodedSendParams));

        bytes memory toAddressBytes = _sendParams.toAddress;
        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        address collection = idToCollection[_collectionId];
        if (collection == address(0)) {
            OmniseaERC721Proxy proxy = new OmniseaERC721Proxy();
            collection = address(proxy);
            IOmniseaERC721(collection).initialize(_collectionParams, _collectionId);
            idToCollection[_collectionId] = collection;
            collectionToId[collection] = _collectionId;
            emit CreatedOnDestination(collection, _collectionId);
        }

        _creditTo(_srcChainId, collection, toAddress, _collectionParams.tokenId, _collectionParams.tokenURI);
        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, _collectionParams.tokenId);

        {
            if (_sendParams.payloadForCall.length > 0) {
                try IOmniseaONFTReceiver(toAddress).onONFTReceived(_srcChainId, _sendParams) {
                    emit SuccessReceiverCall(toAddress, _srcChainId, _sendParams);
                } catch (bytes memory /*lowLevelData*/) {
                    emit FailedReceiverCall(toAddress, _srcChainId, _sendParams);
                }
            }
        }
    }

    // limit on src the amount of tokens to batch send
    function setDstChainIdToLimits(uint16 _dstChainId, uint256 _dstChainIdToTransferGas, uint256 _minGasToTransferAndStore) external onlyOwner {
        dstChainIdToTransferGas[_dstChainId] = _dstChainIdToTransferGas;
        minGasToTransferAndStore = _minGasToTransferAndStore;
    }

    function _payONFTFee(uint _nativeFee, bool _isFirstTransfer) internal virtual returns (uint amount) {
        uint collectionFee_ = (_isFirstTransfer && collectionFee > 0) ? collectionFee : 0;
        uint fee = fixedFee;
        amount = _nativeFee - fee - collectionFee_;

        if (fee > 0) {
            (bool p1,) = payable(revenueManager).call{value : (fixedFee)}("");
            require(p1);
        }

        if (collectionFee_ > 0) {
            (bool p2,) = payable(oseaRevenueManager).call{value : (collectionFee_)}("");
            require(p2);
        }
    }

    function _debitFrom(address _from, address _collection, uint _tokenId) internal virtual {
        IOmniseaERC721 collection = IOmniseaERC721(_collection);
        require(collection.ownerOf(_tokenId) == _from);
        collection.transferFrom(_from, address(this), _tokenId);
    }

    function _creditTo(uint16, address _collection, address _toAddress, uint _tokenId, string memory _tokenURI) internal virtual {
        IOmniseaERC721 collection = IOmniseaERC721(_collection);
        (bool exists, address ownedBy) = _tokenExistsAndOwnerOf(collection, _tokenId);

        require(!exists || (exists && ownedBy == address(this)));
        if (exists) {
            collection.transferFrom(address(this), _toAddress, _tokenId);
            return;
        }
        collection.mint(_toAddress, _tokenId, _tokenURI);
    }

    function _tokenExistsAndOwnerOf(IOmniseaERC721 _collection, uint _tokenId) internal view returns (bool, address) {
        try _collection.ownerOf(_tokenId) returns (address _owner) {
            return (true, _owner);
        } catch {
            return (false, address(0));
        }
    }

    function _verifySignature(uint256 tokenId, address expectedSigner, bytes memory signature) internal pure {
        bytes32 messageHash = keccak256(abi.encodePacked(tokenId));
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address recoveredAddress = ECDSA.recover(prefixedHash, signature);
        require(recoveredAddress == expectedSigner, "Invalid signature");
    }
}
