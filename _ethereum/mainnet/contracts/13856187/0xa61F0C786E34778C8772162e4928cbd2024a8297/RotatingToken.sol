// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

library RotatingToken {

    /**
     * @dev Gets the timestamp for rotation calculations from storage slot.
     * @return _timestamp UNIX timestamp from which to calculate rotations.
     */
    function getStartTimestamp() internal view returns (uint256 _timestamp) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.RotatingToken.startTimestamp')) - 1);
        assembly {
            _timestamp := sload(
                /* slot */
                0xe51ee22146f4be2b058d665ad864b055bc45a4c8ad1bc6964820072aff854bf4
            )
        }
    }

    /**
     * @dev Sets the timestamp for rotation calculations to storage slot.
     * @param _timestamp UNIX timestamp from which to calculate rotations.
     */
    function setStartTimestamp(uint256 _timestamp) internal {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.RotatingToken.startTimestamp')) - 1);
        assembly {
            sstore(
                /* slot */
                0xe51ee22146f4be2b058d665ad864b055bc45a4c8ad1bc6964820072aff854bf4,
                _timestamp
            )
        }
    }

    /**
     * @dev Gets the configuration for rotation calculations from storage slot.
     * @return interval The number of seconds each rotation is shown for.
     * @return steps Total number of steps for complete rotation. Reverse rotation including.
     * @return halfwayPoint Step at which to reverse the rotation backwards. Must be exactly in the middle.
     */
    function getRotationConfig() internal view returns (uint256 interval, uint256 steps, uint256 halfwayPoint) {
        uint48 unpacked;
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.RotatingToken.rotationConfig')) - 1);
        assembly {
            unpacked := sload(
                /* slot */
                0xd29f19547f24a5ccc86f14d7d83b6b987865a37f065e1c2eacd6b3b5be17886e
            )
        }
        interval = uint256(uint16(unpacked >> 32));
        steps = uint256(uint16(unpacked >> 16));
        halfwayPoint = uint256(uint16(unpacked));
    }
    function getRotationConfig(uint256 index) internal view returns (uint256 interval, uint256 steps, uint256 halfwayPoint) {
        uint48 unpacked;
        bytes32 slot = bytes32(uint256(keccak256(abi.encodePacked("eip1967.CXIP.RotatingToken.rotationConfig.", index))) - 1);
        assembly {
            unpacked := sload(slot)
        }
        interval = uint256(uint16(unpacked >> 32));
        steps = uint256(uint16(unpacked >> 16));
        halfwayPoint = uint256(uint16(unpacked));
    }

    /**
     * @dev Sets the configuration for rotation calculations to storage slot.
     * @param interval The number of seconds each rotation is shown for.
     * @param steps Total number of steps for complete rotation. Reverse rotation including.
     * @param halfwayPoint Step at which to reverse the rotation backwards. Must be exactly in the middle.
     */
    function setRotationConfig(uint256 interval, uint256 steps, uint256 halfwayPoint) internal {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.RotatingToken.rotationConfig')) - 1);
        uint256 packed = uint256(interval << 32 | steps << 16 | halfwayPoint);
        assembly {
            sstore(
                /* slot */
                0xd29f19547f24a5ccc86f14d7d83b6b987865a37f065e1c2eacd6b3b5be17886e,
                packed
            )
        }
    }
    function setRotationConfig(uint256 index, uint256 interval, uint256 steps, uint256 halfwayPoint) internal {
        bytes32 slot = bytes32(uint256(keccak256(abi.encodePacked("eip1967.CXIP.RotatingToken.rotationConfig.", index))) - 1);
        uint256 packed = uint256(interval << 32 | steps << 16 | halfwayPoint);
        assembly {
            sstore(slot, packed)
        }
    }

    function calculateRotation(uint256 tokenId, uint256 tokenSeparator) internal view returns (uint256 rotationIndex) {
        uint256 configIndex = (tokenId / tokenSeparator);
        (uint256 interval, uint256 steps, uint256 halfwayPoint) = getRotationConfig(configIndex);
        rotationIndex = ((block.timestamp - getStartTimestamp()) % (interval * steps)) / interval;
        if (rotationIndex > halfwayPoint) {
            rotationIndex = steps - rotationIndex;
        }
       rotationIndex = rotationIndex + ((halfwayPoint + 1) * configIndex);
    }

}
