// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./ERC721.sol";
import "./IERC721.sol";

interface IRoyale is IERC721 {
    function getHP(uint256 player) external view returns (uint256);

    function getAP(uint256 player) external view returns (uint256);

    function attack(
        uint256 player1,
        uint256 player2,
        uint256 ap
    ) external;

    function heal(uint256 player, uint256 ap) external;

    function flee(uint256 player) external;

    function claimPrize(uint256 winner) external;
}

/**
 * @notice dao contract for https://twitter.com/andy8052/status/1553034869445369859
 * enter multiple players->kill enemies->profit
 * @dev not worried about looping over unbounded arrays since not that many nfts in circulation
 * @author rayquaza7
 */
contract BattleRoyaleDao is ERC20, ERC721TokenReceiver {
    /// @dev mainnet address
    IRoyale constant bRoyale =
        IRoyale(0x8e094bC850929ceD3B4280Cc031540A897F39706);

    /// @dev gnosis safe address for killsafe
    address immutable supremeLeader;

    /// @dev store all ids for attack
    uint256[] players;
    /// @dev playerId->owner
    mapping(uint256 => address) public playerOwners;

    // /// @dev whale ids
    // uint[] ids =

    constructor(
        string memory _name,
        string memory _symbol,
        address _supremeLeader
    ) ERC20(_name, _symbol, 18) {
        supremeLeader = _supremeLeader;
    }

    /**
     * @notice deposit your players and receive 1 erc20 token in return for each
     * @dev this contract must be approved by msg.sender
     * assumes one user will have multiple players
     * if not change it to have the asset transfered first before calling it
     * only players that entered the game before it started can enter
     * will not check if game has ended, be careful, saves gas.
     * will not let whale enter, bad whale.
     * @param playerIds list of players ids to transfer
     */
    function enter(uint256[] calldata playerIds) public {
        require(
            bRoyale.isApprovedForAll(msg.sender, address(this)),
            "not approved"
        );
        for (uint256 x = 0; x < playerIds.length; x++) {
            require(!(playerIds[x] >= 57 && playerIds[x] <= 86), "no whale");
            uint256 hp = bRoyale.getHP(playerIds[x]);
            require(hp != 0, "Not in game");
            bRoyale.transferFrom(msg.sender, address(this), playerIds[x]);
            playerOwners[playerIds[x]] = msg.sender;
            players.push(playerIds[x]);
            _mint(msg.sender, 1);
        }
    }

    /**
     * @notice redeem erc20 token and flee the game
     * @dev reverts if player is dead
     * will revert if token balance is insufficient
     * will transfer eth that to you that u get after fleeing
     */
    function flee(uint256 playerId) public {
        require(playerOwners[playerId] == msg.sender, "Not yours");
        delete playerOwners[playerId];
        for (uint256 x; x < players.length; x++) {
            if (players[x] == playerId) {
                delete players[x];
                break;
            }
        }
        _burn(msg.sender, 1);
        uint256 currentBalance = address(this).balance;
        bRoyale.flee(playerId);
        uint256 postBalance = address(this).balance;
        payable(msg.sender).transfer(postBalance - currentBalance);
    }

    /**
     * @notice heal your player
     * @dev daos not gonna pay for healing; players must call it individually
     */
    function heal(uint256 playerId, uint256 ap) public {
        require(playerOwners[playerId] == msg.sender, "Not yours");
        bRoyale.heal(playerId, ap);
    }

    /**
     * @notice choose a player and deliver a kill shot to one of the players,
     * restrict access to dao
     * wrap in a try catch in case asset is dead
     * TODO: use multicall to define custom ap
     */
    function killShot(uint256 playerIdToAttack, uint256 ap) public {
        require(msg.sender == supremeLeader, "no access");
        for (uint256 x; x < players.length; x++) {
            if (bRoyale.getHP(playerIdToAttack) == 0) break;
            try bRoyale.attack(players[x], playerIdToAttack, ap) {} catch {}
        }
    }

    /**
     * @notice claim reward if u think u won
     * make sure to use correct player id else it'll revert
     * will revert if any win condition is not met
     */
    function claim(uint256 playerId) public {
        bRoyale.claimPrize(playerId);
    }

    /**
     * @notice Once the game ends and dao wins.
     * Winnings will be distributed pro rata according to the erc20 held by the user
     */
    function withdraw() public {
        uint256 userBalance = balanceOf[msg.sender];
        payable(msg.sender).transfer(
            address(this).balance * (userBalance / totalSupply)
        );
    }
}
