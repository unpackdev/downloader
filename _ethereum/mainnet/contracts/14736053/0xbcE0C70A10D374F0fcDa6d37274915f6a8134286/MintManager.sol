// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///////////////////////////////////
//     MintETHManager Manager
///////////////////////////////////
import "./BaseManager.sol";
import "./IMITNft.sol";

contract MintManager is BaseManager {

    struct Config {
        uint256 price ;
        uint16 [] qualityRate ;  // quality probability
        uint16 [] quality ;      // quality value
        uint16 [] raceRate ;     // race probability
        uint16 [] race ;         // race value
        uint256 supply ;         // current config supply
        uint256 current ;        // already mint
        uint256 max ;            // max count
        uint256 wlStartBn ;      // whitelist mint open time
        uint256 startBn ;        // none whitelist mint open time
        uint256 endBn ;          // mint end block number
        uint256 openBn ;         // update Genes block number
    }

    enum KIND { NONE, SPACESHIP, HERO, DEFENSIVEFACILITY, SUIT }

    // Spaceship contract
    IMITNft public spaceship ;

    // DefensiveFacility contract
    IMITNft public defensiveFacility ;

    // hero contract
    IMITNft public hero ;

    // white list contractAddr => ( address => bool )
    mapping(address => bool) public whiteList ;

    // tokenId => style
    mapping(uint256 => uint16) public tokenStyle ;

    // tokenId => configIndex
    mapping(uint256 => uint256) public configIndexs ;

    // mint count
    mapping(uint256 => mapping(address => uint256)) public walletMintedCount ;

    // mapping (blockNum => bytes32)
    mapping(uint256 => bytes32) public blockHashMap ;

    // config
    Config [] public configs ;

    constructor(address sign) BaseManager(sign, "MintManager", "v1.0.0") {
    }

    ////////////////////////////////////////////////
    //             Events
    ////////////////////////////////////////////////
    event AddConfigEvent(Config config, uint256 index) ;
    event UpdateConfigEvent(uint256 index, Config oldConfig, Config newConfig) ;
    event MintEvent(uint256 [] tokenIds, KIND kind, address owner, uint256 style, uint256 cIndex) ;
    event MigrationEvent(uint256 [] tokenIds, uint256 [] genes, KIND kind, address owner) ;
    event AddWhiteListEvent(address [] accounts) ;
    event DelWhiteListEvent(address [] accounts) ;
    event InitGeneEvent(uint256 tokenId, KIND kind, uint256 gene, uint256 blockNum, bytes32 hash) ;

    ///////////////////////////////////////////
    //      config manager
    ///////////////////////////////////////////
    function addConfig(Config memory config) external returns(bool) {
        return _addConfig(config) ;
    }

    function batchAddConfig(Config[] memory _configs) external returns(bool) {
        for(uint256 i = 0 ;i < _configs.length; i++ ){
            _addConfig(_configs[i]) ;
        }
        return true ;
    }

    function _addConfig(Config memory config) private onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        configs.push(config) ;
        emit AddConfigEvent(config, configs.length - 1) ;
        return true ;
    }

    function updateConfig(uint256 index, Config memory config) external returns(bool) {
        return _updateConfig(index, config) ;
    }

    function batchUpdateConfig(uint256 [] memory indexs, Config[] memory _configs) external returns(bool) {
        require(indexs.length == _configs.length, "Configuration file array modification information does not match!") ;
        for(uint256 i = 0; i < _configs.length; i++){
            _updateConfig(indexs[i], _configs[i]) ;
        }
        return true ;
    }

    function _updateConfig(uint256 index, Config memory config) private onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        Config memory oldConfig = configs[index] ;
        configs[index] = config ;
        emit UpdateConfigEvent(index, oldConfig, config) ;
        return true ;
    }

    function configLen() external view returns(uint256){
        return configs.length ;
    }

    function getConfigs() external view returns (Config [] memory, uint256 ){
        Config [] memory configInfos = new Config[](configs.length) ;
        for(uint256 i = 0;i < configs.length; i++){
            configInfos[i] = configs[i] ;
        }
        return (configInfos, configs.length) ;
    }

    function setBlockHash(uint256 blockNum, bytes32 hash) external onlyRole(SIGN_ROLE) {
        blockHashMap[blockNum] = hash ;
    }

