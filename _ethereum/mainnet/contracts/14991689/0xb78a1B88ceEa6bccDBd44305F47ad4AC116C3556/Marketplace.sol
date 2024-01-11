// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./MACNFT.sol";


contract Marketplace is AccessControl {

    struct AddOn {
        address nftAddress;
        string hash;
        uint256 price;
        uint256 level;
    }
    
    struct PlayerInfo {
        address nft;
        uint256 nftId;
        uint256 [] addOns;
        uint256 [] oldNFTs;
        bool isUpgrade;
    }

    struct Collection {
        string name;
        string description;
        string hash;
        address nftAddress;
    }

    struct NFTProd {
        address owner;
        address nft;
        uint256 tokenID;
        uint256 price;
        uint8 flag;
        uint256 time;
    }

    address [] public arrPlayers;
    address [] public arrCollections;
    mapping (address => string[])public arrAddOns;

    mapping (address => PlayerInfo) public playerInfo;
    mapping (string => AddOn) public addOnInfo;
    mapping (address => Collection) public collectionInfo;
    mapping (address => mapping(string => bool)) public addOnAvailable;
    mapping (address => uint256) public interestOfPlayers;

    bytes32 public constant PRODUCE_ROLE = keccak256("PRODUCE_ROLE");

    mapping(address => mapping (uint256 => NFTProd)) public playerProds;
    mapping(address => mapping (address => uint256[])) public playerProdsIDs; // player_addrss => (nft_addrss => [nftIDs])
    mapping(address => uint256 []) public saleNFTIDs;

    address payable public addOnMaker;
    address public feeAddress;

    uint public feePercent;
    uint public interestAddonFee;
    uint public totalPercent = 10000;

    event AddCollection(string _name, string _description, address _nft);
    event DeleteCollection(address _nft);
    event NewPlayer(address _nft, address _player, uint256 _nftId);
    event UpdatePlayer(address _nft, address _player, uint256 _nftId);
    event RemovePlayer(address _player);
    event AddAddOn(address _nft, string _hash, uint256 _price);
    event DeleteAddOn(address _nft, string _hash);
    event AddSale(address _nft, uint256 _nftId, uint256 _price, address _owner);
    event Sale(address to, address _nft, uint256 _nftId, uint256 _amount );
    event CancelSale(address _nft, uint256 _nftId);
    
    constructor(uint _fee, uint _addonFee) {
        _setupRole(PRODUCE_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        feePercent = _fee;
        interestAddonFee = _addonFee;
        feeAddress = _msgSender();
    }

    // Collections
    function addCollection(string memory _name, string memory _description, string memory _hash, address _nft) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can add this.");
        require(collectionInfo[_nft].nftAddress != _nft, "can't register double collection");
        
        Collection memory newCollection = Collection(_name, _description, _hash, _nft);
        collectionInfo[_nft] = newCollection;
        arrCollections.push(_nft);
        emit AddCollection(_name, _description, _nft);
    }

    function udpateCollection(string memory _name, string memory _description, string memory _hash, address _nft) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can add this.");

        collectionInfo[_nft].name = _name;
        collectionInfo[_nft].description = _description;
        collectionInfo[_nft].hash = _hash;
    }

    function deleteCollection(address _nft) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can delete this.");
    
        uint arrIndex; 
        bool isExist = false;
        for (uint256 index = 0; index < arrCollections.length; index++){
            if (_nft == arrCollections[index]){
                arrIndex = index;
                isExist = true;
            }
        }
        
        if(isExist){
            arrCollections[arrIndex] = arrCollections[arrCollections.length-1];
            arrCollections.pop(); 
        }
        delete collectionInfo[_nft];

        emit DeleteCollection(_nft);
    }

    // Players
    function registerPlayer(address _nft, address _player, uint256 _nftId, uint16[] memory _addons, uint256[] memory _oldNfts) external {
        require(_nft == collectionInfo[_nft].nftAddress, "there is no collection for this player");
        require(playerInfo[_player].nft != _nft, "can't register double player");

        PlayerInfo storage newPlayer = playerInfo[_player];
        newPlayer.nft = _nft;
        newPlayer.nftId = _nftId;
        newPlayer.addOns = _addons;
        newPlayer.oldNFTs = _oldNfts;
        newPlayer.isUpgrade = true;
        arrPlayers.push(_player);
        interestOfPlayers[_player] = 0;

        emit NewPlayer(_nft, _player, _nftId);
    }

    // Players
    function registerPlayerWithNew(address _nft, address _player, string memory _hash, uint16[] memory _addons, uint256[] memory _oldNfts) external {
        require(_nft == collectionInfo[_nft].nftAddress, "there is no collection for this player");
        require(playerInfo[_player].nft != _nft, "can't register double player");

        uint256 newNftId = MACNFT(_nft).mint(_player, _hash);

        PlayerInfo storage newPlayer = playerInfo[_player];
        newPlayer.nft = _nft;
        newPlayer.nftId = newNftId;
        newPlayer.addOns = _addons;
        newPlayer.oldNFTs = _oldNfts;
        newPlayer.isUpgrade = true;
        arrPlayers.push(_player);
        interestOfPlayers[_player] = 0;

        emit NewPlayer(_nft, _player, newNftId);
    }

    function updatePlayer(address _nft, address _player, uint256 _nftId, uint16[] memory _addons, uint256[] memory _oldNfts, bool _isUpgrade) external {
        require(_nft == collectionInfo[_nft].nftAddress, "there is no collection for this player");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin owner only can update this.");
        playerInfo[_player].nft = _nft;
        playerInfo[_player].nftId = _nftId;
        playerInfo[_player].addOns = _addons;
        playerInfo[_player].oldNFTs = _oldNfts;
        playerInfo[_player].isUpgrade = _isUpgrade;

        emit UpdatePlayer(_nft, _player, _nftId);
    }

    function upgradePlayer(address _nft, address _player, string memory _hash) external {
        require(_nft == collectionInfo[_nft].nftAddress, "there is no collection for this player");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin owner only can update this.");
        
        uint256 newNftId = MACNFT(_nft).mint(_player, _hash);
        
        playerInfo[_player].oldNFTs.push(playerInfo[_player].nftId);
        playerInfo[_player].nftId = newNftId;
        playerInfo[_player].isUpgrade = true;

        emit UpdatePlayer(_nft, _player, newNftId);
    }

    function deletePlayer(address _player) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || (_player == _msgSender()), "Admin or product owner only can delete this.");
        
        uint arrIndex; 
        bool isExist = false;
        for (uint256 index = 0; index < arrPlayers.length; index++){
            if (_player == arrPlayers[index]){
                arrIndex = index;
                isExist = true;
            }
        }
        
        if(isExist){
            arrPlayers[arrIndex] = arrPlayers[arrPlayers.length-1];
            arrPlayers.pop(); 
        }

        delete playerInfo[_player];

        emit RemovePlayer(_player);
    }

    // Addons
    function addAddOn(address _nft, string memory _hash, uint256 _price, uint256 _level) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can add this.");
        require(addOnInfo[_hash].nftAddress != _nft, "can't regsiter double addon");

        AddOn memory newAddOn = AddOn(_nft, _hash, _price, _level);
        addOnInfo[_hash] = newAddOn;
        arrAddOns[_nft].push(_hash);

        emit AddAddOn(_nft, _hash, _price);
    }

    function updateAddOn(address _nft, string memory _hash, uint256 _price, uint256 _level) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can add this.");

        addOnInfo[_hash].nftAddress = _nft;
        addOnInfo[_hash].price = _price;
        addOnInfo[_hash].level = _level;
    }

    function deleteAddOn(address _nft, string memory _hash) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can delete this.");
        
        uint arrIndex; 
        bool isExist = false;
        for (uint256 index = 0; index < arrAddOns[_nft].length; index++){
            if ((keccak256(abi.encodePacked(_hash))) == (keccak256(abi.encodePacked(arrAddOns[_nft][index])))){
                arrIndex = index;
                isExist = true;
            }
        }
        
        if(isExist){
            arrAddOns[_nft][arrIndex] = arrAddOns[_nft][arrAddOns[_nft].length-1];
            arrAddOns[_nft].pop(); 
        }

        delete addOnInfo[_hash];
        emit DeleteAddOn(_nft, _hash);
    }

    function buyAddOn(address _nft, string memory _hash, address _to) public payable {

        require( addOnAvailable[_to][_hash] == true, "Player can't buy it yet." );
        require( msg.value == addOnInfo[_hash].price, "Same price" );
        
        // mint add-on to player
        uint256 addOnId = MACNFT(_nft).mint(_to, addOnInfo[_hash].hash);
        playerInfo[_to].addOns.push(addOnId);
        playerInfo[_to].isUpgrade = false;
        
        uint256 interestingFee = msg.value * interestAddonFee / totalPercent;
        payable(addOnMaker).transfer(msg.value - interestingFee);
        interestOfPlayers[_to] = interestOfPlayers[_to] + interestAddonFee;
    }


    function allowAddOn(string memory _hash, address _player) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Must have admin role to mint");
        addOnAvailable[_player][_hash] = true;
    }


    function addNewProduction(address _nft, uint256 _nftId, uint256 _price) public returns (bool) {
        playerProds[_nft][_nftId] = NFTProd(_msgSender(), _nft, _nftId, _price, 1, block.timestamp);
        saleNFTIDs[_nft].push(_nftId);
        playerProdsIDs[_msgSender()][_nft].push(_nftId);
        MACNFT(_nft).transferFrom(_msgSender(), address(this), _nftId);
        emit AddSale(_nft, _nftId, _price, _msgSender());
        return true;
    }

    function getPlayerSaleNFTs(address _player, address _nft) public view returns(uint256[] memory) {
        return playerProdsIDs[_player][_nft];
    }
    
    function getProdList(address _nft) public view returns(uint256[] memory){
        return saleNFTIDs[_nft];
    }
    
    function getProdById(address _nft, uint256 _nftId) public view returns(NFTProd memory){
        return playerProds[_nft][_nftId];
    }
    
    function getCollections() public view returns (address[] memory){
        return arrCollections;
    }

    function getPlayers() public view returns (address[] memory){
        return arrPlayers;
    }

    function getAddOns(address _nft) public view returns (string[] memory){
        return arrAddOns[_nft];
    }

    function getPlayerInfo(address _player) public view returns (PlayerInfo memory, uint256[] memory, uint256[] memory, bool){
        return (playerInfo[_player], playerInfo[_player].addOns, playerInfo[_player].oldNFTs, playerInfo[_player].isUpgrade);
    } 
    
    function deleteProdByID(address _nft, uint256 _nftId, address _owner) internal returns (bool) {
        // Delet from prod
        uint arrIndex; 
        bool isExist = false;
        for (uint256 index = 0; index < saleNFTIDs[_nft].length; index++){
            if (_nftId == saleNFTIDs[_nft][index]){
                arrIndex = index;
                isExist = true;
            }
        }
        
        if(isExist){
            saleNFTIDs[_nft][arrIndex] = saleNFTIDs[_nft][saleNFTIDs[_nft].length-1];
            saleNFTIDs[_nft].pop(); 
        }

        // Delete from ProdIDs
        uint playerMarketIndex; 
        isExist = false;
        for (uint256 index = 0; index < playerProdsIDs[_owner][_nft].length; index++){
            if (_nftId == playerProdsIDs[_owner][_nft][index]){
                playerMarketIndex = index;
                isExist = true;
            }
        }
        
        if(isExist){
            playerProdsIDs[_owner][_nft][playerMarketIndex] = playerProdsIDs[_owner][_nft][playerProdsIDs[_owner][_nft].length-1];
            playerProdsIDs[_owner][_nft].pop(); 
        }
        
        // Delete from Prodmap
        delete playerProds[_nft][_nftId];
        return true;
    }
    
    
    function buy(address to, address _nft, uint256 _nftId, uint256 _amount ) public payable {
        require(msg.value == playerProds[_nft][_nftId].price, "Amount should be same with price");
        
        MACNFT(_nft).transferFrom(address(this), to, _nftId);
        uint256 feeAmount = msg.value * feePercent / totalPercent;
        payable(playerProds[_nft][_nftId].owner).transfer(msg.value - feeAmount);
        payable(feeAddress).transfer(feeAmount);
        deleteProdByID(_nft, _nftId, playerProds[_nft][_nftId].owner);

        emit Sale(to, _nft, _nftId, _amount);
    }


    // Cancel the sale
    function cancelForSale(address _nft, uint256 _nftId) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || (playerProds[_nft][_nftId].owner == _msgSender()), "Admin or product owner only can delete this.");
        MACNFT(_nft).transferFrom(address(this), playerProds[_nft][_nftId].owner, _nftId);
        deleteProdByID(_nft, _nftId, playerProds[_nft][_nftId].owner);
        emit CancelSale(_nft, _nftId);
        return true;
    }

    function recoverEmergency(address recipient) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can do this.");
        uint256 amount = address(this).balance;
        (bool success,) = payable(recipient).call{value: amount}("");
    }
    
    // set fee precentage
    function setFeeAmount(uint _feeAmount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can do this.");
        feePercent = _feeAmount;
    }

    function setInterestingFeeAmount(uint _feeAmount) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can do this.");
        interestAddonFee = _feeAmount;
    }


    
    //set fee address
    function setFeeAddress(address _feeAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can do this.");
        feeAddress = _feeAddress;
    }

    // set macaddonmaker
    function setAddonMakerAddress(address payable _makerAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Admin only can do this.");
        addOnMaker = _makerAddress;
    }
}
