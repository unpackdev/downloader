// SPDX-License-Identifier: CC0 1.0 Universal

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.19;

import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./MultiOwner.sol";
import "./IWawaNFT.sol";
import "./Wawa.sol";

// @title GetWawa - A contract for claiming Wawa NFTs
contract GetWawa is MultiOwner, ReentrancyGuard {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    address public adminSigner; // Address of the admin who signs the coupon
    address public immutable wawaContract; // Wawa NFT contract address

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    /// @notice the coupon sent was signed by the admin signer
    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    //@notice Status:the coupon is used by msg sender
    uint256 private constant _CLAIMED = 1;

    mapping(address sender => mapping(Faction faction => uint256 status)) private claimedFactionLists;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event SetAdminSigner(address oldAdminSigner, address indexed newAdminSigner);
    event LogClaimWawa(
        address indexed user,
        uint256 indexed tokenId,
        Faction faction,
        uint8 petId,
        Trait trait,
        string tokenURI,
        bytes32 gene,
        uint256 timestamp
    );

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error ZeroAddressNotAllowed();
    error InvalidCoupon();
    error InvalidECDSASignature(address sender, address signer, bytes32 digest, Coupon coupon);
    error SignatureExpired();
    error AlreadyClaimedFaction(address sender, Faction faction);

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(address _adminSigner, address _wawaContract) {
        if (_adminSigner == address(0)) revert ZeroAddressNotAllowed();
        if (_wawaContract == address(0)) revert ZeroAddressNotAllowed();
        adminSigner = _adminSigner;
        wawaContract = _wawaContract;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @notice Require: First-time claim by msg.sender
     */
    modifier onlyIfNotClaimedFaction(Faction faction) {
        if (claimedFactionLists[msg.sender][faction] == _CLAIMED) {
            revert AlreadyClaimedFaction({ sender: msg.sender, faction: faction });
        }
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Coupon                                   */
    /* -------------------------------------------------------------------------- */
    /// @dev set admin signer
    function setAdminSigner(address _adminSigner) external onlyOwner {
        if (_adminSigner == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        address oldAdminSigner = adminSigner;
        adminSigner = _adminSigner;
        emit SetAdminSigner(oldAdminSigner, adminSigner);
    }

    /// @dev check that the coupon sent was signed by the admin signer
    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
        address signer = ECDSA.recover(digest, coupon.v, coupon.r, coupon.s);
        if (signer == address(0)) {
            revert InvalidECDSASignature({ sender: msg.sender, signer: signer, digest: digest, coupon: coupon });
        }
        return signer == adminSigner;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Wawa                                    */
    /* -------------------------------------------------------------------------- */
    /*
     * @title hasClaimed
     * @notice check QuestObject claim status
     * @param faction : quest object nft tokenId
     * @dev check that the coupon was already used
     */
    function hasClaimed(address sender, Faction faction) external view returns (uint256) {
        return claimedFactionLists[sender][faction];
    }

    /*
     * @title claimWawa
     * @notice Send create Message to PhiObject
     * @param tokenId : object nft token_id
     * @dev check that the coupon sent was signed by the admin signer
     */
    function claimWawa(
        string calldata tokenURI,
        Faction faction,
        Trait calldata trait,
        uint8 petId,
        bytes32 gene,
        uint256 expiresIn,
        Coupon calldata coupon
    )
        external
        payable
        nonReentrant
        onlyIfNotClaimedFaction(faction)
    {
        if (expiresIn <= block.timestamp) {
            revert SignatureExpired();
        }

        // Separate the block scope to avoid `Stack too deep` error
        {
            // Check that the coupon sent was signed by the admin signer
            bytes32 digest = keccak256(abi.encode(tokenURI, faction, trait, petId, gene, expiresIn, msg.sender));
            if (!_isVerifiedCoupon(digest, coupon)) {
                revert InvalidCoupon();
            }
        }

        // Register as an already CLAIMED ADDRESS
        claimedFactionLists[msg.sender][faction] = _CLAIMED;
        uint256 tokenId = IWawaNFT(wawaContract).totalSupply() + 1;
        IWawaNFT(wawaContract).getWawa{ value: msg.value }(msg.sender, tokenId, tokenURI, faction, trait, petId, gene);

        emit LogClaimWawa(msg.sender, tokenId, faction, petId, trait, tokenURI, gene, block.timestamp);
    }
}
