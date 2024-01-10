// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721} from "ERC721.sol";

contract HankngyToken is ERC721("HankgyToken", "HKNY")  {

    address kenny = 0xa68FE91Ec2b713A95246590f71c54539d4c1D775;
    string baseURI;

    modifier onlyKenny() {
        require (msg.sender == kenny, "REEEE");
        _;
    }

    function RulesForThemToLiveBy() public pure returns (string [] memory) {
        string[] memory rules;
        rules[0] = "Be born into intergenerational wealth";
        rules[1] = "Have a holdings company";
        rules[2] = "Leverage good, no leverage bad";
        rules[3] = "When in doubt, make reference to Adeles teachings";
        rules[4] = "The 'Win Friends and Influence People Rule`. Utilize the golden words 'I hear you BUT' but then proceed to invalidate everything they have said in the previous conversation. Listening to not rich people is for poor people";
        rules[5] = "Take inspiration from Kevin, it is not enough that I should be rich, others should be poor Liquidity is a zero sum game. Rug them before they rug you";
        rules[6] = "Have a personal banking bitch. Poor people don't have a personal banking bitch. Therefore via proof by contradiction, having a personal banking bitch alleviates poorness";
        rules[7] = "Always establish a plausible story. Affluent people distort the universe to their liking. It's not about what actually happened, it's about the narrative";
        rules[8] = "The ultimate proof of not being poor is utter dominance in anime video games made for Chinese youth. There is no second best";
        rules[9] = "Non poor people appreciate art. When in doubt, turn to the classics";
        return rules;
    }

    function MintGenerationalWealth(address hankordagny, uint256 tokenId) public onlyKenny {
        _mint(hankordagny, tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(tokenId))) : "";
    }
    
    function setBaseURI(string memory newBaseURI) public onlyKenny {
        baseURI = newBaseURI;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    function replaceKenny(address newKenny) public onlyKenny {
        kenny = newKenny;
    }

}