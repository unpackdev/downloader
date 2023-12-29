// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

//  **     **  **       **                    ****   **
// /**    /** /**      //                    /**/   /**
// /**    /** /**       **  ******  ******  ****** ******
// /**    /** /******  /** **////  **////**///**/ ///**/
// /**    /** /**///** /**//***** /**   /**  /**    /**
// /**    /** /**  /** /** /////**/**   /**  /**    /**
// //*******  /******  /** ****** //******   /**    //**
// ///////    /////    // //////   //////    //      //

import "./ChainlinkVRFMetadata.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./ERC721Psi.sol";
import "./ERC721PsiAddressData.sol";
import "./Errors.sol";
import "./IGenesisPFP.sol";
import "./GenesisBase.sol";
import "./MintData.sol";
import "./VRFV2WrapperConsumerBase.sol";
import "./Strings.sol";

/**
 * @title GenesisPFP
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, implementing ERC721URIStorage (storage based token URI management), Ownable and EIP712 typed signatures
 *
 * Token IDs are minted in sequential order (e.g. 1, 2, 3, ...)
 * starting from 1.
 */
contract GenesisPFP is GenesisBase, IGenesisPFP, ChainlinkVRFMetadata {
    using Strings for uint256;

    // =============================================================
    //                   CONSTANTS
    // =============================================================

    /// @notice Minter role used for AccessControl
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Maximum supply
    uint256 public constant MAX_SUPPLY = 9999;

    /**
     * @notice The typeHash is designed to turn into a compile time constant in Solidity.
     * @notice see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash for more information
     * @dev keccak256("MintData(address to,uint256 validity_start,uint256 validity_end,uint256 chain_id,uint256 mint_amount,bytes32 user_nonce)");
     */
    // EIP712 Type Hash
    bytes32 public constant MINT_DATA_TYPEHASH = keccak256(
        "MintData(address to,uint256 validity_start,uint256 validity_end,uint256 chain_id,uint256 mint_amount,bytes32 user_nonce)"
    );

    // =============================================================
    //                   CONSTRUCTOR
    // =============================================================

    /**
     * @dev Initializes the contract
     * @param _name name of the contract
     * @param _symbol symbol of the contract
     * @param _version version of the contract
     * @param _minter allowed address to mint
     * @param _minter royalty receiver
     * @param _link address to fund Chainlink VRF
     * @param _vrfV2Wrapper address to interact with Chainlink VRF
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _version,
        address _minter,
        address _vault,
        address _link,
        address _vrfV2Wrapper
    ) ERC721Psi(_name, _symbol) EIP712(_name, _version) VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, _minter);
        // Set royalties to a default 5% with ERC2981
        _setDefaultRoyalty(_vault, 500);
    }

    // =============================================================
    //                   EXTERNAL
    // =============================================================

    /**
     * @inheritdoc IGenesisPFP
     */
    function mintWithSignature(MintData calldata request, bytes memory signature) external override {
        // Supply is empty
        uint256 _remainingSupply = remainingSupply();
        if (_remainingSupply == 0) revert Errors.MaxSupplyReached();
        // Signature validity begins on `MintData.validity_start`
        if (block.timestamp < request.validity_start) revert Errors.SignatureValidityStart();
        // Signature validity ends on `MintData.validity_end`
        if (block.timestamp > request.validity_end) revert Errors.SignatureValidityEnd();
        // No replay attacks
        if (block.chainid != request.chain_id) revert Errors.WrongChainID();
        // Cannot mint zero tokens
        if (request.mint_amount == 0) revert Errors.InvalidMintAmount();
        // Cannot use a user nonce twise
        if (minted[request.user_nonce]) revert Errors.AlreadyMinted();

        // Verify the signer has the role MINTER_ROLE
        address recovered = verifySignature(request, signature);
        if (!hasRole(MINTER_ROLE, recovered)) {
            revert Errors.InvalidSignature();
        }

        // Get user allocation
        uint256 allocation = request.mint_amount;

        if (request.mint_amount > _remainingSupply) {
            allocation = _remainingSupply;
        }
        // Make sure a user cannot mint twice with the same account
        minted[request.user_nonce] = true;

        _safeMint(request.to, allocation);
    }

    // =============================================================
    //                   PUBLIC
    // =============================================================

    /**
     * @dev hashTypedData V4 computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
     * @param mintData holding the typed struct used by EIP-712
     */
    function hashTypedDataV4(MintData memory mintData) public view returns (bytes32) {
        return _hashTypedDataV4(hashStruct(mintData));
    }

    function remainingSupply() public view returns (uint256) {
        return MAX_SUPPLY - _totalMinted();
    }

    // =============================================================
    //                   INTERNAL
    // =============================================================

    /**
     * @notice see https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct
     * @param mintData structure to hash
     */
    function hashStruct(MintData memory mintData) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                MINT_DATA_TYPEHASH,
                mintData.to,
                mintData.validity_start,
                mintData.validity_end,
                mintData.chain_id,
                mintData.mint_amount,
                mintData.user_nonce
            )
        );
    }

    /**
     * @dev Takes a signature and returns the address from
     * @param mintData MintData object describing the mint request
     * @param signature EIP712-typed signature
     */
    function verifySignature(MintData calldata mintData, bytes memory signature) internal view returns (address) {
        bytes32 _hash = _hashTypedDataV4(hashStruct(mintData));
        return ECDSA.recover(_hash, signature);
    }

    // =============================================================
    //                   ERC721
    // =============================================================

    /**
     * @inheritdoc ERC721Psi
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert Errors.ERC721UriNonExistent();

        // Return empty tokenURI if metadata CID isn't registered
        if (bytes(_baseURI()).length == 0) {
            return "";
        }

        // Return a fallback URI if reveal isn't called yet
        if (chainlinkSeed == 0) {
            return string(abi.encodePacked(_baseURI(), "default.json"));
        }

        uint256 metadataId = ((tokenId + chainlinkSeed) % 9999) + 1;
        return string(abi.encodePacked(_baseURI(), metadataId.toString(), ".json"));
    }
}
