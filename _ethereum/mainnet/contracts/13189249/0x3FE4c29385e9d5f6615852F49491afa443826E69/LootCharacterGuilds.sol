// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";


interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// LootGuilds can mint LootCharacter/LootCharacter Note
interface LootCharacterWorldContract {
    function mint(address owner) external;  // Loot Character Note
    function mint(uint256 tokenId, address owner) external;  // Loot Character
}


contract LootCharacterGuilds is Ownable, Pausable {
    event AssociateLootWithGuild(uint256 tokenId, uint256 guildId);

    // Number of Guilds
    uint256 public TOTAL_GUILDS = 9;

    // There are 8000 Loot. More Loot starts at 8001
    uint256 private TOTAL_LOOT = 8000;

    // "Mint" fee
    uint256 public associateWithGuildFee;

    // Loot and mLoop addresses
    address public lootAddress;
    address public mLootAddress;

    // Loot Character Contract
    address private lootCharacterContractAddress;

    // Loot Character Note Contract
    address private lootCharacterNoteContractAddress;

    // Mapping from Guild ID to Guild Name
    mapping(uint256 => string) public guilds;

    // Mapping from Guild ID to Guild Vault Address
    mapping(uint256 => address) public guildVaults;

    // Mapping from Bag ID to Guild ID
    mapping(uint256 => uint256) public guildLoots;

    constructor(address[9] memory _guildVaults, string[9] memory _guilds, uint256 _associateWithGuildFee, address _lootAddress, address _mLootAddress, address _lootCharacterContractAddress, address _lootCharacterNoteContractAddress) {
        associateWithGuildFee = _associateWithGuildFee;
        lootAddress = _lootAddress;
        mLootAddress = _mLootAddress;
        lootCharacterContractAddress = _lootCharacterContractAddress;
        lootCharacterNoteContractAddress = _lootCharacterNoteContractAddress;
        for(uint i=1; i <= TOTAL_GUILDS; i++) {
            guildVaults[i] = _guildVaults[i-1];
            guilds[i] = _guilds[i-1];
        }
    }

    /**
     * @dev Set the cost (in wei) to associate a Loot item with a Guild
     * @param _associateWithGuildFee Fee in wei
     */
    function setAssociateWithGuildFee(uint _associateWithGuildFee) external onlyOwner {
        associateWithGuildFee = _associateWithGuildFee;
    }

    /**
     * @dev Associate a Loot Bag with a Guild. This costs the caller `associateWithGuildFee` wei.
     * @param tokenId The Loot Bag to associate with a Guild.
     */
    function joinGuild(uint256 tokenId, uint256 guildId) external payable whenNotPaused {
        require(msg.value >= associateWithGuildFee, "Not enough ETH to associate");
        require(msg.sender == LootInterface(lootAddress).ownerOf(tokenId));
        require(guildLoots[tokenId] == 0, "Already assigned to a Guild");
        require(guildId > 0 && guildId < TOTAL_GUILDS, "Not a Guild ID");  // NOTE - Only 8 guilds are joinable. 9th is the treasury guild.
        require(tokenId > 0 && tokenId <= TOTAL_LOOT, "Must be within Loot range");  // We're only allowing Loot to associate for now.

        // Update state
        guildLoots[tokenId] = guildId;

        // Mint LootCharacter and LootcharacterNote
        LootCharacterWorldContract lootCharacter = LootCharacterWorldContract(lootCharacterContractAddress);
        LootCharacterWorldContract lootCharacterNote = LootCharacterWorldContract(lootCharacterNoteContractAddress);
        lootCharacter.mint(tokenId, msg.sender);
        lootCharacterNote.mint(msg.sender);

        // Transfer
        uint256 amtPerRecipient = msg.value / 3;
        payable(guildVaults[guildId]).transfer(amtPerRecipient);
        payable(guildVaults[TOTAL_GUILDS]).transfer(amtPerRecipient);
        payable(owner()).transfer(amtPerRecipient);
        emit AssociateLootWithGuild(tokenId, guildId);
    }

    /**
     * @dev Flip the paused bit
     */
    function flipPaused() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

}
