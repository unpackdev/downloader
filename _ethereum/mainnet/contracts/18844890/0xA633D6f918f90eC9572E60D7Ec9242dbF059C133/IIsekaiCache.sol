// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title IIsekaiCache
 * @notice Interface for Isekai Cache
 */
interface IIsekaiCache {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERRORS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Thrown when the required claim state is not `ClaimState.ACTIVE`.
     */
    error InvalidClaimState();

    /**
     * Thrown when the provided token identifier has already claimed a cache.
     */
    error TokenHasClaimed();

    /**
     * Thrown when no token identifiers have been provided.
     */
    error NoIdsProvided();

    /**
     * Thrown when the caller is not the owner of the provided token identifier.
     */
    error CallerNotOwner();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ENUMS                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Enum used to manage the possible claim states.
     */
    enum ClaimState {
        CLOSED,
        ACTIVE
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         FUNCTIONS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Function used to view the current `ClaimState` value.
     */
    function claimState() external view returns (ClaimState);

    /**
     * @notice Function used to claim an Isekai Cache on behalf of an Isekai Meta token.
     * @param tokenIds Array of Isekai Meta token identifiers.
     */
    function claimCache(uint256[] calldata tokenIds) external;

    /**
     * @notice Function used to toggle the existing `claimState` value.
     */
    function toggleClaimState() external;

    /**
     * @notice Function used to set a new base token URI.
     * @param newBaseTokenURI Newly desired `__baseTokenURI` value.
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) external;

    /**
     * Function used to check if many Isekai Meta tokens have already claimed a cache.
     * @param tokenIds Array of Isekai Meta token identifiers.
     */
    function hasClaimed(uint256[] calldata tokenIds) external view returns (bool[] memory results);

    /**
     * Function used to check if an Isekai Meta token has already claimed a cache.
     * @param tokenId Isekai Meta token identifier.
     */
    function hasClaimed(uint256 tokenId) external view returns (bool);
}
