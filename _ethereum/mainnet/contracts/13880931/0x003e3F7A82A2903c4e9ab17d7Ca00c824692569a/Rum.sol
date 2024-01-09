// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";

interface IGoldHunter {
    function ownerOf(uint id) external view returns (address);
}
interface ITreasureIsland {
    function getAccountGoldMiners(address user) external view returns (Stake[] memory);
    function getAccountPirates(address user) external view returns (Stake[] memory);
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }
}

contract Rum is ERC1155, Ownable, Pausable {
    uint constant public TOKEN_ID = 0;

    uint public minted;

    IGoldHunter public goldHunter;
    ITreasureIsland public treasureIsland;

    mapping(uint => bool) public usedTokens;
    mapping(address => bool) public approvedManagers;

    constructor() ERC1155("https://gold-hunt-rum.herokuapp.com/meta/{id}") {
        _pause();
    }

    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function giveAway(address to, uint amount) public onlyOwner {
        _mint(to, TOKEN_ID, amount, "");
    }

    // This method should be available only for owners of Gen0 collection
    // Minting for these holders is free (gas fee only)
    function mint(uint16[] calldata unstakedTokens) external whenNotPaused {
        uint gen0ids = 0;

        ITreasureIsland.Stake[] memory stake = treasureIsland.getAccountGoldMiners(msg.sender);
        ITreasureIsland.Stake[] memory stakePirates = treasureIsland.getAccountPirates(msg.sender);

        for (uint i = 0; i < stake.length; i++) {
            // Check for Gen0, tokenId < 10000
            require(stake[i].tokenId < 10000, "Not a Gen0 token, cannot mint");


            if (usedTokens[stake[i].tokenId] == false) {
                gen0ids += 1;
                usedTokens[stake[i].tokenId] = true;
            }
        }

        for (uint i = 0; i < stakePirates.length; i++) {
            // Check for Gen0, tokenId < 10000
            require(stakePirates[i].tokenId < 10000, "Not a Gen0 token, cannot mint");

            if (usedTokens[stakePirates[i].tokenId] == false) {
                gen0ids += 1;
                usedTokens[stakePirates[i].tokenId] = true;
            }
        }

        // Need to validate all the tokenId belong to user and mint appropriate amount of tokens
        for (uint i = 0; i < unstakedTokens.length; i++) {
            // Check for Gen0, tokenId < 10000
            require(unstakedTokens[i] < 10000, "Not a Gen0 token, cannot mint");
            require(goldHunter.ownerOf(unstakedTokens[i]) == msg.sender, "Only unstaked tokens");


            if (usedTokens[unstakedTokens[i]] == false) {
                gen0ids += 1;
                usedTokens[unstakedTokens[i]] = true;
            }
        }

        if (gen0ids == 0) {
            revert();
        }
        minted += gen0ids;

        _mint(msg.sender, TOKEN_ID, gen0ids, "");
    }

    function availableClaims(uint16[] calldata tokenIds) external view returns(uint count) {
        uint gen0ids = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] < 10000 && usedTokens[tokenIds[i]] == false) {
                gen0ids += 1;
            }
        }

        return gen0ids;
    }

    function burn(address account, uint amount) external whenNotPaused {
        require(minted > 0 && amount > 0 && minted - amount >= 0, "Invalid parameters");
        require(msg.sender == account || approvedManagers[msg.sender], "You are not allowed to do that");

        minted -= amount;
        _burn(account, TOKEN_ID, amount);
    }

    function setTreasureIsland(address _address) external onlyOwner {
        treasureIsland = ITreasureIsland(_address);
    }
    function setGoldHunter(address _address) public onlyOwner {
        goldHunter = IGoldHunter(_address);
    }
    function addManager(address _address) external onlyOwner {
        approvedManagers[_address] = true;
    }
    function removeManager(address _address) external onlyOwner {
        approvedManagers[_address] = false;
    }
    function totalSupply() external view returns (uint) {
        return minted;
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function pause() external onlyOwner {
        _pause();
    }
}