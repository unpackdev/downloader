// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";
import "./Flowtys.sol";

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.         @@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         ,@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@             @@@@@@@@@@@              /@@@@@@@@@@@@@@@                         @@@@@@@@@@@          @@@@@@@@@@@@@              @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@                     @@@@@                 @@@@@@@@@@@@@@             @@@@@       @@@@@@@@@@             @@@@@@@@@@        @   @  @@@@@@@@@@@@@@@@@@@
@@@@@@@              @@           @@                  @@@@@@@@@@@@@@@  @          @@@        @@@@@@@@@@   @   @       @@@@@@@     @   @   @@@@@@@@@@@@@@@@@@@@@@
@@@@@@        @@@    @@            @@                 @@@@@         @@@@@@*                *@@@@@@@@@@@@@@@@  @         @@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@        @@      @@@@          #@@              *@@@               (@@@              @@@@     @@@@     @@@@@@@@              @@@@@@                       @@
@@@@@         @@@      @@           @@@            @@@                   @@@           @@@@       @@@       @@@@@@            ,@@@@@@@            *@@@   @    @@
@@@@@                               @@@@&@   @@   @@@        @@@@@@      @@@@          @@@        @@        @@@@@           @@@@@@@@@@                   @@@@@@@
@@@@@@                              @@@@@@   @@@@@@@        @@@@        @@@@@         &@@@                 @@@@@            @@@@@@@@@@@@@@@@@@@@@@@         @@@@
@@@@@@                              @@@@@@@@@@@@@@@                  @@@@@@@@        @@@@@                @@@@@              @@@@@@@       @@@@@@@@@         @@@
@@@@@@                              @@@@@@@@@@@@@@                    *@@@@@@       @@@@@@                @@@@@              *@@@@                            @@
@@@@@         @@         @@@@        @@@@@@@@@@@@@@          @@       @@@@@@@      .@@@@@       @@        .@@@@               @@@                             @@
@@@@@        @@@@       @@@@@         @@@@@@@@@@@@@@%       .@@@      @@@@@@@@     @@@@@       @@@         @@@@               @@@                            @@@
@@@@@        @@@@        @@@@         @@@@@@@@@@@@@@@       @@@@        @@@@@@@@@@@@@@@@       @@         @@@@@              @@@@    @@    @                @@@@
@@@@@@       @@@@        @@@@@       @@@@@@@@@@@@@@@     @@@@@@@@        @@@@@@@@@@@@@@@      @@@        @@@@@@@@          @@@@@@@   @    @@@    @@&      @@@@@@
@@@@@@@@@@@@@@@@@@@%   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@     @@@@@@@@@/      @@@@@@@@@@@@@@@@@% @@@@@@@@@@@@@@@@@@@@@@@@@ (@@@@@@@@@@@@@@@   @@@@@@@@@@      /@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/
contract Morphys is ERC721, ERC721Enumerable, Ownable {
    using Math for uint256;
    using Strings for string;
    using Strings for uint256;

    uint256 public constant MAX_MORPHYS = 10000;
    uint256 public maxPerMint = 100;
    bool public mintingIsActive = false;
    bool public morphingIsActive = false;

    // current seasonal collection baseURI and is used for any new morphing / minting
    // Morphing (allowed only to a current seasonal collection): e.g. Morphy Halloween => Morphy Christmas
    // Minting (only once): Flowty => Morphy current collection
    string public currentSeasonalCollectionURI;

    // Maximum price per minting one Morphy for a Flowty owner;
    uint256 public mintingPriceTier1 = 0.012 ether;
    uint256 public mintingPriceTier2 = 0.018 ether;
    uint256 public mintingPriceTier3 = 0.024 ether;
    uint256 public mintingMaxPrice = 0.03 ether;

    // Last minted Flowty at 0xdcb21cd4f3a7d5ab09df28e9aef697c0e895507a1fc7b97c533962845fdfe92d
    uint256 public lastFlowtyMintedBlock = 13263728;
    // Number of blocks between pricing steps. Around 1 Week assuming 15s interval between blocks
    uint256 public agingPricingThreshold = 40320;
    // Price per morphing (changing the look of Morhpy for a new season).
    // Idea that it will be free if you have aged Flowty in your wallet (same tokenId as Morphy).
    // The exact age stage is set for each season starting with Scratched
    uint256 public morphingPrice = 0.01 ether;
    // Starting with Scratched
    Flowtys.Age public morhpingAgeThreeshold = Flowtys.Age.Scratched;

    // mapping between original Flowty tokenId => Morphy tokenId, to allow minting of unminted
    mapping(uint256 => bool) private _morphysMinted;
    // Mapping between tokenId => seasonal collectiong baseURI
    mapping(uint256 => string) private _morphysRegistry;

    address public flowtysContract = 0x52607cb9c342821ea41ad265B9Bb6a23BEa49468;

    event MorphyMinted(uint256 tokenId);
    event MorphyUpdated(uint256 tokenId, string newBaseURI);

    constructor(string memory baseURI) ERC721("Morphys", "MORPHY") {
        currentSeasonalCollectionURI = baseURI;
    }
    /*
    * Withdraw funds
    */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Insufficient balance");

        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    /*
    * The ground cost of Morphying, unless free because a Flowty has required age stage
    */
    function setMorphingCost(uint256 newCost) public onlyOwner {
        morphingPrice = newCost;
    }

    /*
    * Set the minimum required age stage of a Flowty to morph for free
    */
    function setMorphingFreeStage(Flowtys.Age age) public onlyOwner {
        morhpingAgeThreeshold = age;
    }

    /*
    * Minting tiers, starts with Free for holders
    */
    function setMintingMaxCost(uint256 newCostTier1, uint256 newCostTier2, uint256 newCostTier3, uint256 newCostMax) public onlyOwner {
        mintingPriceTier1 = newCostTier1;
        mintingPriceTier2 = newCostTier2;
        mintingPriceTier3 = newCostTier3;
        mintingMaxPrice = newCostMax;
    }

    function setMintMax(uint256 newMax) public onlyOwner {
        maxPerMint = newMax;
    }
    //---------------------------------------------------------------------------------
    /**
    * Current on-going collection that is avaiable to morph or use as base for minting
    */
    function setCurrentCollectionBaseURI(string memory newuri) public onlyOwner {
        currentSeasonalCollectionURI = newuri;
    }

    /*
    * Pause morphing if active, make active if paused
    */
    function flipMorphingState() public onlyOwner {
        morphingIsActive = !morphingIsActive;
    }
    /*
    * Pause minting if active, make active if paused
    */
    function flipMintingState() public onlyOwner {
        mintingIsActive = !mintingIsActive;
    }

    /**
     * Reserve Morphyd from the current Flowtys reserve
     */
    function reserveMorphys() public onlyOwner {        
        Flowtys flowtys = Flowtys(flowtysContract);
        uint balance = flowtys.balanceOf(msg.sender);
        for(uint i = 0; i < balance; i++) {
            createMorphy(msg.sender, flowtys.tokenOfOwnerByIndex(msg.sender, i));
        }
    }

    /**
    * Calculate minting price based on the age of an original Flowty in the wallet
    * Pricing (per Morphy): 
    * 1st Week after initial minting => Free to Mint Morphy
    * 2nd Week after initial minting => mintingPriceTier1
    * 3rd Week after initial minting => mintingPriceTier2
    * 4th Week after initial minting => mintingPriceTier3
    * 5th Week and beyond after initial minting => mintingMaxPrice
    */
    function mintPrice(uint256 tokenId) public view returns (uint256) {
        Flowtys flowtys = Flowtys(flowtysContract);
        uint256 startingBlock = flowtys.getAgeStaringBlock(tokenId);
        if (startingBlock <= (lastFlowtyMintedBlock + agingPricingThreshold)) {
          return 0;
        } else if (startingBlock <= (lastFlowtyMintedBlock + agingPricingThreshold * 2)) {
          return mintingPriceTier1;
        } else if (startingBlock <= (lastFlowtyMintedBlock + agingPricingThreshold * 3)) {
          return mintingPriceTier2;
        } else if (startingBlock <= (lastFlowtyMintedBlock + agingPricingThreshold * 4)) {
          return mintingPriceTier3;
        }
        return mintingMaxPrice;
    }

    function mintPriceForAll(uint256[] memory tokenIds) public view returns (uint256[] memory) {
        require(tokenIds.length <= MAX_MORPHYS, "Can not calculate price for count exceeding MAX_MORPHYS");
        uint256[] memory pricing = new uint256[](tokenIds.length); 
        for(uint i = 0; i < tokenIds.length; i++) {
            pricing[i] = mintPrice(tokenIds[i]);
        }
        return pricing;
    }

    /**
    * Calculates the total price to mint given set of Morphys (returns wei)
    */
    function getTotalPrice(uint256[] memory tokenIds) public view returns (uint256) {
        uint256 totalPrice = 0;
        for(uint i = 0; i < tokenIds.length; i++) {
            totalPrice = totalPrice + mintPrice(tokenIds[i]);
        }
        return totalPrice;
    }

    /**
    * Mints Morphy (only allowed if you holding Flowty and corresponding Morphy has not been minted)
    */
    function mintMorphy(uint256[] memory tokenIds) public payable {
        require(tokenIds.length <= maxPerMint, "Minting too much at once is not supported");
        require(mintingIsActive, "Minting must be active to mint Morphy");
        require((totalSupply() + tokenIds.length) <= MAX_MORPHYS, "Mint would exceed max supply of Morhpys");
        Flowtys flowtys = Flowtys(flowtysContract);
        for(uint i = 0; i < tokenIds.length; i++) {
            // Allow minting if we are the owner of original Flowty, skip otherwise
            if (flowtys.ownerOf(tokenIds[i]) != msg.sender) {
                require(false, "Attempt to mint Morphy for non owned Flowty");
            }
        }
        require(getTotalPrice(tokenIds) == msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < tokenIds.length; i++) {
            createMorphy(msg.sender, tokenIds[i]);
        }
    }

    /**
    * Morphing existing Morphys.
    * Changing current baseURI of a token to a new one, that is current Season topic.
    */
    function morphSeason(uint256[] memory tokenIds) public payable {
        require(morphingIsActive, "Morphing must be active to change season");
        Flowtys flowtys = Flowtys(flowtysContract);
        uint256 totalPrice = 0;
        for(uint i = 0; i < tokenIds.length; i++) {
            // Allow morphing for owner only
            if (ownerOf(tokenIds[i]) != msg.sender || !_exists(tokenIds[i])) {
                require(false, "Trying to morph non existing/not owned Morphy");
            }
            // If you own a Flowty that has changed aging to minimum require => Morphing is free
            if (!(flowtys.ownerOf(tokenIds[i]) == msg.sender && flowtys.getAge(tokenIds[i]) >= morhpingAgeThreeshold)) {
                totalPrice = totalPrice + morphingPrice;
            }
        }
        require(totalPrice == msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < tokenIds.length; i++) {
            _morphysRegistry[tokenIds[i]] = currentSeasonalCollectionURI;
            emit MorphyUpdated(tokenIds[i], currentSeasonalCollectionURI);
        }
    }

    /// Internal
    function createMorphy(address mintAddress, uint256 tokenId) private {
      if (tokenId < MAX_MORPHYS && !_exists(tokenId) && _morphysMinted[tokenId] == false) {
          _safeMint(mintAddress, tokenId);
          _morphysMinted[tokenId] = true;
          _morphysRegistry[tokenId] = currentSeasonalCollectionURI;
          // fire event in logs
          emit MorphyMinted(tokenId);
      }
    }

    /// ERC721 related
    /**
     * @dev See {ERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _morphysRegistry[tokenId];
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return currentSeasonalCollectionURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
