// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IRandom {
    /**
    This struct defines the parameters needed to communicate with a Chainlink
    VRF coordinator.
    @param coordinator The address of the Chainlink VRF coordinator.
    @param link The address of Chainlink's LINK token.
    @param keyHash The key hash of the Chainlink VRF coordinator.
    @param fee The fee in LINK required to utilize Chainlink's VRF service.
  */
    struct Chainlink {
        address coordinator;
        address link;
        bytes32 keyHash;
        uint256 fee;
    }

    function chainlink() external returns (Chainlink memory);

    function random(bytes32 _id) external returns (bytes32);

    function asRange(
        bytes32 _source,
        uint256 _origin,
        uint256 _bound
    ) external view returns (uint256);
}
