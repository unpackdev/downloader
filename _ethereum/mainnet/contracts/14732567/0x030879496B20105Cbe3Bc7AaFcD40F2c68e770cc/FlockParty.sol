// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

/**
A flock of 10,000 groovy animated parrots partying it up in the ether.

FlockParty.xyz
*/

contract FlockParty is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  struct Traits {
    string background;
    string feathers;
    string outline;
    string head;
    string eyes;
    string beak;
    string beakInner;
    string beakOuter;
    string torso;
    string accessory;
    string partiedTooHardy;
  }

  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant MAX_OWNER_MINT = 80;
  uint256 public constant MAX_PER_MINT = 10;
  uint256 public constant PRICE_PER_MINT = 0.08 ether;
  string public constant NO_TRAIT_FLAG = "0";
  string public constant TRAIT_FLAG = "1";

  string public baseTokenURI;
  bool public mintingOpen;

  Counters.Counter private currentId;
  Counters.Counter private ownerMints;

  mapping(uint256 => uint256) private tokenIdToSeed;

  constructor(string memory _baseTokenURI) ERC721("FlockParty", "FLOCK") {
    setBaseURI(_baseTokenURI);
  }

  function mint(uint256 _count) public payable nonReentrant {
    require(mintingOpen == true, "Minting not currently open");
    require(currentId.current() < MAX_SUPPLY - MAX_OWNER_MINT, "Max supply reached");
    require(currentId.current() + _count <= MAX_SUPPLY - MAX_OWNER_MINT, "Not enough NFTs");
    require(_count > 0 && _count <= MAX_PER_MINT, "Outside of allowed mint range");
    require(msg.value >= PRICE_PER_MINT * _count, "Incorrect value");

    for (uint256 i = 0; i < _count; i++) {
      _mint();
    }
  }

  function ownerMint(uint256 _count) public onlyOwner {
    require(currentId.current() < MAX_SUPPLY, "Max supply reached");
    require(ownerMints.current() < MAX_OWNER_MINT, "Max owner supply reached");
    require(currentId.current() + _count <= MAX_SUPPLY, "Not enough NFTs");
    require(ownerMints.current() + _count <= MAX_OWNER_MINT, "Not enough owner NFTs");

    for (uint256 i = 0; i < _count; i++) {
      ownerMints.increment();

      _mint();
    }
  }

  function getSpecies(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "Token ID does not exist");

    string[6] memory solidSpecies = [
      "Blue",
      "Green",
      "Orange",
      "Pink",
      "Red",
      "Yellow"
    ];

    uint256 seed = _getTraitSeed(_tokenId, "SPECIES");

    if (_randomOdds(seed, 550)) return solidSpecies[seed % solidSpecies.length];
    else if (_randomOdds(seed, 650)) return "Shifter";
    else if (_randomOdds(seed, 700)) return "Macaw";
    else if (_randomOdds(seed, 750)) return "Quaker";
    else if (_randomOdds(seed, 800)) return "Love";
    else if (_randomOdds(seed, 850)) return "Lory";
    else if (_randomOdds(seed, 900)) return "Lorikeet";
    else if (_randomOdds(seed, 950)) return "Grey";
    else if (_randomOdds(seed, 970)) return "Black";
    else if (_randomOdds(seed, 990)) return "Gold";
    else if (_randomOdds(seed, 1000)) return "Alien";
    else return solidSpecies[seed % solidSpecies.length];
  }

  function getTraits(uint256 _tokenId) public view returns (Traits memory) {
    require(_exists(_tokenId), "Token ID does not exist");

    Traits memory traits;

    traits.accessory = _getAccessory(_tokenId);
    traits.background = _getBackground(_tokenId);
    traits.beak = _getBeak(_tokenId);
    traits.beakInner = _getBeakInner(_tokenId);
    traits.beakOuter = _getBeakOuter(_tokenId);
    traits.eyes = _getEyes(_tokenId);
    traits.feathers = _getFeathers(_tokenId);
    traits.head = _getHead(_tokenId);
    traits.outline = _getOutline(_tokenId);
    traits.partiedTooHardy = _getPartiedTooHardy(_tokenId);
    traits.torso = _getTorso(_tokenId);

    return traits;
  }

  function getSeed(uint256 _tokenId) public view returns (uint256) {
    require(_exists(_tokenId), "Token ID does not exist");

    return tokenIdToSeed[_tokenId];
  }

  function setBaseURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMintingOpen(bool _isOpen) public onlyOwner {
    mintingOpen = _isOpen;
  }

  function withdraw(address _sendTo) public onlyOwner {
    uint256 balance = address(this).balance;

    payable(_sendTo).transfer(balance);
  }

  function _mint() internal {
    currentId.increment();

    tokenIdToSeed[currentId.current()] = uint256(
      keccak256(
        abi.encodePacked(currentId.current(), blockhash(block.number - 1), msg.sender)
      )
    );

    _safeMint(msg.sender, currentId.current());
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function _getFeathers(uint256 _tokenId) internal view returns (string memory) {
    return getSpecies(_tokenId);
  }

  function _getOutline(uint256 _tokenId) internal view returns (string memory) {
    return getSpecies(_tokenId);
  }

  function _getBeak(uint256 _tokenId) internal view returns (string memory) {
    return getSpecies(_tokenId);
  }

  function _getHead(uint256 _tokenId) internal view returns (string memory) {
    string[48] memory head = [
      "BeanieBlue",
      "BeanieGreen",
      "BeanieGrey",
      "BeanieHoliday",
      "BeanieRed",
      "BeanieYellow",
      "Crown",
      "Flames",
      "FlowerOrange",
      "FlowerPink",
      "FlowerYellow",
      "HairBalding",
      "HairBobCut",
      "HairCombOver",
      "HairMessyCrop",
      "HairMohawk",
      "HairPompadour",
      "HairPuff",
      "HairPuffPigtails",
      "HairSpikedLiberty",
      "HairSpikedLibertyPink",
      "HairSpikedMessy",
      "Halo",
      "HatCop",
      "HatCowboy",
      "HatFedora",
      "HatFiesta",
      "HatPartyBlue",
      "HatPartyDots",
      "HatPartyFP",
      "HatPartyLines",
      "HatPartyPink",
      "HatPartyRed",
      "HatPartyYellow",
      "HatPartyZigZag",
      "HatPirate",
      "HatSanta",
      "HatTrapper",
      "HeadbandFlowersBlue",
      "HeadbandFlowersPurple",
      "Headphones",
      "HelmetViking",
      "HornsLarge",
      "HornsSmall",
      "LightBulb",
      "UnicornGold",
      "UnicornIvory",
      "UnicornRainbow"
    ];

    uint256 seed = _getTraitSeed(_tokenId, "HEAD");

    if (_isSpecies(_tokenId, "Alien")) return NO_TRAIT_FLAG;
    else if (_isPartiedTooHardy(_tokenId)) return NO_TRAIT_FLAG;
    else if (_randomOdds(seed, 250)) return NO_TRAIT_FLAG;
    else return head[seed % head.length];
  }

  function _getEyes(uint256 _tokenId) internal view returns (string memory) {
    string[34] memory eyes = [
      "Blindfold",
      "EyesAngry",
      "EyesAsterick",
      "EyesCheckered",
      "EyesCrossed",
      "EyesEvil",
      "EyesFaded",
      "EyesLaserBlue",
      "EyesLaserRed",
      "EyesOvalWithEyelashes",
      "EyesSleepy",
      "EyesSurprised",
      "EyesVerified",
      "EyesWandering",
      "EyesWink",
      "EyesWorried",
      "EyesX",
      "Glasses3d",
      "GlassesAngular",
      "GlassesAviator",
      "GlassesDoubleWideBlue",
      "GlassesDoubleWideRed",
      "GlassesDoubleWideYellow",
      "GlassesPrescriptionAngular",
      "GlassesPrescriptionRound",
      "GlassesShutterBlue",
      "GlassesShutterGreen",
      "GlassesShutterRed",
      "GlassesShutterYellow",
      "HeadsetCyclops",
      "HeadsetCyclopsLaser",
      "HeadsetVr",
      "MaskMasquerade",
      "Patch"
    ];

    uint256 seed = _getTraitSeed(_tokenId, "EYES");

    if (_isSpecies(_tokenId, "Alien")) return "EyesAlien";
    else if (_randomOdds(seed, 100)) return "EyesOval";
    else return eyes[seed % eyes.length];
  }

  function _getBeakInner(uint256 _tokenId) internal view returns (string memory) {
    string[9] memory beakInner = [
      "Joint",
      "MustacheBandito",
      "MustacheChevron",
      "MustacheEnglish",
      "MustacheHandlebar",
      "MustacheHorseshoe",
      "MustacheImperial",
      "Pipe",
      "Worm"
    ];

    uint256 seed = _getTraitSeed(_tokenId, "BEAK_INNER");
    
    if (_randomOdds(seed, 750)) return NO_TRAIT_FLAG;
    else return beakInner[seed % beakInner.length];
  }

  function _getBeakOuter(uint256 _tokenId) internal view returns (string memory) {
    string[8] memory beakOuter = [
      "BandageGreen",
      "BandageRed",
      "Crack",
      "PiercingHoopDoubleGold",
      "PiercingHoopDoubleSilver",
      "PiercingHoopGold",
      "PiercingHoopSilver",
      "PiercingStud"
    ];

    uint256 seed = _getTraitSeed(_tokenId, "BEAK_OUTER");
    
    if (_randomOdds(seed, 750)) return NO_TRAIT_FLAG;
    else return beakOuter[seed % beakOuter.length];
  }

  function _getTorso(uint256 _tokenId) internal view returns (string memory) {
    string[41] memory torso = [
      "ShirtAligator",
      "ShirtClub",
      "ShirtConfettiBlack",
      "ShirtConfettiBlue",
      "ShirtCrewNeckBlue",
      "ShirtCrewNeckGreen",
      "ShirtCrewNeckRed",
      "ShirtCrewNeckWhite",
      "ShirtFP",
      "ShirtGradient",
      "ShirtHawaiian",
      "ShirtHodl",
      "ShirtLeopard",
      "ShirtMarijuana",
      "ShirtPineapples",
      "ShirtPlaidBlue",
      "ShirtPlaidRed",
      "ShirtPlaidWhite",
      "ShirtPsychodelic",
      "ShirtRasta",
      "ShirtRoses",
      "ShirtTieDye",
      "ShirtTiger",
      "ShirtUnicode",
      "ShirtVNeckBabyBlue",
      "ShirtVNeckGrey",
      "ShirtVNeckPurple",
      "ShirtVNeckWhite",
      "ShirtWagmi",
      "ShirtZebra",
      "SweaterChristmas",
      "TattooAnchor",
      "TattooBarbedWire",
      "TattooEthLogo",
      "TattooHeartAndArrow",
      "TattooHodl",
      "TattooMom",
      "TattooRose",
      "TattooSparrow",
      "TattooVerified",
      "TattooWagmi"
    ];

    uint256 seed = _getTraitSeed(_tokenId, "TORSO");

    if (_randomOdds(seed, 250)) return NO_TRAIT_FLAG;
    else return torso[seed % torso.length];
  }

  function _getAccessory(uint256 _tokenId) internal view returns (string memory) {
    string[21] memory accessory = [
      "BeerMug",
      "Bong",
      "Broom",
      "Burger",
      "ChainFPGold",
      "ChainFPSilver",
      "ChainGold",
      "ChainSilver",
      "CoffeeCup",
      "Diamond",
      "FortyHands",
      "Hammer",
      "Lolipop",
      "Moon",
      "Pizza",
      "RocketShip",
      "RubberDuck",
      "ScienceBeaker",
      "UpVote",
      "Verified",
      "WineGlass"
    ];

    uint256 seed = _getTraitSeed(_tokenId, "ACCESSORY");

    if (_isPartiedTooHardy(_tokenId)) return "NeckBrace";
    else if (_randomOdds(seed, 900)) return NO_TRAIT_FLAG;
    else return accessory[seed % accessory.length];
  }

  function _getBackground(uint256 _tokenId) internal view returns (string memory) {
    string[10] memory solidBg = [
      "Blue",
      "Cyan",
      "Green",
      "Grey",
      "Orange",
      "Pink",
      "Purple",
      "Red",
      "White",
      "Yellow"
    ];

    string[4] memory animatedBg = [
      "FlashingOne",
      "FlashingTwo",
      "FlashingThree",
      "FlashingFour"
    ];

    uint256 seed = _getTraitSeed(_tokenId, "BACKGROUND");

    if (_isPartiedTooHardy(_tokenId)) return animatedBg[seed % animatedBg.length];
    else if (_randomOdds(seed, 930)) return solidBg[seed % solidBg.length];
    else if (_randomOdds(seed, 940)) return "GradientOne";
    else if (_randomOdds(seed, 950)) return "GradientTwo";
    else if (_randomOdds(seed, 960)) return "GradientThree";
    else if (_randomOdds(seed, 970)) return "ConfettiOne";
    else if (_randomOdds(seed, 980)) return "ConfettiTwo";
    else if (_randomOdds(seed, 985)) return "Gold";
    else if (_randomOdds(seed, 990)) return "BinaryGrass";
    else if (_randomOdds(seed, 995)) return "BinaryRedSands";
    else if (_randomOdds(seed, 1000)) return "BinaryHomebrew";
    else return solidBg[seed % solidBg.length];
  }

  function _getPartiedTooHardy(uint256 _tokenId) internal view returns (string memory) {
    uint256 seed = _getTraitSeed(_tokenId, "PARTIED_TOO_HARDY");

    if (_randomOdds(seed, 975)) return NO_TRAIT_FLAG;
    else return TRAIT_FLAG;
  }

  function _isSpecies(uint256 _tokenId, string memory _species) internal view returns (bool) {
    return _stringToBytes(getSpecies(_tokenId)) == _stringToBytes(_species);
  }

  function _isPartiedTooHardy(uint256 _tokenId) internal view returns (bool) {
    return _stringToBytes(_getPartiedTooHardy(_tokenId)) == _stringToBytes(TRAIT_FLAG);
  }

  function _getTraitSeed(uint256 _tokenId, string memory _traitName) internal view returns (uint256) {
    uint256 tokenIdSeed = getSeed(_tokenId);

    return uint256(keccak256(abi.encodePacked(
      string(abi.encodePacked(_traitName, Strings.toString(tokenIdSeed)))
    )));
  }

  function _randomOdds(uint256 _seed, uint256 _chance) internal pure returns (bool) {
    return (_seed % 1000) + 1 <= _chance;
  }

  function _stringToBytes(string memory _string) internal pure returns (bytes32) {
    return keccak256(bytes(_string));
  }
}
