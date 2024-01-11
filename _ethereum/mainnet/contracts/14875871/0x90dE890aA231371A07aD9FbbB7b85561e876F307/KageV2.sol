// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

interface iMetakages {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract KAGEV2 is ERC20, Ownable {
    iMetakages public Metakages;

    uint256 public constant BASE_RATE = 1 ether;
    uint256 public START;
    bool rewardPaused = false;

    mapping(uint256 => uint256) public lastUpdate;

    uint256 TIME_RATE = 86400;

    constructor(address MetakagesAddress) ERC20("Kage", "KAGE") {
        Metakages = iMetakages(MetakagesAddress);
        START = block.timestamp;
        _mint(msg.sender,300000 ether);
    }

    //Write Functions

    function purchaseBurn(address user, uint256 amount) external {
        require(tx.origin == user, "Only the user can purchase and burn");
        _burn(user, amount);
    }

    function claimAllRewards(uint256[] memory tokensOfOwner) external {
        require(!rewardPaused, "Claiming reward has been paused");
        uint256 pendingRewards = getPendingRewards(tokensOfOwner);
        for (uint256 i = 0; i < tokensOfOwner.length; i++) {
            require(
                Metakages.ownerOf(tokensOfOwner[i]) == msg.sender,
                "Only the owner can claim rewards"
            );
            lastUpdate[tokensOfOwner[i]] = block.timestamp;
        }
        _mint(msg.sender, pendingRewards);
    }

    function getPendingRewards(uint256[] memory tokensOfOwner)
        public
        view
        returns (uint256)
    {
        uint256 reward = 0;
        for (uint256 i = 0; i < tokensOfOwner.length; i++) {
            reward +=
                ((BASE_RATE) *
                    (block.timestamp -
                        (
                            lastUpdate[tokensOfOwner[i]] >= START
                                ? lastUpdate[tokensOfOwner[i]]
                                : START
                        ))) /
                TIME_RATE;
        }
        return reward;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }

}
