// SPDX-License-Identifier: MIT
import "./ERC721Creator.sol";
import "./ICreatorExtensionRoyalties.sol";
import "./Signatures.sol";
import "./ECDSA.sol";

pragma solidity ^0.8.9;

/**
 * Shared Manifold extension which supports letting users add arbitrary minting permissions
 * and per token royalties set at the time of minting.
 *
 * Version: 1.2
 */
contract GlobalVerisartManifoldExtension is ICreatorExtensionRoyalties {
    bytes32 private constant _DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    bytes32 private _eip712DomainSeparator =
        keccak256(
            abi.encode(
                _DOMAIN_TYPEHASH,
                keccak256("Verisart"),
                keccak256("1"),
                block.chainid,
                address(this),
                0xf1ca08ca57710ea92070eeb3815fb1f0511ccba827234f5f42e2908ebedebc03 // Verisart's EIP712 salt
            )
        );

    bytes32 private constant _MINT_SIGNED_TYPEHASH =
        keccak256(
            "MintNFT(address sender,address to,address creatorContract,string uri,"
            "bytes32 tokenNonce,address[] royaltyReceivers,uint256[] royaltyBasisPoints)"
        );

    bytes32 private constant _MINT_EDITIONS_SIGNED_TYPEHASH =
        keccak256(
            "MintNFTEditions(address sender,address to,address creatorContract,string[] uris,"
            "bytes32 tokenNonce,address[][] royaltyReceivers,uint256[][] royaltyBasisPoints)"
        );

    mapping(address => bool) private _disableSignedMinting;

    struct RoyaltyConfig {
        address payable receiver;
        uint16 bps;
    }

    event Granted(address indexed creatorContract, address indexed account);
    event Revoked(address indexed creatorContract, address indexed account);
    event RoyaltiesUpdated(
        address indexed creatorContract,
        uint256 indexed tokenId,
        address payable[] receivers,
        uint256[] basisPoints
    );
    event DefaultRoyaltiesUpdated(
        address indexed creatorContract,
        address payable[] receivers,
        uint256[] basisPoints
    );

    mapping(address => mapping(address => bool)) private _permissions;

    mapping(address => mapping(uint256 => RoyaltyConfig[]))
        private _tokenRoyalties;

    mapping(address => RoyaltyConfig[]) private _defaultRoyalties;
    mapping(bytes32 => bool) private _signedMints;

    function supportsInterface(
        bytes4 interfaceId
    ) external view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(ICreatorExtensionRoyalties).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function hasMintingPermission(
        address creatorContract,
        address creator
    ) public view returns (bool) {
        return _permissions[creatorContract][creator];
    }

    function grantMinting(address creatorContract, address creator) external {
        require(
            ERC721Creator(creatorContract).isAdmin(msg.sender),
            "Must be admin"
        );
        _permissions[creatorContract][creator] = true;
        emit Granted(creatorContract, creator);
    }

    function enableSignedMinting(address creatorContract) external {
        require(
            ERC721Creator(creatorContract).isAdmin(msg.sender),
            "Must be admin"
        );
        _disableSignedMinting[creatorContract] = false;
    }

    function disableSignedMinting(address creatorContract) external {
        require(
            ERC721Creator(creatorContract).isAdmin(msg.sender),
            "Must be admin"
        );
        _disableSignedMinting[creatorContract] = true;
    }

    function revokeMinting(address creatorContract, address creator) external {
        require(
            ERC721Creator(creatorContract).isAdmin(msg.sender),
            "Must be admin"
        );
        _permissions[creatorContract][creator] = false;
        emit Revoked(creatorContract, creator);
    }

    function _mintNoPermission(
        ERC721Creator creatorCon,
        address to,
        string calldata uri,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) private {
        _checkRoyalties(receivers, basisPoints);
        uint256 tokenId = creatorCon.mintExtension(to, uri);
        _setTokenRoyalties(
            address(creatorCon),
            tokenId,
            receivers,
            basisPoints
        );
    }

    function mint(
        address creatorContract,
        address to,
        string calldata uri,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external {
        ERC721Creator creatorCon = _checkIsGranted(creatorContract);
        _mintNoPermission(creatorCon, to, uri, receivers, basisPoints);
    }

    function mintSigned(
        address to,
        address creatorContract,
        string calldata uri,
        bytes32 tokenNonce,
        address payable[] calldata royaltyReceivers,
        uint256[] calldata royaltyBasisPoints,
        bytes calldata signature
    ) external {
        require(
            !_disableSignedMinting[creatorContract],
            "Signed minting disabled"
        );
        bytes memory args = abi.encode(
            _MINT_SIGNED_TYPEHASH,
            msg.sender,
            to,
            creatorContract,
            keccak256(abi.encodePacked(uri)),
            tokenNonce,
            keccak256(abi.encodePacked(royaltyReceivers)),
            keccak256(abi.encodePacked(royaltyBasisPoints))
        );

        ERC721Creator creatorCon = _checkSigned(
            creatorContract,
            args,
            tokenNonce,
            signature
        );
        _mintNoPermission(
            creatorCon,
            to,
            uri,
            royaltyReceivers,
            royaltyBasisPoints
        );
    }

    function _mintBatchNoPermission(
        ERC721Creator creatorCon,
        address to,
        string[] calldata uris,
        address payable[][] calldata receiversPerToken,
        uint256[][] calldata basisPointsPerToken
    ) private {
        require(
            receiversPerToken.length == basisPointsPerToken.length,
            "Mismatch in array lengths"
        );
        require(
            receiversPerToken.length == 0 ||
                receiversPerToken.length == uris.length,
            "Incorrect royalty array length"
        );
        for (uint256 i = 0; i < receiversPerToken.length; i++) {
            _checkRoyalties(receiversPerToken[i], basisPointsPerToken[i]);
        }

        uint256[] memory tokenIds = creatorCon.mintExtensionBatch(to, uris);

        if (receiversPerToken.length != 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                _setTokenRoyalties(
                    address(creatorCon),
                    tokenIds[i],
                    receiversPerToken[i],
                    basisPointsPerToken[i]
                );
            }
        }
    }

    function mintBatch(
        address creatorContract,
        address to,
        string[] calldata uris,
        address payable[][] calldata receiversPerToken,
        uint256[][] calldata basisPointsPerToken
    ) external {
        ERC721Creator creatorCon = _checkIsGranted(creatorContract);
        _mintBatchNoPermission(
            creatorCon,
            to,
            uris,
            receiversPerToken,
            basisPointsPerToken
        );
    }

    function mintBatchSigned(
        address to,
        address creatorContract,
        string[] calldata uris,
        bytes32 tokenNonce,
        address payable[][] calldata royaltyReceivers,
        uint256[][] calldata royaltyBasisPoints,
        bytes calldata signature
    ) external {
        require(
            !_disableSignedMinting[creatorContract],
            "Signed minting disabled"
        );
        bytes memory args = abi.encode(
            _MINT_EDITIONS_SIGNED_TYPEHASH,
            msg.sender,
            to,
            creatorContract,
            keccak256(abi.encodePacked(_hashStringArray(uris))),
            tokenNonce,
            keccak256(
                abi.encodePacked(
                    _hashTwoDimensionalAddressArray(royaltyReceivers)
                )
            ),
            keccak256(
                abi.encodePacked(
                    _hashTwoDimensionalUintArray(royaltyBasisPoints)
                )
            )
        );
        ERC721Creator creatorCon = _checkSigned(
            creatorContract,
            args,
            tokenNonce,
            signature
        );
        _mintBatchNoPermission(
            creatorCon,
            to,
            uris,
            royaltyReceivers,
            royaltyBasisPoints
        );
    }

    function setTokenRoyalties(
        address creatorContract,
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external {
        _checkIsGranted(creatorContract);
        _checkRoyalties(receivers, basisPoints);
        _setTokenRoyalties(creatorContract, tokenId, receivers, basisPoints);
        emit RoyaltiesUpdated(creatorContract, tokenId, receivers, basisPoints);
    }

    function setDefaultRoyalties(
        address creatorContract,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external {
        _checkIsGranted(creatorContract);
        _checkRoyalties(receivers, basisPoints);
        delete _defaultRoyalties[creatorContract];
        _setRoyalties(
            receivers,
            basisPoints,
            _defaultRoyalties[creatorContract]
        );
        emit DefaultRoyaltiesUpdated(creatorContract, receivers, basisPoints);
    }

    function getRoyalties(
        address creator,
        uint256 tokenId
    )
        external
        view
        virtual
        override
        returns (address payable[] memory, uint256[] memory)
    {
        RoyaltyConfig[] memory royalties = _tokenRoyalties[creator][tokenId];

        if (royalties.length == 0) {
            royalties = _defaultRoyalties[creator];
        }

        address payable[] memory receivers = new address payable[](
            royalties.length
        );
        uint256[] memory bps = new uint256[](royalties.length);
        for (uint256 i; i < royalties.length; ) {
            receivers[i] = royalties[i].receiver;
            bps[i] = royalties[i].bps;
            unchecked {
                ++i;
            }
        }

        return (receivers, bps);
    }

    function _setTokenRoyalties(
        address creatorContract,
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) private {
        delete _tokenRoyalties[creatorContract][tokenId];
        _setRoyalties(
            receivers,
            basisPoints,
            _tokenRoyalties[creatorContract][tokenId]
        );
    }

    function _setRoyalties(
        address payable[] calldata receivers,
        uint256[] calldata basisPoints,
        RoyaltyConfig[] storage royalties
    ) private {
        for (uint256 i; i < basisPoints.length; ) {
            royalties.push(
                RoyaltyConfig({
                    receiver: receivers[i],
                    bps: uint16(basisPoints[i])
                })
            );
            unchecked {
                ++i;
            }
        }
    }

    function _checkIsAddressGranted(
        address sender,
        address creatorContract
    ) private view returns (ERC721Creator) {
        ERC721Creator creatorCon = ERC721Creator(creatorContract);
        require(
            hasMintingPermission(creatorContract, sender) ||
                creatorCon.isAdmin(sender),
            "Permission denied"
        );
        return creatorCon;
    }

    function _checkIsGranted(
        address creatorContract
    ) private view returns (ERC721Creator) {
        return _checkIsAddressGranted(msg.sender, creatorContract);
    }

    function _checkRoyalties(
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) private pure {
        require(
            receivers.length == basisPoints.length,
            "Mismatch in array lengths"
        );
        uint256 totalBasisPoints;
        for (uint256 i; i < basisPoints.length; ) {
            totalBasisPoints += basisPoints[i];
            unchecked {
                ++i;
            }
        }
        require(totalBasisPoints < 10000, "Invalid total royalties");
    }

    function _checkSigned(
        address creatorContract,
        bytes memory args,
        bytes32 tokenNonce,
        bytes calldata signature
    ) private returns (ERC721Creator) {
        // TODO: Should have global flag here too?

        // Recover signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _eip712DomainSeparator,
                keccak256(args)
            )
        );
        // Recover signer
        address authorizer = ECDSA.recover(digest, signature);

        // Check signer can mint on this contract
        ERC721Creator creatorCon = _checkIsAddressGranted(
            authorizer,
            creatorContract
        );

        // Check nonce hasn't been redeemed already
        bytes32 tokenNonceHash = keccak256(
            abi.encode(creatorContract, tokenNonce)
        );
        require(
            _signedMints[tokenNonceHash] == false,
            "Signed mint already redeemed"
        );

        // Mark the nonce as redeemed
        _signedMints[tokenNonceHash] = true;

        return creatorCon;
    }

    // In EIP-712 arrays of dynamically-sized types need each element hashed first
    function _hashStringArray(
        string[] calldata data
    ) private pure returns (bytes32[] memory) {
        bytes32[] memory keccakData = new bytes32[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            keccakData[i] = keccak256(bytes(data[i]));
        }
        return keccakData;
    }

    function _hashTwoDimensionalAddressArray(
        address payable[][] calldata data
    ) private pure returns (bytes32[] memory) {
        bytes32[] memory keccakData = new bytes32[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            keccakData[i] = keccak256(abi.encodePacked(data[i]));
        }
        return keccakData;
    }

    function _hashTwoDimensionalUintArray(
        uint256[][] calldata data
    ) private pure returns (bytes32[] memory) {
        bytes32[] memory keccakData = new bytes32[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            keccakData[i] = keccak256(abi.encodePacked(data[i]));
        }
        return keccakData;
    }
}
