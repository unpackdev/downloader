// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721Receiver.sol";
import "./ITopia.sol";
import "./IGenesis.sol";

// all in one contract for receiving staked NFTs and distributing daily topia payouts

contract MetatopiaSeason2Hub is Ownable, IERC721Receiver {

    IGenesis public GenesisInterface;
    ITopia public TopiaInterface;
    IERC721 public Genesis = IERC721(0x810FeDb4a6927D02A6427f7441F6110d7A1096d5); // Genesis NFT contract
    IERC721 public Alpha = IERC721(0x96Af517c414B3726c1B2Ecc744ebf9d292DCbF60);
    IERC721 public Wastelands = IERC721(0x0b21144dbf11feb286d24cD42A7c3B0f90c32aC8);

    // 1=runner, 2=bull, 3=matador
    // 4=cadet, 5=alien, 6=general, 
    // 7=baker, 8=foodie, 9=shopowner, 
    // 10=cat, 11=dog, 12=vet
    mapping(uint16 => uint8) public genesisIdentifier; 
    mapping(address => bool) gameContracts;

    // ******* BULLRUN *******
    uint16 private numRunnersStaked;
    uint16 private numBullsStaked;
    mapping(uint16 => address) private OriginalMatadorOwner; 
    mapping(uint16 => address) private OriginalBullOwner;
    mapping(uint16 => address) private OriginalRunnerOwner;

    // ************ MOONFORCE ************
    uint16 private numCadetsStaked; // staked cadet nft ids
    uint16 private numGeneralsStaked;
    mapping(uint16 => address) private OriginalCadetOwner; 
    mapping(uint16 => address) private OriginalAlienOwner; 
    mapping(uint16 => address) private OriginalGeneralOwner;

    // ************ DOGEWORLD ************
    uint16 private numCatsStaked;
    uint16 private numDogsStaked;
    mapping(uint16 => address) private OriginalCatOwner; 
    mapping(uint16 => address) private OriginalDogOwner; 
    mapping(uint16 => address) private OriginalVetOwner;

    // ************ PYE MARKET ************
    uint16 private numBakersStaked; // staked baker nft ids
    uint16 private numFoodiesStaked; // ..
    mapping(uint16 => address) private OriginalBakerOwner; 
    mapping(uint16 => address) private OriginalFoodieOwner; 
    mapping(uint16 => address) private OriginalShopOwnerOwner;

    // ------------------------------------
    // mapping for alpha token id to wallet of staker
    mapping(uint16 => address) private OriginalAlphaOwner;
    // mapping for rat token id to wallet of staker
    mapping(uint16 => address) private OriginalRatOwner;
    // all alpha ids staked
    mapping(uint8 => uint16[]) private alphaIds;
    // mapping to arrays of stealing ids
    mapping(uint8 => uint16[]) private stakedIds; // 1 = Matadors, 2 = Aliens, 3 = Vets, 4 = Shop Owners
    // array of Owned Genesis token ids
    mapping(address => mapping(uint8 => uint16[])) genesisOwnedIds;
    // array of Owned Alpha token ids
    mapping(address => mapping(uint8 => uint16[])) alphaOwnedIds;
    // array of Owned Rat token ids
    mapping(address => uint16[]) ratOwnedIds;
    // number of Genesis staked
    uint256 public numGenesisStaked;
    // number of Alpha staked
    uint256 public numAlphasStaked;
    // number of rats staked;
    uint16 public numRatsStaked;

    // amount of $TOPIA earned so far per holder
    mapping(address => uint256) public totalHolderTOPIA;
    // mapping for alpha tokenId to game it's being staked in
    mapping(uint16 => uint8) public alphaGameIdentifier;
    // mapping for genesis tokenId to game it's being staked in
    mapping(uint16 => uint8) genesisGameIdentifier;
    // amount of $TOPIA earned so far
    uint256 public totalTOPIAEarned;

    bool public rescueEnabled;
    bool public devRescueEnabled;

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    constructor(address _topia) {
        TopiaInterface = ITopia(_topia);
    }

    // ************* EVENTS

    event TopiaClaimed (address indexed owner, uint256 earned, uint256 blockNum, uint256 timeStamp);
    event AlphaReceived (address indexed _originalOwner, uint16 _id);
    event AlphaReturned (address indexed _originalOwner, uint16 _id);
    event RatReceived (address indexed _originalOwner, uint16 _id);
    event RatReturned (address indexed _originalOwner, uint16 _id);
    event BullReceived (address indexed _originalOwner, uint16 _id);
    event BullReturned (address indexed _returnee, uint16 _id);
    event MatadorReceived (address indexed _originalOwner, uint16 _id);
    event MatadorReturned (address indexed _returnee, uint16 _id);
    event RunnerReceived (address indexed _originalOwner, uint16 _id);
    event RunnerReturned (address indexed _returnee, uint16 _id);
    event CadetReceived (address indexed _originalOwner, uint16 _id);
    event CadetReturned (address indexed _returnee, uint16 _id);
    event AlienReceived (address indexed _originalOwner, uint16 _id);
    event AlienReturned (address indexed _returnee, uint16 _id);
    event GeneralReceived (address indexed _originalOwner, uint16 _id);
    event GeneralReturned (address indexed _returnee, uint16 _id);
    event CatReceived (address indexed _originalOwner, uint16 _id);
    event CatReturned (address indexed _returnee, uint16 _id);
    event DogReceived (address indexed _originalOwner, uint16 _id);
    event DogReturned (address indexed _returnee, uint16 _id);
    event VetReceived (address indexed _originalOwner, uint16 _id);
    event VetReturned (address indexed _returnee, uint16 _id);
    event BakerReceived (address indexed _originalOwner, uint16 _id);
    event BakerReturned (address indexed _returnee, uint16 _id);
    event FoodieReceived (address indexed _originalOwner, uint16 _id);
    event FoodieReturned (address indexed _returnee, uint16 _id);
    event ShopOwnerReceived (address indexed _originalOwner, uint16 _id);
    event ShopOwnerReturned (address indexed _returnee, uint16 _id);
    event NFTStolen (address indexed _thief, address indexed _victim, uint16 _id);
    event PlatoonCreated (address indexed _creator, uint16[] cadets);
    event LitterCreated (address indexed _creator, uint16[] cats);
    event MobCreated (address indexed _creator, uint16[] runners);
    event UnionCreated (address indexed _creator, uint16[] bakers);
    event CadetAdded (address indexed _owner, uint16 _id);
    event CatAdded (address indexed _owner, uint16 _id);
    event RunnerAdded (address indexed _owner, uint16 _id);
    event BakerAdded (address indexed _owner, uint16 _id);
    event GroupUnstaked (address indexed _unstaker, uint8 _gameId, uint80 timestamp);
    event MatadorMigrated (address indexed _owner, uint16 _id);
    event GeneralMigrated (address indexed _owner, uint16 _id);
    event ShopOwnerMigrated (address indexed _owner, uint16 _id);
    event VetMigrated (address indexed _owner, uint16 _id);
    
    // ************* Universal TOPIA functions

    function pay(address _to, uint256 _amount) external onlyGames() {
        TopiaInterface.mint(_to, _amount);
        totalHolderTOPIA[_to] += _amount;
        totalTOPIAEarned += _amount;
        emit TopiaClaimed(_to, _amount, block.number, block.timestamp);
    }

    function burnFrom(address _to, uint256 _amount) external onlyGames() {
        TopiaInterface.burnFrom(_to, _amount);
    }

    // ************* MODIFIERS

    modifier onlyGames() {
        require(gameContracts[msg.sender], "only game contract allowed");
        _;
    }

    // ************* SETTERS

    function setGenesis(address _genesis) external onlyOwner {
        Genesis = IERC721(_genesis);
        GenesisInterface = IGenesis(_genesis);
    }

    function setTopia(address _topia) external onlyOwner {
        TopiaInterface = ITopia(_topia);
    }

    // mass update the genesisIdentifier mapping
    function batchSetGenesisIdentifier(uint16[] calldata _idNumbers, uint8[] calldata _types) external onlyOwner {
        require(_idNumbers.length == _types.length);
        for (uint16 i = 0; i < _idNumbers.length;) {
            require(_types[i] != 0 && _types[i] <= 12);
            genesisIdentifier[_idNumbers[i]] = _types[i];
            unchecked{ i++; }
        }
    }

    function setRescueEnabled(bool _flag) external onlyOwner {
        rescueEnabled = _flag;
    }

    function setDevRescueEnabled(bool _flag) external onlyOwner {
        devRescueEnabled = _flag;
    }

    // ************* EVENT FXNS

    function balanceOf(address owner) external view returns (uint256) {
        uint256 gen;
        for(uint8 i = 1; i <= 5; i++) {
            gen += genesisOwnedIds[owner][i].length;
        }

        uint256 alph;
        for(uint8 i = 1; i <= 5; i++) {
            alph += alphaOwnedIds[owner][i].length;
        }

        uint256 stakedBalance = alph + gen;
        return stakedBalance;
    }

    function getUserGenesisStaked(address owner) external view returns (uint16[] memory stakedGenesis) {
        uint256 length;
        for(uint8 i = 1; i <= 5; i++) {
            length += genesisOwnedIds[owner][i].length;
        }

        stakedGenesis = new uint16[](length);
        uint y = 0;
        for(uint8 i = 1; i <= 5; i++) {
            uint256 L = genesisOwnedIds[owner][i].length;
            for(uint z = 0; z < L; z++) {
                stakedGenesis[y] = uint16(genesisOwnedIds[owner][i][z]);
                y++;
            }
        }
    }

    function getUserStakedGenesisGame(address owner, uint8 game) external view returns (uint16[] memory stakedGenesis) {
        uint256 length = genesisOwnedIds[owner][game].length;
        stakedGenesis = new uint16[](length);

        for(uint i = 0; i < length;) {
            stakedGenesis[i] = uint16(genesisOwnedIds[owner][game][i]);
            unchecked{ i++; }
        }
    }

    function getUserAlphaStaked(address owner) external view returns (uint16[] memory stakedAlphas) {
        uint256 length;
        for(uint8 i = 1; i <= 5; i++) {
            length += alphaOwnedIds[owner][i].length;
        }

        stakedAlphas = new uint16[](length);
        uint y = 0;
        for(uint8 i = 1; i <= 5; i++) {
            uint256 L = alphaOwnedIds[owner][i].length;
            for(uint z = 0; z < L; z++) {
                stakedAlphas[y] = uint16(alphaOwnedIds[owner][i][z]);
                y++;
            }
        }
    }

    function getUserStakedAlphaGame(address owner, uint8 game) external view returns (uint16[] memory stakedAlphas) {
        uint256 length = alphaOwnedIds[owner][game].length;
        stakedAlphas = new uint16[](length);

        for(uint i = 0; i < length;) {
            stakedAlphas[i] = uint16(alphaOwnedIds[owner][game][i]);
            unchecked{ i++; }
        }
    }

    function getUserRatStaked(address owner) external view returns (uint16[] memory stakedRats) {
        uint256 length = ratOwnedIds[owner].length;
        stakedRats = new uint16[](length);

        for(uint i = 0; i < length;) {
            stakedRats[i] = uint16(ratOwnedIds[owner][i]);
            unchecked{ i++; }
        }
    }

    // ************ ALPHA NFT RECEIVE AND RETURN FUNCTIONS

    // @param: _gameIdentifier 1 = BullRun, 2 = MoonForce, 3 = Doge World, 4 = PYE Market, 5 = Wastelands
    function receiveAlpha(address _originalOwner, uint16 _id, uint8 _gameIdentifier) external onlyGames {
        require(_gameIdentifier >= 1 && _gameIdentifier <= 5 , "invalid id");
        IERC721(Alpha).safeTransferFrom(_originalOwner, address(this), _id);
        OriginalAlphaOwner[_id] = _originalOwner;
        alphaIds[_gameIdentifier].push(_id);
        alphaGameIdentifier[_id] = _gameIdentifier;
        alphaOwnedIds[_originalOwner][_gameIdentifier].push(_id);
        numAlphasStaked++;
        emit AlphaReceived(_originalOwner, _id);
    }

    function returnAlphaToOwner(address _returnee, uint16 _id, uint8 _gameIdentifier) external onlyGames {
        require(_returnee == OriginalAlphaOwner[_id], "not owner");
        IERC721(Alpha).safeTransferFrom(address(this), _returnee, _id);
        delete OriginalAlphaOwner[_id];
        delete alphaGameIdentifier[_id];
        uint256 d = uint256(_id);
        uint256 x = alphaOwnedIds[_returnee][_gameIdentifier].length;
        for(uint i = 0; i < x;) {
            if(alphaOwnedIds[_returnee][_gameIdentifier][i] == d) {
                alphaOwnedIds[_returnee][_gameIdentifier][i] = alphaOwnedIds[_returnee][_gameIdentifier][x -  1];
                alphaOwnedIds[_returnee][_gameIdentifier].pop();

                break;
            } else {
                unchecked{ i++; }
                continue;
            }
        }
        uint256 y = alphaIds[_gameIdentifier].length;
        uint256 m = (0 & (y - 1)) + (0 ^ (y - 1)) / 2;
        unchecked { 
            for(uint i = 0; i < y;) {
                if(alphaIds[_gameIdentifier][i] == d) {
                    alphaIds[_gameIdentifier][i] = alphaIds[_gameIdentifier][y -  1];
                    alphaIds[_gameIdentifier].pop();

                    break;
                } else if(alphaIds[_gameIdentifier][y - i - 1] == d) {
                    alphaIds[_gameIdentifier][i] = alphaIds[_gameIdentifier][y -  1];
                    alphaIds[_gameIdentifier].pop();

                    break;
                } else if(alphaIds[_gameIdentifier][m - i] == d) {
                    alphaIds[_gameIdentifier][i] = alphaIds[_gameIdentifier][y -  1];
                    alphaIds[_gameIdentifier].pop();

                    break;
                } else if(alphaIds[_gameIdentifier][m + i] == d) {
                    alphaIds[_gameIdentifier][i] = alphaIds[_gameIdentifier][y -  1];
                    alphaIds[_gameIdentifier].pop();

                    break;
                } else {
                    i++;
                    continue;
                }
            }
        }
        numAlphasStaked--;

        emit AlphaReturned(_returnee, _id);
    }

    function emergencyRescueAlpha(uint16 _id, address _account) external {
        if(devRescueEnabled && msg.sender == owner()) {
            IERC721(Alpha).safeTransferFrom(address(this), _account, _id);
        } else if (rescueEnabled && msg.sender == OriginalAlphaOwner[_id]) {
            IERC721(Alpha).safeTransferFrom(address(this), _account, _id);
        }
    }

    // ************ WASTELANDS NFT RECEIVE AND RETURN FUNCTIONS

    function receiveRat(address _originalOwner, uint16 _id) external onlyGames {
        IERC721(Wastelands).safeTransferFrom(_originalOwner, address(this), _id);
        OriginalRatOwner[_id] = _originalOwner;
        ratOwnedIds[_originalOwner].push(_id);
        numRatsStaked++;
        emit RatReceived(_originalOwner, _id);
    }

    function returnRatToOwner(address _returnee, uint16 _id) external onlyGames {
        require(_returnee == OriginalRatOwner[_id], "not owner");
        IERC721(Wastelands).safeTransferFrom(address(this), _returnee, _id);
        delete OriginalRatOwner[_id];
        uint256 x = ratOwnedIds[_returnee].length;
        for(uint i = 0; i < x;) {
            if(ratOwnedIds[_returnee][i] == _id) {
                ratOwnedIds[_returnee][i] = ratOwnedIds[_returnee][x -  1];
                ratOwnedIds[_returnee].pop();

                break;
            } else {
                unchecked{ i++; }
                continue;
            }
        }
        numRatsStaked--;
        emit RatReturned(_returnee, _id);
    }

    function emergencyRescueRat(uint16 _id, address _account) external {
        if(devRescueEnabled && msg.sender == owner()) {
            IERC721(Wastelands).safeTransferFrom(address(this), _account, _id);
        } else if (rescueEnabled && msg.sender == OriginalRatOwner[_id]) {
            IERC721(Wastelands).safeTransferFrom(address(this), _account, _id);
        }
    }

    // ************ METATOPIA WASTELANDS FUNCTIONS

    // for tier 3 NFTS being sent to wastelands 
    // @param: _gameId: 1 = bullrun, 2 = MF, 3 = DW, 4 = PM
    // @param: returningFromWastelands, if the NFT has already been in the wastelands and user is trying to get it back
    function migrate(uint16 _id, address _originalOwner, uint8 _gameId, bool returningFromWastelands) external onlyGames {
        require(_gameId >= 1 && _gameId <= 4, "Invalid game id");
        if (_gameId == 1) { // incoming matador
            if (!returningFromWastelands) { // nft is being sent to the wastes
                OriginalMatadorOwner[_id] = _originalOwner;
                emit MatadorMigrated(_originalOwner, _id);
            } else { // nft is going back to original owner
                delete OriginalMatadorOwner[_id];
                emit MatadorReturned(_originalOwner, _id);
            }
        } else if (_gameId == 2) { // incoming general
            if (!returningFromWastelands) { // nft is being sent to the wastes
                OriginalGeneralOwner[_id] = _originalOwner;
                emit GeneralMigrated(_originalOwner, _id);
            } else { // nft is going back to original owner
                delete OriginalGeneralOwner[_id];
                emit GeneralReturned(_originalOwner, _id);
            }
        } else if (_gameId == 3) { // incoming vet
            if (!returningFromWastelands) { // nft is being sent to the wastes
                OriginalVetOwner[_id] = _originalOwner;
                emit VetMigrated(_originalOwner, _id);
            } else { // nft is going back to original owner
                delete OriginalVetOwner[_id];
                emit VetReturned(_originalOwner, _id);
            }
        } else if (_gameId == 4) { // incoming shopowner
            if (!returningFromWastelands) { // nft is being sent to the wastes
                OriginalShopOwnerOwner[_id] = _originalOwner;
                emit ShopOwnerMigrated(_originalOwner, _id);
            } else { // nft is going back to original owner
                delete OriginalShopOwnerOwner[_id];
                emit ShopOwnerReturned(_originalOwner, _id);
            }
        }
        if (!returningFromWastelands) { // nft is being sent to the wastes
            Genesis.safeTransferFrom(_originalOwner, address(this), _id);
            genesisGameIdentifier[_id] = 5; // NFT goes to Wastelands
            genesisOwnedIds[_originalOwner][5].push(_id);
        } else {
            Genesis.safeTransferFrom(address(this), _originalOwner, _id);
            delete genesisGameIdentifier[_id];
            removeGenesisArray(_id, _originalOwner, 5);
        }
    }

    // ************ METATOPIA GENESIS NFT RECEIVE AND RETURN FUNCTIONS
    // @param: _gameId: 1 = bullrun, 2 = MF, 3 = DW, 4 = PM, 5 = Wastelands
    // 1=runner, 2=bull, 3=matador
    // 4=cadet, 5=alien, 6=general, 
    // 7=baker, 8=foodie, 9=shopowner, 
    // 10=cat, 11=dog, 12=vet

    function receieveManyGenesis(address _originalOwner, uint16[] memory _ids, uint8[] memory identifiers, uint8 _gameIdentifier) external onlyGames {
        for(uint i = 0; i < _ids.length;) {
            if (identifiers[i] == 1) {                
                OriginalRunnerOwner[_ids[i]] = _originalOwner;
                numRunnersStaked++;                
                emit RunnerReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 2) {                
                OriginalBullOwner[_ids[i]] = _originalOwner;
                numBullsStaked++;                
                emit BullReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 3) {                
                OriginalMatadorOwner[_ids[i]] = _originalOwner;
                stakedIds[1].push(_ids[i]);                
                emit MatadorReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 4) {                
                OriginalCadetOwner[_ids[i]] = _originalOwner;
                numCadetsStaked++;                
                emit CadetReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 5) {                
                OriginalAlienOwner[_ids[i]] = _originalOwner;
                stakedIds[2].push(_ids[i]);                 
                emit AlienReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 6) {                
                OriginalGeneralOwner[_ids[i]] = _originalOwner;
                numGeneralsStaked++;                
                emit GeneralReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 7) {                
                OriginalBakerOwner[_ids[i]] = _originalOwner;
                numBakersStaked++;                
                emit BakerReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 8) {                
                OriginalFoodieOwner[_ids[i]] = _originalOwner;
                numFoodiesStaked++;        
                emit FoodieReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 9) {     
                OriginalShopOwnerOwner[_ids[i]] = _originalOwner; 
                stakedIds[4].push(_ids[i]); 
                emit ShopOwnerReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 10) {
                OriginalCatOwner[_ids[i]] = _originalOwner;
                numCatsStaked++;
                emit CatReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 11) {
                OriginalDogOwner[_ids[i]] = _originalOwner;
                numDogsStaked++;
                emit DogReceived(_originalOwner, _ids[i]);
            } else if (identifiers[i] == 12) {
                OriginalVetOwner[_ids[i]] = _originalOwner;
                stakedIds[3].push(_ids[i]); 
                emit VetReceived(_originalOwner, _ids[i]);
            }

            genesisGameIdentifier[_ids[i]] = _gameIdentifier;
            if (genesisIdentifier[_ids[i]] == 0) {
                genesisIdentifier[_ids[i]] = identifiers[i];
            }

            genesisOwnedIds[_originalOwner][_gameIdentifier].push(_ids[i]);
            Genesis.safeTransferFrom(_originalOwner, address(this), _ids[i]);

            unchecked{ i++; }
        }
        numGenesisStaked += _ids.length;
    }

    function returnGenesisToOwner(address _returnee, uint16 _id, uint8 identifier, uint8 _gameIdentifier) external onlyGames {
        if (identifier == 1) {
            require(_returnee == OriginalRunnerOwner[_id], "not owner");
            delete OriginalRunnerOwner[_id];
            delete genesisGameIdentifier[_id];
            numRunnersStaked--; 
            emit RunnerReturned(_returnee, _id);
        } else if (identifier == 2) {
            require(_returnee == OriginalBullOwner[_id], "not owner");
            delete OriginalBullOwner[_id];
            delete genesisGameIdentifier[_id];
            numBullsStaked--;
            emit BullReturned(_returnee, _id);
        } else if (identifier == 3) {
            require(_returnee == OriginalMatadorOwner[_id], "not owner");
            delete OriginalMatadorOwner[_id];
            delete genesisGameIdentifier[_id];
            removeStakedArray(_id, 1);
            emit MatadorReturned(_returnee, _id);
        } else if (identifier == 4) {
            require(_returnee == OriginalCadetOwner[_id], "not owner");
            delete OriginalCadetOwner[_id];
            delete genesisGameIdentifier[_id];
            numCadetsStaked--;
            emit CadetReturned(_returnee, _id);
        } else if (identifier == 5) {
            require(_returnee == OriginalAlienOwner[_id], "not owner");
            delete OriginalAlienOwner[_id];
            delete genesisGameIdentifier[_id];
            removeStakedArray(_id, 2);
            emit AlienReturned(_returnee, _id);
        } else if (identifier == 6) {
            require(_returnee == OriginalGeneralOwner[_id], "not owner");
            delete OriginalGeneralOwner[_id];
            delete genesisGameIdentifier[_id];
            numGeneralsStaked--;
            emit GeneralReturned(_returnee, _id);
        } else if (identifier == 7) {
            require(_returnee == OriginalBakerOwner[_id], "not owner");
            delete OriginalBakerOwner[_id];
            delete genesisGameIdentifier[_id];
            numBakersStaked--;
            emit BakerReturned(_returnee, _id);
        } else if (identifier == 8) {
            require(_returnee == OriginalFoodieOwner[_id], "not owner");
            delete OriginalFoodieOwner[_id];
            delete genesisGameIdentifier[_id];
            numFoodiesStaked--;
            emit FoodieReturned(_returnee, _id);
        } else if (identifier == 9) {
            require(_returnee == OriginalShopOwnerOwner[_id], "not owner");
            delete OriginalShopOwnerOwner[_id];
            delete genesisGameIdentifier[_id];
            removeStakedArray(_id, 4);
            emit ShopOwnerReturned(_returnee, _id);
        } else if (identifier == 10) {
            require(_returnee == OriginalCatOwner[_id], "not owner");
            delete OriginalCatOwner[_id];
            delete genesisGameIdentifier[_id];
            numCatsStaked--;
            emit CatReturned(_returnee, _id);
        } else if (identifier == 11) {
            require(_returnee == OriginalDogOwner[_id], "not owner");
            delete OriginalDogOwner[_id];
            delete genesisGameIdentifier[_id];
            numDogsStaked--;
            emit DogReturned(_returnee, _id);
        } else if (identifier == 12) {
            require(_returnee == OriginalVetOwner[_id], "not owner");
            delete OriginalVetOwner[_id];
            delete genesisGameIdentifier[_id];
            removeStakedArray(_id, 3);
            emit VetReturned(_returnee, _id);
        }
        removeGenesisArray(_id, _returnee, _gameIdentifier);
        numGenesisStaked--;

        IERC721(Genesis).safeTransferFrom(address(this), _returnee, _id);
    }

    function removeGenesisArray(uint16 _id, address _returnee, uint8 _gameIdentifier) internal {
        uint256 x = genesisOwnedIds[_returnee][_gameIdentifier].length;
        for(uint i = 0; i < x;) {
            if(genesisOwnedIds[_returnee][_gameIdentifier][i] == _id) {
                genesisOwnedIds[_returnee][_gameIdentifier][i] = genesisOwnedIds[_returnee][_gameIdentifier][x -  1];
                genesisOwnedIds[_returnee][_gameIdentifier].pop();

                break;
            } else {
                unchecked{ i++; }
                continue;
            }
        }
    }

    function removeStakedArray(uint16 _id, uint8 _type) internal {
        uint256 x = stakedIds[_type].length;
        for(uint i = 0; i < x;) {
            if(stakedIds[_type][i] == _id) {
                stakedIds[_type][i] = stakedIds[_type][x -  1];
                stakedIds[_type].pop();

                break;
            } else {
                unchecked{ i++; }
                continue;
            }
        }
    }

    function emergencyRescueGenesis(uint16 _id, address _account) external {
        require(devRescueEnabled && msg.sender == owner());
        IERC721(Genesis).safeTransferFrom(address(this), _account, _id);
    }

    // ************** STEALING LOGIC ***************
    // @param: _gameId: 1 = bullrun, 2 = MF, 3 = DW, 4 = PM, 5 = Wastelands
    // @param _id: the actual NFT id
    // @param: identifier:
    // 1=runner, 2=bull, 3=matador
    // 4=cadet, 5=alien, 6=general, 
    // 7=baker, 8=foodie, 9=shopowner, 
    // 10=cat, 11=dog, 12=vet
    function stealGenesis(uint16 _id, uint256 seed, uint8 _gameId, uint8 identifier, address _victim) external onlyGames returns (address thief) {
        uint256 bucket = (seed & 0xFFFFFFFF);
        if (_gameId == 1) { // is a bullrun nft
            if (identifier == 1) { // is a runner
                thief = OriginalAlphaOwner[uint16(alphaIds[1][bucket % alphaIds[1].length])];
                delete OriginalRunnerOwner[_id];
            } else if (identifier == 2) { // is a bull
                thief = OriginalMatadorOwner[uint16(stakedIds[1][(bucket % stakedIds[1].length)])];
                delete OriginalBullOwner[_id];
            }
        } else if (_gameId == 2) { // is a mf nft, aliens can't be stolen
            if (identifier == 4) { // is a cadet
                thief = OriginalAlienOwner[uint16(stakedIds[2][(bucket % stakedIds[2].length)])];
                delete OriginalCadetOwner[_id];
            }
        } else if (_gameId == 3) { // is a dw nft
            if (identifier == 10) { // is a cat
                thief = OriginalAlphaOwner[uint16(alphaIds[3][bucket % alphaIds[3].length])];
                delete OriginalCatOwner[_id];
            } else if (identifier == 11) { // is a dog
                thief = OriginalVetOwner[uint16(stakedIds[3][(bucket % stakedIds[3].length)])];
                delete OriginalDogOwner[_id];               
            }
        } else if (_gameId == 4) { // is a pm nft
            if (identifier == 7) { // is a baker
                thief = OriginalAlphaOwner[uint16(alphaIds[4][bucket % alphaIds[4].length])];
                delete OriginalBakerOwner[_id];
            } else if (identifier == 8) { // is a foodie
                thief = OriginalShopOwnerOwner[uint16(stakedIds[4][(bucket % stakedIds[4].length)])];
                delete OriginalFoodieOwner[_id];
            }
        }
        removeGenesisArray(_id, _victim, _gameId);
        IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
        emit NFTStolen(thief, _victim, _id);
    }

    // only tier 3 nfts can be stolen during wastelands migration
    // for tier 3's being SENT to wastes
    
    function stealMigratingGenesis(uint16 _id, uint256 seed, uint8 _gameId, address _victim, bool returningFromWastelands) external onlyGames returns (address thief) {
        uint256 bucket = (seed & 0xFFFFFFFF);
        if (_gameId == 1) { // steal matador
            thief = OriginalAlienOwner[uint16(stakedIds[2][(bucket % stakedIds[2].length)])];
            if (!returningFromWastelands) { // if NFT is going to wastelands
                IERC721(Genesis).safeTransferFrom(_victim, thief, _id);
            } else { // user is bringing NFT back from wastelands
                IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
            }
            delete OriginalMatadorOwner[_id];
        } else if (_gameId == 2) { // steal general
            thief = OriginalAlienOwner[uint16(stakedIds[2][(bucket % stakedIds[2].length)])];
            if (!returningFromWastelands) { // if NFT is going to wastelands
                IERC721(Genesis).safeTransferFrom(_victim, thief, _id);
            } else { // user is bringing NFT back from wastelands
                IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
            }
            delete OriginalGeneralOwner[_id];
        } else if (_gameId == 3) { // steal vet
            thief = OriginalAlienOwner[uint16(stakedIds[2][(bucket % stakedIds[2].length)])];
            if (!returningFromWastelands) { // if NFT is going to wastelands
                IERC721(Genesis).safeTransferFrom(_victim, thief, _id);
            } else { // user is bringing NFT back from wastelands
                IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
            }
            delete OriginalVetOwner[_id];
        } else if (_gameId == 4) { // steal shopowner
            thief = OriginalAlienOwner[uint16(stakedIds[2][(bucket % stakedIds[2].length)])];
            if (!returningFromWastelands) { // if NFT is going to wastelands
                IERC721(Genesis).safeTransferFrom(_victim, thief, _id);
            } else { // user is bringing NFT back from wastelands
                IERC721(Genesis).safeTransferFrom(address(this), thief, _id);
            }
            delete OriginalShopOwnerOwner[_id];
        }
        emit NFTStolen(thief, _victim, _id);
    }

    // ************ UNIVERSAL NFT GROUPING FXNS (PLATOONS, MOBS, LITTERS, UNIONS) *************

    // @param: _ids: NFT ids being staked together to form a platoon, litter... etc
    // @param: _creator: address of the person creating their group (staker)
    // @param: _gameIdentifier: 1 = bullrun, 2 = MF, 3 = DW, 4 = PM

    function createGroup(uint16[] calldata _ids, address _creator, uint8 _gameIdentifier) external onlyGames {
        uint16 length = uint16(_ids.length); 
        for (uint i = 0; i < length;) {
            uint8 identifier;
            if (_gameIdentifier == 1) { // must be mob
                    Genesis.safeTransferFrom(_creator, address(this), _ids[i]);
                    OriginalRunnerOwner[_ids[i]] = _creator;
                    numRunnersStaked++;
                    identifier = 1;
                    emit RunnerReceived(_creator, _ids[i]);
            } else if (_gameIdentifier == 2) { // must be platoon
                    Genesis.safeTransferFrom(_creator, address(this), _ids[i]);
                    OriginalCadetOwner[_ids[i]] = _creator;
                    numCadetsStaked++;
                    identifier = 4;
                    emit CadetReceived(_creator, _ids[i]);
            } else if (_gameIdentifier == 3) { // must be litter
                    Genesis.safeTransferFrom(_creator, address(this), _ids[i]);
                    OriginalCatOwner[_ids[i]] = _creator;
                    numCatsStaked++;
                    identifier = 10;
                    emit CatReceived(_creator, _ids[i]);
            } else if (_gameIdentifier == 4) { // must be union
                    IERC721(Genesis).safeTransferFrom(_creator, address(this), _ids[i]);
                    OriginalBakerOwner[_ids[i]] = _creator;
                    numBakersStaked++;
                    identifier = 7;
                    emit BakerReceived(_creator, _ids[i]);
            }
            genesisGameIdentifier[_ids[i]] = _gameIdentifier;
            if (genesisIdentifier[_ids[i]] == 0) {
                genesisIdentifier[_ids[i]] = identifier;
            }

            genesisOwnedIds[_creator][_gameIdentifier].push(_ids[i]);

            unchecked { i++; }
        }
        numGenesisStaked += length;

        if (_gameIdentifier == 1) { 
            emit MobCreated(_creator, _ids); 
        } else if (_gameIdentifier == 2) { 
            emit PlatoonCreated(_creator, _ids); 
        } else if (_gameIdentifier == 3) { 
            emit LitterCreated(_creator, _ids);
        } else if (_gameIdentifier == 4) { 
            emit UnionCreated(_creator, _ids);
        }
    }

    function addToGroup(uint16 _id, address _creator, uint8 _gameIdentifier) external onlyGames {

        if (_gameIdentifier == 1) { // must be mob
                IERC721(Genesis).safeTransferFrom(_creator, address(this), _id);
                OriginalRunnerOwner[_id] = _creator;
                numRunnersStaked++;
                emit RunnerReceived(_creator, _id);
        } else if (_gameIdentifier == 2) { // must be platoon
                IERC721(Genesis).safeTransferFrom(_creator, address(this), _id);
                OriginalCadetOwner[_id] = _creator;
                numCadetsStaked++;
                emit CadetReceived(_creator, _id);
        } else if (_gameIdentifier == 3) { // must be litter
                IERC721(Genesis).safeTransferFrom(_creator, address(this), _id);
                OriginalCatOwner[_id] = _creator;
                numCatsStaked++;
                emit CatReceived(_creator, _id);
        } else if (_gameIdentifier == 4) { // must be union
                IERC721(Genesis).safeTransferFrom(_creator, address(this), _id);
                OriginalBakerOwner[_id] = _creator;
                numBakersStaked++;
                emit BakerReceived(_creator, _id);
        }
        numGenesisStaked++;
        genesisOwnedIds[_creator][_gameIdentifier].push(_id);

        
        if (_gameIdentifier == 1) { 
            if (genesisIdentifier[_id] == 0) {
                genesisIdentifier[_id] = 1;
            }
            emit RunnerAdded(_creator, _id); 
        } else if (_gameIdentifier == 2) { 
            if (genesisIdentifier[_id] == 0) {
                genesisIdentifier[_id] = 4;
            }
            emit CadetAdded(_creator, _id); 
        } else if (_gameIdentifier == 3) { 
            if (genesisIdentifier[_id] == 0) {
                genesisIdentifier[_id] = 10;
            }
            emit CatAdded(_creator, _id);
        } else if (_gameIdentifier == 4) { 
            if (genesisIdentifier[_id] == 0) {
                genesisIdentifier[_id] = 7;
            }
            emit BakerAdded(_creator, _id);
        }

    }

    function unstakeGroup(address _creator, uint8 _gameIdentifier) external onlyGames {  
        emit GroupUnstaked(_creator, _gameIdentifier, uint80(block.timestamp));
    } 

    // ************ BULLRUN GAME FUNCTIONS

    function getBullOwner(uint16 _id) external view returns (address) {
        return OriginalBullOwner[_id];
    }

    function getMatadorOwner(uint16 _id) external view returns (address) {
        return OriginalMatadorOwner[_id];
    }

    function getRunnerOwner(uint16 _id) external view returns (address) {
        return OriginalRunnerOwner[_id];
    }

    function matadorCount() public view returns (uint16) {
        return uint16(stakedIds[1].length);
    }

    function bullCount() public view returns (uint16) {
        return numBullsStaked;
    }

    function runnerCount() public view returns (uint16) {
        return numRunnersStaked;
    }

    // ************ MOONFORCE GAME FUNCTIONS

    function getCadetOwner(uint16 _id) external view returns (address) {
        return OriginalCadetOwner[_id];
    }

    function getAlienOwner(uint16 _id) external view returns (address) {
        return OriginalAlienOwner[_id];
    }

    function getGeneralOwner(uint16 _id) external view returns (address) {
        return OriginalGeneralOwner[_id];
    }

    function cadetCount() external view returns (uint16) {
        return numCadetsStaked;
    }

    function alienCount() external view returns (uint16) {
        return uint16(stakedIds[2].length);
    }

    function generalCount() external view returns (uint16) {
        return numGeneralsStaked;
    }

    // ************ DOGE WORLD GAME FUNCTIONS
    
    function getCatOwner(uint16 _id) external view returns (address) {
        return OriginalCatOwner[_id];
    }

    function getDogOwner(uint16 _id) external view returns (address) {
        return OriginalDogOwner[_id];
    }

    function getVetOwner(uint16 _id) external view returns (address) {
        return OriginalVetOwner[_id];
    }

    function catCount() external view returns (uint16) {
        // return uint16(catIds.length());
        return numCatsStaked;
    }

    function dogCount() external view returns (uint16) {
        // return uint16(dogIds.length());
        return numDogsStaked;
    }

    function vetCount() external view returns (uint16) {
        return uint16(stakedIds[3].length);
    }

    // ************ PYE MARKET GAME FUNCTIONS
    
    function getBakerOwner(uint16 _id) external view returns (address) {
        return OriginalBakerOwner[_id];
    }

    function getFoodieOwner(uint16 _id) external view returns (address) {
        return OriginalFoodieOwner[_id];
    }

    function getShopOwnerOwner(uint16 _id) external view returns (address) {
        return OriginalShopOwnerOwner[_id];
    }

    function bakerCount() external view returns (uint16) {
        return numBakersStaked;
    }

    function foodieCount() external view returns (uint16) {
        return numFoodiesStaked;
    }

    function shopOwnerCount() external view returns (uint16) {
        return uint16(stakedIds[4].length);
    }

    function setGameContract(address _contract, bool flag) external onlyOwner {
        gameContracts[_contract] = flag;
    }

    // ************ ALPHA AND RAT COUNT ***************

    function alphaCount(uint8 _gameIdentifier) external view returns (uint16) {
        return uint16(alphaIds[_gameIdentifier].length);
    }

    function allAlphaCount() external view returns (uint16 count) {
        count += uint16(alphaIds[1].length);
        count += uint16(alphaIds[2].length);
        count += uint16(alphaIds[3].length);
        count += uint16(alphaIds[4].length);
        count += uint16(alphaIds[5].length);
    }

    function ratCount() external view returns (uint16) {
        return numRatsStaked;
    }
}