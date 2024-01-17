// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IKryptoSign.sol";

contract KryptoSign is Initializable, OwnableUpgradeable, IKryptoSign {
    using ECDSAUpgradeable for bytes32;

    mapping(bytes32 => IKryptoSign.Document) private _documents;
    mapping(bytes32 => IKryptoSign.Signature[]) private _signatures;
    mapping(bytes32 => mapping(address => bool)) private _signed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function createDocument(string calldata ipfs) external {
        bytes32 documentId = getDocumentId(ipfs);

        _documents[documentId] = IKryptoSign.Document({
            ipfs: ipfs,
            owner: _msgSender()
        });

        emit DocumentCreated(documentId, _msgSender());
    }

    function signDocument(
        bytes32 documentId,
        string calldata ipfs,
        bytes calldata signature
    ) external {
        require(
            keccak256(abi.encodePacked(documentId, ipfs, _msgSender()))
                .toEthSignedMessageHash()
                .recover(signature) == _msgSender(),
            "Invalid Signature"
        );
        require(!_signed[documentId][_msgSender()], "Already Signed");

        _documents[documentId].ipfs = ipfs;

        _signatures[documentId].push(
            IKryptoSign.Signature({
                ipfs: ipfs,
                signature: signature,
                signer: _msgSender()
            })
        );

        emit DocumentSigned(documentId, _msgSender());
    }

    function getDocument(bytes32 documentId)
        external
        view
        returns (IKryptoSign.Document memory)
    {
        return _documents[documentId];
    }

    function getSignatures(bytes32 documentId)
        external
        view
        returns (IKryptoSign.Signature[] memory)
    {
        return _signatures[documentId];
    }

    function getDocumentId(string calldata ipfs)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(ipfs, _msgSender(), block.number));
    }
}
