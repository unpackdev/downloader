// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

interface IGGold {
    function mint(address account, uint amount) external;
}

interface IStaking {
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }
    function getAccountGoldMiners(address user) external view returns (Stake[] memory);
    function getAccountPirates(address user) external view returns (Stake[] memory);
}

contract GGoldDispenser is Ownable {
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    IGGold public gold;
    IStaking public staking;

    mapping(uint16 => bool) public claimedFromTokenId;

    uint public constant GOLD_HUNTER_GGOLD_RATE = 20000 ether;
    uint public constant PIRATE_GGOLD_RATE = 40000 ether;

    constructor() {
    }

    function setStaking(address _address) external onlyOwner {
        staking = IStaking(_address);
    }

    function setGold(address _address) external onlyOwner {
        gold = IGGold(_address);
    }

    function claim() external {
        IStaking.Stake[] memory pirateStakes = staking.getAccountPirates(msg.sender);
        IStaking.Stake[] memory minerStakes = staking.getAccountGoldMiners(msg.sender);

        uint owed = 0;
        for (uint i = 0; i < pirateStakes.length; i++) {
            require(claimedFromTokenId[pirateStakes[i].tokenId] == false, "Already claimed from this");
            owed += PIRATE_GGOLD_RATE;
            claimedFromTokenId[pirateStakes[i].tokenId] = true;
        }

        for (uint i = 0; i < minerStakes.length; i++) {
            require(claimedFromTokenId[minerStakes[i].tokenId] == false, "Already claimed from this");
            owed += GOLD_HUNTER_GGOLD_RATE;
            claimedFromTokenId[minerStakes[i].tokenId] = true;
        }
        if (owed == 0) return;

        gold.mint(msg.sender, owed);
    }
}
