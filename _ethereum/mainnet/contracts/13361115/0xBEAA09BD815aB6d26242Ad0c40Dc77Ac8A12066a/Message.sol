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
       ///////////////////////////////////////
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

       MESSAGE

       2021

       Sterling Crispin

       https://www.sterlingcrispin.com/message.html
**/


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/// [MIT License]
/// @title ERC721Tradable
/// @notice Edited ERC721Tradable.sol from OpenSea without mintTo and other garbo IDC about
abstract contract ERC721Tradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }
    // OpenSea friendly func
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
/// [MIT License]
/// @title Message
/// @notice An experiment in communication.
/// @author Sterling Crispin <sterlingcrispin@gmail.com>
contract Message is ERC721Tradable {
    using Strings for string;

    uint256 constant MAXTOKENS = 482;// 512 total tokens
    uint256 OWNERTOKENS = 30;

    bool internal mintingEnabled = false;
    string internal constant spanA = '<tspan x="40" dy="25">';
    string internal constant spanZ = '</tspan>';
    string internal constant svgStart = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400" width="800" height="800"><defs><linearGradient id="grad"  x1="0" x2="0" y1="0" y2="1"><stop offset="0%" stop-color="dimgrey" /><stop offset="10%" stop-color="black" /></linearGradient><radialGradient id="grad2" cx="0.5" cy="0.9" r="1.2" fx="0.5" fy="0.9" spreadMethod="repeat"><stop offset="0%" stop-color="red"/><stop offset="100%" stop-color="blue"/></radialGradient></defs><style>.base { fill:';
    string internal constant svgO1 = 'font-family: monospace; font-size: 15px; }</style><rect y="8" width="100%" height="100%" fill="url(#grad';
    string internal constant svgB1 = '<rect y="50%" width="100%" height="100%" fill="url(#grad';
    string internal constant svgB2 = ')" />';
    string internal constant svgO3 = '<text x="20" y="60" class="base">//usr: ';
    string internal constant svgP2 = '<text x="20" y="250" class="base">//pub: '; 
    string internal constant svgEnd = '<rect width="100%" height="100%" fill="none" stroke="dimgrey" stroke-width="20"/><circle cx="20" cy="395" r="3" fill="limegreen"/></svg>';
    string internal constant errBad = "Writing disabled due to Something Bad";
    string internal constant errPub = "Public Message is not enabled";
    string internal constant errOwn = "You are not the owner";
    string internal constant upgradeMetaEnd = '"},';
    string internal constant upgradeAvailMeta = '{"trait_type": "Upgrades Available","value": "';
    string internal constant upgradeUsedMeta = '{"trait_type": "Upgrades Used","value": "';
    string internal constant upgradeWigMeta = '{"trait_type": "Wiggle","value": "';
    string internal constant ugSphereMeta = '{"trait_type": "Spheres","value": "';
    string internal constant ugGradMeta = '{"trait_type": "Sunrise","value": "';
    string internal constant rarityMeta = '{"trait_type": "Vibe","value":';
    uint256 internal constant size = 400;
    
    struct MsgData{
        address owner;
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
        ERC721Tradable("Message", "MESSAGE", _proxyRegistryAddress)
    {}

    function readUpgradeMetadata(uint256 tokenId) public view returns(string[5] memory){
        return allMessage[tokenId].upgradeMeta;
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

    function checkOwner(uint256 tokenId) private view{
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
        allMessage[tokenId].ownerMessage[0] =  string(abi.encodePacked('</text>',svgCommand,'<text>')); 
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
        allMessage[tokenId].publicMessage[0] = string(abi.encodePacked('</text>',svgCommand,'<text>')); 
        allMessage[tokenId].publicLineCount = 1;
    }

    // lucky you
    function mint() public {
        require(mintingEnabled,"Public minting not currently enabled");
        require(balanceOf(_msgSender()) < 1, "Limit is 1 per wallet");
        require(totalSupply() < MAXTOKENS, "Max tokens have already been minted.");
        _privateMint(_msgSender());
    }

    // lucky me 
    function contractOwnerMint(address newOwner) public onlyOwner {
        require(OWNERTOKENS > 0, "Maxed");
        OWNERTOKENS -= 1;
        _privateMint(newOwner);
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

    function _privateMint(address newOwner) private {
        uint256 newToken = totalSupply()+1;
        // 25%
        if(rand(4) == 0){
            allMessage[newToken].rareType = 4;
        }
        // 14%
        if(rand(7) == 0){
            allMessage[newToken].rareType = 1;
        }
        // 8%
        if(rand(13) == 0){
            allMessage[newToken].rareType = 2;
        }
        // 0.13% ish
        if(rand(1234) == 0){
            allMessage[newToken].rareType = 3;
        }
        // 12%
        if(rand(8) == 0){
            allMessage[newToken].upgradeAvailable = rand(4)+1;
        } else {
            allMessage[newToken].upgradeAvailable = 0;
        }
        allMessage[newToken].publicMessage = ["hello world","","","",""];
        allMessage[newToken].ownerMessage = allMessage[newToken].publicMessage;
        allMessage[newToken].upgrade = ""; 
        allMessage[newToken].publicLineCount = 1;
        allMessage[newToken].ownerLineCount = 1;
        allMessage[newToken].writeState = 1;
        allMessage[newToken].upgradeUsed = [0,0,0];
        refreshAvailableUpgradeMetadata(newToken);
        _safeMint(newOwner,newToken);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        allMessage[tokenId].owner = to;
    }

    function isApprovedForAll(address _owner, address _operator) override public view returns (bool){
        if (owner() == _owner && _owner == _operator) {
            return true;
        }
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }
        return false;
    }
    
    function ugType0(uint256 tokenId) private {
        allMessage[tokenId].upgrade = string(abi.encodePacked(allMessage[tokenId].upgrade, DrawSvgOps.Wiggle(size)));
        allMessage[tokenId].upgradeUsed[0] += 1;
        allMessage[tokenId].upgradeMeta[0] = string(abi.encodePacked(upgradeWigMeta, TypeConversions.uint2str(allMessage[tokenId].upgradeUsed[0]), upgradeMetaEnd));
    }

    function ugType1(uint256 tokenId) private {
        allMessage[tokenId].upgrade = string(abi.encodePacked(allMessage[tokenId].upgrade, DrawSvgOps.Ellipse(size)));
        allMessage[tokenId].upgradeUsed[1] += 1;
        allMessage[tokenId].upgradeMeta[1] = string(abi.encodePacked(ugSphereMeta, TypeConversions.uint2str(allMessage[tokenId].upgradeUsed[1]), upgradeMetaEnd));
    }

    function refreshAvailableUpgradeMetadata(uint256 tokenId) private{
        allMessage[tokenId].upgradeMeta[3] = string(abi.encodePacked(
            upgradeAvailMeta, 
            TypeConversions.uint2str(allMessage[tokenId].upgradeAvailable), 
        upgradeMetaEnd));
    }
    function upgradeMessage(uint256 tokenId) public{
        require(allMessage[tokenId].owner == _msgSender(), errOwn);
        require(allMessage[tokenId].upgradeAvailable > 0, 'No remaining upgrades');
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
                    ugGradMeta, 
                    TypeConversions.uint2str(allMessage[tokenId].upgradeUsed[2]), 
                    upgradeMetaEnd));
            } else {
                ugType0(tokenId);
            }
        }
        refreshAvailableUpgradeMetadata(tokenId);
        allMessage[tokenId].upgradeMeta[4] = string(abi.encodePacked(
            upgradeUsedMeta, 
            TypeConversions.uint2str(allMessage[tokenId].upgradeUsed[0] + allMessage[tokenId].upgradeUsed[1] + allMessage[tokenId].upgradeUsed[2]), 
            upgradeMetaEnd));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        MsgData memory msgCopy = allMessage[tokenId];
        string memory attr = string(abi.encodePacked('"attributes": [', msgCopy.upgradeMeta[0],msgCopy.upgradeMeta[1],msgCopy.upgradeMeta[2],msgCopy.upgradeMeta[3],msgCopy.upgradeMeta[4]));
        string memory fontColor = 'limegreen;'; 
        if(msgCopy.rareType == 4){
            fontColor = 'yellow;'; 
            attr = string(abi.encodePacked(attr,rarityMeta, '"I just think they\'re neat"}'));
        } else if(msgCopy.rareType == 1){
            fontColor = 'cornflowerblue;'; 
            attr = string(abi.encodePacked(attr,rarityMeta,'"Oh, wow. Cool."}'));
        } else if(msgCopy.rareType == 2){
            fontColor = 'red;';
            attr = string(abi.encodePacked(attr,rarityMeta,'"Looks Rare"}'));
        } else if(msgCopy.rareType == 3){
            fontColor = 'red;font-style: oblique;font-weight: 900;letter-spacing: 3px;';
            attr = string(abi.encodePacked(attr,rarityMeta,'"Looks Rare and Cool"}'));
        } else {
            attr = string(abi.encodePacked(attr,rarityMeta,'"Green"}'));
        }
        string memory grad = msgCopy.upgradeUsed[2] == 0 ? "" : "2";
        string memory box2 = '';
        if(msgCopy.writeState==1){
            box2 = string(abi.encodePacked(svgB1,grad,svgB2));
        }
        string memory output = string(abi.encodePacked(svgStart,fontColor,svgO1,grad,svgB2,box2,svgO3));
        output = string(abi.encodePacked(output, msgCopy.ownerMessage[0],msgCopy.ownerMessage[1],msgCopy.ownerMessage[2], msgCopy.ownerMessage[3],msgCopy.ownerMessage[4]));
        if(msgCopy.writeState==1){
            output = string(abi.encodePacked(output, '</text>',svgP2, msgCopy.publicMessage[0],msgCopy.publicMessage[1],msgCopy.publicMessage[2]));
            output = string(abi.encodePacked(output, msgCopy.publicMessage[3],msgCopy.publicMessage[4]));
        }
        output = string(abi.encodePacked(output,'</text>', msgCopy.upgrade, svgEnd));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Message #', Strings.toString(tokenId), '", "description": "Message is an experiment in communication. Write via contract, refresh metadata. Be nice. https://sterlingcrispin.com/message.html",', attr ,'], "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
}