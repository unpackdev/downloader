/*

 _______  _______           _______ _________ _______  _        _______ 
(  ____ \(  ____ )|\     /|(  ____ \\__   __/(  ___  )( \      (  ____ \   (for Adventurers) 
| (    \/| (    )|( \   / )| (    \/   ) (   | (   ) || (      | (    \/
| |      | (____)| \ (_) / | (_____    | |   | (___) || |      | (_____ 
| |      |     __)  \   /  (_____  )   | |   |  ___  || |      (_____  )
| |      | (\ (      ) (         ) |   | |   | (   ) || |            ) |
| (____/\| ) \ \__   | |   /\____) |   | |   | )   ( || (____/\/\____) |
(_______/|/   \__/   \_/   \_______)   )_(   |/     \|(_______/\_______)   
    by chris and tony
    
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721BurnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";

import "./Interfaces.sol";
import "./IRift.sol";

/*
  "...you notice the Rift’s force emanating from your bag. You peek inside, 
  and see the glowing force crystalize before your eyes. It’s glowing with the Rift’s power..."
  - Crystal Codex

  Mana Crystals are a Loot derivative & resource management game. Powered by the Rift.

  You need a Loot, gLoot, or mLoot bag to create Mana Crystals. 
  Cost to create your bag's first Crystal is 0.04 for Loot & gLoot, or 0.004 for mLoot.
  Mana yields are 10x for Loot and gLoot compared to mLoot.
  You will get 1000 Mana for creating your first Crystal. (100 for mLoot)

  The Mana Crystals use your bag's Rift level to determine their Mana production.
  Minting and Burning Crystals gives your Bag XP.

  Crystals generate Mana every day. 
  Mana is used to generate more Crystals, purchase Rift Charges, and Questing.

  Available actions:
  - Mint -> Create a new Mana Crystal. Costs Mana + a Rift Charge
  - Claim Mana -> Extracts the generated Mana from the Crystal, resetting the stored Mana to 0.
  - Refocus* (level up) -> Increases Mana production. 
  - Burn* (done at the Rift) -> Burns the Crystal into the Rift. Rewards some Mana and XP.

  *some actions require the Crystal to be Synced i.e., left untouched for some # of days equal to focus.
*/

