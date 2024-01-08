// SPDX-License-Identifier: MIT

/*
                                   ...   .........'''',,,;;;,,,;;;;;;;;;;;;;;,,;;,,,,,''''............                                      
                                   .......''',,,,,,,,;:::::cccccccccccccccccccccc:::::;;;,,,''.........                                     
                                .........',,;;;:::ccooccllllooooooooooooolc::lolllllccccc:::;;,,,'''.......                                 
                           .........',,;;;::ccccllldKNkllddddxxxxxxxxxxdodo:,:dxddddoooollllcc:;::;,,'''........     .                      
                        ........''',;;;:cclllooooddOWMN0xodkkOOOOOOOxxxkOko;',okkkkkkxxxddolc;',cccc:::;,,''...........   .                 
              .  ....  .......',;;::ccllloodddxxxxxKMNOxkxlok0000OkkOKKOdlc:,';x000OOOOkdlc:;''ldoollccc::;;;,'''....... ....        .      
           ..... .......'',',,;:cclllooddxxxkkkOOkONMXxoddc,:x00OO0NN0xooool:,'cOKKK0kdol:'...cxxxdddoolllcc:;;;;,'...........  ............
  .................'''',,;;::cclllooddxxkkOOO0000O0WMKxd0XOo;;ok00KNXxooooddo:''cOOkxdl:'. ..;kOOkkkxxxddoollccc::;,''''....................
  ...............'',,,,;;:ccllloddxxxkOOOO00KKKKK0KMW0dxKWX0kdxOOkKWKdlodooool;.'cddo;......,xKK00OOOkkxxxddoollcc::;;;;,'.....''...........
 ..............',,,,;;::ccllooddxkkOOO00KKKKKKKKK0XMWOokNWX00OO0K0XWOooodolllc:;;;;'........oKXKKK0000OOkkxxdddolllcc:;::;''...',...........
..............'',;;;:ccllooodxxkOO0000KKKKKKKOO0kONMNkd0WWKOOOkKXKNXdoodolclllc:;'.........:OXXXXXXK0000OOkkxxxddlcllc::::,','..............
  ........'''',;;::ccllooddxxkkO0O00KKK00KKOd:;:cOMMXkkXMW0kkkOXKXWOlloodlccccc:,.........'dXNNNXXXX000KK0Okkkkxl;,collccc,.''.......'......
 .......',,'',,;:ccllooodxxkkOO00000Oxdddxo;....,0MWKxOWMXOxddO00NXdlooooll:;;;;,'''''....;OXXXXXXXXKK0KKK00OOOko,,ld:,cllc'..,'.'..........
 ........'',,,;:cllooodxxkkOkO0KK0Oo;'.....     ;KWKxldO0xlcccllxKk::ccccc:;;;,,'',,,,....c0XXXXXXXXKKKXXKKKK00Od;:o:. ';,.  .''.''.........
 .......'',,;::cloodddxkOOO00KKOxo:'.           .;,......       ..........'',,;,'',,;'....:xKXNXXXNXXXKOdx0XKOdxxdl'          ....'''.......
........',;;:clllodxxkkOOkddkOd;...                                            ...',,..'. .:xKXXXNNNNXkc:dXKd'.cxo'       ...... .''........
 .....'',;;:clloddxkkOOko;.,c:..                                                    . ...  .'l0XXNNNWNko:lOx.  ........'..',''. .';;'.''....
 ....',,;;:ccloddxkOkkdc'....                                                                .;oxk0XNNNKk:ox'   .,ldoc::;,,;,'....,;,.......
....',,;;:cllodxxkOOxo;....                                                                     .,lkKNNNd':o,,ccxXWWWNXOddddlcoc'...........
....',;;:cclodxxkOkoc,.                                                                          .,dKNNXc..';oKWMMMMMMMWX00KXNNKk:. ........
....',;;cllodxkkOOl'.                                                          .                  ;kX0kKx'.'lOWMMMMMMMMMWWWMMMMMWO;.........
...',;::clodxkOO0k:                                                           cd.                .oXNkxkxl..:kNMMMMMMMMMMMMMMMMMMNx;........
..',,;:clodxkOO0Kx'                      ..',,'..                           .lXNo                .lKNKOdlcc,'l0WMMMMMMWWMMMMMMMMMW0l'..,''''
..',;:cllddxk00K0l.                 .;lxO0XNNNNXK0xl;.                    .cOWMM0'                :0WWN0ko;;,lOKXNWWWNNNWMMMMMMMMNk;..',;;,'
..',:cclodxkO000d;.              .:xKWMMMMMWWWWMMMMMWKOkdc.             .o0WMMMMNc                'kNWWWWKc;:okOO0KKKKKKXWWMMMWXkl;''''';;,'
.',;:clodxxdddol,.             .l0WMMMMMMMMN0oclx0NMMMMMMWk'        .,lxXWMMMMMMMx.               .l0XNWMWKoloxkkkO0O00O00KXX0o'.';ccc;;;;,'
',,;cllodo:,....              ;OWMMMMMMMMMMMXd.  'dXMMMMMWO'      .:ONWMMMMMMMMMMO.               .:ccxXNWWXkolllloxxdkkxxdddl,.,,;odolcc;,'
',;:clodo:..                 :KMMWNNWMMMMMMMMNd. .lXMMMMNx,     'l0WMMMMMMMMMMMMMO.               ....lOXWWWWXOdoccloololcccc:::lodxdollc;,'
',;cclodd:..               .cKMMWXk0WMMMMMMMMMO. ,kWMMWO;.    ,dXWMMMMMMMMMMMMMMM0'                  .lKWWWWWWWNX0kddollccloddxkOOkxddolc:;,
',:clodxxo,.              'kNMMMW0ooKMMMMMMMMMO,;OWMMWO,   .:kNMMMMMMMMMMMMMMMMMMO.                  ,dKWMMWWMWWWWWWNNXXKKKXNNXK00Okxdolc:;,
',:clodxkxl'              lWMMMMWXo,:OWMMMMMMNkdKWMMNx'  .l0WMMMMMMMMMMMMMMMMMMMMx.                 .cONWWWWMMWWWWWWWWWWNNWNNNXXK0Okxdolc:;,
,;cllodxkOkl.       .     .lk0XWMMXkc:dKWWWWWXXNMMW0c. 'dKWMMMMMMMMMMMMMMMMMMMMMXc                   ,OWWWWMMMMWWWWWWWWNNWWWNNNXK0Okxdolc:;,
;:clodxxkO0Oo.      cl.      ..:kNMMNKO0XNWWWWMMW0l.  ;KMMMMMMMMMMMMMMMMMMMMMMMWd.                    lXMWWNNNXNNNWWWWWNWWNNNNNXK0Okxxolc:;,
;:clodxxkO00k,      :K0l'        'cx0XWMMMMWNXOo;.    lNMMMMMMMMMMMMMMMMMMMMMMWk.                    .lXWNKd;;coxOKXXK0OOOkxxxkOOOOkxdoc:;'.
,:clodxxOOOxc.      .OMWXOo;..      ..,:cc:;,.        oWMMMMMMMMMMMMMMMMMMMMMMK;                     'o0KOo' ..',;;;,'...........',,',,'''..
;:clodxxOOkl,.      .dWMMMMWN0kdlc;,.                .dWMMMMMMMMMMMMMMMMMMMMMXc                     .:dxl;.. ....                      ....'
;:clodxxkOOxl'       :XMMMMMMMMMMMWW0:               .xMMMMMMMMMMMMMMMMMMMMMNo.                     .,,'.                                   
;:cloodxkOOOOxc.     .OMMMMMMMMMMMMMMNd.             .kMMMMMMMMMMMMMMMMMMWNKo.                      .                                       
;:cllodxkOO0KXO,      ;0WMMMMMMMMMMMMMW0;            .OMMMMMMMMMMWXKOxdoc;'.                                                                
;:cclodxkOO00Ol.       .oXMMMMMMMMMMMMMMXo.          .OMMWNX0kdl:,..                                                                        
,;:llodxxkkOko,          'xNMMMMMMMMMMMMMWO,         .col:,..                                                                               
,;:lloodxkOkd:..           :0WMMMMMMMMMMMMMXc.                                                                                              
,;:cllodxxkkdc'.            .lKMMWWNXKOkdoc:'                                                                                               
,;::cloodxxkkxd;.             'cc;,'..                                                                                                      
,;::clooddxkOOOxc.                                                                                                                          
',;:ccloodxkkO000kc..                                                                                                                       
',;::clloodxkkO00K0d,..                                                                                                                     
.',;::clllodxkOO00KKx:.                                                                                                                     
..'',;:clloddxkOO00K0l'.                                                                                         .''.                       
...'',;:clloodxkOO00KOl,.                                                                                    ......:l.  .'.                 
...''',,:ccloodxkOOO0K0kl,.                                                                              .'''..     cc.  ;;                 
...'..',;::cloodxkkOO0KKKkl,.                                                                        ..'''.         .l;  .:'                
......',;;;ccloodxxkOO0KKXX0koc;.                                                                 .'''..          .',;'   ,;.               
.......',,;::clloddxkkO00KXXXXK0Od:.                                                          ......            .,,..  .'...                
.......'.'',;;ccloodxxkkO00KXXXXXKx;.                                                      .,'..          .,;,.        .                    
..........'',;;:clloodxxkOOO0KXXXKOl;::,''.                                                ';.        .',,,..                               
 ..........',,;;:cclooddxxkkOO00Oxoc,;okOxc,...                                             ,'      .,'..              .,.  .,.             
 .. .......'',,;;::cllooddxxkkkxc'...;cc;'.',;;'..                ..                        .,.     ..                  ',   ..             
  ..........',,,,;::cclllol:,,;cloooc;..     ....                                            .,.     ..                  '.   ..            
  ............''',,;;;;;::...:dxoc;.........                    ..                            .'      ..                  ..   .            
   .......  ......'''....':oxd:............                ..','',',,.                         '.              ..''..     ..                
             ...........;ddc'.... .....',,'''..         ........ .:do,.                        .,.            .... ..                       
           .. ......  .cl;......   ..::;'.....',.                 .''.                          .'             ..... .                      
           .   ..... .,,......     'll.        .'..                                              ''.'..       ...                           
                ....',...   ..    .:o'     .',,. .'.                                              .'..                                      
            .  ....,xd....        .:c. .,;..,::. .'.                                                                                        
               ....;0d.......      ,c' .:c'  ..   '.                    .                                                                   
                 ..:0d. .,,. .     .;:. ..       .'.                 .'co;.                                                                 
                  .;0d.  'oc...      ',.        .,.                 ..';c,.                          .                                      
                 ..;Oo.   :d;...      .''..  ..''.                  .'..                             ..                                     

Dev by @bitcoinski
*/

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

