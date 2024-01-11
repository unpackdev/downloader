// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ICallProxy.sol";
import "./IDeBridgeGate.sol";
import "./IDeNFT.sol";
import "./INFTBridge.sol";
import "./DeBridgeGate.sol";
import "./DeBridgeNFTDeployer.sol";
import "./Flags.sol";

contract NFTBridge is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable,
    INFTBridge
{
    using AddressUpgradeable for address payable;
    using AddressUpgradeable for address;

    uint256 public constant TOKEN_BURNABLE_TYPE = 1;

    /* ========== STATE VARIABLES ========== */

    /// @dev Maps debridgeId => nft bridge-specific information.
    mapping(bytes32 => BridgeNFTInfo) public getBridgeNFTInfo;
    /// @dev Returns native token info by token address
    mapping(address => NativeNFTInfo) public getNativeInfo;
    /// @dev Returns brdige address in another chain
    mapping(uint256 => ChainInfo) public getChainInfo;

    /// @dev DeBridgeGate address
    DeBridgeGate public deBridgeGate;
    /// @dev Address of nft deployer
    DeBridgeNFTDeployer public deBridgeNFTDeployer;

    /// @dev outgoing submissions count
    uint256 public nonce;

    /// @dev nft's created by platform
    mapping(address => uint256) public createdTokens;

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert AdminBadRole();
        _;
    }

    modifier onlyCrossBridgeAddress() {
        ICallProxy callProxy = ICallProxy(deBridgeGate.callProxy());
        if (address(callProxy) != msg.sender) {
            revert CallProxyBadRole();
        }

        bytes memory nativeSender = callProxy.submissionNativeSender();
        uint256 chainIdFrom = callProxy.submissionChainIdFrom();

        if (keccak256(getChainInfo[chainIdFrom].nftBridgeAddress) != keccak256(nativeSender)) {
            revert NativeSenderBadRole(nativeSender, chainIdFrom);
        }
        _;
    }

    /* ========== CONSTRUCTOR  ========== */

    function initialize(DeBridgeGate _deBridgeGate) public initializer {
        deBridgeGate = _deBridgeGate;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== send, claim ========== */

    /// @dev This method is used for the transfer of assets [from the native chain](https://docs.debridge.finance/the-core-protocol/transfers#transfer-from-native-chain).
    /// It locks an asset in the smart contract in the native chain and enables minting of nft on the secondary chain.
    /// @param _tokenAddress nft Asset identifier.
    /// @param _tokenId Token Id to be transfered
    /// @param _chainIdTo Chain id of the target chain.
    /// @param _receiver Receiver address in target chain who will receive nft.
    /// @param _executionFee  Fee paid to the transaction executor in target chain.
    /// @param _referralCode Referral code
    function send(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _permitDeadline,
        bytes memory _permitSignature,
        uint256 _chainIdTo,
        address _receiver,
        uint256 _executionFee,
        uint32 _referralCode
    ) external payable nonReentrant whenNotPaused {
        if (!getChainInfo[_chainIdTo].isSupported) {
            revert ChainToIsNotSupported();
        }

        // run permit first
        if (_permitSignature.length > 0) {
            IERC4494(_tokenAddress).permit(
                address(this),
                _tokenId,
                _permitDeadline,
                _permitSignature
            );
        }

        bool isNativeToken;
        bytes memory targetData;
        {
            NativeNFTInfo storage nativeTokenInfo = getNativeInfo[_tokenAddress];
            isNativeToken = nativeTokenInfo.chainId == 0
                ? true // token not in mapping
                : nativeTokenInfo.chainId == getChainId(); // token native chain id the same

            // encode function that will be called in target chain
            string memory tokenURI = IERC721MetadataUpgradeable(_tokenAddress).tokenURI(_tokenId);
            if (isNativeToken) {
                if (createdTokens[_tokenAddress] == TOKEN_BURNABLE_TYPE) {
                    _checkAddAsset(_tokenAddress);
                    IDeNFT(_tokenAddress).burn(_tokenId);
                } else {
                    _receiveNativeNFT(_tokenAddress, _tokenId);
                }
            } else {
                IDeNFT(_tokenAddress).burn(_tokenId);
            }

            // encode function that will be called in target chain
            targetData = nativeTokenInfo.chainId == _chainIdTo &&
                nativeTokenInfo.tokenType != TOKEN_BURNABLE_TYPE // is sending to native chain
                ? _encodeClaim(
                    _decodeAddressFromBytes(nativeTokenInfo.tokenAddress), // _decodeAddressFromBytes support only emv tokens now
                    _tokenId,
                    _receiver
                )
                : _encodeMint(
                    _tokenAddress,
                    _tokenId,
                    _receiver,
                    tokenURI,
                    nativeTokenInfo.tokenType
                );
        }

        {
            deBridgeGate.send{value: msg.value}(
                address(0), // _tokenAddress
                msg.value, // _amount
                _chainIdTo, // _chainIdTo
                abi.encodePacked(getChainInfo[_chainIdTo].nftBridgeAddress), // _receiver
                "", // _permit
                false, // _useAssetFee
                _referralCode, // _referralCode
                _encodeAutoParamsTo(targetData, _executionFee) // _autoParams
            );
        }
        emit NFTSent(_tokenAddress, _tokenId, abi.encodePacked(_receiver), _chainIdTo, nonce);
        nonce++;
    }

    /// @dev Unlock the asset on the current chain and transfer to receiver.
    /// @param _tokenAddress nft Asset identifier.
    /// @param _tokenId Token Id to be transfered
    /// @param _receiver Receiver address.
    function claim(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver
    )
        external
        onlyCrossBridgeAddress
        whenNotPaused
    {
        _safeTransferFrom(_tokenAddress, address(this), _receiver, _tokenId);

        emit NFTClaimed(
            _tokenAddress,
            _tokenId,
            _receiver
        );
    }

    /// @dev Mint nft to receiver.
    /// @param _nativeTokenAddress nft native asset identifier.
    /// @param _nativeChainId nft native chainId.
    /// @param _tokenId Token Id to be transfered
    /// @param _receiver Receiver address.
    /// @param _nativeName nft name.
    /// @param _nativeSymbol nft symbol.
    /// @param _tokenUri uri for current token Id.
    function mint(
        bytes memory _nativeTokenAddress,
        uint256 _nativeChainId,
        uint256 _tokenId,
        address _receiver,
        string memory _nativeName,
        string memory _nativeSymbol,
        string memory _tokenUri,
        uint256 _tokenType
    )
        external
        onlyCrossBridgeAddress
        whenNotPaused
    {
        bytes32 debridgeId = getDebridgeId(_nativeChainId, _nativeTokenAddress);

        if (!getBridgeNFTInfo[debridgeId].exist) {
            address currentNFTAddress = deBridgeNFTDeployer.deployAsset(
                debridgeId,
                _nativeName,
                _nativeSymbol
            );
            _addAsset(
                debridgeId,
                currentNFTAddress,
                _nativeTokenAddress,
                _nativeChainId,
                _nativeName,
                _nativeSymbol,
                _tokenType
            );
        }

        address tokenAddress = getBridgeNFTInfo[debridgeId].tokenAddress;
        IDeNFT(tokenAddress).mint(_receiver, _tokenId, _tokenUri);

        emit NFTMinted(
            tokenAddress,
            _tokenId,
            _receiver,
            _tokenUri
        );
    }

    /// @dev Create NFT
    /// @param _name Asset name
    /// @param _symbol Asset symbol
    function createNFT(
        address _minter,
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    ) external whenNotPaused {
        address currentNFTAddress = deBridgeNFTDeployer.createNFT(
            _minter,
            _name,
            _symbol,
            _baseUri
        );
        createdTokens[currentNFTAddress] = TOKEN_BURNABLE_TYPE;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    // ============ ADMIN METHODS ============

    function setNFTDeployer(DeBridgeNFTDeployer _deBridgeNFTDeployer) external onlyAdmin {
        deBridgeNFTDeployer = _deBridgeNFTDeployer;
    }

    function setDeBridgeGate(DeBridgeGate _deBridgeGate) external onlyAdmin {
        deBridgeGate = _deBridgeGate;
    }

    /// @param _bridgeAddress Bridge address, set to 0 to disable a chain
    /// @param _chainId Chain id
    function addChainSupport(bytes calldata _bridgeAddress, uint256 _chainId) external onlyAdmin {
        if (_chainId == 0 || _chainId == getChainId()) {
            revert WrongArgument();
        }
        getChainInfo[_chainId].nftBridgeAddress = _bridgeAddress;
        getChainInfo[_chainId].isSupported = true;

        emit AddedChainSupport(_bridgeAddress, _chainId);
    }

    function removeChainSupport(uint256 _chainId) external onlyAdmin {
        delete getChainInfo[_chainId];
        emit RemovedChainSupport(_chainId);
    }

    /// @dev Stop all transfers.
    function pause() external onlyAdmin {
        _pause();
    }

    /// @dev Allow transfers.
    function unpause() external onlyAdmin {
        _unpause();
    }

    // ============ Private methods ============

    /// @dev Add support for the asset.
    /// @param _debridgeId Asset identifier.
    /// @param _tokenAddress Address of the asset on the current chain.
    /// @param _nativeAddress Address of the asset on the native chain.
    /// @param _nativeChainId Native chain id.
    function _addAsset(
        bytes32 _debridgeId,
        address _tokenAddress,
        bytes memory _nativeAddress,
        uint256 _nativeChainId,
        string memory _nativeName,
        string memory _nativeSymbol,
        uint256 _tokenType
    ) internal {
        BridgeNFTInfo storage bridgeInfo = getBridgeNFTInfo[_debridgeId];

        if (bridgeInfo.exist) revert AssetAlreadyExist();
        if (_tokenAddress == address(0)) revert ZeroAddress();

        bridgeInfo.exist = true;
        bridgeInfo.tokenAddress = _tokenAddress;
        bridgeInfo.nativeChainId = _nativeChainId;

        NativeNFTInfo storage nativeTokenInfo = getNativeInfo[_tokenAddress];
        nativeTokenInfo.chainId = _nativeChainId;
        nativeTokenInfo.tokenAddress = _nativeAddress;
        nativeTokenInfo.name = _nativeName;
        nativeTokenInfo.symbol = _nativeSymbol;
        nativeTokenInfo.tokenType = _tokenType;

        emit NFTContractAdded(
            _debridgeId,
            _tokenAddress,
            abi.encodePacked(_nativeAddress),
            _nativeChainId,
            _nativeName,
            _nativeSymbol,
            _tokenType
        );
    }

    function _decodeAddressFromBytes(bytes memory _bytes) internal pure returns (address addr) {
        // See https://ethereum.stackexchange.com/a/50528
        assembly {
            addr := mload(add(_bytes, 20))
        }
    }

    function _receiveNativeNFT(address _tokenAddress, uint256 _tokenId)
        internal
    {
        _checkAddAsset(_tokenAddress);
        _safeTransferFrom(_tokenAddress, msg.sender, address(this), _tokenId);
    }

    function _checkAddAsset(address _tokenAddress) internal returns (bytes32 debridgeId) {
        debridgeId = getDebridgeId(getChainId(), _tokenAddress);
        if (!getBridgeNFTInfo[debridgeId].exist) {
            _addAsset(
                debridgeId,
                _tokenAddress,
                abi.encodePacked(_tokenAddress),
                getChainId(),
                IERC721MetadataUpgradeable(_tokenAddress).name(),
                IERC721MetadataUpgradeable(_tokenAddress).symbol(),
                createdTokens[_tokenAddress]
            );
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that `to` became the owner of the 'tokenId'
     *
     */
    function _safeTransferFrom(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        IERC721Upgradeable(_tokenAddress).safeTransferFrom(_from, _to, _tokenId);
        // check that address to received nft
        if (IERC721Upgradeable(_tokenAddress).ownerOf(_tokenId) != _to) revert NotReceivedERC721();
    }

    function _encodeClaim(
        address _nativeTokenAddress,
        uint256 _tokenId,
        address _receiver
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                this.claim.selector,
                _nativeTokenAddress,
                _tokenId,
                _receiver
            );
    }

    /// @dev Encode mint method with arguments
    /// @param _tokenAddress Address of the asset on the current chain.
    /// @param _tokenId token id that will be minted
    /// @param _receiver receiver in target chain
    function _encodeMint(
        address _tokenAddress,
        uint256 _tokenId,
        address _receiver,
        string memory _tokenURI,
        uint256 _tokenType
    ) internal view returns (bytes memory) {
        NativeNFTInfo memory nativeTokenInfo = getNativeInfo[_tokenAddress];

        return
            abi.encodeWithSelector(
                this.mint.selector,
                nativeTokenInfo.tokenAddress, //_nativeTokenAddress
                nativeTokenInfo.chainId, //_nativeChainId
                _tokenId,
                _receiver,
                nativeTokenInfo.name, //_nativeSymbol
                nativeTokenInfo.symbol, //_nativeSymbol
                _tokenURI,
                _tokenType
            );
    }

    function _encodeAutoParamsTo(bytes memory _data, uint256 _executionFee)
        internal
        view
        returns (bytes memory)
    {
        IDeBridgeGate.SubmissionAutoParamsTo memory autoParams;
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.REVERT_IF_EXTERNAL_FAIL, true);
        autoParams.flags = Flags.setFlag(autoParams.flags, Flags.PROXY_WITH_SENDER, true);

        // fallbackAddress can be used to transfer NFT with deAssets
        autoParams.fallbackAddress = abi.encodePacked(msg.sender);
        autoParams.data = _data;
        autoParams.executionFee = _executionFee;
        return abi.encode(autoParams);
    }

    // ============ VIEWS ============

    /// @dev Calculates asset identifier.
    /// @param _chainId Current chain id.
    /// @param _tokenAddress Address of the asset on the other chain.
    function getDebridgeId(uint256 _chainId, address _tokenAddress) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_chainId, _tokenAddress));
    }

    /// @dev Calculates asset identifier.
    /// @param _chainId Current chain id.
    /// @param _tokenAddress Address of the asset on the other chain.
    function getDebridgeId(uint256 _chainId, bytes memory _tokenAddress)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_chainId, _tokenAddress));
    }

    /// @dev Get current chain id
    function getChainId() public view virtual returns (uint256 cid) {
        assembly {
            cid := chainid()
        }
    }

    // ============ Version Control ============
    function version() external pure returns (uint256) {
        return 100; // 1.0.0
    }
}