/// @title Mana Crystals from the Rift
contract Crystals is
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    IRiftBurnable
{
    event CrystalRefocused(address indexed owner, uint256 indexed tokenId, uint256 focus);
    event ManaClaimed(address indexed owner, uint256 indexed tokenId, uint256 amount);

    ICrystalsMetadata public iMetadata;

    IMana public iMana;
    IRift public iRift;
    address internal riftAddress;
    
    uint32 private constant GEN_THRESH = 10000000;
    uint32 private constant glootOffset = 9997460;

    uint64 public mintedCrystals;

    uint8 public maxFocus;
    uint256 public mintFee;
    uint256 public mMintFee;
    uint16[10] private xpTable;

    /// @dev indexed by bagId + (GEN_THRESH * bag generation) == tokenId
    mapping(uint256 => Crystal) public crystalsMap;
    mapping(uint256 => Bag) public bags;

    address private openSeaProxyRegistryAddress;
    bool private isOpenSeaProxyActive;

    function initialize(address manaAddress) public initializer {
        __ERC721_init("Mana Crystals", "MCRYSTAL");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        iMana = IMana(manaAddress);
        maxFocus = 10;
        mintFee = 0.04 ether;
        mMintFee = 0.004 ether;
        xpTable = [15,30,50,75,110,155,210,280,500,800];
        isOpenSeaProxyActive = false;
    }

    //WRITE

    /**
     * @dev Must be used to create the first Crystal with any bag. 
     * @param bagId The id of Loot or mLoot bag, or the id of a gLoot bag + 9997460
     */
    function firstMint(uint256 bagId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(bags[bagId].mintCount == 0, "Use mint crystal");
        require(bagId <= GEN_THRESH, "Bag unrecognized");
        if (bagId < 8001 || bagId > glootOffset) {
            require(msg.value == mintFee, "FEE");
        } else {
            require(msg.value == mMintFee, "FEE");
        }
        // set up bag in rift and give it a charge. does nothing for existing bags in rift
        iRift.setupNewBag(bagId);
        _mintCrystal(bagId);
        iMana.ccMintTo(_msgSender(), (bagId < 8001 || bagId > glootOffset) ? 1000 : 100);
    }

    /**
     * @dev Create a Crystal with a Rift Charge and Mana.
     * @param bagId The id of Loot or mLoot bag, or offset gloot
     */
    function mintCrystal(uint256 bagId)
        external
        whenNotPaused
        nonReentrant
    {
        require(bagId <= GEN_THRESH, "Bag unrecognized");
        require(bags[bagId].mintCount > 0, "Use first mint");
        iMana.burn(_msgSender(), iRift.bags(bagId).level * ((bagId < 8001 || bagId > glootOffset) ? 100 : 10));

        _mintCrystal(bagId);
    }

    function _mintCrystal(uint256 bagId) internal {
        iRift.useCharge(1, bagId, _msgSender());

        uint256 tokenId = getNextCrystal(bagId);

        bags[bagId].mintCount += 1;
        crystalsMap[tokenId] = Crystal({
            focus: 1,
            lastClaim: uint64(block.timestamp) - 1 days,
            focusManaProduced: 0,
            attunement: iRift.bags(bagId).level,
            regNum: uint32(mintedCrystals),
            lvlClaims: 0
        });

        iRift.awardXP(uint32(bagId), 50 + (15 * (iRift.bags(bagId).level - 1)));
        mintedCrystals += 1;
        _safeMint(_msgSender(), tokenId);
    }

    function multiClaimCrystalMana(uint256[] memory tokenIds) 
        external 
        whenNotPaused
        nonReentrant
    {
        for (uint i=0; i < tokenIds.length; i++) {
            _claimCrystalMana(tokenIds[i]);
        }
    }

    /**
     * @dev Mints Mana from Crystal. Can be called once per day.
     * @param tokenId The id of Crystal
     */
    function claimCrystalMana(uint256 tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        _claimCrystalMana(tokenId);
    }

    function _claimCrystalMana(uint256 tokenId) internal ownsCrystal(tokenId) {
        require(crystalsMap[tokenId].lvlClaims < iRift.riftLevel(), "Rift not powerful enough for this action");
        uint32 manaToProduce = claimableMana(tokenId);
        require(manaToProduce > 0, "NONE");
        Crystal memory c = crystalsMap[tokenId];
        crystalsMap[tokenId] = Crystal({
            focus: c.focus,
            lastClaim: uint64(block.timestamp),
            focusManaProduced: c.focusManaProduced + manaToProduce,
            attunement: c.attunement,
            regNum: c.regNum,
            lvlClaims: c.lvlClaims + 1
        });
        bags[tokenId % GEN_THRESH].totalManaProduced += manaToProduce;
        iMana.ccMintTo(_msgSender(), manaToProduce);
        emit ManaClaimed(_msgSender(), tokenId, manaToProduce);
    }

    function multiRefocusCrystal(uint256[] memory tokenIds)
        external
        whenNotPaused
        nonReentrant
    {
        for (uint i=0; i < tokenIds.length; i++) {
            _refocusCrystal(tokenIds[i]);
        }
    }

    /**
     * @dev Levels up a Crystal. Increasing its Focus by 1. 
     * @param tokenId The id of a synced Crystal
     */
    function refocusCrystal(uint256 tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        _refocusCrystal(tokenId);
    }

    function _refocusCrystal(uint256 tokenId) internal ownsCrystal(tokenId) {
        Crystal memory crystal = crystalsMap[tokenId];
        require(crystal.focus < maxFocus, "MAX");
        isSynced(crystal.lastClaim, crystal.focus);
        uint32 mana = claimableMana(tokenId);

        // mint extra mana
        if (mana > (crystal.focus * getResonance(tokenId))) {
            iMana.ccMintTo(_msgSender(), mana - (crystal.focus * getResonance(tokenId)));
        }

        crystalsMap[tokenId] = Crystal({
            focus: crystal.focus + 1,
            lastClaim: uint64(block.timestamp),
            focusManaProduced: 0,
            attunement: crystal.attunement,
            regNum: crystal.regNum,
            lvlClaims: 0
        });

        emit CrystalRefocused(_msgSender(), tokenId, crystal.focus);
    }

    // READ 

    /**
     * @dev Amount of Mana rewarded for refocusing a Crystal
     * @param tokenId The id of a synced Crystal
     */
    function refocusMana(uint256 tokenId) external view returns (uint32) {
        Crystal memory crystal = crystalsMap[tokenId];

        if (diffDays(crystal.lastClaim, block.timestamp) < crystal.focus || crystal.focus == maxFocus) {
            return 0;
        }
        uint32 mana = claimableMana(tokenId);
        if (mana > (crystal.focus * getResonance(tokenId))) {
            return mana - (crystal.focus * getResonance(tokenId));
        } else {
            return 0;
        }
    }

    /**
     * @dev Amount of XP rewarded for minting a Crystal with given bag
     * @param bagId The id of Loot or mLoot bag, or offset gloot
     */
    function mintXP(uint256 bagId) external view returns (uint32) {
        return 50 + (15 * (iRift.bags(bagId).level == 0 ? 0 : iRift.bags(bagId).level - 1));
    }

    function getResonance(uint256 tokenId) public view returns (uint32) {
        // 2 x Focus x OG Bonus * attunement bonus
        return uint32(crystalsMap[tokenId].focus * 2
            * (isOGCrystal(tokenId) ? 10 : 1)
            * attunementBonus(crystalsMap[tokenId].attunement) / 100);
    }

    function getSpin(uint256 tokenId) public view returns (uint32) {
        return uint32((3 * (crystalsMap[tokenId].focus) * getResonance(tokenId)));
    }

    /** @dev increases by 10% each attunement level */
    function attunementBonus(uint16 attunement) internal pure returns (uint32) {
        // first gen
        if (attunement == 1) { return 100; }
        return uint32(11**uint256(attunement) / 10**(attunement-2));
    }

    function claimableMana(uint256 crystalId) public view returns (uint32) {
        uint256 daysSinceClaim = diffDays(
            crystalsMap[crystalId].lastClaim,
            block.timestamp
        );

        if (block.timestamp - crystalsMap[crystalId].lastClaim < 1 days) {
            return 0;
        }

        uint32 manaToProduce = uint32(daysSinceClaim) * getResonance(crystalId);

        // if capacity is reached, limit mana to capacity, ie Spin
        if (manaToProduce > getSpin(crystalId)) {
            manaToProduce = getSpin(crystalId);
        }

        return manaToProduce;
    }

    /** @dev Crystal is synced if it hasn't been claimed or refocused in days equal to current focus */
    function isSynced(uint64 lastClaim, uint16 focus) internal view {
        require(
            diffDays(
                lastClaim,
                block.timestamp
            ) >= focus, "Not Synced"
        );
    }

    /** @dev The rewards the Crystal will give if it's burned */
    function burnObject(uint256 tokenId) external view override returns (BurnableObject memory) {
        isSynced(crystalsMap[tokenId].lastClaim, crystalsMap[tokenId].focus);
        return BurnableObject({
            power: crystalsMap[tokenId].focus + crystalsMap[tokenId].attunement - 1,
            mana: crystalsMap[tokenId].focus * (isOGCrystal(tokenId) ? 100 : 10),
            xp: crystalsMap[tokenId].attunement * xpTable[crystalsMap[tokenId].focus - 1]
        });
    }

    /**
     * @dev Return the token URI through the Loot Expansion interface
     * @param lootId The Loot Character URI
     */
    function getLootExpansionTokenUri(uint256 lootId) external view returns (string memory) {
        return tokenURI(lootId);
    }

    function getNextCrystal(uint256 bagId) internal view returns (uint256) {
        return bags[bagId].mintCount * GEN_THRESH + bagId;
    }

    function availableClaims(uint256 tokenId) external view returns (uint8) {
        return crystalsMap[tokenId].lvlClaims > iRift.riftLevel() ? 0 : uint8(iRift.riftLevel() - crystalsMap[tokenId].lvlClaims);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId);
    }

     function tokenURI(uint256 tokenId) 
        public
        view
        override
        returns (string memory) 
    {
        require(address(iMetadata) != address(0), "no addr set");
        return iMetadata.tokenURI(tokenId);
    }

    // OWNER

    // function to disable gasless listings for security in case
    // opensea ever shuts down or is compromised
    function setIsOpenSeaProxyActive(bool _isOpenSeaProxyActive)
        external
        onlyOwner
    {
        isOpenSeaProxyActive = _isOpenSeaProxyActive;
    }

    function ownerSetOpenSeaProxy(address addr) external onlyOwner {
        openSeaProxyRegistryAddress = addr;
    }

    function ownerUpdateMaxFocus(uint8 maxFocus_) external onlyOwner {
        require(maxFocus > maxFocus, "INV");
        maxFocus = maxFocus_;
    }

    function ownerSetRiftAddress(address addr) external onlyOwner {
        iRift = IRift(addr);
        riftAddress = addr;
    }

    function ownerSetManaAddress(address addr) external onlyOwner {
        iMana = IMana(addr);
    }

    function ownerSetMetadataAddress(address addr) external onlyOwner {
        iMetadata = ICrystalsMetadata(addr);
    }

    function ownerWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    // HELPER

    function isOGCrystal(uint256 tokenId) internal pure returns (bool) {
        // treat OG Loot and GA Crystals as OG
        return tokenId % GEN_THRESH < 8001 || tokenId % GEN_THRESH > glootOffset;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256)
    {
        require(fromTimestamp <= toTimestamp);
        return (toTimestamp - fromTimestamp) / (24 * 60 * 60);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    modifier ownsCrystal(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "UNAUTH");
        _;
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
         // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (
            isOpenSeaProxyActive &&
            address(proxyRegistry.proxies(owner)) == operator
        ) {
            return true;
        }

        if (operator == riftAddress) { return true; }
        return super.isApprovedForAll(owner, operator);
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}