//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


import "./ERC721.sol";
import "./EIP712.sol";
import "./AccessControl.sol";
import "./Nonces.sol";
interface IPolygonZkEVMBridge {
    /**
     * @dev Thrown when sender is not the PolygonZkEVM address
     */
    error OnlyPolygonZkEVM();

    /**
     * @dev Thrown when the destination network is invalid
     */
    error DestinationNetworkInvalid();

    /**
     * @dev Thrown when the amount does not match msg.value
     */
    error AmountDoesNotMatchMsgValue();

    /**
     * @dev Thrown when user is bridging tokens and is also sending a value
     */
    error MsgValueNotZero();

    /**
     * @dev Thrown when the Ether transfer on claimAsset fails
     */
    error EtherTransferFailed();

    /**
     * @dev Thrown when the message transaction on claimMessage fails
     */
    error MessageFailed();

    /**
     * @dev Thrown when the global exit root does not exist
     */
    error GlobalExitRootInvalid();

    /**
     * @dev Thrown when the smt proof does not match
     */
    error InvalidSmtProof();

    /**
     * @dev Thrown when an index is already claimed
     */
    error AlreadyClaimed();

    /**
     * @dev Thrown when the owner of permit does not match the sender
     */
    error NotValidOwner();

    /**
     * @dev Thrown when the spender of the permit does not match this contract address
     */
    error NotValidSpender();

    /**
     * @dev Thrown when the amount of the permit does not match
     */
    error NotValidAmount();

    /**
     * @dev Thrown when the permit data contains an invalid signature
     */
    error NotValidSignature();

    function bridgeAsset(
        uint32 destinationNetwork,
        address destinationAddress,
        uint256 amount,
        address token,
        bool forceUpdateGlobalExitRoot,
        bytes calldata permitData
    ) external payable;

    function bridgeMessage(
        uint32 destinationNetwork,
        address destinationAddress,
        bool forceUpdateGlobalExitRoot,
        bytes calldata metadata
    ) external payable;

    function claimAsset(
        bytes32[32] calldata smtProof,
        uint32 index,
        bytes32 mainnetExitRoot,
        bytes32 rollupExitRoot,
        uint32 originNetwork,
        address originTokenAddress,
        uint32 destinationNetwork,
        address destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external;

    function claimMessage(
        bytes32[32] calldata smtProof,
        uint32 index,
        bytes32 mainnetExitRoot,
        bytes32 rollupExitRoot,
        uint32 originNetwork,
        address originAddress,
        uint32 destinationNetwork,
        address destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external;

    function updateGlobalExitRoot() external;

    function activateEmergencyState() external;

    function deactivateEmergencyState() external;
}

interface IRootChainManager {
    event TokenMapped(
        address indexed rootToken,
        address indexed childToken,
        bytes32 indexed tokenType
    );

    event PredicateRegistered(
        bytes32 indexed tokenType,
        address indexed predicateAddress
    );

    function registerPredicate(bytes32 tokenType, address predicateAddress)
        external;

    function mapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function cleanMapToken(
        address rootToken,
        address childToken
    ) external;

    function remapToken(
        address rootToken,
        address childToken,
        bytes32 tokenType
    ) external;

    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function exit(bytes calldata inputData) external;
}

contract BOX is ERC721, AccessControl, EIP712("Black Box", "1"), Nonces{

    string private _baseTokenURI;
    address private _ownerL2;
    // Ether (goerli) bridge to Polygon Mumbai Testnet : 0xe45d449909905f82a5e0b0f2afa5953c2e3583fd 
    // Ether (goerli) bridge to Polygon zkEMV testnet : 0xF6BEEeBB578e214CA9E23B0e9683454Ff88Ed2A7
    // Ether (sepolia) bridge to Immutable zkEvm testnet:     
    //address private immutable _bridge;

    bytes32 public constant SIGNER = keccak256("SIGNER");
    bytes32 private constant PERMIT_MINT_ETHERS_TYPEHASH =
        keccak256(
            "PermitMintEther(address owner,uint256 tokenId,uint256 value,uint256 nonce)"
        );

    constructor(address ownerL2) ERC721("Black Box","BB") {
        _ownerL2=ownerL2;
        //_bridge=bridge;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SIGNER, msg.sender);
    }


     /**
     * @dev Return token's URI=base+ `tokenId` + '.json'.
     *
     */

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(_baseURI(), Strings.toString(tokenId), ".json")
            );
    }

    /**
     * @dev Return `_baseTokenURI` as the base for token's URI.
     *
     */

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets `_baseTokenURI` as the base for token's URI.
     *
     */
    function setBaseURI(
        string memory uri
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = uri;
    }

    /**
     * @dev Mints for `to` `tokenId` token for `value` ethers,
     * given ``signer``'s signed approval.
     *
     *
     * Emits an {Transfer} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permitMintForEthers(
        address to,
        uint256 tokenId,
        uint256 value,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(msg.value == value, "Invalid value"); //C04 fix
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_MINT_ETHERS_TYPEHASH,
                to,
                tokenId,
                value,
                _useNonce(to)
            )
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        require(hasRole(SIGNER, signer), "Invalid signature");
        _mint(to, tokenId);
        (bool done, ) = payable(_ownerL2).call{value: value}("");
        require(done, "Error sending ethers");
        // bring to Polygon
        //IRootChainManager(_bridge).depositEtherFor{value: value}(_ownerL2);
        // bring to L2
        //IPolygonZkEVMBridge(_bridge).bridgeAsset{value: value}(1,_ownerL2,value, address(0), true, '');
    }

    error TransferProhibited(address sender);

    function _transfer(
        address auth,
        address to,
        uint256 tokenId
    ) internal virtual override{
        if (auth != address(0)) {
            revert TransferProhibited(auth);
        }
        super._transfer(auth, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}