//    function setSpaceship(address spaceshipAddr) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
//        spaceship = IMITNft(spaceshipAddr) ;
//        return true ;
//    }
//
//    function setDefensiveFacility(address defensiveFacilityAddr) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
//        defensiveFacility = IMITNft(defensiveFacilityAddr) ;
//        return true ;
//    }
//
//    function setHero(address heroAddr) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
//        hero = IMITNft(heroAddr) ;
//        return true ;
//    }

    function initNftAddr(address spaceshipAddr, address defensiveFacilityAddr, address heroAddr) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        spaceship = IMITNft(spaceshipAddr) ;
        defensiveFacility = IMITNft(defensiveFacilityAddr) ;
        hero = IMITNft(heroAddr) ;
        return true ;
    }

    function withdraw(address payable feeAddr) external onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        bool sent = feeAddr.send(address(this).balance);
        require(sent, "Failed to withdraw Fees!");
        return true;
    }

    // batch add white list
    function addWhiteList(address [] memory accounts) external onlyRole(SIGN_ROLE) returns (bool) {
        for(uint256 i = 0; i < accounts.length; i++) {
            whiteList[accounts[i]] = true ;
        }
        emit AddWhiteListEvent(accounts) ;
        return true ;
    }

    // batch del white list
    function delWhiteList(address [] memory accounts) external onlyRole(SIGN_ROLE) returns (bool) {
        for(uint256 i = 0; i < accounts.length; i++) {
            whiteList[accounts[i]] = false ;
        }
        emit DelWhiteListEvent(accounts) ;
        return true ;
    }

    // The project party mints NFT tokens by itself
    function mintOfficial(uint256 [] memory tokenIds, address owner, uint8 style, uint256 cIndex, KIND kind) external onlyRole(SIGN_ROLE) returns (bool){
        checkMintConfig(cIndex, tokenIds.length, true) ;
        configs[cIndex].current += tokenIds.length;
        return _mint(tokenIds, owner, style, cIndex, kind) ;
    }

    function mint(uint256 [] memory tokenIds, uint8 style, uint256 cIndex, uint256[3] memory kDesc, bytes memory signature) external payable returns (bool){
        require(kDesc[0] > 0 || kDesc[1] > 0 || kDesc[2] > 0, "Parameter Error") ;
        // params check
        checkMintConfig(cIndex, tokenIds.length, false) ;
        configs[cIndex].current += tokenIds.length;
        walletMintedCount[cIndex][_msgSender()] += tokenIds.length ;
        // check signers
        _checkMintSign(tokenIds, style, cIndex, kDesc, signature) ;

        // batch mint NFT
        uint256 index = 0 ;
        for(uint256 i = 0; i < 3; i++) {
            if(kDesc[i] > 0) {
                KIND kind = KIND(i + 1) ;
                uint256 [] memory tIds = new uint256[](kDesc[i]) ;
                for(uint256 j = 0; j < kDesc[i]; j++) {
                    tIds[j] = tokenIds[j + index] ;
                }
                _mint(tIds, _msgSender(), style, cIndex, kind);
                index += kDesc[i] ;
            }
        }
        return true;
    }

    function _mint(uint256 [] memory tokenIds, address owner, uint16 style, uint256 cIndex, KIND kind) private returns (bool) {
        recordStyleConfig(tokenIds, style, cIndex) ;
        bool mintOk = false ;
        if(kind == KIND.SPACESHIP) {
            mintOk = spaceship.batchMint(tokenIds, owner) ;
            require(mintOk, "The Spaceship NFT Mint failed!") ;
        } else if(kind == KIND.DEFENSIVEFACILITY) {
            mintOk = defensiveFacility.batchMint(tokenIds, owner) ;
            require(mintOk, "The DefensiveFacility NFT Mint failed!") ;
        } else if(kind == KIND.HERO) {
            mintOk = hero.batchMint(tokenIds, owner) ;
            require(mintOk, "The Hero NFT Mint failed!") ;
        } else {
            require(false, "Invalid NFT type!") ;
        }
        emit MintEvent(tokenIds, kind, owner, style, cIndex) ;
        return true;
    }

    // The project party mints NFT tokens by itself
    function mintSuitOfficial(uint256 [] memory sIds, uint256 [] memory dIds, uint256 [] memory hIds, address owner, uint8 style, uint256 cIndex) external onlyRole(SIGN_ROLE) returns (bool){
        checkMintConfig(cIndex, sIds.length, true) ;
        configs[cIndex].current += sIds.length ;
        return _mintSuit(sIds, dIds, hIds, owner, style, cIndex) ;
    }

    function mintSuit(uint256 [] memory sIds, uint256 [] memory dIds, uint256 [] memory hIds, uint8 style, uint256 cIndex, bytes memory signature) external payable returns (bool){
        // params check
        checkMintConfig(cIndex, sIds.length, false) ;
        configs[cIndex].current += sIds.length ;
        walletMintedCount[cIndex][_msgSender()] += sIds.length ;

        // check signers
        _checkMintSuitSign(sIds, dIds, hIds, style, cIndex, signature) ;

        // batch mint NFT
        return _mintSuit(sIds, dIds, hIds, _msgSender(), style, cIndex);
    }

    function _mintSuit(uint256 [] memory sIds, uint256 [] memory dIds, uint256 [] memory hIds, address owner, uint16 style, uint256 cIndex) private returns (bool) {
        require(sIds.length == dIds.length && dIds.length == hIds.length, "The ID array of the suit NFT does not match!") ;
        _mint(sIds, owner, style, cIndex, KIND.SPACESHIP) ;
        _mint(dIds, owner, style, cIndex, KIND.DEFENSIVEFACILITY) ;
        _mint(hIds, owner, style, cIndex, KIND.HERO) ;
        return true;
    }

    // record NFT style and quality race rate
    function recordStyleConfig(uint256 [] memory tokenIds, uint16 style, uint256 cIndex) private  {
        for(uint256 i = 0;i < tokenIds.length ; i++) {
            tokenStyle[tokenIds[i]] = style ;
            configIndexs[tokenIds[i]] = cIndex ;
        }
    }

    // check mint config
    function checkMintConfig (uint256 cIndex, uint256 mintCount, bool isOffice) private {
        Config memory config = configs[cIndex] ;
        if(config.max > 0 && isOffice == false) {
            uint256 addressMaxMintCount = (walletMintedCount[cIndex][_msgSender()] < config.max) ? (config.max - walletMintedCount[cIndex][_msgSender()]) : 0;
            require(addressMaxMintCount >= mintCount, string(abi.encodePacked("You can mint up to ", Strings.toString(addressMaxMintCount), " NFT sets !"))) ;
        }

        if(isOffice == false) {
            require(config.wlStartBn <= block.number, string(abi.encodePacked("Whitelisted users will enable Mint activity in block ", Strings.toString(config.wlStartBn) ,"!"))) ;
            require(whiteList[_msgSender()] || config.startBn <= block.number, string(abi.encodePacked("Non-whitelisted users will start Mint activity in block ", Strings.toString(config.startBn) ,"!"))) ;
            (bool isSuccee,uint256 cost) = SafeMath.tryMul(mintCount, config.price) ;
            require(isSuccee, "Too many Mint NFT!") ;
            require(msg.value >= cost, string(abi.encodePacked("You need to pay " ,Strings.toString(cost)," wei"))) ;
        }

        require(config.endBn == 0 || config.endBn > block.number, string(abi.encodePacked("The Mint campaign has ended at block ", Strings.toString(config.endBn) ,"!"))) ;
        uint256 maxMintCount = config.supply - config.current ;
        require(config.supply > config.current && maxMintCount >= mintCount, string(abi.encodePacked("You can mint up to ",Strings.toString(maxMintCount)," NFT sets !"))) ;
    }

    function migration(uint256 [] memory tokenIds,uint256 [] memory genes, KIND kind, bytes memory signature) external returns(bool) {
        // check sign
        _checkMigrationSign(tokenIds, genes, kind, signature) ;

        // migration Spaceship
        bool migrationOk = false ;
        if(kind == KIND.SPACESHIP) {
            migrationOk = spaceship.batchMigration(tokenIds, genes, _msgSender()) ;
        } else if(kind == KIND.DEFENSIVEFACILITY) {
            migrationOk = defensiveFacility.batchMigration(tokenIds, genes, _msgSender()) ;
        } else if(kind == KIND.HERO) {
            migrationOk = hero.batchMigration(tokenIds, genes, _msgSender()) ;
        } else {
            require(false, "Invalid NFT type!") ;
        }
        require(migrationOk, "Spaceship NFT migration Fail!") ;
        emit MigrationEvent(tokenIds, genes, kind, _msgSender()) ;
        return true ;
    }

    // update genes
    function initGens(uint256 [] memory tokenIds, KIND kind) external onlyRole(SIGN_ROLE) returns(bool){
        bool setGensOk = false ;
        uint256 [] memory gens ;
        address [] memory owners ;
        if(kind == KIND.SPACESHIP) {
            owners  = spaceship.batchOwnerOf(tokenIds);
            gens = createGens(tokenIds, owners, kind) ;
            setGensOk = spaceship.batchSetGens(tokenIds, gens) ;
        } else if(kind == KIND.DEFENSIVEFACILITY) {
            owners = defensiveFacility.batchOwnerOf(tokenIds);
            gens = createGens(tokenIds, owners, kind) ;
            setGensOk = defensiveFacility.batchSetGens(tokenIds, gens) ;
        } else if(kind == KIND.HERO) {
            owners = hero.batchOwnerOf(tokenIds);
            gens = createGens(tokenIds, owners, kind) ;
            setGensOk = hero.batchSetGens(tokenIds, gens) ;
        } else {
            require(false, "Invalid NFT type!") ;
        }
        require(setGensOk, "Initialization of the Spaceship NFT gene failed !") ;
        return true ;
    }

    function createGens(uint256 [] memory tokenIds,address [] memory owners, KIND kind) private returns(uint256 [] memory) {
        uint256 [] memory genes = new uint256[](tokenIds.length) ;
        for(uint256 i = 0 ;i < tokenIds.length; i++ ){
            Config memory conf = configs[configIndexs[tokenIds[i]]] ;
            genes[i] = createGen(tokenIds[i], owners[i], conf.openBn) ;
            emit InitGeneEvent(tokenIds[i], kind, genes[i], conf.openBn, blockHashMap[conf.openBn]) ;
        }
        return genes ;
    }

    function createGen(uint256 tokenId, address owner, uint256 blockNum)
    private view returns (uint256) {
        uint256 blockHash = uint256(blockHashMap[blockNum]) ;
        require(blockHash > 0, "Failed to obtain the block hash. Procedure!") ;

        Config memory config = configs[configIndexs[tokenId]] ;

        uint16[] memory traits = new uint16[] (3) ;
        uint16 qualityRandom = uint16(uint256(keccak256(abi.encodePacked("quality", "_", Strings.toString(tokenId), "_", Strings.toHexString(blockHash)))) % 10000) ;

        traits[0] = getValues(config.qualityRate, config.quality, qualityRandom) ;

        uint16 raceRandom = uint16(uint256(keccak256(abi.encodePacked("race", "_", Strings.toString(tokenId), "_", addressToString(owner), "_", Strings.toHexString(blockHash)))) % 10000) ;
        traits[1]  = getValues(config.raceRate, config.race, raceRandom) ;
        traits[2]  = tokenStyle[tokenId] ;

        return combinedGene(traits) ;
    }

    function getValues(uint16 [] memory rate, uint16 [] memory values, uint16 random) private pure returns(uint16) {
        for(uint256 i = 0; i < rate.length ; i++ ) {
            if(random < rate[i]) {
                return values[i] ;
            }
        }
        return values[0] ;
    }

    function combinedGene(uint16 [] memory traits) internal pure returns(uint256) {
        // quality-race-style
        uint256 genes = 0 ;
        for(uint256 i = 0; i < traits.length; i++) {
            genes = genes << 16 ;
            genes = genes | traits[i] ;
        }
        return genes ;
    }

    /////////////////////////////////////////////
    //              check sign
    /////////////////////////////////////////////
    function _checkMintSign(uint256 [] memory tokenIds, uint8 style, uint256 cIndex, uint256[3] memory kDesc, bytes memory signature)
    private view {
        // cal hash
        bytes memory encodeData = abi.encode(
            keccak256(abi.encodePacked("Mint(uint256[] tokenIds,uint8 style,uint256 cIndex,uint256[3] kDesc,address owner)")),
            keccak256(abi.encodePacked(tokenIds)),
            style,
            cIndex,
            keccak256(abi.encodePacked(kDesc)),
            _msgSender()
        ) ;

        (bool success,) = checkSign(encodeData, signature) ;
        require(success, "mint: The operation of Mint permission is wrong!") ;
    }

    function _checkMintSuitSign(uint256 [] memory sIds, uint256 [] memory dIds, uint256 [] memory hIds, uint8 style, uint256 cIndex, bytes memory signature)
    private view {

        // cal hash
        bytes memory encodeData = abi.encode(
            keccak256("mintSuit(uint256[] sIds,uint256[] dIds,uint256[] hIds,uint8 style,uint256 cIndex,address owner)"),
            keccak256(abi.encodePacked(sIds)),
            keccak256(abi.encodePacked(dIds)),
            keccak256(abi.encodePacked(hIds)),
            style,
            cIndex,
            _msgSender()
        ) ;

        (bool success,) = checkSign(encodeData, signature) ;
        require(success, "mint: The operation of Mint permission is wrong!") ;
    }

    function _checkMigrationSign(uint256 [] memory tokenIds,uint256 [] memory genes, KIND kind, bytes memory signature) private view {
        string memory method = "" ;
        if(kind == KIND.SPACESHIP) {
            method = "MigrationSpaceship(uint256[] tokenIds,uint256[] genes,uint8 kind,address owner)" ;
        } else if(kind == KIND.DEFENSIVEFACILITY){
            method = "MigrationDefensivefacility(uint256[] tokenIds,uint256[] genes,uint8 kind,address owner)" ;
        } else if(kind == KIND.HERO){
            method = "MigrationHero(uint256[] tokenIds,uint256[] genes,uint8 kind,address owner)" ;
        } else {
            require(false, "Invalid NFT type!") ;
        }
        bytes memory encodeData = abi.encode(
            keccak256(abi.encodePacked(method)),
            keccak256(abi.encodePacked(tokenIds)),
            keccak256(abi.encodePacked(genes)),
            kind,
            _msgSender()
        ) ;
        (bool success, ) = checkSign(encodeData, signature) ;
        require(success, "mint: The operation of SpaceshipMigration permission is wrong!") ;
    }
}
