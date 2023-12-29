// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./EIP712.sol";
import "./LibBitmap.sol";
import "./SignatureChecker.sol";

import "./Constants.sol";

/**
 * @title MintPass
 * @author fx(hash)
 * @notice Extension for claiming tokens through mint passes
 */
abstract contract MintPass is EIP712 {
    using SignatureChecker for address;

    /*//////////////////////////////////////////////////////////////////////////
                                    STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Mapping of token address to reserve ID to reserve nonce
     */
    mapping(address => mapping(uint256 => uint256)) public reserveNonce;

    /**
     * @notice Mapping of token address to reserve ID to address of mint pass authority
     */
    mapping(address => mapping(uint256 => address)) public signingAuthorities;

    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when mint pass is claimed
     * @param _token Address of the token
     * @param _reserveId ID of the reserve
     * @param _claimer Address of the mint pass claimer
     * @param _index Index of purchase info inside the BitMap
     */
    event PassClaimed(address indexed _token, uint256 indexed _reserveId, address indexed _claimer, uint256 _index);

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Error thrown when the signature of mint pass claimer is invalid
     */
    error InvalidSignature();

    /**
     * @notice Error thrown when a mint pass has already been claimed
     */
    error PassAlreadyClaimed();

    /*//////////////////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes EIP-712
     */
    constructor() EIP712("MINT_PASS", "1") {}

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Generates the typed data hash for a mint pass claim
     * @param _token address of token for the reserve
     * @param _reserveId Id of the reserve to mint the token from
     * @param _index Index of the mint pass
     * @param _claimer Address of mint pass claimer
     * @return Digest of typed data hash claimer
     */
    function generateTypedDataHash(
        address _token,
        uint256 _reserveId,
        uint256 _reserveNonce,
        uint256 _index,
        address _claimer
    ) public view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, _token, _reserveNonce, _reserveId, _index, _claimer));
        return _hashTypedDataV4(structHash);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Validates a mint pass claim
     * @param _token Address of the token contract
     * @param _reserveId ID of the reserve
     * @param _index Index of the mint pass
     * @param _claimer Account associated with the mint pass
     * @param _signature Signature of the mint pass claimer
     * @param _bitmap Bitmap used for checking if index is already claimed
     */
    function _claimMintPass(
        address _token,
        uint256 _reserveId,
        uint256 _index,
        address _claimer,
        bytes calldata _signature,
        LibBitmap.Bitmap storage _bitmap
    ) internal {
        if (LibBitmap.get(_bitmap, _index)) revert PassAlreadyClaimed();
        uint256 nonce = reserveNonce[_token][_reserveId];
        bytes32 hash = generateTypedDataHash(_token, _reserveId, nonce, _index, _claimer);
        address signer = signingAuthorities[_token][_reserveId];
        if (!signer.isValidSignatureNow(hash, _signature)) revert InvalidSignature();
        LibBitmap.set(_bitmap, _index);

        emit PassClaimed(_token, _reserveId, _claimer, _index);
    }
}
