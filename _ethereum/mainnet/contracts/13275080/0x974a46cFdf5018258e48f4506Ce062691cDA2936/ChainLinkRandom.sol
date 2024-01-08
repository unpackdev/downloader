// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";

contract ChainLinkRandom is Ownable, VRFConsumerBase {
    event TokenSeed(uint256 seed);

    uint256 public seed;

    uint256 internal fee;
    bytes32 internal keyHash;


    constructor(
        address _VRFCoordinator,
        address _LINKToken,
        bytes32 _keyHash
    ) public VRFConsumerBase(_VRFCoordinator, _LINKToken) {
        keyHash = _keyHash;
        fee = 2 * 10**18; // 2 LINK token
    }

    /**
     * @dev receive random number from chainlink
     * @notice random number will greater than zero
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        if (randomNumber > 0) seed = randomNumber;
        else seed = 1;
        emit TokenSeed(seed);
    }

    function _generateRandomSeed() internal {
        require(LINK.balanceOf(address(this)) >= fee);
        requestRandomness(keyHash, fee);
    }

    /**
     * @dev compute element with shuffle with id
     */
    function shuffleId(
        uint256 _DSA_SUPPLY,
        uint256 _id,
        uint256 _start
    ) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encode(seed, _id)));
        return
            random.mod(_DSA_SUPPLY.sub(_start)).add(_start);
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }
}
