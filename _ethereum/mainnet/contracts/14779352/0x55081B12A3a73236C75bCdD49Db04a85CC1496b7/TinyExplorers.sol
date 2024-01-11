// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./TinyExplorersTypes.sol";
import "./ITinyExplorersRenderer.sol";

 

error InvalidExplorerCount();
error MintingPaused();
error MintNotAuthorized();
error NotOwnerOfTinyKingdom();
error PaymentAmountInvalid();
error PublicSaleIsNotActive();
error TokenAlreadyClaimed();


/// @dev interface for TinyKingdoms contract
interface TinyKingdomsInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/// @dev interface for TinyKingdoms Metadata contract
interface TinyKingdomsMetadataInterface {
    function isPirate(uint256 tokenId) external view returns (bool flag);
}

// @author emrecolako by oblique
// CC0 + on-chain 

//                            *%%%%%%%%%%%%%%%%%%%%%%%%%%%%#######+                         
//                          -**%%%%%%%%%%%%%%%%%%%%%%%%%%%%%########++-                      
//                          =%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##########=                      
//                          =%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%########=                      
//                       -##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#########**:                   
// -==.               .==*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%###########+==.                
// *%%:.....        ..:%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#############%%%:..        ......
// *%%%%%%%*        #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#############%%%%%#        +%%%%#
// *%%%%%%%%********%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#############%%%%%%********#%%%%#
// *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#############%%%%%%%%%%%%%%%%%%%#
// *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#############%%%%%%%%%%%%%%%%%%%#
// *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%################%%%%%%%%%%%%%%%%%%%#
// *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#########%%%%%%%%%%%%%%%%%%%%%#
// *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%########%%%%%%%%%%%%%%%%%%%%%%#
// *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%---=====------%%#=====---%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
// :-----%%%%%%%%%%%%%%%%%%%#**#%%**+===-----+*****===-----=====+%%#==*%%%%%%%%%%%%%%%%%%%--:
//      .********#%%%%%#####*==#%%*****+=====******--------===---##*--=#####%%%%%%********.  
//               *%%%%%========#%%%%%%%%%%%%%=--------=====------===--------%%%%%*           
//               .....:========+++%%%%%%%%%%%+==---==============-----------......           
//                    .===========**#%%%%%#**+==---==============-----------.                
//                    .=============+%%%%%+--===---===--------===-----------.                
//                       :========:::::::::--===---===--:::::::::===-----.                   
//                       .::-=====-----------===---===-----------===--:..                    
//                          :--===------------==---===-----------===::.                      
//                             -=====-----------===-----------=====-                         
//                             -=====-------------------------=====-                         
//                             -====---------------------------====-                         
//                             -==------===--===---===--===------==-                         
//                             -==--------===============--------==-                         
//                             -==-----------=========-----------==-                         
//                             :--------------========-------------:                         
//                                ===-------------------------===                            
//                                ===-------------------------===                            
//                                ::---------------------------::                            
//                                  .===-------------------===.                              
//                                   ---===-------------===---                               
//                             :--:::-----===============-----:::--:                         
//                       .:::::===---------=============---------===:::::.                   
//                       :*****+==-------------------------------==+*****:                   
//                  +****+++******===-------------------------===******+++****+              
//               :--***+++++******+++-------------------------+++******+++++***--:           
//             ..=*****==+***********===-------------------===***********+==*****+           
//            -*************************===-------------===**********************+           
//         :==+***************************+==---------==+*************************==:        

