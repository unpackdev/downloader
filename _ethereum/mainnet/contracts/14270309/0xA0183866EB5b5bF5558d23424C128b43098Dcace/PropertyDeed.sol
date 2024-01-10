// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";


// ************************ @author: THE ARCHITECT // ************************ //
/*                                    ,                                           
                          %%%%%%%%%%%%     (%%%%%%%%%&/                         
                     %%%%%%%%%  %%%%%%.    (%%%%,   #%%&&&&(                    
                    (%%%%%% #%%% %%%%%.   #%%%%%#  %%%%%&&&&                    
             .%%     /%%%%%%%###(#####.    ######### %%%%%%      ##             
           /%%%%%(     %%%##((((((,          ,(((((((##%%,    /%%%%%%%#         
          %%%%%%%%%(    .##(.                       .(##     %%%%%%%%%%%        
       *%%%,/%%%%%%###                                     %%%%%( # %%%%%%      
      %%%%%/*%%% ###*         #%%%%%%%%%%%%%%%%%%%(        .###%%( %#.%%%%%#    
    (%%%%%%,*# ((/        %%%%%%%%%%%%%%%%%%%%%%%%%%%%#       .(((# %%%%%%%%,   
    %%%%%%###(((,      (%%%%%%%%%%%%.         ,%%%%%%%%%%%      (((##%%%%%%%%   
          ,#(((      #%%%%%%%%%(                   ,%%%%%%%%     ((####         
                    %%%%%%%%%         /%%%%%%%/        %%%%%%               *./  
 %%%%%%%%%%/,      %%%%%%%%       #%%%%%%%%%%%%%%%%/     #%%%%,     .%%%%%%%%%%/
 %%%%%%%%%%#*     %%%%%%%%      %%%%%%%%%%%%%%%%%%%%%.     %%%%    *##%%%%%%%%%%
 %%%%%,,%%##(    .%%%%%%%     ,%%%%%%%%%%%%%%%%%%%%%%%/     %%%/   *###   // %%%
%%%%%  %%#(((    ,%%%%%%#     %%%%%%%%%%%Q%%%%%%%%%%%%%      %%/   (((( ,%%% %%%
%%%%%     ,#*    .#######     %%%%%%%%%%%%%%%%%%%%%%%%%       %/   *((#%%%%* %%%
 %%%%%%%%%%##     ########    (%%%%%%%%%%%%%%%%%%%%%%%%       %    *###%%%%%%&&%
 *&&&%%/           ########    (#%#############%%%%%%%%      #.         #%%%&&& 
                    #########*   *#######*##########%%                          
        ,,%###((     ,##########((((((((((((((######/            ##%%%%%%.      
    .%%%%%%%###((.      ###((((((((((((((((((((((#(            *(###%%%%%%%%,   
     (%%  ,  ,,((((.       /((((((((((((((((((((             /(((#%%%  %%%%%    
      /%%% %%%( ####(*           /((((((((/                (((((##%  ,%%%%%     
        %%%*%/%%%%%%#(                                      (####%%%%%%%%%/      
          %%%%%%%%      ((((((*.                   (####.     %%%%%%%%%#        
             #%%%     .####(((((((####     ((((((/(#,%%%%%      #%%%%           
                     /%%%%% #%%## /%##.    ####  % %% %%%%%%                    
                    (%%%%%%%%%    %%%%.    %%%%.(%% %% %%%%%                    
                      %%%%%%%%%%%%%%%%    %%%%%%,*%%%%%%%%%                     
                             %%%%%%%%     %%%%%%%%                                   
*/
// *************************************************************************** //

