//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./BatchReveal.sol";

// <-.(`-') (`-')  _  (`-').->(`-')  __(`-')    
//  __( OO) (OO ).-/  ( OO)_  ( OO).-( (OO ).-> 
// '-'---.\ / ,---.  (_)--\_)(,------.\    .'_  
// | .-. (/ | \ /`.\ /    _ / |  .---''`'-..__) 
// | '-' `.)'-'|_.' |\_..`--.(|  '--. |  |  ' | 
// | /`'.  (|  .-.  |.-._)   \|  .--' |  |  / : 
// | '--'  /|  | |  |\       /|  `---.|  '-'  / 
// `------' `--' `--' `-----' `------'`------'  v1.5
//
//                       :::!~!!!!!:.
//                   .xUHWH!! !!?M88WHX:.
//                 .X*#M@$!!  !X!M$$$$$$WWx:.
//                :!!!!!!?H! :!$!$$$$$$$$$$8X:
//               !!~  ~:~!! :~!$!#$$$$$$$$$$8X:
//              :!~::!H!<   ~.U$X!?R$$$$$$$$MM!
//              ~!~!!!!~~ .:XW$$$U!!?$$$$$$RMM!
//                !:~~~ .:!M"T#$$$$WX??#MRRMMM!
//                ~?WuxiW*`   `"#$$$$8!!!!??!!!
//              :X- M$$$$       `"T#$T~!8$WUXU~
//             :%`  ~#$$$m:        ~!~ ?$$$$$$
//           :!`.-   ~T$$$$8xx.  .xWW- ~""##*"
// .....   -~~:<` !    ~?T#$$@@W@*?$$      /`
// W$@@M!!! .!~~ !!     .:XUW$W!~ `"~:    :
// #"~~`.:x%`!!  !H:   !WM$$$$Ti.: .!WUn+!`
// :::~:!!`:X~ .: ?H.!u "$$$B$$$!W:U!T$$M~
// .~~   :X@!.-~   ?@WTWo("*$$$W$TH$! `
// Wi.~!X$?!-~    : ?$$$B$Wu("**$RM!
// $R@i.~~ !     :   ~$$$$$B$$en:``
// ?MXT@Wx.~    :     ~"##*$$$$M~
// :W$B$$$W!     :        ~$$$$$$
// ~"T$$$R!      :            ~M$$
// ~#M$$$$$$     ~-~~~-.__.-~~~-~
// ghouls rebased by @0xhanvalen

contract BasedGhoulsv2 is ERC721Upgradeable, ERC2981Upgradeable, AccessControlUpgradeable, BatchReveal {
    using StringsUpgradeable for uint256;

    mapping (address => bool) public EXPANSIONPAKRedemption;
    mapping (address => bool) public REBASERedemption;

    bool public isMintable;
    uint16 public totalSupply;
    uint16 public maxGhouls;
    uint16 public summonedGhouls;
    uint16 public rebasedGhouls;
    uint16 public maxRebasedGhouls;

    string public baseURI;
    string public unrevealedURI;

    bytes32 public EXPANSION_PAK;
    bytes32 public SUMMONER_LIST;

    function initialize() initializer public {
        __ERC721_init("Based Ghouls", "GHLS");
        maxGhouls = 6666;
        maxRebasedGhouls = 870;
        baseURI = "https://ghlstest.s3.amazonaws.com/json/";
        unrevealedURI = "https://ghlsprereveal.s3.amazonaws.com/json/Shallow_Grave.json";
        EXPANSION_PAK = 0xeaad81dc1fbbd6832eacc1a6445f0220959cd68597f0e7a6b1270b2bb16cf31d;
        SUMMONER_LIST = 0x96b5de66f7385e7ecc21f6a51bce0f5fa347f5210ac6883f09d88b824b70c806;
        lastTokenRevealed = 0;
        isMintable = false;
        totalSupply = 0;
        _setDefaultRoyalty(0x475dcAA08A69fA462790F42DB4D3bbA1563cb474, 690);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, 0x98CCf605c43A0bF9D6795C3cf3b5fEd836330511);
    }

    function updateBaseURI(string calldata _newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newURI;
    }

    function updateUnrevealedURI(string calldata _newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        unrevealedURI = _newURI;
    }
 
    function setMintability(bool _mintability) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isMintable = _mintability;
    }

    // u gotta... GOTTA... send the merkleproof in w the mint request. 
    function summon(bytes32[] calldata _merkleProof, bool _isRebase) public {
        require(isMintable, "NYM");
        require(totalSupply < maxGhouls, "OOG");
        address minter = msg.sender;
        require(tx.origin == msg.sender, "NSCM");
        if (_isRebase) {
            require(!REBASERedemption[minter], "TMG");
            require(!EXPANSIONPAKRedemption[minter], "TMG");
            require(rebasedGhouls + 3 <= maxRebasedGhouls, "NEG");
            bytes32 leaf = keccak256(abi.encodePacked(minter));
            bool isLeaf = MerkleProofUpgradeable.verify(_merkleProof, SUMMONER_LIST, leaf);
            require(isLeaf, "NBG");
            REBASERedemption[minter] = true;
            EXPANSIONPAKRedemption[minter] = true;
            totalSupply = totalSupply + 3;
            rebasedGhouls += 3;
            _mint(minter, totalSupply - 3);
            _mint(minter, totalSupply - 2);
            _mint(minter, totalSupply - 1);
        }
        if (!isHordeReleased && !_isRebase) {
                require(!EXPANSIONPAKRedemption[minter], "TMG");
                require(summonedGhouls + 1 + maxRebasedGhouls <= maxGhouls, "NEG");
                bytes32 leaf = keccak256(abi.encodePacked(minter));
                bool isLeaf = MerkleProofUpgradeable.verify(_merkleProof, EXPANSION_PAK, leaf);
                require(isLeaf, "NBG");
                EXPANSIONPAKRedemption[minter] = true;
                totalSupply = totalSupply + 1;
                summonedGhouls += 1;
                _mint(minter, totalSupply - 1);
        }
        if (isHordeReleased) {
            require(summonedGhouls + 1 + maxRebasedGhouls <= maxGhouls, "NEG");
            summonedGhouls += 1;
            totalSupply = totalSupply + 1;
            _mint(minter, totalSupply - 1);
        }
        if(totalSupply >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
            uint256 seed;
            unchecked {
                seed = uint256(blockhash(block.number - 69)) * uint256(block.timestamp % 69);
            }
            setBatchSeed(seed);
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        if(id >= lastTokenRevealed){
            return unrevealedURI;
        } else {
             return string(abi.encodePacked(baseURI, getShuffledTokenId(id).toString(), ".json"));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC2981Upgradeable, ERC721Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    bool public isHordeReleased;

    function insertExpansionPack(bytes32 _newMerkle) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes32) {
        EXPANSION_PAK = _newMerkle;   
        return EXPANSION_PAK;
    }

    function releaseTheHorde (bool _isHordeReleased) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        isHordeReleased = _isHordeReleased;
        return isHordeReleased;
    }
}