contract TinyExplorers is ERC721Enumerable, ReentrancyGuard, Ownable{


    uint256 private constant TOTAL_SUPPLY = 8192;

    uint256 private constant MINT_PRICE = 0.05 ether;

    uint256 public claimed = 0;


    // Restrict free claim to Tiny Kingdoms holders 
    bool public restricted = true; 
    bool public mintingPaused= true;


    address public renderingContractAddress;

    /// @dev change address to mainnet - below is rinkeby 
    // mainnet
    address private tinyKingdomsMetadataAddress = 0x22d8bD368796830F51c57f6E00E8fa37008B82e8;
    address private tinyKingdomsAddress = 0x788defd1AE1e2299D54CF9aC3658285Ab1dA0900;

    TinyKingdomsMetadataInterface tinyKingdomsMetadataContract = TinyKingdomsMetadataInterface(tinyKingdomsMetadataAddress);
    TinyKingdomsInterface tinyKingdomsContract = TinyKingdomsInterface(tinyKingdomsAddress);


    mapping(uint256 => TinyExplorersTypes.TinyExplorer) explorers;
    
    
    // ============ TOGGLES ============

    /// @notice toggle pause minting
    function togglePause() public onlyOwner{
        mintingPaused = !mintingPaused;
    }
    
    function toggleRestricted() public onlyOwner{
        restricted =!restricted;
    }

    // ============ MODIFIERS ============

    modifier publicSaleActive() {
        if (restricted) revert PublicSaleIsNotActive();
        _;
    }
    

    modifier ownerOfTinyKingdom(uint256 tinyKingdomsId) {
        if (restricted) {
            if(tinyKingdomsContract.ownerOf(tinyKingdomsId) != msg.sender) revert NotOwnerOfTinyKingdom();
            _;
        }
        _;
    }

    constructor() ERC721("Tiny Explorers", "EXPLORER") {} 

    // ============ HELPER FUNCTIONS ============
    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }


    /// @dev Check if Tiny Kingdom flag is a Jolly Roger
    function isPirateAndHasKingdom(uint256 tokenId) internal view returns (bool flag) {    
        if (tokenId>0 && tokenId<4097) return tinyKingdomsMetadataContract.isPirate(tokenId);
        else return false;   
    }


    function generateExplorer(uint256 tokenId) public view returns (uint256,bool _pirate){

        bool pirate = isPirateAndHasKingdom(tokenId); 
        uint256 hash = uint256(keccak256(abi.encodePacked(tokenId,msg.sender,block.difficulty,block.timestamp)));
        

        return (hash,pirate);
    }


    // ============ MINTING FUNCTIONS ============

    /// @dev Allows Tiny Kingdoms holders to claim an explorer for free
    function claimWithTinyKingdoms(uint256 tinyKingdomsId) public nonReentrant{
        require(tinyKingdomsId > 0 && tinyKingdomsId < 4097,  "Invalid token");
        require(!_exists(tinyKingdomsId), "This token has already been minted");

        require(tinyKingdomsContract.ownerOf(tinyKingdomsId) == msg.sender, "Not the owner of this Tiny Kingdom");
        
        mint(msg.sender,tinyKingdomsId);

    }

    /// @dev Allows Tiny Kingdoms holders to claim multiple explorers for free (just pay gas)
    function multiclaimWithTinyKingdoms(uint256[] memory tinyKingdomsIds) public payable nonReentrant {

        for (uint256 i; i<tinyKingdomsIds.length; i++) {

            require(tinyKingdomsIds[i] > 0 && tinyKingdomsIds[i] < 4097, "Token is not eligible to claim");
            if(tinyKingdomsContract.ownerOf(tinyKingdomsIds[i]) != msg.sender) revert NotOwnerOfTinyKingdom();
            if(explorers[tinyKingdomsIds[i]].dna!=0) revert TokenAlreadyClaimed();

            mint(msg.sender,tinyKingdomsIds[i]);
            }
    }

    /// @dev Mint Explorers

    function mintExplorers(uint256 amount) public payable nonReentrant publicSaleActive{
            
            if (claimed+amount>TOTAL_SUPPLY) revert InvalidExplorerCount();
            if (tx.origin != msg.sender) revert MintNotAuthorized();
            if (msg.value !=MINT_PRICE*amount) revert PaymentAmountInvalid();
            
            for (uint256 i; i <amount; i++) {

                uint256 nextId=findfirstExplorer();

                mint(msg.sender,nextId);
            }

    }

    /// @dev internal minting function
    function mint(address to, uint256 tokenId) internal {

        if (mintingPaused) revert MintingPaused();

        TinyExplorersTypes.TinyExplorer memory explorer;
        (explorer.dna,explorer.isPirate)=generateExplorer(tokenId);

        
        _safeMint(msg.sender, tokenId);
        explorers[tokenId] = explorer;    
        
        claimed++;

    }

    /// @dev check if an explorer has been created
    function explorerExists(uint256 tokenId) public view returns (bool){

        if (explorers[tokenId].dna!=0) return true;
        else return false;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){

        ITinyExplorersRenderer renderer = ITinyExplorersRenderer(renderingContractAddress);

        if (renderingContractAddress == address(0)) {
            return '';
        }
        return renderer.tokenURI(tokenId,explorers[tokenId]);
    }

    /// @dev Find first unclaimed explorer post claiming stage 
     function findfirstExplorer() internal view returns (uint256){
         
        uint256 firstExplorer=1;
        
        for (uint256 i=1; i< TOTAL_SUPPLY; i++){
            if (explorerExists(i)==false) break;
            firstExplorer = i+1;
        }
        
        return firstExplorer;
    }

    function withdraw() public onlyOwner {

        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

//  for Y..
}