contract PROPERTYDEED is ERC1155, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    Counters.Counter public _tokenIdCounter;

    string public name = "METAVATARS - PROPERTY DEED";
    string public description = "METAVATARS PROPERTY DEED allow you to receive what is rightfully yours on P403. When you first enter the Metavatars world, you will be able to automatically synchronize your wallet with your inventory. The magic of the blockchain will do the rest.";

    uint256 public MAX_MINT_PER_WALLET = 1;
    uint256 public price = 0 ether;

    enum currentStatus {
        Before,
        PrivateMint,
        Pause
    }

    currentStatus public status;

    uint256 public constant LOOTBOX = 1;
    uint256 public constant PET = 2;
    uint256 public constant MOUNT = 3;
    uint256 public constant RESIDENCE = 4;
    uint256 public constant LAND = 5;

    mapping(address => uint256) public LootBoxTokensPerWallet;
    mapping(address => uint256) public PetTokensPerWallet;
    mapping(address => uint256) public MountTokensPerWallet;
    mapping(address => uint256) public ResidenceTokensPerWallet;
    mapping(address => uint256) public LandTokensPerWallet;

    bytes32 public LootBoxRootTree;
    bytes32 public PetRootTree;
    bytes32 public MountRootTree;
    bytes32 public ResidenceRootTree;
    bytes32 public LandRootTree;

    constructor(
        string memory _uri,
        bytes32 _lootMerkleRoot,
        bytes32 _petMerkleRoot,
        bytes32 _mountMerkleRoot,
        bytes32 _residenceMerkleRoot,
        bytes32 _landMerkleRoot
    ) ERC1155(_uri) {
        LootBoxRootTree = _lootMerkleRoot;
        PetRootTree = _petMerkleRoot;
        MountRootTree = _mountMerkleRoot;
        ResidenceRootTree = _residenceMerkleRoot;
        LandRootTree = _landMerkleRoot;
    }

    function getCurrentStatus() public view returns(currentStatus) {
        return status;
    }

    function setInPause() external onlyOwner {
        status = currentStatus.Pause;
    }

    function startPrivateMint() external onlyOwner {
        status = currentStatus.PrivateMint;
    }

    function setMaxMintPerWallet(uint256 maxMintPerWallet_) external onlyOwner {
        MAX_MINT_PER_WALLET = maxMintPerWallet_;
    }

    function setLootMerkleTree(bytes32 lootMerkleTree_) public onlyOwner{
        LootBoxRootTree = lootMerkleTree_;
    }

    function setPetMerkleTree(bytes32 petMerkleTree_) public onlyOwner{
        PetRootTree = petMerkleTree_;
    }

    function setMountMerkleTree(bytes32 mountMerkleTree_) public onlyOwner{
        MountRootTree = mountMerkleTree_;
    }

    function setResidenceMerkleTree(bytes32 residenceMerkleTree_) public onlyOwner{
        ResidenceRootTree = residenceMerkleTree_;
    }

    function setLandMerkleTree(bytes32 landMerkleTree_) public onlyOwner{
        LandRootTree = landMerkleTree_;
    }

    function lootMint(bytes32[] calldata merkleProof, uint32 amount) external {
        require(status == currentStatus.PrivateMint, "METAVATARS PROPERTY DEED: Loot Mint Is Not OPEN !");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, LootBoxRootTree, leaf), "METAVATARS PROPERTY DEED: You're not Eligible for the Loot Mint !");
        require(LootBoxTokensPerWallet[msg.sender] + amount <= MAX_MINT_PER_WALLET, "METAVATARS PROPERTY DEED: Max Loot Mint per Wallet !");

        LootBoxTokensPerWallet[msg.sender] += amount;
        _mint(msg.sender, LOOTBOX,  amount, "");
    }

    function petMint(bytes32[] calldata merkleProof, uint32 amount) external {
        require(status == currentStatus.PrivateMint, "METAVATARS PROPERTY DEED: Pet Mint Is Not OPEN !");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, PetRootTree, leaf), "METAVATARS PROPERTY DEED: You're not Eligible for the Loot Mint !");
        require(PetTokensPerWallet[msg.sender] + amount <= MAX_MINT_PER_WALLET, "METAVATARS PROPERTY DEED: Max Loot Mint per Wallet !");

        PetTokensPerWallet[msg.sender] += amount;
        _mint(msg.sender, PET,  amount, "");
    }

    function mountMint(bytes32[] calldata merkleProof, uint32 amount) external {
        require(status == currentStatus.PrivateMint, "METAVATARS PROPERTY DEED: Mount Mint Is Not OPEN !");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, MountRootTree, leaf), "METAVATARS PROPERTY DEED: You're not Eligible for the Loot Mint !");
        require(MountTokensPerWallet[msg.sender] + amount <= MAX_MINT_PER_WALLET, "METAVATARS PROPERTY DEED: Max Loot Mint per Wallet !");

        MountTokensPerWallet[msg.sender] += amount;
        _mint(msg.sender, MOUNT,  amount, "");
    }

    function residenceMint(bytes32[] calldata merkleProof, uint32 amount) external {
        require(status == currentStatus.PrivateMint, "METAVATARS PROPERTY DEED: Residence Mint Is Not OPEN !");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, ResidenceRootTree, leaf), "METAVATARS PROPERTY DEED: You're not Eligible for the Loot Mint !");
        require(ResidenceTokensPerWallet[msg.sender] + amount <= MAX_MINT_PER_WALLET, "METAVATARS PROPERTY DEED: Max Loot Mint per Wallet !");

        ResidenceTokensPerWallet[msg.sender] += amount;
        _mint(msg.sender, RESIDENCE,  amount, "");
    }

    function landMint(bytes32[] calldata merkleProof, uint32 amount) external {
        require(status == currentStatus.PrivateMint, "METAVATARS PROPERTY DEED: Land Mint Is Not OPEN !");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, LandRootTree, leaf), "METAVATARS PROPERTY DEED: You're not Eligible for the Loot Mint !");
        require(LandTokensPerWallet[msg.sender] + amount <= MAX_MINT_PER_WALLET, "METAVATARS PROPERTY DEED: Max Loot Mint per Wallet !");

        LandTokensPerWallet[msg.sender] += amount;
        _mint(msg.sender, LAND,  amount, "");
    }

    function gift(uint256 amount, uint256 tokenId, address giveawayAddress) public onlyOwner {
        require(amount > 0, "METAVATARS PROPERTY DEED: Need to gift 1 min !");
        _mint(giveawayAddress, tokenId, amount, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(_id > 0 && _id < 6, "URI: nonexistent token");
            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }
}




