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

contract MAVA is ERC1155, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    Counters.Counter public _tokenIdCounter;

    string public name = "METAVATARS - MAVA";
    string public description = "This magical coin grants the power to access the best-stocked vaults in the Scarlex bank. This digital title was designed to offer its owner almost eternal wealth in MAVA.";

    uint256 public MAX_MINT_PER_WALLET = 1;
    uint256 public price = 0 ether;

    enum currentStatus {
        Before,
        PrivateMint,
        Pause
    }

    currentStatus public status;

    mapping(address => uint256) public MavaTokensPerWallet;

    bytes32 public MavaRootTree;

    constructor(
        string memory _uri,
        bytes32 _mavaMerkleRoot
    ) ERC1155(_uri) {
        MavaRootTree = _mavaMerkleRoot;
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

    function setMavaMerkleTree(bytes32 mavaMerkleTree_) public onlyOwner{
        MavaRootTree = mavaMerkleTree_;
    }

    function MAVAMint(bytes32[] calldata merkleProof, uint32 amount) external {
        require(status == currentStatus.PrivateMint, "METAVATARS MAVA: Mava Mint Is Not OPEN !");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, MavaRootTree, leaf), "METAVATARS MAVA: You're not Eligible for the Mava Mint !");
        require(MavaTokensPerWallet[msg.sender] + amount <= MAX_MINT_PER_WALLET, "METAVATARS MAVA: Max Mava Mint per Wallet !");

        MavaTokensPerWallet[msg.sender] += amount;
        _mint(msg.sender, 1,  amount, "");
    }

    function gift(uint256 amount, address giveawayAddress) public onlyOwner {
        require(amount > 0, "METAVATARS MAVA: Need to gift 1 min !");
        _mint(giveawayAddress, 1, amount, "");
    }

    function uri(uint256 _id) public view override returns (string memory) {
            require(_id == 1, "URI: nonexistent token");
            return string(abi.encodePacked(super.uri(_id)));
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
