// SPDX-License-Identifier: MIT

/*
* @title ERC721 token for LilFranks, redeemable through burning LilFranks MintPassport tokens
*
* @author original logic by Niftydude, extended by @bitcoinski, adapted by @andrewjiang
*/

pragma solidity 0.8.0;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

import "./ILilFranks.sol";
import "./console.sol";

/*  
     
                                                        ,sM""""%W,
                                                     ,#"          7m
                                          ,mAWmw,   #              ]p
                                        @"       "W#        ]p      #
                               s##WWmw @                    @       #
                            ,#        %b                            #%m,
                           ]b                                      j    `@,
                           @b                                             @
                            @p    %m              ,'                      ]b
                             "Wp    "=         ,,sMW""^````"5#            #
                              ]##W        ,e#"`             15b        ,#Q,,ssmmw,,
                      ,####ll5#b          #                  ^%#mw,e###bGl#f##Q##WGl##m
                    ;#@S#####p@b          @Q                      @#b GGGG ^'' GGGG@##f#
                    @#########"%m         ###m,                   ]b( ,;,,QJQ G,QQ"#`%W@b
                    #SG##@"\QkpQQ@###MMWW%%"""""7""""""""""""""^```               `"%##""@p
                   #5#Q# ,Q##"`         ,,s,,                      s######wssm   p     %Qp@
                 ##5#S5##W     p 'WW##############            "@@@###########       .p  @m#
                @###b#@#   ,       ]#########@###   .#MW55WM   @@############s          @b
                 %####@b       ,  7@#############        `^"%p  @############       .p .#
                  ] %###           ^############b           ,#  ^@####@#####    s     ;#
                 sM%M `%#Q G7bGGGG,G "@##@####M    "7WWWWWW"       '"%##W7         ,#"
                          "%mp GGG GGGGG  '   GGG  GGG.#7p                    ,,#M"
                              `"WmQQ, GGGGGGGGGGGG "We###" GG         ,,sm#M"`
                                      `"""%%W####mmmmmmm##m#MWW%""""`
                                             ######"^  GG@
                                            @#b^ GGGGGGGG^Q
                                           # "WQ         ,#b
                                         ,"      "%w,  s"  "m
                                     ,s#""#m         @@     #"W,
                                 ,s#"       "@W,      #  ,M      `""=m,,
                              ,#M`              ""@Wm,@#`             @#"m
                             @#p                   @#"                 #  @
                            @N ^p               ,#"    ##@             b   @
                            #    b           sM`       """             b   jb
                           @     ^p        @   ;##p      ,             #    b
                           #  @   ]         @p "WM     ]#l@            @    #
                           `  ``   `        ```          `             ``   `
*/