// ************************ @author: THE ARCHITECT // ************************ //
/*                                    ,                                           
                          %%%%%%%%%%%%     (%%%%%%%%%&/                         
                     %%%%%%%%%  %%%%%%.    (%%%%,   #%%&&&&(                    
                    (%%%%%% #%%% %%%%%.   #%%%%%#  %%%%%&&&&                    
             .%%     /%%%%%%%###(#####.    ######### %%%%%%      ##             
           /%%%%%(     %%%##((((((,          ,(((((((##%%,    /%%%%%%%#         
          %%%%%%%%%(    .##(.                       .(##     %%%%%%%%%%%        
       *%%%,/%%%%%%###                                     %%%%%( # %%%%%%      
      %%%%%/*%%% ###*         #%%%%%%%%%%%%%%%%%%%(        .###%%( %#.%%%%%#    
    (%%%%%%,*# ((/        %%%%%%%%%%%%%%%%%%%%%%%%%%%%#       .(((# %%%%%%%%,   
    %%%%%%###(((,      (%%%%%%%%%%%%.         ,%%%%%%%%%%%      (((##%%%%%%%%   
          ,#(((      #%%%%%%%%%(                   ,%%%%%%%%     ((####         
                    %%%%%%%%%         /%%%%%%%/        %%%%%%               *./  
 %%%%%%%%%%/,      %%%%%%%%       #%%%%%%%%%%%%%%%%/     #%%%%,     .%%%%%%%%%%/
 %%%%%%%%%%#*     %%%%%%%%      %%%%%%%%%%%%%%%%%%%%%.     %%%%    *##%%%%%%%%%%
 %%%%%,,%%##(    .%%%%%%%     ,%%%%%%%%%%%%%%%%%%%%%%%/     %%%/   *###   // %%%
%%%%%  %%#(((    ,%%%%%%#     %%%%%%%%%%%Q%%%%%%%%%%%%%      %%/   (((( ,%%% %%%
%%%%%     ,#*    .#######     %%%%%%%%%%%%%%%%%%%%%%%%%       %/   *((#%%%%* %%%
 %%%%%%%%%%##     ########    (%%%%%%%%%%%%%%%%%%%%%%%%       %    *###%%%%%%&&%
 *&&&%%/           ########    (#%#############%%%%%%%%      #.         #%%%&&& 
                    #########*   *#######*##########%%                          
        ,,%###((     ,##########((((((((((((((######/            ##%%%%%%.      
    .%%%%%%%###((.      ###((((((((((((((((((((((#(            *(###%%%%%%%%,   
     (%%  ,  ,,((((.       /((((((((((((((((((((             /(((#%%%  %%%%%    
      /%%% %%%( ####(*           /((((((((/                (((((##%  ,%%%%%     
        %%%*%/%%%%%%#(                                      (####%%%%%%%%%/      
          %%%%%%%%      ((((((*.                   (####.     %%%%%%%%%#        
             #%%%     .####(((((((####     ((((((/(#,%%%%%      #%%%%           
                     /%%%%% #%%## /%##.    ####  % %% %%%%%%                    
                    (%%%%%%%%%    %%%%.    %%%%.(%% %% %%%%%                    
                      %%%%%%%%%%%%%%%%    %%%%%%,*%%%%%%%%%                     
                             %%%%%%%%     %%%%%%%%                                   
*/
// *************************************************************************** //
