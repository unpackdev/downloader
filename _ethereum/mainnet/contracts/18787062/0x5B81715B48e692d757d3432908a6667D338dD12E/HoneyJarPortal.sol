// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC721.sol";

import "./IERC721Receiver.sol";
import "./ERC165Checker.sol";

import "./ONFT721Core.sol";

import "./IHibernationDen.sol";
import "./IHoneyJarPortal.sol";
import "./CrossChainTHJ.sol";
import "./GameRegistryConsumer.sol";
import "./Constants.sol";
import "./IHoneyJar.sol";

/// @title HoneyJarPortal
/// @notice Manages cross chain business logic and interactions with HoneyJar NFT
/// @dev Modeled off of @layerzero/token/onft/extension/ProxyONFT721.sol
/// @dev setTrustedRemote must be called when initializing`
contract HoneyJarPortal is IHoneyJarPortal, GameRegistryConsumer, CrossChainTHJ, ONFT721Core, IERC721Receiver {
    using ERC165Checker for address;

    // Events
    event StartCrossChainGame(uint256 chainId, uint8 bundleId, uint256 numSleepers);
    event SendFermentedJars(uint256 destChainId_, uint8 bundleId_, uint256[] fermentedJarIds_);
    event MessageRecieved(bytes payload);
    event HibernationDenSet(address denAddress);
    event StartGameProcessed(uint256 srcChainId, StartGamePayload);
    event FermentedJarsProcessed(uint256 srcChainId, FermentedJarsPayload);
    event LzMappingSet(uint256 evmChainId, uint16 lzChainId);
    event AdapterParamsSet(MessageTypes msgType, uint16 version, uint256 gasLimit);

    // Errors
    error InvalidToken(address tokenAddress);
    error HoneyJarNotInPortal(uint256 tokenId);
    error OwnerNotCaller();
    error LzMappingMissing(uint256 chainId);

    enum MessageTypes {
        SEND_NFT,
        START_GAME,
        SET_FERMENTED_JARS
    }

    // Dependencies
    IHoneyJar public immutable honeyJar;
    IHibernationDen public hibernationDen;

    // Internal State
    /// @notice mapping of chainId --> lzChainId
    /// @dev see https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
    mapping(uint256 => uint16) public lzChainId;
    /// @notice mapping of lzChainId --> realChainId
    mapping(uint16 => uint256) public realChainId;

    /// @notice adapter params for each messageType
    mapping(MessageTypes => bytes) public msgAdapterParams;

    constructor(uint256 _minGasToTransfer, address _lzEndpoint, address _honeyJar, address _den, address _gameRegistry)
        ONFT721Core(_minGasToTransfer, _lzEndpoint)
        GameRegistryConsumer(_gameRegistry)
    {
        if (!_honeyJar.supportsInterface(type(IERC721).interfaceId)) revert InvalidToken(_honeyJar);
        honeyJar = IHoneyJar(_honeyJar);
        hibernationDen = IHibernationDen(_den);

        // Initial state
        // https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids#polygon-zkevm
        _setLzMapping(1, 101); // mainnet
        _setLzMapping(5, 10121); //Goerli
        _setLzMapping(42161, 110); // Arbitrum
        _setLzMapping(421613, 10143); //Atrbitrum goerli
        _setLzMapping(10, 111); //Optimism
        _setLzMapping(420, 10132); // Optimism Goerli
        _setLzMapping(137, 109); // Polygon
        _setLzMapping(80001, 10109); // Mumbai
        _setLzMapping(1101, 158); // Polygon zkEVM
        _setLzMapping(1442, 10158); // Polygon zkEVM testnet
        _setLzMapping(10106, 106); // Avalanche - Fuji

        _setAdapterParams(MessageTypes.START_GAME, 1, 500000);
        _setAdapterParams(MessageTypes.SET_FERMENTED_JARS, 1, 500000);
    }

    ///////////////////////////////////////////////////////////
    //////////////////  Admin Functions     ///////////////////
    ///////////////////////////////////////////////////////////

    /// @dev there can only be one honeybox per portal.
    function setHibernationDen(address denAddress_) external onlyRole(Constants.GAME_ADMIN) {
        hibernationDen = IHibernationDen(denAddress_);

        emit HibernationDenSet(denAddress_);
    }

    function setLzMapping(uint256 evmChainId, uint16 lzChainId_) external onlyRole(Constants.GAME_ADMIN) {
        _setLzMapping(evmChainId, lzChainId_);
    }

    function setAdapterParams(MessageTypes msgType, uint16 version, uint256 gasLimit)
        external
        onlyRole(Constants.GAME_ADMIN)
    {
        _setAdapterParams(msgType, version, gasLimit);
    }

    function _setAdapterParams(MessageTypes msgType, uint16 version, uint256 gasLimit) internal {
        msgAdapterParams[msgType] = abi.encodePacked(version, gasLimit);

        emit AdapterParamsSet(msgType, version, gasLimit);
    }

    function _setLzMapping(uint256 evmChainId, uint16 lzChainId_) internal {
        lzChainId[evmChainId] = lzChainId_;
        realChainId[lzChainId_] = evmChainId;

        emit LzMappingSet(evmChainId, lzChainId_);
    }

    // Needs to be public since the overriding function in ONFT is public
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////////////
    //////////////////  ONFT Transfer        ///////////////////
    ////////////////////////////////////////////////////////////

    /// @notice burns the token that is bridged. Contract needs BURNER role
    function _debitFrom(address _from, uint16, bytes memory, uint256 _tokenId) internal override {
        if (honeyJar.ownerOf(_tokenId) != _msgSender()) revert OwnerNotCaller();

        honeyJar.burn(_tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint256 _tokenId) internal override {
        // This shouldn't happen, but just in case.
        if (_exists(_tokenId) && honeyJar.ownerOf(_tokenId) != address(this)) revert HoneyJarNotInPortal(_tokenId);
        if (!_exists(_tokenId)) {
            honeyJar.mintTokenId(_toAddress, _tokenId); //HoneyJar Portal should have MINTER Perms on HoneyJar
        } else {
            honeyJar.safeTransferFrom(address(this), _toAddress, _tokenId);
        }
    }

    /// @notice slightly modified version of the _send method in ONFTCore.
    /// @dev payload is encoded with messageType to be able to consume different message types.
    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256[] memory _tokenIds,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal override {
        // allow 1 by default
        require(_tokenIds.length > 0, "LzApp: tokenIds[] is empty");
        require(
            _tokenIds.length == 1 || _tokenIds.length <= dstChainIdToBatchLimit[_dstChainId],
            "ONFT721: batch size exceeds dst batch limit"
        );

        address toAddress;
        assembly {
            toAddress := mload(add(_toAddress, 20))
        }

        bytes memory payload = _encodeSendNFT(toAddress, _tokenIds);

        _checkGasLimit(
            _dstChainId,
            uint16(MessageTypes.SEND_NFT),
            _adapterParams,
            dstChainIdToTransferGas[_dstChainId] * _tokenIds.length
        );

        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _debitFrom(_from, _dstChainId, _toAddress, _tokenIds[i]);
        }

        _lzSend(_dstChainId, payload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit SendToChain(_dstChainId, _from, _toAddress, _tokenIds);
    }

    //////////////////////////////////////////////////////
    //////////////////  Game Methods  //////////////////
    //////////////////////////////////////////////////////

    /// @notice should only be called from ETH (ChainId=1)
    /// @notice Caller MUST estimate fees and pass in appropriate value to this method.
    /// @dev can only be called by game instances
    /// @dev estimated gas around 492236 - 642115
    function sendStartGame(
        address payable refundAddress_,
        uint256 destChainId_,
        uint8 bundleId_,
        uint256 numSleepers_,
        uint256[] calldata checkpoints_
    ) external payable override onlyRole(Constants.GAME_INSTANCE) {
        uint16 lzDestId = lzChainId[destChainId_];
        if (lzDestId == 0) revert LzMappingMissing(destChainId_);
        bytes memory adapterParams = msgAdapterParams[MessageTypes.START_GAME];

        // Will check adapterParams against minDstGas
        _checkGasLimit(
            lzDestId,
            uint16(MessageTypes.START_GAME),
            adapterParams,
            1000 * numSleepers_ // Padding for each NFT being stored
        );

        bytes memory payload = _encodeStartGame(bundleId_, numSleepers_, checkpoints_);
        _lzSend(lzDestId, payload, refundAddress_, address(0x0), adapterParams, msg.value);

        emit StartCrossChainGame(destChainId_, bundleId_, numSleepers_);
    }

    /// @notice caller must estimate gas and send as msg.value.
    /// @param destChainId_ real chainId the message is sent to (should be L1)
    /// @param bundleId_ the bundleId
    /// @param fermentedJarIds_ list of jars to be fermented.
    function sendFermentedJars(
        address payable refundAddress_,
        uint256 destChainId_,
        uint8 bundleId_,
        uint256[] calldata fermentedJarIds_
    ) external payable override onlyRole(Constants.GAME_INSTANCE) {
        uint16 lzDestId = lzChainId[destChainId_];
        if (lzDestId == 0) revert LzMappingMissing(destChainId_);
        bytes memory adapterParams = msgAdapterParams[MessageTypes.SET_FERMENTED_JARS];

        _checkGasLimit(
            lzDestId,
            uint16(MessageTypes.SET_FERMENTED_JARS),
            adapterParams,
            1000 * fermentedJarIds_.length // Padding for each NFT being stored
        );

        bytes memory payload = _encodeFermentedJars(bundleId_, fermentedJarIds_);
        _lzSend(lzDestId, payload, refundAddress_, address(0x0), bytes(""), msg.value);

        emit SendFermentedJars(destChainId_, bundleId_, fermentedJarIds_);
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal override {
        (MessageTypes msgType) = abi.decode(_payload, (MessageTypes));
        address srcAddress;
        assembly {
            srcAddress := mload(add(_srcAddress, 20))
        }

        if (msgType == MessageTypes.SEND_NFT) {
            _processSendNFTMessage(_srcChainId, _srcAddress, _payload);
        } else if (msgType == MessageTypes.START_GAME) {
            _processStartGame(_srcChainId, _payload);
        } else if (msgType == MessageTypes.SET_FERMENTED_JARS) {
            _processFermentedJars(_srcChainId, _payload);
        } else {
            emit MessageRecieved(_payload);
        }
    }

    ////////////////////////////////////////////////////////////
    //////////////////  Message Processing   ///////////////////
    ////////////////////////////////////////////////////////////

    function _processStartGame(uint16 srcChainId, bytes memory _payload) internal {
        uint256 realSrcChainId = realChainId[srcChainId];
        if (realSrcChainId == 0) revert LzMappingMissing(srcChainId);
        StartGamePayload memory payload = _decodeStartGame(_payload);
        hibernationDen.startGame(realSrcChainId, payload.bundleId, payload.numSleepers, payload.checkpoints);

        emit StartGameProcessed(realSrcChainId, payload);
    }

    function _processFermentedJars(uint16 srcChainId, bytes memory _payload) internal {
        uint256 realSrcChainId = realChainId[srcChainId];
        if (realSrcChainId == 0) revert LzMappingMissing(srcChainId);
        FermentedJarsPayload memory payload = _decodeFermentedJars(_payload);
        hibernationDen.setCrossChainFermentedJars(payload.bundleId, payload.fermentedJarIds);

        emit FermentedJarsProcessed(realSrcChainId, payload);
    }

    /// @notice a copy of the OFNFT721COre _nonBlockingrcv to keep NFT functionality the same.
    function _processSendNFTMessage(uint16 _srcChainId, bytes memory _srcAddress, bytes memory _payload) internal {
        SendNFTPayload memory payload = _decodeSendNFT(_payload);

        uint256 nextIndex = _creditTill(_srcChainId, payload.to, 0, payload.tokenIds);
        if (nextIndex < payload.tokenIds.length) {
            // not enough gas to complete transfers, store to be cleared in another tx
            bytes32 hashedPayload = keccak256(_payload);
            storedCredits[hashedPayload] = StoredCredit(_srcChainId, payload.to, nextIndex, true);
            emit CreditStored(hashedPayload, _payload);
        }

        emit ReceiveFromChain(_srcChainId, _srcAddress, payload.to, payload.tokenIds);
    }

    //////////////////////////////////////////////////////
    //////////////////  Encode/Decode   //////////////////
    //////////////////////////////////////////////////////

    struct StartGamePayload {
        uint8 bundleId;
        uint256 numSleepers;
        uint256[] checkpoints;
    }

    struct SendNFTPayload {
        address to;
        uint256[] tokenIds;
    }

    struct FermentedJarsPayload {
        uint8 bundleId;
        uint256[] fermentedJarIds;
    }

    function _encodeSendNFT(address to, uint256[] memory tokenIds) internal pure returns (bytes memory) {
        return abi.encode(MessageTypes.SEND_NFT, SendNFTPayload(to, tokenIds));
    }

    function _encodeStartGame(uint8 bundleId_, uint256 numSleepers_, uint256[] memory checkpoints_)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(MessageTypes.START_GAME, StartGamePayload(bundleId_, numSleepers_, checkpoints_));
    }

    function _encodeFermentedJars(uint8 bundleId_, uint256[] memory fermentedJarIds_)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(MessageTypes.SET_FERMENTED_JARS, FermentedJarsPayload(bundleId_, fermentedJarIds_));
    }

    function _decodeSendNFT(bytes memory _payload) internal pure returns (SendNFTPayload memory payload) {
        (, payload) = abi.decode(_payload, (MessageTypes, SendNFTPayload));
    }

    function _decodeStartGame(bytes memory _payload) internal pure returns (StartGamePayload memory payload) {
        (, payload) = abi.decode(_payload, (MessageTypes, StartGamePayload));
    }

    function _decodeFermentedJars(bytes memory _payload) internal pure returns (FermentedJarsPayload memory) {
        (, FermentedJarsPayload memory payload) = abi.decode(_payload, (MessageTypes, FermentedJarsPayload));
        return payload;
    }

    /////////////////////////////////////////////
    //////////////////  Misc   //////////////////
    /////////////////////////////////////////////

    function onERC721Received(address _operator, address, uint256, bytes memory)
        public
        view
        override
        returns (bytes4)
    {
        // only allow `this` to transfer token from others
        if (_operator != address(this)) return bytes4(0);
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice check if a tokenId exists on the chain
    /// @dev erc721.ownerOf reverts, needed to continue functioning
    function _exists(uint256 tokenId) internal view returns (bool) {
        try honeyJar.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }
}
