// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./InterfacesMigrated.sol";
import "./Structs.sol";
import "./controllable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";

contract FreaksNGuildsMigrated is Initializable, Controllable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable{

    bytes32 internal entropySauce;

    IFBX public fbx;
    MetadataHandlerLike public metadaHandler;
    IFnG public fngOriginal;
    IHUNTING public hunting;

    uint256 public startingPrice;
    uint256 public priceIncrease;
    uint256 public maxSupply;
    uint256 public maxSupplyL1;
    uint256 public celestialSupply;
    uint256 public freakSupply;
    uint256 public mintPrice;

    uint256 private _currentIndex;
    uint256 internal _incrementor;

    mapping(uint256 => Freak) public freaks;
    mapping(uint256 => CelestialV2) public celestials;


    /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwnerOrController(){
        require(isController(msg.sender) || msg.sender == owner(), "noauth");
        _;
    }


    /*///////////////////////////////////////////////////////////////
                    Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(
        uint256 _startingPrice, 
        uint256 _priceIncrease,
        uint256 _maxSupply,
        uint256 _maxSupplyL1,
        uint256 _startingIndex,
        address _fbx,
        address _metadataHandler,
        address _fngOriginal
    ) public initializer {
        __UUPSUpgradeable_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ERC721_init_unchained("Freaks N Guilds Migrated", "FnG");
        __ERC721Enumerable_init_unchained();

        startingPrice = _startingPrice;
        priceIncrease = _priceIncrease;
        maxSupply = _maxSupply;
        maxSupplyL1 = _maxSupplyL1;
        _currentIndex = _startingIndex;
        fbx = IFBX(_fbx);
        metadaHandler = MetadataHandlerLike(_metadataHandler);
        fngOriginal = IFnG(_fngOriginal);
        _incrementor = 1000 ether;
        mintPrice = 2000 ether;
        _pause();
    }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}


  /*///////////////////////////////////////////////////////////////
                    ADMIN
  //////////////////////////////////////////////////////////////*/ 

    function setCurIndex(uint256 currentIndex) external onlyOwner {
        _currentIndex = currentIndex;
    }

    /**
        @notice Allow owner to set pause state
        @param _pauseState new pause state
     */
    function setPause(bool _pauseState) external onlyOwner {
        if (_pauseState == true) {
        _pause();
        } else {
        _unpause();
        }
    }

    /**
        @notice set contract addresses
        @param _fbx fbx address
        @param _metadataHandler metadataHandler address
        @param _fngOriginal fngOriginal address
        @param _hunting hunting address
     */
    function setContracts(
        address _fbx,
        address _metadataHandler,
        address _fngOriginal,
        address _hunting
    ) external onlyOwner {
        fbx = IFBX(_fbx);
        metadaHandler = MetadataHandlerLike(_metadataHandler);
        fngOriginal = IFnG(_fngOriginal);
        hunting = IHUNTING(_hunting);
    }

    function updateFreakAttributes(uint256 tokenId, Freak calldata attributes) external onlyOwnerOrController {
        require(_exists(tokenId), "noexist");
        freaks[tokenId] = attributes;
    }

    function updateCelestialAttributes(uint256 tokenId, CelestialV2 calldata attributes) external onlyOwnerOrController {
        require(_exists(tokenId), "noexist");
        celestials[tokenId] = attributes;
    }

    function burn(uint256 tokenId) external onlyOwnerOrController {
        if(isFreak(tokenId)){
        delete freaks[tokenId];
        freakSupply -= 1;
        }else{
        delete celestials[tokenId];
        celestialSupply -= 1;
        }
        _burn(tokenId);
    }

    /// @notice Add or edit contract controllers.
    /// @param addrs Array of addresses to be added/edited.
    /// @param state New controller state of addresses.
    function setControllers(address[] calldata addrs, bool state) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) super._setController(addrs[i], state);
    }

    /**
        @notice set new incrementor for mint price
        @param newPriceIncrease new price increase per 2000 minted
     */
    function setPriceIncrease(uint256 newPriceIncrease) external onlyOwner {
        priceIncrease = newPriceIncrease;
    }

    function setMaxSupplyL1(uint256 newMaxSupplyL1) external onlyOwner {
        maxSupplyL1 = newMaxSupplyL1;
    }


    /*///////////////////////////////////////////////////////////////
                    MINT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
        @notice migrate fng token from genisis contract
        @param tokenIds tokenIds to migrate
     */
    // function migrate(uint256[] calldata tokenIds) external whenNotPaused{
    //     require(tokenIds.length > 0, "noids");
    //     for(uint256 i = 0; i < tokenIds.length; i++){
    //         require(fngOriginal.ownerOf(tokenIds[i]) == msg.sender, "noown");
    //         if(fngOriginal.isFreak(tokenIds[i])){
    //             Freak memory freak = fngOriginal.getFreakAttributes(tokenIds[i]);
    //             freaks[tokenIds[i]] = freak;
    //             freakSupply++;
    //         }else{
    //             Celestial memory celestial = fngOriginal.getCelestialAttributes(tokenIds[i]);
    //             celestials[tokenIds[i]] = CelestialV2(
    //                 celestial.healthMod, 
    //                 celestial.powMod, 
    //                 celestial.cPP, 
    //                 celestial.cLevel, 
    //                 1,
    //                 1,
    //                 1
    //             );
    //             celestialSupply++;
    //         }
    //         _mint(msg.sender, tokenIds[i]);
    //         fngOriginal.transferFrom(msg.sender, address(this), (tokenIds[i]));
    //     }
    // }

    /**
        @notice migrate freaks and stake them in the hunting grounds
        @param freakIds list of freakIds to migrate and stake
        @param pool numeric representation of staking pool to stake freaks in
     */
    function migrateAndHunt(uint256[] calldata freakIds, uint256 pool) external whenNotPaused {
        require(freakIds.length > 0, "noids");
        for(uint256 i = 0; i < freakIds.length; i++){
            require(fngOriginal.ownerOf(freakIds[i]) == msg.sender, "nown");
            require(fngOriginal.isFreak(freakIds[i]), "noF");
            Freak memory freak = fngOriginal.getFreakAttributes(freakIds[i]);
            freaks[freakIds[i]] = freak;
            freakSupply++;
            _mint(address(hunting), freakIds[i]);
            fngOriginal.transferFrom(msg.sender, address(this), (freakIds[i]));
        }
        hunting.huntFromMigration(msg.sender, freakIds, pool);
    }

    /**
        @notice migrate celestials and stake them in the hunting observatory
        @param celestialIds list of celestial IDs to migrate and stake
     */
    function migrateAndObserve(uint256[] calldata celestialIds) external whenNotPaused {
        require(celestialIds.length > 0, "noids");
        for(uint256 i = 0; i < celestialIds.length; i++){
            require(fngOriginal.ownerOf(celestialIds[i]) == msg.sender, "noown");
            require(!fngOriginal.isFreak(celestialIds[i]), "noC");
            Celestial memory celestial = fngOriginal.getCelestialAttributes(celestialIds[i]);
            celestials[celestialIds[i]] = CelestialV2(
                celestial.healthMod, 
                celestial.powMod, 
                celestial.cPP, 
                celestial.cLevel, 
                1,
                1,
                1
            );
            celestialSupply++;
            _mint(address(hunting), celestialIds[i]);
            fngOriginal.transferFrom(msg.sender, address(this), (celestialIds[i]));
        }
        hunting.observeFromMigration(msg.sender, celestialIds);
    }

    /**
        @notice mint new FnG token with FBX
        @param amount amount of tokens to mint
    */
    function mint(uint256 amount) external whenNotPaused{
        require(_currentIndex + amount <= (maxSupplyL1 + 1), "max");
        uint256 currentPrice;
        uint256 rand = _rand();
        for (uint256 i = 0; i < amount; i++) {
            uint256 rNum = rand % 100;
            uint256 celestialOdds = 12;
            uint256 celestialMax = 1200;
            if(_currentIndex > 20000){
                celestialOdds = 10;
                celestialMax = 1000;
            }
            currentPrice += mintPrice;
            if (rNum < celestialOdds && celestialSupply < celestialMax) {
                _revealCelestial(rNum, _currentIndex);
                rand = _randomize(rand, _currentIndex);
            } else {
                _revealFreak(rNum, _currentIndex);
                rand = _randomize(rand, _currentIndex);
            }
            if (_currentIndex % 2000 == 0) {
                _incrementor = _incrementor + priceIncrease;
                mintPrice = mintPrice + _incrementor;
            }
            _mint(msg.sender, _currentIndex);
            _currentIndex++;
        }
        fbx.burn(msg.sender, currentPrice);
    }

    /**
        @notice mint function for bridge to mint token created on poly
        @param to address to mint to
        @param tokenId tokenId to mint
        @param attributes attributes of token
     */
    function mintFreak(address to, uint256 tokenId, Freak calldata attributes) external onlyOwnerOrController{
        require(!_exists(tokenId), "alrdym");
        freaks[tokenId] = attributes;
        freakSupply++;
        _mint(to, tokenId);
    }

    /**
        @notice mint function for bridge to mint token created on poly
        @param to address to mint to
        @param tokenId tokenId to mint
        @param attributes attributes of token
     */
    function mintCelestial(address to, uint256 tokenId, CelestialV2 calldata attributes) external onlyOwnerOrController{
        require(!_exists(tokenId), "alrdym");
        celestials[tokenId] = attributes;
        celestialSupply++;
        _mint(to, tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    /**
        @notice check if tokenId is of type 'Freak'
        @param tokenId tokenId to check
        @return boolean
     */
    function isFreak(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "noexist");
        return freaks[tokenId].species != 0 ? true : false;
    }

    /**
        @notice get attribute of a Freak
        @param tokenId the token id of the Freak
        @return freak attibutues of the freak
     */
    function getFreakAttributes(uint256 tokenId) external view returns (Freak memory freak) {
        require(_exists(tokenId), "noexist");
        return freaks[tokenId];
    }

    /**
        @notice get attribute of a Freak
        @param tokenId the token id of the Freak
        @return species attibutues of the freak
    */
    function getSpecies(uint256 tokenId) external view returns (uint8 species) {
        require(isFreak(tokenId), "noF");
        return freaks[tokenId].species;
    }

    /**
        @notice get attributes of celestial
        @param tokenId the token id of the celestial
        @return celestial attributes of the celestial
     */
    function getCelestialAttributes(uint256 tokenId) external view returns (CelestialV2 memory celestial) {
        require(_exists(tokenId), "noexist");
        return (celestials[tokenId]);
    }

    /**
        @notice get tokens by account
        @param account account to query
     */
    function getTokens(address account) external view returns(uint256 [] memory){
        uint256 balance = balanceOf(account);
        uint256 [] memory tokensOwned = new uint256[](balance);
        for(uint256 i = 0; i < balance; i++){
            tokensOwned[i] = tokenOfOwnerByIndex(account, i);
        }
        return tokensOwned;
    } 

      /// @dev Call the `metadaHandler` to retrieve the tokenURI for each character.
    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "noexist");
        if (!isFreak(id)) {
            // Celestial
            CelestialV2 memory celestial = celestials[id];
            return metadaHandler.getCelestialTokenURI(id, celestial);
        } else if (isFreak(id)) {
            // Freak
            Freak memory freak = freaks[id];
            return metadaHandler.getFreakTokenURI(id, freak);
        } else {
            return ""; // placeholder for compile
        }
    }

    

    /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/
    function _revealCelestial(uint256 rNum, uint256 id) internal {
        uint256 _rNum = _randomize(rNum, id);
        uint8 healthMod = _calcMod(id, _rNum);
        _rNum = _randomize(_rNum, id);
        uint8 powMod = _calcMod(id, _rNum);
        CelestialV2 memory celestial = CelestialV2(healthMod, powMod, 1, 1, 1, 1, 1);
        celestials[id] = celestial;
        celestialSupply += 1;
    }

    function _revealFreak(uint256 rNum, uint256 id) internal {
        uint256 _rNum = _randomize(rNum, id);
        uint8 species = uint8((_rNum % 3) + 1);
        _rNum = _randomize(_rNum, id);
        uint8 mainHand = uint8((_rNum % 3) + 1);
        _rNum = _randomize(_rNum, id);
        uint8 body = uint8((_rNum % 3) + 1);
        _rNum = _randomize(_rNum, id);
        uint8 power = _calcPow(species, _rNum);
        _rNum = _randomize(_rNum, id);
        uint8 health = _calcHealth(species, _rNum);
        _rNum = _randomize(_rNum, id);
        uint8 armor = uint8((_rNum % 3) + 1); 
        uint8 criticalStrikeMod = 0;
        Freak memory freak = Freak(species, body, armor, mainHand, 0, power, health, criticalStrikeMod);
        freaks[id] = freak;
        freakSupply += 1;
    }

    /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return
        uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
    }

    function _calcMod(uint256 tokenId, uint256 rNum) internal pure returns (uint8) {
        // uint256 _rNum = _randomize(rNum, _rand(), id);
        // might need to cast? we will see...
        uint8 baseMod = 4;
        uint8 delta = 3;
        if(tokenId > 20000){
        baseMod = 2;
        delta = 4;
        }
        return uint8((rNum % delta) + baseMod);
    }

    function _calcHealth(uint8 species, uint256 rNum) internal pure returns (uint8) {
        uint8 baseHealth = 90; // ogre
        if (species == 1) {
        baseHealth = 50; // troll
        } else if (species == 2) {
        baseHealth = 70; // fairy
        }
        // might need to cast? we will see...
        return uint8((rNum % 21) + baseHealth);
    }

    function _calcPow(uint8 species, uint256 rNum) internal pure returns (uint8) {
        uint8 basePow = 90; //ogre
        if (species == 1) {
        basePow = 115; // troll
        } else if (species == 2) {
        basePow = 65; //fairy
        }
        // might need to cast? we will see...
        return uint8((rNum % 21) + basePow);
    }

    /*///////////////////////////////////////////////////////////////
                    OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused 
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

      /// @notice See {ERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return isController(operator) || super.isApprovedForAll(owner, operator);
    }

    function _authorizeUpgrade(address) internal onlyOwner override {}  
}

