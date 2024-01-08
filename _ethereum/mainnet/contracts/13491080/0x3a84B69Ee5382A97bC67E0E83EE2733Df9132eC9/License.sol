// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";

contract NiftyBotsLicense is ERC721, Ownable, Pausable, ERC721Burnable, ERC721Enumerable {
    using Counters for Counters.Counter;

    enum Tier {NONE, FREE, SEED, NIFTY, FOREVER}

    struct License {
        uint256 season;
        Tier tier;
        uint256 validUntil;
    }

    struct TierConfig {
        Tier tier;
        uint256 weiAmount;
        uint256 validDuration;
    }

    string private _baseTokenURI = "https://license.niftybots.app/metadata/";
    string private _ipfsURI;
    uint256 private _ipfsAt;

    // token ID => license info
    mapping(uint256 => License) public licenses;

    // tier configuration
    // tier config ID => tier config
    mapping(uint256 => TierConfig) public tierConfigs;

    // allow list for private minting of a free license
    // allowed address => allowed free mint flag
    mapping(address => bool) public freeMintAllowList;
    bool public freeForAll = false;

    // one-off discounts
    // address => discount in percent
    mapping(address => uint8) public discountList;

    uint8 public burnDiscount = 20; // percent

    Counters.Counter private _tokenIdCounter;
    uint8 private constant FOREVER_LICENSE_DURATION = 1;

    Counters.Counter private _seasonCounter;
    uint256 public seasonDuration = 26 weeks; // roughly 6 months
    uint256 currentSeasonStartDate;
    uint256[] public seasonStartDates;

    event LicenseMinted(address account, uint256 tokenId);
    event SeasonChanged(uint256 newSeason, uint256 newSeasonStartDate, uint256 firstTokenId);

    constructor() ERC721("NiftyBots License", "NBL") {
        // initialize first season
        _changeSeason();

        // setup initial tier structure
        tierConfigs[1] = TierConfig(Tier.FREE, 0 ether, 26 weeks);
        tierConfigs[2] = TierConfig(Tier.SEED, 0.3 ether, 26 weeks);
        tierConfigs[3] = TierConfig(Tier.NIFTY, 0.6 ether, 26 weeks);
        tierConfigs[4] = TierConfig(Tier.FOREVER, 2 ether, FOREVER_LICENSE_DURATION);
    }

    // region metadata

    /**
     * @notice Change the base URI for returning metadata
     *
     * @param baseTokenURI the respective base URI
     */
    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @notice Change the base URI for returning metadata and change the ipfs token index.
     *
     * @param ipfsURI the respective ipfs base URI
     * @param untilId the token index of the last token covered by ipfs
     */
    function updateIpfs(string memory ipfsURI, uint256 untilId) external onlyOwner {
        _ipfsURI = ipfsURI;
        _ipfsAt = untilId;
    }

    function _baseURI(uint256 tokenId) internal view returns (string memory) {
        if (tokenId > _ipfsAt) {
            return _baseTokenURI;
        } else {
            return _ipfsURI;
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Query for nonexistent token");

        string memory baseURI = _baseURI(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId))) : "";
    }

    function isLicenseValid(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Query for nonexistent token");
        return (licenses[tokenId].validUntil > block.timestamp || licenses[tokenId].validUntil == FOREVER_LICENSE_DURATION);
    }

    // endregion

    // region various admin tasks

    function setPublicSalePaused(bool paused) external onlyOwner {
        if (paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * Toggles free for all, which allows minting of free licenses without allow list.
     */
    function setFreeForAll(bool ffa) external onlyOwner {
        freeForAll = ffa;
    }

    function setBurnDiscount(uint8 newDiscount) external onlyOwner {
        require(newDiscount < 101, "Discount must be less than 101");
        burnDiscount = newDiscount;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(_msgSender()), address(this).balance);
    }

    receive() external payable {}

    // endregion

    // region seasons

    function updateSeasonDuration(uint256 newDuration) external onlyOwner {
        require(newDuration > 0, "Duration must be larger than 0.");
        seasonDuration = newDuration;
    }

    function currentSeason() external view returns (uint256 season) {
        return _seasonCounter._value;
    }

    function currentSeasonEndsAt() external view returns (uint256 season) {
        return currentSeasonStartDate + seasonDuration;
    }

    function changeSeasonIfRequired() internal {
        if (block.timestamp > currentSeasonStartDate + seasonDuration) {
            _changeSeason();
        }
    }

    function _changeSeason() internal {
        _seasonCounter.increment();
        currentSeasonStartDate = block.timestamp;
        seasonStartDates.push(block.timestamp);
        emit SeasonChanged(_seasonCounter._value, currentSeasonStartDate, _tokenIdCounter.current());
    }

    // endregion

    // region tier management

    function updateTierConfigs(
        uint256[] calldata ids,
        Tier[] calldata tiers,
        uint256[] calldata weiAmounts,
        uint256[] calldata validDurations
    ) external onlyOwner {
        require(ids.length < 11, "Can only update 10 at a time.");
        for (uint256 i; i < ids.length; i++) {
            tierConfigs[ids[i]] = TierConfig(tiers[i], weiAmounts[i], validDurations[i]);
        }
    }

    function removeTierConfigs(uint256[] calldata tierIds) external onlyOwner {
        for (uint256 i; i < tierIds.length; i++) {
            delete tierConfigs[tierIds[i]];
        }
    }

    // endregion

    // region free tier allow list

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        require(addresses.length < 11, "Can only update 10 at a time.");
        for (uint256 i; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");
            freeMintAllowList[addresses[i]] = true;
        }
    }

    function removeFromAllowList(address[] calldata addresses) external onlyOwner {
        require(addresses.length < 11, "Can only update 10 at a time.");
        for (uint256 i; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't remove the null address");
            freeMintAllowList[addresses[i]] = false;
        }
    }

    function canMintFree(address addr) external view returns(bool) {
        return freeForAll || freeMintAllowList[addr];
    }

    // endregion

    // region discounts

    function setDiscounts(address[] calldata addresses, uint8[] calldata discounts) public onlyOwner {
        require(addresses.length < 11, "Can only update 10 at a time.");
        for (uint256 i; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't set discount for the null address");

            if (discounts[i] == 0) { // remove discount
                delete discountList[addresses[i]];
            } else {
                require(discounts[i] < 101, "Discount must be < 100");
                discountList[addresses[i]] = discounts[i];
            }
        }
    }

    // endregion

    // region license minting

    /**
     * @notice Mint a custom license for some address.
     *
     * @param tier the license tier
     * @param validUntil timestamp until when the license shall be valid
     * @param to the address to receive the license
     */
    function mintCustomLicense(Tier tier, uint256 validUntil, address to) public onlyOwner {
        require(tier != Tier.NONE, 'This tier does not exist.');
        require(to != address(0), 'Cannot mint to null address.');
        _performMint(tier, validUntil, to);
    }

    /**
     * @notice Mint a specific license for some address.
     *
     * @param tierId the license tier ID
     * @param to the address to receive the license
     */
    function mintLicenseToAddress(uint256 tierId, address to) public onlyOwner {
        TierConfig storage tierConfig = tierConfigs[tierId];
        mintCustomLicense(tierConfig.tier, _calculateValidUntil(tierConfig.validDuration), to);
    }

    /**
     * @notice Mint licenses of given tiers to self.
     *
     * @param tierIds the license tier ids
     */
    function mintLicenses(uint256[] calldata tierIds) public onlyOwner {
        for (uint256 i; i < tierIds.length; i++) {
            mintLicenseToAddress(tierIds[i], _msgSender());
        }
    }

    function mintLicense(uint256 tierId) external payable whenNotPaused {

        TierConfig storage tierConfig = tierConfigs[tierId];
        require(tierConfig.tier != Tier.NONE, 'This tier does not exist.');

        address sender = _msgSender();
        if (tierConfig.tier == Tier.FREE) {
            if (!freeForAll) {  // require on allow list to get free license unless free for all is active
                require(freeMintAllowList[sender], 'Address cannot mint a free license.');
                // free mint is one-time use
                delete freeMintAllowList[sender];
            }
        } else {
            // calculate discount and remove from discount list if applicable
            uint8 discount = discountList[sender];
            delete discountList[sender];

            // require enough eth to pay
            uint256 discountAmount = tierConfig.weiAmount * discount / 100;
            require((tierConfig.weiAmount - discountAmount) <= msg.value, 'ETH amount is not sufficient');
        }

        _performMint(tierConfig.tier, _calculateValidUntil(tierConfig.validDuration), sender);
    }

    function _performMint(Tier tier, uint256 validUntil, address to) internal {
        require(validUntil == FOREVER_LICENSE_DURATION || validUntil > block.timestamp, 'validUntil must be in the future.');

        // start at token ID 1
        _tokenIdCounter.increment();

        // increment token counter first so the change season event can hold the first token id of the season
        changeSeasonIfRequired();

        uint256 tokenId = _tokenIdCounter.current();
        licenses[tokenId] = License(_seasonCounter._value, tier, validUntil);
        _safeMint(to, tokenId);

        emit LicenseMinted(to, tokenId);
    }

    function _calculateValidUntil(uint256 validDuration) internal view returns (uint256) {
        return validDuration == FOREVER_LICENSE_DURATION ? FOREVER_LICENSE_DURATION : block.timestamp + validDuration;
    }

    // endregion

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        // discount for next purchase when burning
        address owner = ERC721.ownerOf(tokenId);

        if (licenses[tokenId].tier == Tier.FREE) {
            freeMintAllowList[owner] = true;
        } else {
            uint8 currentDiscount = discountList[owner];
            // only apply burn discount if actually more than any current discount they might have
            if (burnDiscount > currentDiscount) {
                discountList[owner] = burnDiscount;
            }
        }

        // remove on chain metadata
        delete licenses[tokenId];

        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
