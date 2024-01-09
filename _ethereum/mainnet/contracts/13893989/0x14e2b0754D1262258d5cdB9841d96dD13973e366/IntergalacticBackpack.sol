// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Arrays.sol";

contract IntergalacticBackpack is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;

    uint256 public constant MAX_TOKENS = 10000;

    uint256 public constant MAX_TOKENS_PER_PURCHASE = 30;

    uint256 private price = 25000000000000000; // 0.025 Ether

    // World: wwd56rt7io
    // Backpack items: "The Dust Times Weekly Sunday Magazine","Juibatik Science Center Poker Cards","www4vas Boba House Loyalty Card","Jinfara Moon Brand Sugarfree Cough Drops","Snasis Leaf Anti-Allergy Tablets"

    // World: Alycora
    // Backpack Items: "Inter-nebular University Never-Dry Hi-Liter","One Uff Performance Quantum Quick Dry Sock","Tronitii Brand Heffa Bean Snacks","Exabyte Conversation Memory Headphones","Juicy Cosmic Ultra Mint Gum Wrapper"

    // World: Lusellas
    // Backpack Items: "U7115 Star Solar Battery Pack","#ED6572 Lipstick","Itaris Nebula Highschool Hoodie Size XL (Stolen)","Dr. E. Kemlin Ultra Smile Dentistry Business Card","Shimin Soy Sauce Packet (Less Sodium)"

    // World: TH47R23Y
    // Backpack Items: "Two Passport Photos","3/4 Full U89FJAB Nebula Hotel Shampoo and Conditioner","Herasis Waterfalls Keychain","Introduction to Quantum Mechanics","Love Is A Chance In Time Diner Takeout Menu"

    // World: Diphadisan
    // Backpack Items: "Metra Hoodie Price Tag","Somla Cake Factory Take-out Receipt","Standup on Saturn : A Comedic Autobiography","Hand-knit Lydium Cloth Scarf","Planet 67 Starbright Bubble Gum"

    // World: Grianfar
    // Backpack Items: "UYT Moon Platinum Rings","Wesva Beach Sand Shell","Mentra Cat Resort Hang In There Kitten Keychain","Hairbrush","Grianfar Debit Card (Stolen)"

    // World: Kitpalasis
    // Backpack Items: "Mudon Brand Sharpie","Melsovian Metal Glimmer Lip Gloss","Solar Flare Sunglasses","Nonne Rope Particulate Allergy Spray","Real Quobitrons of Kitpalasis Season 12 Digital Pass"

    // World: Enrasilavis
    // Backpack Items: "West Takosis Moon Brand Potato Chips","Emattril Energy Bar (gluten free)","Enkatron Office League Soccer Ball","Ganro Farms Glow Sticks (six pack)","Gravity Adjusted Sunflower Seeds"

    // World: 84RT74
    // Backpack Items: "Burnt Velceron Tacos","Numbatron Discount Granola","House Of A Thousand Numbatron Daggers","Zavkre Projection Movie Capsule","Akelan Everburn Matches"

    // World: Niaselki
    // Backpack Items: "MukaWuka Sushi Gift Card (600 Dransini)","Alshevian Husky Dental Treats","Wera Karis District Spa Locker Key","Moonatis Euphoria Capsule Lab Test Results","Xiiraki Didn't Consume Me! (Cave Exit Gift Shop T-Shirt)"

    // World: Gnikase
    // Backpack Items: "1-996-Moon-Junk 20% Coupon","Yosta Nebula Dust Resistant Calculator","Velerisian Driver's License Renewal Form","Leaking Deblirium Hotel and Spa Pen","Ripped Bag Moschiu Brand Gummy Worms"

    // World: 111111111111R
    // Backpack Items: "111111111111R Vintage Floppy Disk No. 274","Binary Depot 6000 Musoka Gift Card","Happy Sunshine Art Co. Sketch Pad","Velsivis Sulfur Rain Umbrella","Nebrakik Exchange 24/7 Reusable Mug"

    // World: Earth
    // Backpack Items: "CHEETOS Puffs FLAMIN HOT Cheese Flavored","Duct Tape","Apple Macbook Pro","The Incredible Hulk and Wolverine No. 1 October 1986","Pokemon Card Appraisal Complaint Form"

    // World: Mars
    // Backpack Items: "Mars Mars Bar","Hydroponic Lettuce Wrap","Earth 3073 Collectable Calendar","Solar Compass","Planet Red Mini Golf and Bowling Loyalty Card"

    // World: AlakosVortex
    // Backpack Items: "Convolution Mist","Jakathintik Gyroscope","Four Dimensional Flashlight","Dust Nebula Windbreaker","Antimatter Safety Flare"


    constructor() ERC721("Intergalactic Backpack", "BACKPACK") Ownable() {}

    // Mint functionality

    function mint(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1, "Exceeds maximum tokens you can purchase in a single transaction");
        require(totalSupply + _count < MAX_TOKENS + 1, "Exceeds maximum tokens available for purchase");
        require(msg.value >= price.mul(_count), "Ether value sent is not correct");

        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override (ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Random function

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // Shuffle all items

    function shuffleAllItems(uint256 tokenId) internal view returns (string[75] memory) {

      string[75] memory r;
      string[75] memory s = ["The Dust Times Weekly Sunday Magazine","Juibatik Science Center Poker Cards","www4vas Boba House Loyalty Card","Jinfara Moon Brand Sugarfree Cough Drops","Snasis Leaf Anti-Allergy Tablets","Inter-nebular University Never-Dry Hi-Liter","One Uff Performance Quantum Quick Dry Sock","Tronitii Brand Heffa Bean Snacks","Exabyte Conversation Memory Headphones","Juicy Cosmic Ultra Mint Gum Wrapper","U7115 Star Solar Battery Pack","#ED6572 Lipstick","Itaris Nebula Highschool Hoodie Size XL (Stolen)","Dr. E. Kemlin Ultra Smile Dentistry Business Card","Shimin Soy Sauce Packet (Less Sodium)","Two Passport Photos","3/4 Full U89FJAB Nebula Hotel Shampoo and Conditioner","Herasis Waterfalls Keychain","Introduction to Quantum Mechanics","Love Is A Chance In Time Diner Takeout Menu","Metra Hoodie Price Tag","Somla Cake Factory Take-out Receipt","Standup on Saturn : A Comedic Autobiography","Hand-knit Lydium Cloth Scarf","Planet 67 Starbright Bubble Gum","UYT Moon Platinum Rings","Wesva Beach Sand Shell","Mentra Cat Resort Hang In There Kitten Keychain","Hairbrush","Grianfar Debit Card (Stolen)","Mudon Brand Sharpie","Melsovian Metal Glimmer Lip Gloss","Solar Flare Sunglasses","Nonne Rope Particulate Allergy Spray","Real Quobitrons of Kitpalasis Season 12 Digital Pass","West Takosis Moon Brand Potato Chips","Emattril Energy Bar (gluten free)","Enkatron Office League Soccer Ball","Ganro Farms Glow Sticks (six pack)","Gravity Adjusted Sunflower Seeds","Burnt Velceron Tacos","Numbatron Discount Granola","House Of A Thousand Numbatron Daggers","Zavkre Projection Movie Capsule","Akelan Everburn Matches","MukaWuka Sushi Gift Card (600 Dransini)","Alshevian Husky Dental Treats","Wera Karis District Spa Locker Key","Moonatis Euphoria Capsule Lab Test Results","Xiiraki Didn't Consume Me! (Cave Exit Gift Shop T-Shirt)","1-996-Moon-Junk 20% Coupon","Yosta Nebula Dust Resistant Calculator","Velerisian Driver's License Renewal Form","Leaking Deblirium Hotel and Spa Pen","Ripped Bag Moschiu Brand Gummy Worms","111111111111R Vintage Floppy Disk No. 274","Binary Depot 6000 Musoka Gift Card","Happy Sunshine Art Co. Sketch Pad","Velsivis Sulfur Rain Umbrella","Nebrakik Exchange 24/7 Reusable Mug","CHEETOS Puffs FLAMIN HOT Cheese Flavored","Duct Tape","Apple Macbook Pro","The Incredible Hulk and Wolverine No. 1 October 1986","Pokemon Card Appraisal Complaint Form","Mars Mars Bar","Hydroponic Lettuce Wrap","Earth 3073 Collectable Calendar","Solar Compass","Planet Red Mini Golf and Bowling Loyalty Card","Convolution Mist","Jakathintik Gyroscope","Four Dimensional Flashlight","Dust Nebula Windbreaker","Antimatter Safety Flare"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      return r;

    }

    // Progress of worlds

    function getWorldsProgress(uint256 tokenId) private view returns (string[15] memory) {

        string[15] memory r;

        string[15] memory w = ["wwd56rt7io","Alycora","Lusellas","TH47R23Y","Diphadisan","Grianfar","Kitpalasis","Enrasilavis","84RT74","Niaselki","Gnikase","111111111111R","Earth","Mars","AlakosVortex"];

        uint l = w.length;
        uint i;
        string memory t;

        while (l > 0) {
          uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
          i = v % l--;
          t = w[l];
          w[l] = w[i];
          w[i] = t;
        }

        r = w;

        return r;
    }

    // Helratian mutation percentage

    function getHelratianMutationPercentage(uint256 tokenId) private view returns (string memory) {

        string[100] memory p = ["1%", "2%", "3%", "4%", "5%", "6%", "7%", "8%", "9%", "10%", "11%", "12%", "13%", "14%", "15%", "16%", "17%", "18%", "19%", "20%", "21%", "22%", "23%", "24%", "25%", "26%", "27%", "28%", "29%", "30%", "31%", "32%", "33%", "34%", "35%", "36%", "37%", "38%", "39%", "40%", "41%", "42%", "43%", "44%", "45%", "46%", "47%", "48%", "49%", "50%", "51%", "52%", "53%", "54%", "55%", "56%", "57%", "58%", "59%", "60%", "61%", "62%", "63%", "64%", "65%", "66%", "67%", "68%", "69%", "70%", "71%", "72%", "73%", "74%", "75%", "76%", "77%", "78%", "79%", "80%", "81%", "82%", "83%", "84%", "85%", "86%", "87%", "88%", "89%", "90%", "91%", "92%", "93%", "94%", "95%", "96%", "97%", "98%", "99%", "100%"];

        uint l = p.length;
        uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
        uint256 i = v % l--;
        string memory r = p[i];
        return r;
    }

    // Entranika gems retrieved

    function getEntranikaGemsRetrieved(uint256 tokenId) private view returns (string memory) {

        string[12] memory g = ["1","2","3","4","5","6","7","8","9","10","11","12"];

        uint l = g.length;
        uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
        uint256 i = v % l--;
        string memory r = g[i];
        return r;
    }

    // Lightyears travelled

    function getLightYearsTravelled(uint256 tokenId) private view returns (string memory) {

        uint256 m = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));
        uint256 n = v % m;
        uint256 t = n % 9461000000000;
        string memory r = toString(t);

        return r;

    }

    // Generate backpack

    function generateBackpack(uint256 tokenId) private view returns (string[5] memory) {

        string[5] memory r;
        uint l = 75;
        uint256 q = random(string(abi.encodePacked(block.timestamp, block.difficulty, toString(tokenId))));

        for (uint a = 0; a < 5; a++) {

            string[75] memory h = shuffleAllItems(tokenId);
            uint256 x = q % l--;
            r[a] = h[x];
            l--;

        }

        return r;

    }

    // Backpack emoji

    function insertBackpack() private pure returns (string memory) {
        string memory backpack = unicode"🎒";
        return backpack;
    }

    // Token URI

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[49] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg"  viewBox="0 0 750 750"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getHelratianMutationPercentage(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getEntranikaGemsRetrieved(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getLightYearsTravelled(tokenId);

        parts[6] = '</text><text x="10" y="100" class="base">';

        parts[7] = generateBackpack(tokenId)[0];

        parts[8] = '</text><text x="10" y="120" class="base">';

        parts[9] = generateBackpack(tokenId)[1];

        parts[10] = '</text><text x="10" y="140" class="base">';

        parts[11] = generateBackpack(tokenId)[2];

        parts[12] = '</text><text x="10" y="160" class="base">';

        parts[13] = generateBackpack(tokenId)[3];

        parts[14] = '</text><text x="10" y="180" class="base">';

        parts[15] = generateBackpack(tokenId)[4];

        parts[16] = '</text><text x="10" y="220" class="base">';

        parts[17] = getWorldsProgress(tokenId)[0];

        parts[18] = '</text><text x="10" y="240" class="base">';

        parts[19] = getWorldsProgress(tokenId)[1];

        parts[20] = '</text><text x="10" y="260" class="base">';

        parts[21] = getWorldsProgress(tokenId)[2];

        parts[22] = '</text><text x="10" y="280" class="base">';

        parts[23] = getWorldsProgress(tokenId)[3];

        parts[24] = '</text><text x="10" y="300" class="base">';

        parts[25] = getWorldsProgress(tokenId)[4];

        parts[26] = '</text><text x="10" y="320" class="base">';

        parts[27] = getWorldsProgress(tokenId)[5];

        parts[28] = '</text><text x="10" y="340" class="base">';

        parts[29] = getWorldsProgress(tokenId)[6];

        parts[30] = '</text><text x="10" y="360" class="base">';

        parts[31] = getWorldsProgress(tokenId)[7];

        parts[32] = '</text><text x="10" y="380" class="base">';

        parts[33] = getWorldsProgress(tokenId)[8];

        parts[34] = '</text><text x="10" y="400" class="base">';

        parts[35] = getWorldsProgress(tokenId)[9];

        parts[36] = '</text><text x="10" y="420" class="base">';

        parts[37] = getWorldsProgress(tokenId)[10];

        parts[38] = '</text><text x="10" y="440" class="base">';

        parts[39] = getWorldsProgress(tokenId)[11];

        parts[40] = '</text><text x="10" y="460" class="base">';

        parts[41] = getWorldsProgress(tokenId)[12];

        parts[42] = '</text><text x="10" y="480" class="base">';

        parts[43] = getWorldsProgress(tokenId)[13];

        parts[44] = '</text><text x="10" y="500" class="base">';

        parts[45] = getWorldsProgress(tokenId)[14];

        parts[46] = '</text><text x="10" y="540" class="base">';

        parts[47] = insertBackpack();

        parts[48] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        output = string(abi.encodePacked(output, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23], parts[24]));
        output = string(abi.encodePacked(output, parts[25], parts[26], parts[27], parts[28], parts[29], parts[30], parts[31], parts[32]));
        output = string(abi.encodePacked(output, parts[33], parts[34], parts[35], parts[36], parts[37], parts[38], parts[39], parts[40]));
        output = string(abi.encodePacked(output, parts[41], parts[42], parts[43], parts[44], parts[45], parts[46], parts[47], parts[48]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Intergalactic Backpack #', toString(tokenId), '", "description": "It is 3273 and you are a brilliant innovator who has just helped transplant humanity to Mars from a dying Earth. As you complete your mission to go join your family, the world-consuming Helratians attack Earth through a rip in the Alakos Vortex that opens up between Earth and Mars. Each attack by a Helratian causes you to mutate further and further away from your human form. Pulled into the Alakos Vortex, you must retrieve the twelve Entranika Gems scattered across distant worlds in order to become fully human again. Your family awaits you on Mars. Will you make it back to them? This is your Intergalactic Backpack full of items gathered from the fifteen worlds you have travelled in the order shown. Remember to check your vitals: Helratian Mutation Percentage, Entranika Gems Retrieved and Light Years Travelled. Good luck!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    // to String utility

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