// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";
import "./DrawSvgOps.sol";
import "./StringHell.sol";
import "./v1ContractData.sol";

/**
       ///////////////////////////////////////
       ///////////////////////////////////////
       ///,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
       ///..................................//
       ///                                  //
       ///                                  //
       ///       //usr: hello world         //
       ///                                  //
       ///                                  //
       ///                                  //
       ///                                  //
       ///,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,//
       ///..................................//
       ///                                  //
       ///                                  //
       ///       //pub: hello world         //
       ///                                  //
       ///                                  //
       ///                                  //
       ///                                  //
       ///////(O)/////////////////////////////
       ///////////////////////////////////////

       I hope you all have fun. Be nice.

       Usr Message      (Message V2)

       2021

       Sterling Crispin

       https://www.sterlingcrispin.com/message.html


       "If you have everything under control,
       you're not moving fast enough"

**/


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

/// ~~~~~~~~~~~~~      
/// stub to connect to the v1 contract
abstract contract Message is ERC721 {
    function readRarityType(uint256 tokenId) public view returns (uint256){}
}
/// ~~~~~~~~~~~~~      
/// [MIT License]
/// @title UsrMessage
/// @notice An experiment in communication.
/// @author Sterling Crispin <sterlingcrispin@gmail.com>
contract UsrMessage is ERC721Tradable {
    using Strings for string;

    // ~~~
    // v1 connection code
    Message v1Contract;
    // unfortunately I failed to provide an easy accessor to this data 
    // so I had to scrape the v1 contract's current data and hard code these values
    struct v1TokenUpgradeStruct{
        uint256 value;
    }
    mapping(uint256 => v1TokenUpgradeStruct) public v1TokenUpgradeMap;
    
    function ContractOwnerPopulateV1Upgrades() public onlyOwner {
        uint16[56] memory idx = v1ContractData.GetUpgradeIdx();
        uint8[56] memory val = v1ContractData.GetUpgradeVal();
        for(uint256 i; i < 56; i++){
            v1TokenUpgradeMap[idx[i]].value = val[i];
        }
    }
    function contractOwnerRegisterV1Contract(address addr) public onlyOwner{
        v1Contract = Message(addr);
    }

    // ~~~
    uint256 constant MAXTOKENS = 482;// 512 total tokens
    uint256 OWNERTOKENS = 30;

    bool internal mintingEnabled = false;
    string internal constant textTagOpen = '<text>';
    string internal constant textTagClose = '</text>';
    string internal constant spanA = '<tspan x="40" dy="25">';
    string internal constant spanZ = '</tspan>';
    string internal constant errBad = "Disabled";
    string internal constant errPub = "Disabled";
    string internal constant errOwn = "Not Owner";
    string internal constant upgradeMetaEnd = '"},';
    string internal constant traitMeta = '{"trait_type": ';
    string internal constant upgradeAvailMeta = '"Upgrade Available","value": "';
    string internal constant upgradeUsedMeta = '"Upgrades Used","value": "';
    string internal constant upgradeWigMeta = '"Wiggle","value": "';
    string internal constant ugSphereMeta = '"Spheres","value": "';
    string internal constant ugGradMeta = '"Sunrise","value": "';
    string internal constant rarityMeta = '"Vibe","value":';
    uint256 internal constant size = 400;
    
    struct MsgData{
        address owner;
        bool claimed;
        // 0 = Owner Only, 1 = Public Enabled , 2 = disabled due to lawsuit or Something Bad
        uint256 writeState;
        uint256 publicLineCount;
        string[5] publicMessage;
        uint256 ownerLineCount;
        string[5] ownerMessage;
        // green = 0, cool = 1, rare = 2, coolRare = 3, neat = 4
        uint256 rareType;
        // wiggle 0, spheres 1, grad 2, available = 3, used = 4
        string[5] upgradeMeta;
        // svg code
        string upgrade;
        // wiggle 0, spheres 1, grad 2
        uint256[3] upgradeUsed;
        uint256 upgradeAvailable;
    }

    mapping(uint256 => MsgData) public allMessage;

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Usr Message", "USR MESSAGE", _proxyRegistryAddress)
    {}

    function readUpgradeAvailable(uint256 tokenId) public view returns(uint256){
        return allMessage[tokenId].upgradeAvailable;
    }

    function readUpgradeUsed(uint256 tokenId) public view returns(uint256[3] memory){
        return allMessage[tokenId].upgradeUsed;
    }
    
    function readWriteState(uint256 tokenId) public view returns (uint256){
        return allMessage[tokenId].writeState;
    }

    function readRarityType(uint256 tokenId) public view returns (uint256){
        return allMessage[tokenId].rareType;
    }

    function readPublicMessage(uint256 tokenId) public view returns (string[5] memory){
        return allMessage[tokenId].publicMessage;
    }

    function readPublicLineCount(uint256 tokenId) public view returns (uint256){
        return allMessage[tokenId].publicLineCount;
    }

    function readOwnerMessage(uint256 tokenId) public view returns (string[5] memory){
        return allMessage[tokenId].ownerMessage;
    }

    function readOwnerLineCount(uint256 tokenId) public view returns (uint256){
        return allMessage[tokenId].ownerLineCount;
    }

    function checkOwner(uint256 tokenId) private view {
        require(allMessage[tokenId].writeState != 2, errBad);
        require(allMessage[tokenId].owner == _msgSender(), errOwn);
    }

    function clearOwnerMessage(uint256 tokenId) private {
        allMessage[tokenId].ownerMessage = ["","","","",""];
    }

    function ownerWriteSingleLine(uint256 tokenId, string memory messageMaxCharacterPerLineAbout30) public {
        checkOwner(tokenId);
        clearOwnerMessage(tokenId);
        allMessage[tokenId].ownerMessage[0] =  string(abi.encodePacked(messageMaxCharacterPerLineAbout30 )); 
        allMessage[tokenId].ownerLineCount = 1;
    }

    function ownerWriteTwoLines(uint256 tokenId, string[2] memory messageMaxCharacterPerLineAbout30) public {
        checkOwner(tokenId);
        clearOwnerMessage(tokenId);
        allMessage[tokenId].ownerMessage[0] = string(abi.encodePacked(messageMaxCharacterPerLineAbout30[0])); 
        allMessage[tokenId].ownerMessage[1] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[1],spanZ)); 
        allMessage[tokenId].ownerLineCount = 2;  
    }

    function ownerWriteMultiLines(uint256 tokenId, string[5] memory messageMaxCharacterPerLineAbout30) public {
        checkOwner(tokenId);
        allMessage[tokenId].ownerMessage[0] = string(abi.encodePacked(messageMaxCharacterPerLineAbout30[0])); 
        allMessage[tokenId].ownerMessage[1] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[1],spanZ)); 
        allMessage[tokenId].ownerMessage[2] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[2],spanZ)); 
        allMessage[tokenId].ownerMessage[3] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[3],spanZ)); 
        allMessage[tokenId].ownerMessage[4] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[4],spanZ)); 
        allMessage[tokenId].ownerLineCount = 5;
    }
    
    function ownerWriteDrawing(uint256 tokenId, string memory svgCommand) public {
        checkOwner(tokenId);
        clearOwnerMessage(tokenId);
        allMessage[tokenId].ownerMessage[0] =  string(abi.encodePacked(textTagClose,svgCommand,textTagOpen)); 
        allMessage[tokenId].ownerLineCount = 1;
    }

    function ownerTogglePublicWrite(uint256 tokenId, bool toggle) public {
        checkOwner(tokenId);
        allMessage[tokenId].writeState = toggle ? 1 : 0;
    }

    function checkPublic(uint256 tokenId) private view {
        require(allMessage[tokenId].writeState == 1, errPub);
    }
    
    function clearPublicMessage(uint256 tokenId) private {
        allMessage[tokenId].publicMessage = ["","","","",""];
    }
    
    function publicWriteSingleLine(uint256 tokenId, string memory messageMaxCharacterPerLineAbout30) public {
        checkPublic(tokenId);
        clearPublicMessage(tokenId);
        allMessage[tokenId].publicMessage[0] =  string(abi.encodePacked(messageMaxCharacterPerLineAbout30 )); 
        allMessage[tokenId].publicLineCount = 1;
    }

    function publicWriteTwoLines(uint256 tokenId, string[2] memory messageMaxCharacterPerLineAbout30) public {
        checkPublic(tokenId);
        clearPublicMessage(tokenId);
        allMessage[tokenId].publicMessage[0] = string(abi.encodePacked(messageMaxCharacterPerLineAbout30[0])); 
        allMessage[tokenId].publicMessage[1] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[1],spanZ)); 
        allMessage[tokenId].publicLineCount = 2;
    }

    function publicWriteMultiLine(uint256 tokenId, string[5] memory messageMaxCharacterPerLineAbout30) public {
        checkPublic(tokenId);
        allMessage[tokenId].publicMessage[0] = string(abi.encodePacked(messageMaxCharacterPerLineAbout30[0])); 
        allMessage[tokenId].publicMessage[1] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[1],spanZ)); 
        allMessage[tokenId].publicMessage[2] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[2],spanZ)); 
        allMessage[tokenId].publicMessage[3] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[3],spanZ)); 
        allMessage[tokenId].publicMessage[4] = string(abi.encodePacked(spanA,messageMaxCharacterPerLineAbout30[4],spanZ)); 
        allMessage[tokenId].publicLineCount = 5;
    }
    
    function publicWriteDrawing(uint256 tokenId, string memory svgCommand) public {
        checkPublic(tokenId);
        clearPublicMessage(tokenId);
        allMessage[tokenId].publicMessage[0] = string(abi.encodePacked(textTagClose,svgCommand,textTagOpen)); 
        allMessage[tokenId].publicLineCount = 1;
    }

    // previous owners claim token
    function claimV1Token(uint256 tokenId) public {
        require(mintingEnabled,"Disabled");
        require(_msgSender() == v1Contract.ownerOf(tokenId), errOwn);
        require(allMessage[tokenId].claimed == false, "v2 token already owned");
    
        allMessage[tokenId].claimed = true;
        allMessage[tokenId].writeState = 1;
        allMessage[tokenId].publicLineCount = 1;
        allMessage[tokenId].ownerLineCount = 1;
        allMessage[tokenId].publicMessage = ["hello world","","","",""];
        allMessage[tokenId].ownerMessage = allMessage[tokenId].publicMessage;
        allMessage[tokenId].rareType = v1Contract.readRarityType(tokenId);
        // restoring available upgrades from v1 data
        allMessage[tokenId].upgradeAvailable = v1TokenUpgradeMap[tokenId].value;
        allMessage[tokenId].upgradeUsed = [0,0,0];
        refreshAvailableUpgradeMetadata(tokenId);
        _safeMint(_msgSender(),tokenId);
    }
    
    // I won't use this on influencers
    function contractOwnerToggleCool(uint256 tokenId, bool toggle) public onlyOwner {
        allMessage[tokenId].rareType = toggle ? 1 : 0;
    }

    // For emergency use only...
    function contractOwnerToggleNice(uint256 tokenId, bool toggle) public onlyOwner {
        allMessage[tokenId].writeState = toggle ? 0 : 2;
        if(toggle == false){
            clearPublicMessage(tokenId);
            clearOwnerMessage(tokenId);
            allMessage[tokenId].writeState = 2;
            allMessage[tokenId].rareType = 0;
            allMessage[tokenId].ownerLineCount = 1;
            allMessage[tokenId].publicLineCount = 1;
            allMessage[tokenId].upgradeAvailable = 0;
            allMessage[tokenId].upgradeUsed =[0,0,0];
            allMessage[tokenId].upgrade = "";
            allMessage[tokenId].upgradeMeta = ["","","","",""];
        }
    }
    function contractOwnerToggleMinting(bool toggle) public onlyOwner {
        mintingEnabled = toggle;
    }
    // BOT OPERATOR WARNING: if you attack this
    // I'll call contractOwnerToggleNice() removing rarity
    // and disabling your shit,  so don't fuck around and find out. 
    function rand(uint256 num) private view returns (uint256) {
        return  uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, num, totalSupply()))) % num;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        allMessage[tokenId].owner = to;
    }
    
    function ugType0(uint256 tokenId) private {
        allMessage[tokenId].upgrade = string(abi.encodePacked(allMessage[tokenId].upgrade, DrawSvgOps.Wiggle(size)));
        allMessage[tokenId].upgradeUsed[0] += 1;
        allMessage[tokenId].upgradeMeta[0] = string(abi.encodePacked(
            traitMeta,
            upgradeWigMeta, 
            Strings.toString(allMessage[tokenId].upgradeUsed[0]), 
            upgradeMetaEnd));
    }

    function ugType1(uint256 tokenId) private {
        allMessage[tokenId].upgrade = string(abi.encodePacked(allMessage[tokenId].upgrade, DrawSvgOps.Ellipse(size)));
        allMessage[tokenId].upgradeUsed[1] += 1;
        allMessage[tokenId].upgradeMeta[1] = string(abi.encodePacked(
            traitMeta,
            ugSphereMeta, 
            Strings.toString(allMessage[tokenId].upgradeUsed[1]), 
            upgradeMetaEnd));
    }

    function refreshAvailableUpgradeMetadata(uint256 tokenId) private {
        allMessage[tokenId].upgradeMeta[3] = string(abi.encodePacked(
            traitMeta,
            upgradeAvailMeta, 
            Strings.toString(allMessage[tokenId].upgradeAvailable), 
        upgradeMetaEnd));
    }
    function upgradeMessage(uint256 tokenId) public {
        require(allMessage[tokenId].owner == _msgSender(), errOwn);
        require(allMessage[tokenId].upgradeAvailable > 0, 'No upgrades');
        allMessage[tokenId].upgradeAvailable -= 1;
        uint256 ugType = rand(3);
        if(ugType == 0){
            ugType0(tokenId);
        } 
        else if (ugType == 1){
            ugType1(tokenId);
        } else if (ugType == 2){
            if(allMessage[tokenId].upgradeUsed[2] < 1){
                allMessage[tokenId].upgradeUsed[2] += 1;
                allMessage[tokenId].upgradeMeta[2] = string(abi.encodePacked(
                    traitMeta,
                    ugGradMeta, 
                    Strings.toString(allMessage[tokenId].upgradeUsed[2]), 
                    upgradeMetaEnd));
            } else {
                ugType0(tokenId);
            }
        }
        refreshAvailableUpgradeMetadata(tokenId);
        allMessage[tokenId].upgradeMeta[4] = string(abi.encodePacked(
            traitMeta,
            upgradeUsedMeta, 
            Strings.toString(allMessage[tokenId].upgradeUsed[0] + allMessage[tokenId].upgradeUsed[1] + allMessage[tokenId].upgradeUsed[2]), 
            upgradeMetaEnd));
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        MsgData memory msgCopy = allMessage[tokenId];
        string memory attr = string(abi.encodePacked(
            '"attributes": [',
            msgCopy.upgradeMeta[0],
            msgCopy.upgradeMeta[1],
            msgCopy.upgradeMeta[2],
            msgCopy.upgradeMeta[3]
            ,msgCopy.upgradeMeta[4]));
        string memory fontColor = 'limegreen;'; 
        attr = string(abi.encodePacked(attr,traitMeta,rarityMeta));
        if(msgCopy.rareType == 4){
            fontColor = 'yellow;'; 
            attr = string(abi.encodePacked(attr,'"I just think they\'re neat"}'));
        } else if(msgCopy.rareType == 1){
            fontColor = 'cornflowerblue;'; 
            attr = string(abi.encodePacked(attr,'"Oh, wow. Cool."}'));
        } else if(msgCopy.rareType == 2){
            fontColor = 'red;';
            attr = string(abi.encodePacked(attr,'"Looks Rare"}'));
        } else if(msgCopy.rareType == 3){
            fontColor = 'red;font-style: oblique;font-weight: 900;letter-spacing: 3px;';
            attr = string(abi.encodePacked(attr,'"Looks Rare and Cool"}'));
        } else {
            attr = string(abi.encodePacked(attr,'"Green"}'));
        }
        string memory grad = msgCopy.upgradeUsed[2] == 0 ? "" : "2";
        string memory box2 = '';
        if(msgCopy.writeState==1){
            box2 = string(abi.encodePacked(StringHell.SvgB1(),grad,')" />'));
        }
        string memory output = string(abi.encodePacked(
            StringHell.SvgStart(),
            fontColor,
            StringHell.SvgO1(),
            grad,
            ')" />',
            box2,
            StringHell.SvgO3()));
        output = string(abi.encodePacked(
            output, 
            msgCopy.ownerMessage[0],
            msgCopy.ownerMessage[1],
            msgCopy.ownerMessage[2], 
            msgCopy.ownerMessage[3],
            msgCopy.ownerMessage[4]));
        if(msgCopy.writeState==1){
            output = string(abi.encodePacked(
                output, 
                textTagClose,
                StringHell.SvgP2(),
                msgCopy.publicMessage[0],
                msgCopy.publicMessage[1],
                msgCopy.publicMessage[2]));
            output = string(abi.encodePacked(
                output, 
                msgCopy.publicMessage[3],
                msgCopy.publicMessage[4]));
        }
        output = string(abi.encodePacked(
            output,
            textTagClose,
            msgCopy.upgrade, 
            StringHell.SvgEnd()));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Message #', 
            Strings.toString(tokenId), 
            StringHell.Desc(), 
            attr ,
            StringHell.JsonStub(), 
            Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked(StringHell.Json(), json));
        return output;
    }
}