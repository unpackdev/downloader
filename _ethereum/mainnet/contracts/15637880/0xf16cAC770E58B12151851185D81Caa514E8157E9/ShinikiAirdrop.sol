// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ISignatureVerifier.sol";

contract ShinikiAirdrop is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    // Info interface address signature
    ISignatureVerifier public SIGNATURE_VERIFIER;

    // Info interface address token
    IERC721Upgradeable public tokenShiniki;

    // Info address owner token
    address public ownerToken;

    // Info address claimed
    mapping(address => bool) public claimed;

    function initialize(
        IERC721Upgradeable _tokenShiniki,
        address _ownerToken,
        address signatureVerifier
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        tokenShiniki = _tokenShiniki;
        ownerToken = _ownerToken;

        SIGNATURE_VERIFIER = ISignatureVerifier(signatureVerifier);
    }

    /**
    @notice User claim airdrop
     * @param receiver 'address' receiver for nft
     * @param tokenIds 'array' tokenIds
     * @param nonce 'uint256' a number random
     * @param signature 'bytes' a signature to verify data when claim nft
     */
    function claimAirdrop(
        address receiver,
        uint256[] memory tokenIds,
        uint256 nonce,
        bytes memory signature
    ) public nonReentrant whenNotPaused {
        require(
            SIGNATURE_VERIFIER.verifyClaimAirdrop(
                receiver,
                tokenIds,
                nonce,
                signature
            ),
            "ShinikiAirdrop: signature claim airdrop is invalid"
        );
        for (uint64 i = 0; i < tokenIds.length; i++) {
            IERC721Upgradeable(tokenShiniki).safeTransferFrom(
                ownerToken,
                receiver,
                tokenIds[i]
            );
        }
        claimed[receiver] = true;
    }

    /**
    @notice Setting token ERC721
     * @param _tokenShiniki 'address' token
     */
    function setTokenShiniki(IERC721Upgradeable _tokenShiniki)
        external
        onlyOwner
    {
        tokenShiniki = _tokenShiniki;
    }

    /**
    @notice Setting owner token
     * @param _ownerToken 'address' owner token 
     */
    function setTokenOwner(address _ownerToken) external onlyOwner {
        ownerToken = _ownerToken;
    }

    /**
    @notice Setting new address signature
     * @param _signatureVerifier 'address' signature 
     */
    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        SIGNATURE_VERIFIER = ISignatureVerifier(_signatureVerifier);
    }

    /**
    @dev Pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    @dev Unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}
