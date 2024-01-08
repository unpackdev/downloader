pragma solidity ^0.7.0;

import "./interfaces.sol";

abstract contract Variables {
    /**
     * @dev Insta AaveV2 Merkle
     */
    InstaAaveV2MerkleInterface immutable internal instaAaveV2Merkle;

    constructor(address _instaAaveV2Merkle) {
        instaAaveV2Merkle = InstaAaveV2MerkleInterface(_instaAaveV2Merkle);
    }
}
