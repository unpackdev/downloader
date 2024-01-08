// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./OnChain.sol";
import "./Randomization.sol";
import "./SVG.sol";
import "./ICloudTraitProvider.sol";
import "./CloudCollectiveErrors.sol";
import "./CloudFormation.sol";
import "./Whitelisted.sol";

/// @title CloudCollective
contract CloudCollective is ERC721, PaymentSplitter, ICloudTraitProvider, Ownable, ReentrancyGuard {

    using Strings for uint256;

    /// Price to form one cloud
    uint256 public constant FORMATION_PRICE = 0.06 ether;

    /// Maximum clouds that will be formed
    uint256 public constant MAX_CLOUDS = 9999;

    /// Maximum quantity of clouds that can be formed at once
    /// @dev changing this has an impact on `_forecastForToken()`
    uint256 public constant MAX_FORMATION_QUANTITY = 50;

    /// @dev Seed for randomness
    uint256 private _seed;

    /// @dev The block number when formation is available
    uint256 private _wenMint;

    /// @dev Enables/disables the reveal
    bool private _wenReveal;

    /// @dev Mapping of TokenIds to Seeds
    uint256[] private _tokenIdsToSeeds;

    /// @dev Holders of these 100% on-chain projects are whitelisted
    Whitelisted private immutable _whitelisted;

    /// Look...at these...Clouds
    constructor(uint256 seed, address whitelisted, address[] memory payees, uint256[] memory shares_) ERC721("CloudCollective", "CCT") PaymentSplitter(payees, shares_) {
        _seed = seed;
        _whitelisted = Whitelisted(whitelisted);
    }

    /// @inheritdoc ICloudTraitProvider
    function butterflyEffect(uint256 tokenId) external view onlyWhenExists(tokenId) onlyWenRevealed returns (ICloudTraits.ButterflyEffect memory) {
        return _seedForToken(tokenId);
    }

    /// @inheritdoc ICloudTraitProvider
    function cloudForecast(uint256 tokenId) public view override onlyWhenExists(tokenId) onlyWenRevealed returns (ICloudTraits.Forecast memory forecast) {
        forecast = _forecastForToken(tokenId);
    }

    /// @inheritdoc ICloudTraitProvider
    function conditionName(ICloudTraits.Condition condition) public pure returns (string memory) {
        string[5] memory conditions = ["Luminous", "Overcast", "Stormy", "Golden", "Magic"];
        return conditions[uint256(condition)];
    }

    /// @notice For easy import into MetaMask
    function decimals() external pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc ICloudTraitProvider
    function energyCategoryName(ICloudTraits.EnergyCategory energyCategory) public pure override returns (string memory) {
        string[6] memory energyCategories = ["Soothe", "Center", "Grow", "Connect", "Empower", "Enlighten"];
        return energyCategories[uint256(energyCategory)];
    }

    /// @inheritdoc ICloudTraitProvider
    function energyStateName(ICloudTraits.Forecast memory forecast) public pure override returns (string memory) {
        string[6] memory energyCategories;
        if (forecast.energyCategory == ICloudTraits.EnergyCategory.Soothe) {
            energyCategories = ["Relaxation", "Peace", "Calm", "Lightness", "Comfort", "Healing"];
        } else if (forecast.energyCategory == ICloudTraits.EnergyCategory.Center) {
            energyCategories = ["Truth", "Gratitude", "Clarity", "Awareness", "Acceptance", "Alignment"];
        } else if (forecast.energyCategory == ICloudTraits.EnergyCategory.Grow) {
            energyCategories = ["Transformation", "Possibility", "Expansiveness", "Prosperity", "Opportunity", "Abundance"];
        } else if (forecast.energyCategory == ICloudTraits.EnergyCategory.Connect) {
            energyCategories = ["Love", "Wisdom", "Intuition", "Compassion", "Alignment", "Empathy"];
        } else if (forecast.energyCategory == ICloudTraits.EnergyCategory.Empower) {
            energyCategories = ["Courage", "Strength", "Groundedness", "Resilience", "Purpose", "Certainty"];
        } else /* if (forecast.energyCategory == ICloudTraits.EnergyCategory.Enlighten) */ {
            energyCategories = ["Joy", "Happiness", "Amusement", "Manifestation", "Creativity", "Passion"];
        }
        return energyCategories[forecast.energy];
    }

    /// Forms the provided quantity of CloudCollective tokens
    /// @param quantity The quantity of CloudCollective tokens to form
    function formClouds(uint256 quantity) external payable nonReentrant {
        if (_wenMint > 0) {
            if (block.number < _wenMint) revert NotOpenForMinting();
        } else { // Check whitelist (needs reentrancy protection)
            if (!_whitelisted.isWhitelisted(_msgSender())) revert NotWhitelisted();
        }
        if (quantity == 0 || quantity > MAX_FORMATION_QUANTITY) revert InvalidQuantity();
        if (_tokenIdsToSeeds.length + quantity > MAX_CLOUDS) revert NoMoreClouds();
        if (msg.value < FORMATION_PRICE * quantity) revert InvalidPriceSent();
        _formClouds(quantity);
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /// @inheritdoc ICloudTraitProvider
    function scaleName(ICloudTraits.Scale scale) public pure returns (string memory) {
        string[7] memory scales = ["Tiny", "Petite", "Moyenne", "Milieu", "Grande", "Super", "Monstre"];
        return scales[uint256(scale)];
    }

    /// Wen the world is ready
    /// @dev Only the contract owner can invoke this
    function revealClouds() external onlyOwner {
        _wenReveal = true;
    }

    /// Enable minting
    /// @dev Only the contract owner can invoke this
    function setMintingBlock(uint256 wenMint) external onlyOwner {
        _wenMint = wenMint;
    }

    /// Exposes the raw image SVG to the world, for any applications that can take advantage
    function imageSVG(uint256 tokenId) public view returns (string memory) {
        return string(CloudFormation.createSvg(cloudForecast(tokenId), tokenId));
    }

    /// Exposes the image URI to the world, for any applications that can take advantage
    function imageURI(uint256 tokenId) external view returns (string memory) {
        return string(OnChain.svgImageURI(bytes(imageSVG(tokenId))));
    }

    /// Prevents a function from executing until wenReveal is set
    modifier onlyWenRevealed() {
        if (!_wenReveal) revert NotYetRevealed();
        _;
    }

    /// Prevents a function from executing if the tokenId does not exist
    modifier onlyWhenExists(uint256 tokenId) {
        if (!_exists(tokenId)) revert NonexistentCloud();
        _;
    }

    /// @inheritdoc PaymentSplitter
    /// @dev Only the owner is allowed to attempt to release for another account. All other failures are handled by the base class
    function release(address payable account) public override {
        if (_msgSender() != account && _msgSender() != owner()) revert OnlyShareholders();
        super.release(account);
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) public view override onlyWhenExists(tokenId) returns (string memory) {
        return string(OnChain.tokenURI(_metadataForToken(tokenId)));
    }

    /// @dev Returns the total amount of tokens stored by the contract.
    function totalSupply() external view returns (uint256) {
        return _tokenIdsToSeeds.length;
    }

    function _attributesFromForecast(ICloudTraits.Forecast memory forecast) private pure returns (bytes memory) {
        return OnChain.commaSeparated(
            OnChain.traitAttribute("Condition", bytes(conditionName(forecast.condition))),
            OnChain.traitAttribute("Energy", bytes(energyStateName(forecast))),
            OnChain.traitAttribute("Energy Category", bytes(energyCategoryName(forecast.energyCategory))),
            OnChain.traitAttribute("Hue", SVG.colorAttributeRGBValue(forecast.color)),
            OnChain.traitAttribute("Scale", bytes(scaleName(forecast.scale)))
        );
    }

    function _conditionPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](4);
        array[0] = 38; // 38% Luminous
        array[1] = 33; // 33% Overcast
        array[2] = 19; // 19% Stormy
        array[3] = 9; // 9% Golden
        return array; // 1% Magic
    }

    function _energyCategoryPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](5);
        array[0] = 35; // 35% Soothe
        array[1] = 25; // 25% Center
        array[2] = 20; // 20% Grow
        array[3] = 15; // 15% Connect
        array[4] = 4; // 4% Empower
        return array; // 1% Enlighten
    }

    function _forecastForToken(uint256 tokenId) private view returns (ICloudTraits.Forecast memory forecast) {
        forecast.chaos = uint200(_seedForToken(tokenId).seed >> (tokenId % MAX_FORMATION_QUANTITY));

        bytes25 random = bytes25(forecast.chaos);
        uint256 increment = tokenId % 20;

        forecast.formation = ICloudTraits.Formation(uint8(random[increment]) % 5);
        forecast.mirrored = uint8(random[increment+1]) % 2 == 0;
        forecast.scale = ICloudTraits.Scale(uint8(random[increment+2]) % 7);
        forecast.condition = ICloudTraits.Condition(Randomization.randomIndex(uint8(random[increment+3]), _conditionPercentages()));
        forecast.color = CloudFormation.conditionColor(forecast.condition, forecast.chaos, tokenId);
        forecast.energyCategory = ICloudTraits.EnergyCategory(Randomization.randomIndex(uint8(random[increment+4]), _energyCategoryPercentages()));
        forecast.energy = uint8(random[increment+5]) % 6;
    }

    function _formClouds(uint256 quantity) private {
        uint256 seed = Randomization.randomSeed(_seed);
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(_msgSender(), _tokenIdsToSeeds.length, "");
            _tokenIdsToSeeds.push(seed);
        }
        _seed = seed;
    }

    function _metadataForToken(uint256 tokenId) private view returns (bytes memory) {
        string memory token = tokenId.toString();
        if (_wenReveal) {
            ICloudTraits.Forecast memory forecast = _forecastForToken(tokenId);
            return OnChain.dictionary(OnChain.commaSeparated(
                OnChain.keyValueString("name",  abi.encodePacked(scaleName(forecast.scale), " ", conditionName(forecast.condition), " ", energyStateName(forecast), " ", token)),
                OnChain.keyValueArray("attributes", _attributesFromForecast(forecast)),
                OnChain.keyValueString("image", OnChain.svgImageURI(CloudFormation.createSvg(forecast, tokenId)))
            ));
        }
        return OnChain.dictionary(OnChain.commaSeparated(
            OnChain.keyValueString("name", abi.encodePacked("Forming Cloud ", token)),
            OnChain.keyValueString("image", "ipfs://QmWaooUQqr1VCqU2cdWypixg8Jcr5XhhSdi1Vg4u9krvDq")
        ));
    }

    function _seedForToken(uint256 tokenId) private view returns (ICloudTraits.ButterflyEffect memory effect) {
        effect.seed = _tokenIdsToSeeds[tokenId];
    }
}
