// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import "./ERC721Upgradeable.sol";
import "./Strings.sol";
import "./ERC20.sol";
import "./ERC721.sol";


 

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

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
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


contract PUNK is ERC721 {
    uint256 tokenId;
    using Strings for *;
    ERC20 ddddToken;

    address BigBoss;

    mapping(uint256=>string[3]) userColor; 
    mapping(uint256=>string) ssrList;
   
     uint8[66] xList = [0, 8, 15, 7, 6, 5, 6, 14, 5, 15, 7, 6, 7, 8, 16, 8, 8, 10, 9, 12, 9, 7, 9, 9, 13, 10, 9, 14, 9, 14, 9, 14, 10, 10, 10, 15, 11, 12, 12, 11, 11, 12, 13, 14, 13, 14, 15, 15, 16, 14, 15, 16, 18, 19, 22, 21, 17, 17, 19, 19, 20, 20, 20, 19, 20, 20];
    uint8[66] yList = [0, 4, 4, 5, 6, 7, 8, 8, 9, 9, 10, 12, 14, 19, 10, 9, 10, 9, 10, 9, 9, 12, 15, 16, 8, 11, 11, 11, 12, 12, 13, 13, 14, 20, 13, 13, 12, 12, 16, 18, 21, 22, 19, 18, 20, 15, 14, 21, 20, 19, 20, 21, 19, 19, 20, 22, 23, 22, 20, 21, 22, 21, 11, 12, 15, 17];
    uint8[66] wList = [24, 6, 1, 9, 12, 12, 7, 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 5, 7, 1, 1, 1, 1, 1, 1, 6, 1, 1, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 3, 1, 3, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1, 4, 1, 1, 4, 3, 3, 3, 1, 1, 1, 3, 1, 1];
    uint8[66] hList = [24, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 5, 5, 9, 10, 1, 1, 1, 2, 1, 2, 9, 1, 10, 1, 4, 4, 1, 1, 1, 1, 10, 1, 1, 1, 12, 9, 1, 1, 1, 2, 1, 3, 1, 3, 5, 1, 3, 1, 1, 1, 3, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1];
    string[66] cList = ["bg", "h", "h", "h", "h", "h", "h", "h", "h", "h", "b", "b", "b", "b", "b", "f", "h", "f", "f", "h", "h", "f", "f", "51331b", "f", "f", "2758b1", "2758b1", "2c5195", "2c5195", "b", "b", "f", "b", "293d64", "293d64", "f", "f", "010001", "c42011", "b", "b", "b", "b", "f", "f", "f", "b", "b", "c", "c", "c", "b", "b", "b", "b", "b", "c", "c", "683c09", "683c09", "c", "s", "s", "s", "s"];
    string[] bgList = ["8e6fb6", "67a570", "95554f", "638596"];
    string[] hairList = ["000000","fef68d","28b042","e22626","a66d2c","e55700","ff8fbd","710cc7"];
    string[] skinList = ["ead9d9","dab181","ad8b61","713f1d"];
    

    uint8[][4] glassList = [[6,8,13,9,14],[12,13,13,14,14],[10,4,3,2,2],[1,1,1,1,1]];
    string[] glassColorList = ['000','000','000','000','000'];

    uint8[][4] laserList = [[7,8,16,7],[12,13,13,14],[10,8,1,10],[1,1,1,1]];
    string[] laserColorList = ['CACACA','EC2553','CACACA','CACACA'];
    
    uint8[][4] pirateList = [[7,8,8,9],[12,13,14,15],[10,4,4,2],[1,1,1,1]];
    string[] pirateColorList = ['000','000','000','000'];
    string[] NameList = ['g','l','p'];


    constructor(address ddddAddr,address BigBossAddr) ERC721("People's Punk", "PPUNK") public {
        ddddToken = ERC20(ddddAddr);
        BigBoss = BigBossAddr;
    }
     modifier refuseContract() {
        require(tx.origin == _msgSender(), "refuse constractor");
            require(!isContract(_msgSender()),"refuse contract");
        _;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    
    function withdraw() public {
        require(_msgSender()==BigBoss,'only BigBoss');
        uint256 balance = ddddToken.balanceOf(address(this));
        ddddToken.transfer(BigBoss,balance);
    }

  
    function getNextId() public view returns (uint256) {
        return tokenId + 1;
    }

    function mintNFT() public refuseContract returns(uint256){
            string memory skinColor;
            ddddToken.transferFrom(_msgSender(), address(this), 40400 ether);
            tokenId = getNextId();
            _mint(_msgSender(), tokenId);
            string memory bgColor = selectRandom(bgList);
            string memory hairColor = selectRandom(hairList);
            uint skinNum = getRandom(10);
            if(skinNum<=10){
                skinColor = "7ea269";
            }else if(skinNum==1){
                skinColor = "c8fbfb";
            }else{
                skinColor = selectRandom(skinList);
            }
            
            userColor[tokenId]= [bgColor,hairColor,skinColor];
            if(getRandom(1)==6){
                ssrList[tokenId] = selectRandom(NameList);
            }
            return tokenId;
    }

    string constant p0 =
        '<svg width="240" height="240" xmlns="http://www.w3.org/2000/svg" version="1.1">';
    string constant p1 = '<rect x="';
    string constant p2 = '" y="';
    string constant p3 = '" width="';
    string constant p4 = '" height="';
    string constant p5 = '" style="fill:#';
    string constant p6 = '" />';
    string constant p9 = "</svg>";

   

    function getColor(string memory c,uint256 tokenId) internal view returns (string memory) {
        string memory r;
        string[3] memory colorInfo = userColor[tokenId];

        if (keccak256(bytes(c)) == keccak256(bytes("bg"))) {
            return colorInfo[0];
        } else if (keccak256(bytes(c)) == keccak256(bytes("h"))) {
            return colorInfo[1];
        } else if (keccak256(bytes(c)) == keccak256(bytes("b"))) {
            return "000";
        }else if (keccak256(bytes(c)) == keccak256(bytes("f"))) {
            return colorInfo[2];
        } else if (keccak256(bytes(c)) == keccak256(bytes("c"))) {
            return "855114";
        } else if (keccak256(bytes(c)) == keccak256(bytes("s"))) {
            return "8e9fa9";
        } else {
            return c;
        }
    }

  

    function selectRandom(string[] memory list) internal view returns(string memory){
        uint256 len = list.length;
        require(len<20,"allodoxaphobia");
        uint256 index = getRandom(2)%len;
        return list[index];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory output = "";
        for (uint8 x; x < xList.length; x += 1) {
            output = string(
                abi.encodePacked(
                    output,
                    p1,
                    (xList[x] * 10).toString(),
                    p2,
                    (yList[x] * 10).toString(),
                    p3,
                    (wList[x] * 10).toString(),
                    p4,
                    (hList[x] * 10).toString(),
                    p5,
                    getColor(cList[x],tokenId),
                    p6
                )
            );
        }
        
        string memory ssr = ssrList[tokenId];
        if(keccak256(bytes(ssr)) != keccak256(bytes(""))){
            uint8[][4] memory wearList;
            string[] memory warColorList;  
            if(keccak256(bytes(ssr)) == keccak256(bytes("g"))){
                wearList = glassList;
                warColorList = glassColorList;
            }else if(keccak256(bytes(ssr)) == keccak256(bytes("l"))){
                wearList = laserList;
                warColorList = laserColorList;
            }else if(keccak256(bytes(ssr)) == keccak256(bytes("p"))){
                wearList = pirateList;
                warColorList = pirateColorList;
            }
            for(uint8 index ;index<wearList[0].length;index+=1){
            output = string(
                abi.encodePacked(
                    output,
                    p1,
                    (wearList[0][index] * 10).toString(),
                    p2,
                    (wearList[1][index] * 10).toString(),
                    p3,
                    (wearList[2][index] * 10).toString(),
                    p4,
                    (wearList[3][index] * 10).toString(),
                    p5,
                    warColorList[index],
                    p6
                )
            );
        }
        }
        
        string memory r = string(abi.encodePacked(p0, output, p9));
        string memory name = "People's Punk";
        string memory a = string(abi.encodePacked('{"name": "',name,'", "description": "',name,' is a next-gen social network co-sponsored by 173 genesis founders.  $DDDD is the fractionalized token of Cryptopunk#173 meanwhile the social token of ',name,' community, which is a indicator that measures the social capital of this social network. ',name,' is also the name of Cryptopunk#173 You can mint the fractionalized punk173 NFT by visiting https://punk173.com", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(r)), '"}'));
        string memory json = Base64.encode(bytes(a));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }


    function getRandom(uint256 length) public view returns (uint256) {
        // from fomo3D
        uint256 l = 10 ** length;
        uint256 num = uint256(
            keccak256(
                abi.encodePacked(
                    "PassWd",getNextId(),_msgSender(),
                    (block.timestamp) +
                        (block.difficulty) +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        (block.gaslimit) +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        (block.number)
                )
            )
        ) % l;
        return num;
    }
}