import "./ICollectible.sol";

import "./console.sol";


/*
* @title ERC721 token for Collectible, redeemable through burning  MintPass tokens
*/

contract Collectible is ICollectible, AccessControl, ERC721Enumerable, ERC721Pausable, ERC721Burnable, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    Counters.Counter private earlyIDCounter; 
    Counters.Counter private generalCounter; 

  
    mapping(uint256 => TokenData) public tokenData;

    mapping(uint256 => RedemptionWindow) public redemptionWindows;

    struct TokenData {
        string tokenURI;
        bool exists;
    }

    struct RedemptionWindow {
        uint256 windowOpens;
        uint256 windowCloses;
        uint256 maxRedeemPerTxn;
    }
    
    string private baseTokenURI;

    string public _contractURI;
    

    MintPassFactory public mintPassFactory;

    event Redeemed(address indexed account, string tokens);

    /**
    * @notice Constructor to create Collectible
    * 
    * @param _symbol the token symbol
    * @param _mpIndexes the mintpass indexes to accommodate
    * @param _redemptionWindowsOpen the mintpass redemption window open unix timestamp by index
    * @param _redemptionWindowsClose the mintpass redemption window close unix timestamp by index
    * @param _maxRedeemPerTxn the max mint per redemption by index
    * @param _baseTokenURI the respective base URI
    * @param _contractMetaDataURI the respective contract meta data URI
    * @param _mintPassToken contract address of MintPass token to be burned
    */
    constructor (
        string memory _name, 
        string memory _symbol,
        uint256[] memory _mpIndexes,
        uint256[] memory _redemptionWindowsOpen,
        uint256[] memory _redemptionWindowsClose, 
        uint256[] memory _maxRedeemPerTxn,
        string memory _baseTokenURI,
        string memory _contractMetaDataURI,
        address _mintPassToken,
        uint earlyIDMax
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;    
        _contractURI = _contractMetaDataURI;
        mintPassFactory = MintPassFactory(_mintPassToken);
        earlyIDCounter.increment();
        for(uint256 i = 0; i <= earlyIDMax; i++) {
            generalCounter.increment();
        }

        for(uint256 i = 0; i < _mpIndexes.length; i++) {
            uint passID = _mpIndexes[i];
            redemptionWindows[passID].windowOpens = _redemptionWindowsOpen[i];
            redemptionWindows[passID].windowCloses = _redemptionWindowsClose[i];
            redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn[i];
        }

          _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
          _setupRole(DEFAULT_ADMIN_ROLE, 0x81745b7339D5067E82B93ca6BBAd125F214525d3); 
          _setupRole(DEFAULT_ADMIN_ROLE, 0x90bFa85209Df7d86cA5F845F9Cd017fd85179f98);
          _setupRole(DEFAULT_ADMIN_ROLE, 0xE272d43Bee9E24a8d66ACe72ea40C44196E12947);
        
    }


    /**
    * @notice Set the mintpass contract address
    * 
    * @param _mintPassToken the respective Mint Pass contract address 
    */
    function setMintPassToken(address _mintPassToken) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPassFactory = MintPassFactory(_mintPassToken); 
    }    

    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param _baseTokenURI the respective base URI
    */
    function setBaseURI(string memory _baseTokenURI) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = _baseTokenURI;    
    }    

    /**
    * @notice Pause redeems until unpause is called
    */
    function pause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
    * @notice Unpause redeems until pause is called
    */
    function unpause() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
     

    /**
    * @notice Configure time to enable redeem functionality
    * 
    * @param _windowOpen UNIX timestamp for redeem start
    */
    function setRedeemStart(uint256 passID, uint256 _windowOpen) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        redemptionWindows[passID].windowOpens = _windowOpen;
    }        

    /**
    * @notice Configure time to enable redeem functionality
    * 
    * @param _windowClose UNIX timestamp for redeem close
    */
    function setRedeemClose(uint256 passID, uint256 _windowClose) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        redemptionWindows[passID].windowCloses = _windowClose;
    }  

    /**
    * @notice Configure the max amount of passes that can be redeemed in a txn for a specific pass index
    * 
    * @param _maxRedeemPerTxn number of passes that can be redeemed
    */
    function setMaxRedeemPerTxn(uint256 passID, uint256 _maxRedeemPerTxn) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn;
    }        

    /**
    * @notice Check if redemption window is open
    * 
    * @param passID the pass index to check
    */
    function isRedemptionOpen(uint256 passID) public view override returns (bool) { 
        if(paused()){
            return false;
        }
        return block.timestamp > redemptionWindows[passID].windowOpens && block.timestamp < redemptionWindows[passID].windowCloses;
    }


    /**
    * @notice Redeem specified amount of MintPass tokens
    * 
    * @param mpIndexes the tokenIDs of MintPasses to redeem
    * @param amounts the amount of MintPasses to redeem
    */
    function redeem(uint256[] calldata mpIndexes, uint256[] calldata amounts) external override{
        require(msg.sender == tx.origin, "Redeem: not allowed from contract");
        require(!paused(), "Redeem: paused");
        
        //check to make sure all are valid then re-loop for redemption 
        for(uint256 i = 0; i < mpIndexes.length; i++) {
            require(amounts[i] > 0, "Redeem: amount cannot be zero");
            require(amounts[i] <= redemptionWindows[mpIndexes[i]].maxRedeemPerTxn, "Redeem: max redeem per transaction reached");
            require(mintPassFactory.balanceOf(msg.sender, mpIndexes[i]) >= amounts[i], "Redeem: insufficient amount of Mint Passes");
            require(block.timestamp > redemptionWindows[mpIndexes[i]].windowOpens, "Redeem: redeption window not open for this Mint Pass");
            require(block.timestamp < redemptionWindows[mpIndexes[i]].windowCloses, "Redeem: redeption window is closed for this Mint Pass");
        }

        string memory tokens = "";
    
        for(uint256 i = 0; i < mpIndexes.length; i++) {

            mintPassFactory.burnFromRedeem(msg.sender, mpIndexes[i], amounts[i]);
            for(uint256 j = 0; j < amounts[i]; j++) {
                _safeMint(msg.sender, mpIndexes[i] == 0 ? earlyIDCounter.current() : generalCounter.current());
                tokens = string(abi.encodePacked(tokens, mpIndexes[i] == 0 ? earlyIDCounter.current().toString() : generalCounter.current().toString(), ","));
                if(mpIndexes[i] == 0){
                    earlyIDCounter.increment();
                }
                else{
                    generalCounter.increment();
                }
            
            }
            
        }

        emit Redeemed(msg.sender, tokens);
    }  

    

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl,IERC165, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     


   /**
    * @notice Configure the max amount of passes that can be redeemed in a txn for a specific pass index
    * 
    * @param id of token
    * @param uri to point the token to
    */
    function setIndividualTokenURI(uint256 id, string memory uri) external override onlyRole(DEFAULT_ADMIN_ROLE){
        require(_exists(id), "ERC721Metadata: Token does not exist");
        tokenData[id].tokenURI = uri;
        tokenData[id].exists = true;
    }   
   

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
         if(tokenData[tokenId].exists){
            return tokenData[tokenId].tokenURI;
        }
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), '.json'));
    }   

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   

    function setContractURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE){
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }


}

   

interface MintPassFactory {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
 }
 