contract LilFranks is ILilFranks, AccessControl, ERC721Enumerable, ERC721Pausable, ERC721Burnable, Ownable {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private generalCounter; 

    // Roles
    bytes32 public constant LIL_FRANKS_OPERATOR_ROLE = keccak256("LIL_FRANKS_OPERATOR_ROLE");
    bytes32 public constant LIL_FRANKS_URI_UPDATER_ROLE = keccak256("LIL_FRANKS_URI_OPERATOR_ROLE");
  
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
    string private ipfsURI;

    string public _contractURI;

    uint256 private ipfsAt;

    MintPassportFactory public lilFranksMintPassportFactory;

    event Redeemed(address indexed account, string tokens);

    /**
    * @notice Constructor to create Lil Frank
    * 
    * @param _symbol the token symbol
    * @param _mpIndexes the mintpass indexes to accommodate
    * @param _redemptionWindowsOpen the mintpass redemption window open unix timestamp by index
    * @param _redemptionWindowsClose the mintpass redemption window close unix timestamp by index
    * @param _maxRedeemPerTxn the max mint per redemption by index
    * @param _baseTokenURI the respective base URI
    * @param _contractMetaDataURI the respective contract meta data URI
    * @param _mintPassToken contract address of MintPassport token to be burned
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
        address _mintPassToken
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;    
        _contractURI = _contractMetaDataURI;
        lilFranksMintPassportFactory = MintPassportFactory(_mintPassToken);

        for(uint256 i = 0; i < _mpIndexes.length; i++) {
            uint passID = _mpIndexes[i];
            redemptionWindows[passID].windowOpens = _redemptionWindowsOpen[i];
            redemptionWindows[passID].windowCloses = _redemptionWindowsClose[i];
            redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn[i];
        }

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x5a379aaCf8Bf1E9D4E715D00654846eb1CFC8a76); // Deployer
        _setupRole(DEFAULT_ADMIN_ROLE, 0xF3bF7cf9e6B96E754F8d0D927F2162683B278322); // @lilfranksvault
        _setupRole(DEFAULT_ADMIN_ROLE, 0x760e7B42c920c2a0FeB58DDD610c14A6Bdd2Ebea); // @andrewjiang
        grantRole(LIL_FRANKS_OPERATOR_ROLE, msg.sender);
    }

    /**
    * @notice Set the mintpassport contract address
    * 
    * @param _mintPassToken the respective Mint Passport contract address 
    */
    function setMintPassportToken(address _mintPassToken) external override onlyOwner {
        lilFranksMintPassportFactory = MintPassportFactory(_mintPassToken); 
    }    

    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param _baseTokenURI the respective base URI
    */
    function setBaseURI(string memory _baseTokenURI) external override onlyOwner {
        baseTokenURI = _baseTokenURI;    
    }    


    /**
    * @notice Change the base URI for returning metadata
    * 
    * @param _ipfsURI the respective ipfs base URI
    */
    function setIpfsURI(string memory _ipfsURI) external override onlyOwner {
        ipfsURI = _ipfsURI;    
    }    

    /**
    * @notice Change last ipfs token index
    * 
    * @param at the token index 
    */
    function endIpfsUriAt(uint256 at) external onlyOwner {
        ipfsAt = at;    
    }    

    /**
    * @notice Pause redeems until unpause is called
    */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
    * @notice Unpause redeems until pause is called
    */
    function unpause() external override onlyOwner {
        _unpause();
    }
     

    /**
    * @notice Configure time to enable redeem functionality
    * 
    * @param _windowOpen UNIX timestamp for redeem start
    */
    function setRedeemStart(uint256 passID, uint256 _windowOpen) external override onlyOwner {
        redemptionWindows[passID].windowOpens = _windowOpen;
    }        

    /**
    * @notice Configure time to enable redeem functionality
    * 
    * @param _windowClose UNIX timestamp for redeem close
    */
    function setRedeemClose(uint256 passID, uint256 _windowClose) external override onlyOwner {
        redemptionWindows[passID].windowCloses = _windowClose;
    }  

    /**
    * @notice Configure the max amount of passes that can be redeemed in a txn for a specific pass index
    * 
    * @param _maxRedeemPerTxn number of passes that can be redeemed
    */
    function setMaxRedeemPerTxn(uint256 passID, uint256 _maxRedeemPerTxn) external override onlyOwner {
        redemptionWindows[passID].maxRedeemPerTxn = _maxRedeemPerTxn;
    }        

    /**
    * @notice Check if redemption window is open
    * 
    * @param passID the pass index to check
    */
    function isRedemptionOpen(uint256 passID) public view override returns (bool) { 
        return block.timestamp > redemptionWindows[passID].windowOpens && block.timestamp < redemptionWindows[passID].windowCloses;
    }


    /**
    * @notice Redeem specified amount of MintPass tokens for MetaHero
    * 
    * @param mpIndexes the tokenIDs of MintPasses to redeem
    * @param amounts the amount of MintPasses to redeem
    */
    function redeem(uint256[] calldata mpIndexes, uint256[] calldata amounts) external override{
        console.log('redeeming...');
        require(msg.sender == tx.origin, "Redeem: not allowed from contract");
        require(!paused(), "Redeem: paused");
        
        //check to make sure all are valid then re-loop for redemption 
        for(uint256 i = 0; i < mpIndexes.length; i++) {
            require(amounts[i] > 0, "Redeem: amount cannot be zero");
            require(amounts[i] <= redemptionWindows[mpIndexes[i]].maxRedeemPerTxn, "Redeem: max redeem per transaction reached");
            require(lilFranksMintPassportFactory.balanceOf(msg.sender, mpIndexes[i]) >= amounts[i], "Redeem: insufficient amount of Mint Passports");
            require(block.timestamp > redemptionWindows[mpIndexes[i]].windowOpens, "Redeem: redeption window not open for this Mint Passport");
            require(block.timestamp < redemptionWindows[mpIndexes[i]].windowCloses, "Redeem: redeption window is closed for this Mint Passport");
        }

        string memory tokens = "";
    
        for(uint256 i = 0; i < mpIndexes.length; i++) {

            lilFranksMintPassportFactory.burnFromRedeem(msg.sender, mpIndexes[i], amounts[i]);
            for(uint256 j = 0; j < amounts[i]; j++) {
                _safeMint(msg.sender, generalCounter.current());
                tokens = string(abi.encodePacked(tokens, generalCounter.current().toString(), ","));
                generalCounter.increment();
            }
            
            console.log('new token IDs redeemed:', tokens);
        }

        emit Redeemed(msg.sender, tokens);
    }  

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl,IERC165, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }     

    function promoteTeamMember(address _addr, uint role) public{
        if(role == 0){
            grantRole(LIL_FRANKS_OPERATOR_ROLE, _addr);
        }
        else if(role == 1){
            grantRole(LIL_FRANKS_URI_UPDATER_ROLE, _addr);
        }
         
    }

    function demoteTeamMember(address _addr, uint role) public {
        if(role == 0){
            revokeRole(LIL_FRANKS_OPERATOR_ROLE, _addr);
        }
        else if(role == 1){
           revokeRole(LIL_FRANKS_URI_UPDATER_ROLE, _addr);
        }
         
    }

    function hasLilFranksRole(address _addr, uint role) public view returns (bool){
        if(role == 0){
            return hasRole(LIL_FRANKS_OPERATOR_ROLE, _addr);
        }
        else if(role == 1){
            return hasRole(LIL_FRANKS_URI_UPDATER_ROLE, _addr);
        }
        return false;
    }

   /**
    * @notice Configure the max amount of passes that can be redeemed in a txn for a specific pass index
    * 
    * @param id of token
    * @param uri to point the token to
    */
    function setIndividualTokenURI(uint256 id, string memory uri) external override {
        require(hasRole(LIL_FRANKS_URI_UPDATER_ROLE, msg.sender), "Access: sender does not have access");
        require(_exists(id), "ERC721Metadata: Token does not exist");
        tokenData[id].tokenURI = uri;
        tokenData[id].exists = true;
    }   
   
    function _baseURI(uint256 tokenId) internal view returns (string memory) {
       
        if(tokenId >= ipfsAt) {
            return baseTokenURI;
        } else {
            return ipfsURI;
        }
    }     

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(tokenData[tokenId].exists){
            return tokenData[tokenId].tokenURI;
        }

        string memory baseURI = _baseURI(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }   

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }   

    function setContractURI(string memory uri) external {
        require(hasRole(LIL_FRANKS_URI_UPDATER_ROLE, msg.sender) );
        _contractURI = uri;
    }

    //TODO: SET ROYALTIES HERE and in MetaData
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

}

interface MintPassportFactory {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
 }