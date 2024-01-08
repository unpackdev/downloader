// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Shapelies is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    uint public price = 1e16; //0.01 ETH
    uint public constant maxSupply = 1000;


    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    string[] private C = [
        "#c24449","#c24449","#c24449",
        "#38a336","#38a336","#38a336",
        "#3f87c1","#3f87c1","#3f87c1",
        "#c2b72b","#c2b72b",
        "#da53d4","#da53d4",
        "#ea834a"
    ];

    function cross(uint256 x, uint256 y,uint256 r) internal view returns (string memory) {
        return string(abi.encodePacked('<path id="c" d="M ',toString(x*10),' ',toString(y*10),' l 2 2 m -2 -2 l -2 2 m 2 -2 l 2 -2 m -2 2 l -2 -2" stroke="',C[r%C.length],'" stroke-width="2" fill="transparent"/>'));
    }

    function tri(uint256 x, uint256 y,uint256 r) internal view returns (string memory) {
        return string(abi.encodePacked('<path id="t" d="M ',toString(x*10),' ',toString(y*10),' m -2.5 2 l 2.5 -4.5 l 2.5 4.5 l -5 0 z" fill="',C[r%C.length],'"/>'));
    }

    function rhombus(uint256 x, uint256 y,uint256 r) internal view returns (string memory) {
        return string(abi.encodePacked('<path id="r" d="M ',toString(x*10),' ',toString(y*10),' m -2.75 0 l 2.75 -2.75 l 2.75 2.75 l -2.75 2.75 l -2.75 -2.75 z" fill="',C[r%C.length],'"/>'));
    }

    function square(uint256 x, uint256 y,uint256 r) internal view returns (string memory) {
        return string(abi.encodePacked('<path id="s" d="M ',toString(x*10),' ',toString(y*10),' m -2.5 -2.5 v 5 h 5 v -5 h -5 z" fill="',C[r%C.length],'"/>'));
    }

    function circle(uint256 x, uint256 y,uint256 r) internal view returns (string memory) {
        return string(abi.encodePacked('<circle id="o" cx="',toString(x*10),'" cy="',toString(y*10),'" r="2.2"  fill="',C[r%C.length],'"/>'));
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: Token has not been minted");
        uint256[2] memory R;
        R[0] = random(string(abi.encodePacked("RZERO", toString(tokenId))));
        R[1] = random(string(abi.encodePacked("RCOLOR", toString(tokenId))));
       

        uint256 c = 3 + (R[0]%6);
        uint256 r;
        uint256 r1;
        uint256 count;
        string memory dat;    

        for(uint x=1;x<=c;x++){
            for(uint y=1;y<=c;y++){
                r = R[0]>>(y+c*x);
                r1 = R[1]>>(y+c*x);
                if(r%6 == 0) dat = string(abi.encodePacked(dat,circle(x,y,r1)));
                if(r%6 == 1) dat = string(abi.encodePacked(dat,cross(x,y,r1)));
                if(r%6 == 2) dat = string(abi.encodePacked(dat,tri(x,y,r1)));
                if(r%6 == 3) dat = string(abi.encodePacked(dat,rhombus(x,y,r1)));
                if(r%6 == 4) dat = string(abi.encodePacked(dat,square(x,y,r1)));
                if(r%6 != 5) count++;
            }
        }

        string memory s = toString(10 * (c+1));
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 100 100"><svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 ',
                s," ",s,'"><style>svg{font-family: arial,sans-serif; font-weight:bolder;}</style><rect width="100%" height="100%" fill="white"/>',
                dat,"</svg>',",'<text font-size="2px" dominant-baseline="bottom" text-anchor="end" x="99" y="99" fill="black">#',toString(tokenId),'</text>',"</svg>"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Shapelie #',
                        toString(tokenId),
                        '","description": "Shapelies are randomised sheets of colorful shapes generated and stored entirely on-chain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),'","attributes": [{"trait_type": "Count","value":',toString(count),' }, {"trait_type": "Size","value": ',toString(c*c),'}]}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function setPrice(uint256 newPrice) public onlyOwner {
		price = newPrice;
	}

    function mint() public payable nonReentrant {
		require(price <= msg.value, "not enough ether");
		require(totalSupply() < maxSupply, "all tokens minted");
		_safeMint(_msgSender(), totalSupply()+1);
	}

    function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 1000 && tokenId < 1025, "token id invalid");
        _safeMint(owner(), tokenId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    constructor() ERC721("Shapelies", "SHAPELIES")  Ownable() {}    
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
