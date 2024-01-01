// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// OpenZeppelin
import "./SafeERC20.sol";
import "./IERC20.sol";

// Local imports - Structs
import "./RequestTypes.sol";
import "./CrossChainRequestTypes.sol";
import "./EnumTypes.sol";

// Local imports - Constants
import "./RaiseConstants.sol";
import "./CrossChainErrors.sol";

// Local imports - Events
import "./RaiseEvents.sol";

// Local imports - Encoders
import "./RaiseEncoder.sol";

// Local imports - Storages
import "./LibBadge.sol";

// Local imports - Services
import "./RaiseService.sol";
import "./CreateRaiseService.sol";
import "./AlephZeroSenderService.sol";
import "./LayerZeroSenderService.sol";
import "./BadgeService.sol";
import "./ERC20AssetService.sol";
import "./EscrowService.sol";
import "./SignatureService.sol";

// Local imports - Interfaces
import "./ICreateRaiseFacet.sol";

contract CreateRaiseFacet is ICreateRaiseFacet {
    /// @dev Create raise and send cross chain message if needed to register raise on the other chain.
    /// @dev Events: NewRaise(
    ///                 address sender,
    ///                 StorageTypes.Raise raise,
    ///                 StorageTypes.RaiseDetails raiseDetails,
    ///                 StorageTypes.ERC20Asset erc20Asset,
    ///                 StorageTypes.BaseAsset baseAsset,
    ///                 uint256 badgeId,
    ///                 uint256 nonce
    ///             )
    /// @param _request RequestTypes.CreateRaiseRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    /// @param _crossChainData RequestTypes.CrossChainData struct with data for cross chain communication
    function createRaise(
        RequestTypes.CreateRaiseRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        CrossChainRequestTypes.CrossChainData calldata _crossChainData
    ) external payable {
        // tx.members
        address sender_ = msg.sender;

        // request members
        string memory raiseId_ = _request.raise.raiseId;

        // validate request
        CreateRaiseService.validateCreateRaiseRequest(_request);

        // EIP-712 encoding
        bytes memory encodedMsg_ = RaiseEncoder.encodeCreateRaise(_request);

        // verify message
        SignatureService.verifyMessage(RaiseConstants.EIP712_NAME, RaiseConstants.EIP712_VERSION, keccak256(encodedMsg_), _message);

        // verify signature
        SignatureService.verifySignature(_message, _v, _r, _s);

        // set raise, raise details, ERC-20 and base asset, nonce in storage
        RaiseService.setRaiseCreationData(
            raiseId_,
            sender_,
            _request.base.nonce,
            _request.raise,
            _request.raiseDetails,
            _request.erc20Asset,
            _request.baseAsset
        );

        // set ERC-1155 badge URI in storage
        LibBadge.setBadgeUri(raiseId_, _request.badgeUri);

        // calculate uint256 badge id
        uint256 badgeId_ = BadgeService.convertRaiseToBadge(raiseId_);
        // set URI in ERC-1155 token
        BadgeService.setEquityBadgeURI(badgeId_, _request.badgeUri);

        // create Escrow
        address escrow_ = EscrowService.createEscrow(raiseId_);

        // handle cross chain request
        if (_request.erc20Asset.chainId == block.chainid) {
            if (_crossChainData.provider == EnumTypes.CrossChainProvider.None) {
                // verify if raise is not of type early stage
                if (_request.raise.raiseType != EnumTypes.RaiseType.EarlyStage) {
                    // transfer vested token to escrow
                    ERC20AssetService.collectVestedToken(_request.erc20Asset.erc20, sender_, escrow_, _request.erc20Asset.amount);
                }
            } else {
                // revert if native chain id and custom provider
                revert CrossChainErrors.ProviderChainIdMismatch(_crossChainData.provider, _request.erc20Asset.chainId, block.chainid);
            }
        } else {
            if (_crossChainData.provider == EnumTypes.CrossChainProvider.None) {
                // revert if external chain id and no provider
                revert CrossChainErrors.ProviderChainIdMismatch(_crossChainData.provider, _request.erc20Asset.chainId, block.chainid);
            } else if (_crossChainData.provider == EnumTypes.CrossChainProvider.LayerZero) {
                // send message through LayerZero
                LayerZeroSenderService.sendCrossChainMessage(_crossChainData.data, _request.erc20Asset.chainId);
            } else if (_crossChainData.provider == EnumTypes.CrossChainProvider.AlephZero) {
                // send message through AlephZero
                AlephZeroSenderService.sendCrossChainMessage(_crossChainData.data, _request.erc20Asset.chainId);
            } else {
                // revert if provider unsupported
                revert CrossChainErrors.UnsupportedProvider();
            }
        }

        // emit
        emit RaiseEvents.NewRaise(
            sender_,
            _request.raise,
            _request.raiseDetails,
            _request.erc20Asset,
            _request.baseAsset,
            badgeId_,
            _request.base.nonce
        );
    }
}
