// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./IIsekaiCache.sol";

/**
 * @title IsekaiCache
 * @notice This contract contains all functionality related to the claiming of an Isekai Meta cache token.
 */
contract IsekaiCache is IIsekaiCache, Ownable, ERC721A {
    string private __baseTokenURI;
    uint256[31] private __claims;

    /// Isekai Meta ERC721A token contract.
    IERC721A public constant ISEKAI_META = IERC721A(0x684E4ED51D350b4d76A3a07864dF572D24e6dC4c);

    /**
     * @inheritdoc IIsekaiCache
     */
    ClaimState public claimState;

    constructor(string memory _baseTokenURI) ERC721A("Isekai Cache", "CACHE") {
        _initializeOwner({newOwner: msg.sender});
        _initializeClaims();

        __baseTokenURI = _baseTokenURI;
    }

    /**
     * @inheritdoc IIsekaiCache
     */
    function claimCache(uint256[] calldata tokenIds) external {
        if (tokenIds.length == 0) revert NoIdsProvided();
        if (claimState != ClaimState.ACTIVE) revert InvalidClaimState();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (msg.sender != ISEKAI_META.ownerOf(tokenId)) revert CallerNotOwner();

            /// Calculate the bit that represents the token identifier position in `__claims`.
            uint256 idxOffset = tokenId / 256;
            uint256 bitOffset = tokenId % 256;
            uint256 bit = __claims[idxOffset] >> bitOffset & 1;
            if (bit == 0) revert TokenHasClaimed();

            /// Flip the bit from 1 to 0.
            __claims[idxOffset] = __claims[idxOffset] & ~(1 << bitOffset);
        }

        _mint({to: msg.sender, quantity: tokenIds.length});
    }

    /**
     * @inheritdoc IIsekaiCache
     */
    function toggleClaimState() external onlyOwner {
        claimState = claimState == ClaimState.CLOSED ? ClaimState.ACTIVE : ClaimState.CLOSED;
    }

    /**
     * @inheritdoc IIsekaiCache
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) external onlyOwner {
        __baseTokenURI = newBaseTokenURI;
    }

    /**
     * @inheritdoc IIsekaiCache
     */
    function hasClaimed(uint256[] calldata tokenIds) external view returns (bool[] memory results) {
        if (tokenIds.length == 0) revert NoIdsProvided();

        results = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length;) {
            results[i] = _hasClaimed({tokenId: tokenIds[i]});
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IIsekaiCache
     */
    function hasClaimed(uint256 tokenId) external view returns (bool) {
        return _hasClaimed(tokenId);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       INTERNAL LOGIC                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to set all 256 bits in each index of the `__claims` array to 1.
     */
    function _initializeClaims() internal {
        for (uint256 i = 0; i < __claims.length;) {
            __claims[i] = type(uint256).max;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Function used to determine if an Isekai Meta token has already claimed a cache.
     * @param tokenId Isekai Meta token idenitifier.
     */
    function _hasClaimed(uint256 tokenId) internal view returns (bool) {
        return __claims[tokenId / 256] >> tokenId % 256 & 1 != 1;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC721A OVERRIDES                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Overriden to allow for a modifiable `__baseTokenURI` value.
     */
    function _baseURI() internal view override returns (string memory) {
        return __baseTokenURI;
    }

    /**
     * Override to set the starting token ID to 1.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
