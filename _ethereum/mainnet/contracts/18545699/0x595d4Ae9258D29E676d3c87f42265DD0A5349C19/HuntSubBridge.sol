// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./OwnableUpgradeable.sol";

import "./IHuntSubBridge.sol";
import "./ILayerZeroNonBlockingReceiver.sol";
import "./ILayerZeroUserApplicationConfig.sol";
import "./ILayerZeroEndpoint.sol";
import "./Types.sol";
import "./IHunterValidator.sol";
import "./IHuntGame.sol";
import "./IBulletOracle.sol";

contract HuntSubBridge is
    OwnableUpgradeable,
    ERC721Holder,
    ERC1155Holder,
    IHuntSubBridge,
    ILayerZeroNonBlockingReceiver,
    ILayerZeroUserApplicationConfig
{
    ILayerZeroEndpoint public endpoint;
    address private huntBridge;
    uint16 mainLayerZeroChainId;
    uint64 public extraGas;

    /// use 1 slot to save decode
    uint256 private paused;
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;
    uint256 public override baseFee;

    function initialize(address _endpoint, address _huntBridge, uint16 _mainLayerZeroChainId) public initializer {
        __Ownable_init();

        require(uint160(_endpoint) & uint160(_huntBridge) != 0, "ADDR_ERR");
        endpoint = ILayerZeroEndpoint(_endpoint);
        huntBridge = _huntBridge;
        mainLayerZeroChainId = _mainLayerZeroChainId;
        extraGas = 3e6; // 3m enough for global nft mint and create game and register white list now
        /// @dev matic network use 25 matic initialized
        baseFee = block.chainid == 137 ? 25 ether : 0.01 ether;
    }

    modifier selfPermit() {
        require(msg.sender == address(this));
        _;
    }

    modifier pausable() {
        require(!isPaused(), "paused");
        _;
    }

    function lzReceive(uint16 _lzSrcId, bytes calldata _pathData, uint64 _nonce, bytes calldata _payload) public {
        /// @notice only permitted by endpoint
        require(msg.sender == address(endpoint));
        require(_lzSrcId == mainLayerZeroChainId, "LZID_ERR");
        require(_pathData.length == 40 && address(bytes20(_pathData)) == huntBridge, "SENDER_ERR");
        require(_payload.length > 1, "WRONG_PAYLOAD");

        try this.nonblockingLzReceive{ gas: gasleft() - 6e4 }(_lzSrcId, _pathData, _nonce, _payload) {} catch Error(
            string memory reason
        ) {
            _storeFailedMessage(_lzSrcId, _pathData, _nonce, _payload, bytes(reason));
        } catch (bytes memory reason) {
            _storeFailedMessage(_lzSrcId, _pathData, _nonce, _payload, reason);
        }
    }

    function retryMessage(uint16 _lzSrcId, bytes calldata _pathData, uint64 _nonce, bytes calldata _payload) public {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_lzSrcId][_pathData][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        delete failedMessages[_lzSrcId][_pathData][_nonce];
        // execute the message. revert if it fails again
        this.nonblockingLzReceive(_lzSrcId, _pathData, _nonce, _payload);
        emit RetryMessageSuccess(_lzSrcId, _pathData, _nonce, payloadHash);
    }

    function depositAndCreateGame(
        bool isErc1155,
        address addr,
        uint256 tokenId,
        IHunterValidator hunterValidator,
        uint64 totalBullets,
        uint256 bulletPrice,
        uint64 ddl,
        bytes memory registerParams
    ) public payable {
        require(msg.value > baseFee, "insufficient for base fee");
        /// @notice all wrong params will be modified at factory to avoid frequent revoke cost
        require(ddl > block.timestamp + 6 hours, "ERR_DDL"); // avoid narrow ddl makes bridge and create failed
        require(totalBullets > 0, "EMPTY_BULLET");
        if (isErc1155) {
            IERC1155(addr).safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        } else {
            IERC721(addr).safeTransferFrom(msg.sender, address(this), tokenId, "");
        }
        bytes memory extraData = abi.encode(hunterValidator, totalBullets, bulletPrice, ddl, registerParams);
        bytes memory _calldata = Types.encodeNftBridgeParams(
            block.chainid,
            isErc1155,
            addr,
            tokenId,
            msg.sender,
            Consts.CREATE_GAME_RECIPIENT,
            extraData
        );

        endpoint.send{ value: msg.value - baseFee }(
            mainLayerZeroChainId,
            abi.encodePacked(huntBridge, address(this)),
            _calldata,
            payable(msg.sender),
            address(0),
            Types.encodeAdapterParams(extraGas)
        );
        uint64 _nonce = endpoint.getOutboundNonce(mainLayerZeroChainId, address(this));
        emit NftDepositInitialized(
            isErc1155,
            addr,
            tokenId,
            msg.sender,
            Consts.CREATE_GAME_RECIPIENT,
            extraData,
            _nonce
        );
    }

    /// @notice approved first
    function deposit(bool isErc1155, address addr, uint256 tokenId, address recipient) public payable pausable {
        if (isErc1155) {
            IERC1155(addr).safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        } else {
            IERC721(addr).safeTransferFrom(msg.sender, address(this), tokenId, "");
        }

        bytes memory _calldata = Types.encodeNftBridgeParams(
            block.chainid,
            isErc1155,
            addr,
            tokenId,
            msg.sender,
            recipient,
            ""
        );
        endpoint.send{ value: msg.value }(
            mainLayerZeroChainId,
            abi.encodePacked(huntBridge, address(this)),
            _calldata,
            payable(msg.sender),
            address(0),
            Types.encodeAdapterParams(extraGas)
        );
        uint64 _nonce = endpoint.getOutboundNonce(mainLayerZeroChainId, address(this));
        emit NftDepositInitialized(isErc1155, addr, tokenId, msg.sender, recipient, "", _nonce);
    }

    /// @notice only owner
    function pauseDeposit(bool _pause) public onlyOwner {
        paused = _pause ? 1 : 0;
        emit Paused(_pause);
    }

    function isPaused() public view returns (bool) {
        return paused == 1;
    }

    function estimateFees() public view returns (uint256) {
        (uint256 native, ) = endpoint.estimateFees(
            mainLayerZeroChainId,
            address(this),
            "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
            false,
            Types.encodeAdapterParams(extraGas)
        );
        return native;
    }

    ///set config
    function setHuntBridge(address _bridge) public onlyOwner {
        huntBridge = _bridge;
    }

    function setExtraGas(uint64 _extraGas) public onlyOwner {
        extraGas = _extraGas;
    }

    function setBaseFee(uint256 _baseFee) public onlyOwner {
        baseFee = _baseFee;
    }

    function claimFee() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // generic config for user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) public override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) public override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) public override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) public override onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    /// @notice used for internal
    function nonblockingLzReceive(uint16, bytes calldata, uint64 _nonce, bytes calldata _payload) public selfPermit {
        (, bool isERC1155, address addr, uint256 tokenId, address from, address recipient, ) = Types
            .decodeNftBridgeParams(_payload);
        if (isERC1155) {
            IERC1155(addr).safeTransferFrom(address(this), recipient, tokenId, 1, "");
        } else {
            IERC721(addr).transferFrom(address(this), recipient, tokenId);
        }
        emit NftWithdrawFinalized(isERC1155, addr, tokenId, from, recipient, "", _nonce);
    }

    /// @dev  store failed message for retry message
    function _storeFailedMessage(
        uint16 _lzId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload,
        bytes memory _reason
    ) internal virtual {
        failedMessages[_lzId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_lzId, _srcAddress, _nonce, _payload, _reason);
    }
}
