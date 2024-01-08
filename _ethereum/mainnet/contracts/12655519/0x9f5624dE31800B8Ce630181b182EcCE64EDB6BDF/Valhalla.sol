// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721EnumerableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ValhallaStorageV1.sol";

struct GameWinner {
    address addr;
    uint8 rank;
}

struct SpecialWinner {
    address addr;
    uint8 level;
}

struct ValhallaPlanetWithMetadata {
    uint256 id;
    address owner;
    ValhallaPlanet planet;
}

contract Valhalla is ERC721EnumerableUpgradeable, ValhallaStorageV1 {
    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "not admin");
        _;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory base = "https://darkforest-valhalla.s3.us-east-2.amazonaws.com/";
        ValhallaPlanet memory planet = planets[tokenId];
        return
            string(
                abi.encodePacked(
                    base,
                    "r",
                    StringsUpgradeable.toString(uint256(planet.roundId)),
                    "-",
                    StringsUpgradeable.toString(uint256(planet.rank)),
                    "-",
                    StringsUpgradeable.toString(tokenId)
                )
            );
    }

    function changeAdmin(address newAdminAddress) public onlyAdmin {
        adminAddress = newAdminAddress;
    }

    function initialize(address _adminAddress) public initializer {
        adminAddress = _adminAddress;
    }

    function bulkAddGameWinners(uint8 roundId, GameWinner[] memory gameWinners) public onlyAdmin {
        for (uint16 i = 0; i < gameWinners.length; i++) {
            require(gameWinnerRanks[roundId][gameWinners[i].addr] == 0, "already added");
            require(!gameWinnerCanClaim[roundId][gameWinners[i].addr], "already added");
            gameWinnerRanks[roundId][gameWinners[i].addr] = gameWinners[i].rank;
            gameWinnerCanClaim[roundId][gameWinners[i].addr] = true;
        }
    }

    function bulkAddSpecialWinners(uint8 roundId, SpecialWinner[] memory specialWinners)
        public
        onlyAdmin
    {
        for (uint16 i = 0; i < specialWinners.length; i++) {
            require(specialWinnerLevels[roundId][specialWinners[i].addr] == 0, "already added");
            require(!specialWinnerCanClaim[roundId][specialWinners[i].addr], "already added");
            specialWinnerLevels[roundId][specialWinners[i].addr] = specialWinners[i].level;
            specialWinnerCanClaim[roundId][specialWinners[i].addr] = true;
        }
    }

    function getLevelFromRank(uint8 rank) private pure returns (uint8 level) {
        if (rank == 1) {
            level = 7;
        } else if (rank < 4) {
            level = 6;
        } else if (rank < 8) {
            level = 5;
        } else if (rank < 16) {
            level = 4;
        } else if (rank < 32) {
            level = 3;
        } else if (rank < 64) {
            level = 2;
        }
    }

    function getTokenId(
        address player,
        uint8 roundId,
        uint8 planetType
    ) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(player, uint8(roundId), planetType))); // player, roundId, planetType
    }

    function claimWinner(uint8 roundId) public {
        require(gameWinnerCanClaim[roundId][msg.sender], "can't claim");

        uint256 tokenId = getTokenId(msg.sender, roundId, 0);

        uint8 playerRank = gameWinnerRanks[roundId][msg.sender];
        ValhallaPlanet memory planet =
            ValhallaPlanet({
                originalWinner: msg.sender,
                roundId: roundId,
                level: getLevelFromRank(playerRank),
                rank: playerRank,
                planetType: 0
            });

        gameWinnerCanClaim[roundId][msg.sender] = false;
        planets[tokenId] = planet;

        _mint(msg.sender, tokenId);
    }

    function claimSpecial(uint8 roundId) public {
        require(specialWinnerCanClaim[roundId][msg.sender], "can't claim");

        uint256 tokenId = getTokenId(msg.sender, uint8(roundId), 1);

        ValhallaPlanet memory planet =
            ValhallaPlanet({
                originalWinner: msg.sender,
                roundId: roundId,
                level: specialWinnerLevels[roundId][msg.sender],
                rank: 0,
                planetType: 1
            });

        specialWinnerCanClaim[roundId][msg.sender] = false;
        planets[tokenId] = planet;

        _mint(msg.sender, tokenId);
    }

    /**
     * Returns a struct of the planet and its owner and tokenID. Throws if token with this ID doesn't exist.
     */
    function getPlanetWithMetadata(uint256 tokenId)
        public
        view
        returns (ValhallaPlanetWithMetadata memory)
    {
        return
            ValhallaPlanetWithMetadata({
                id: tokenId,
                owner: ownerOf(tokenId),
                planet: planets[tokenId]
            });
    }
}
