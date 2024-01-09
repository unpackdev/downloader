// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Arrays.sol";
import "./ReentrancyGuard.sol";

contract IntergalacticBackpack is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {

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

    // World: Alakos Vortex
    // Backpack Items: "Convolution Mist","Jakathintik Gyroscope","Four Dimensional Flashlight","Dust Nebula Windbreaker","Antimatter Safety Flare"

    constructor() ERC721("Intergalactic Backpack", "BKPK") Ownable() {}

    // Mint functionality

    function mint(uint256 _count) public nonReentrant payable {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1);
        require(totalSupply + _count < MAX_TOKENS + 1);
        require(msg.value >= price.mul(_count));

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
          uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      return r;

    }

    // Progress of worlds

    function gWP(uint256 tokenId) private view returns (string[15] memory) {

        string[15] memory r;

        string[15] memory w = ["wwd56rt7io","Alycora","Lusellas","TH47R23Y","Diphadisan","Grianfar","Kitpalasis","Enrasilavis","84RT74","Niaselki","Gnikase","111111111111R","Earth","Mars","Alakos Vortex"];

        uint l = w.length;
        uint i;
        string memory t;

        while (l > 0) {
          uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
          i = v % l--;
          t = w[l];
          w[l] = w[i];
          w[i] = t;
        }

        r = w;

        return r;
    }

    // Helratian mutation percentage

    // function gHMP(uint256 tokenId) private view returns (string memory) {

    //     string[100] memory p = ["1%", "2%", "3%", "4%", "5%", "6%", "7%", "8%", "9%", "10%", "11%", "12%", "13%", "14%", "15%", "16%", "17%", "18%", "19%", "20%", "21%", "22%", "23%", "24%", "25%", "26%", "27%", "28%", "29%", "30%", "31%", "32%", "33%", "34%", "35%", "36%", "37%", "38%", "39%", "40%", "41%", "42%", "43%", "44%", "45%", "46%", "47%", "48%", "49%", "50%", "51%", "52%", "53%", "54%", "55%", "56%", "57%", "58%", "59%", "60%", "61%", "62%", "63%", "64%", "65%", "66%", "67%", "68%", "69%", "70%", "71%", "72%", "73%", "74%", "75%", "76%", "77%", "78%", "79%", "80%", "81%", "82%", "83%", "84%", "85%", "86%", "87%", "88%", "89%", "90%", "91%", "92%", "93%", "94%", "95%", "96%", "97%", "98%", "99%", "100%"];

    //     uint l = p.length;
    //     uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
    //     uint256 i = v % l--;
    //     string memory r = p[i];
    //     return r;
    // }

    function gHMP(uint256 tokenId) private view returns (string memory) {

        string[100] memory p = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96", "97", "98", "99", "100"];

        uint l = p.length;
        uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
        uint256 i = v % l--;
        string memory r = p[i];
        return r;
    }

    // Entranika gems retrieved

    // function gEGR(uint256 tokenId) private view returns (uint256) {

    //     uint8[12] memory g = [1,2,3,4,5,6,7,8,9,10,11,12];

    //     uint256 l = g.length;
    //     uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
    //     uint256 i = v % l--;
    //     uint256 r = g[i];
    //     return r;
    // }

    function gEGR(uint256 tokenId) private view returns (string memory) {

        string[12] memory g = ["1","2","3","4","5","6","7","8","9","10","11","12"];

        uint l = g.length;
        uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
        uint256 i = v % l--;
        string memory r = g[i];
        return r;
    }

    // Lightyears travelled

    function gLYT(uint256 tokenId) private view returns (string memory) {

        uint256 m = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
        uint256 n = v % m;
        uint256 t = n % 9461000000000;
        string memory r = toString(t);

        return r;

    }

    // Generate backpack

    function gB(uint256 tokenId) private view returns (string[5] memory) {

        string[5] memory r;
        // uint l = 75;
        uint256 v = random(string(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, toString(tokenId))));

        string[75] memory h = shuffleAllItems(tokenId);
        uint l = h.length;

        for (uint a = 0; a < 5; a++) {

            // string[75] memory h = shuffleAllItems(tokenId);
            uint256 x = v % l--;
            r[a] = h[x];
            h[x] = h[l--];
            delete h[l--];
            // l--;

        }

        return r;

    }

    // Backpack emoji

    function insertBackpack() private pure returns (string memory) {
        string memory backpack = unicode"🎒";
        return backpack;
    }

    // Make Attributes

    function makeAttributes(uint256 tokenId) public view returns (string memory) {
        string[22] memory traits;

        // uint g = gEGR(tokenId);
        // string memory gS = toString(g);

        traits[0] = string(abi.encodePacked('{"trait_type":"Helratian Mutation Percentage","value":"', gHMP(tokenId), '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"Entranika Gems Retrieved","value":"', gEGR(tokenId), '"}'));
        // traits[1] = string(abi.encodePacked('{"display_type":"number","trait_type":"Entranika Gems Retrieved","value":', gS, ',"max_value": 12}'));
        // traits[1] = string(abi.encodePacked('{"trait_type":"Entranika Gems Retrieved","value":', gS, ',"max_value": 12}'));
        // traits[2] = string(abi.encodePacked('{"trait_type":"Light Years Travelled", "value":"', gLYT(tokenId), '"}'));
        traits[2] = string(abi.encodePacked('{"trait_type":"Item #1","value":"', gB(tokenId)[0], '"}'));
        traits[3] = string(abi.encodePacked('{"trait_type":"Item #2","value":"', gB(tokenId)[1], '"}'));
        traits[4] = string(abi.encodePacked('{"trait_type":"Item #3","value":"', gB(tokenId)[2], '"}'));
        traits[5] = string(abi.encodePacked('{"trait_type":"Item #4","value":"', gB(tokenId)[3], '"}'));
        traits[6] = string(abi.encodePacked('{"trait_type":"Item #5","value":"', gB(tokenId)[4], '"}'));
        traits[7] = string(abi.encodePacked('{"trait_type":"World #1","value":"', gWP(tokenId)[0], '"}'));
        traits[8] = string(abi.encodePacked('{"trait_type":"World #2","value":"', gWP(tokenId)[1], '"}'));
        traits[9] = string(abi.encodePacked('{"trait_type":"World #3","value":"', gWP(tokenId)[2], '"}'));
        traits[10] = string(abi.encodePacked('{"trait_type":"World #4","value":"', gWP(tokenId)[3], '"}'));
        traits[11] = string(abi.encodePacked('{"trait_type":"World #5","value":"', gWP(tokenId)[4], '"}'));
        traits[12] = string(abi.encodePacked('{"trait_type":"World #6","value":"', gWP(tokenId)[5], '"}'));
        traits[13] = string(abi.encodePacked('{"trait_type":"World #7","value":"', gWP(tokenId)[6], '"}'));
        traits[14] = string(abi.encodePacked('{"trait_type":"World #8","value":"', gWP(tokenId)[7], '"}'));
        traits[15] = string(abi.encodePacked('{"trait_type":"World #9","value":"', gWP(tokenId)[8], '"}'));
        traits[16] = string(abi.encodePacked('{"trait_type":"World #10","value":"', gWP(tokenId)[9], '"}'));
        traits[17] = string(abi.encodePacked('{"trait_type":"World #11","value":"', gWP(tokenId)[10], '"}'));
        traits[18] = string(abi.encodePacked('{"trait_type":"World #12","value":"', gWP(tokenId)[11], '"}'));
        traits[19] = string(abi.encodePacked('{"trait_type":"World #13","value":"', gWP(tokenId)[12], '"}'));
        traits[20] = string(abi.encodePacked('{"trait_type":"World #14","value":"', gWP(tokenId)[13], '"}'));
        traits[21] = string(abi.encodePacked('{"trait_type":"World #15","value":"', gWP(tokenId)[14], '"}'));

        // string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2], ',', traits[3], ',', traits[4], ',', traits[5], ',', traits[6], ',', traits[7], ',', traits[8], ','));
        // attributes = string(abi.encodePacked(attributes, traits[9], ',', traits[10], ',', traits[11], ',', traits[12], ',', traits[13], ',', traits[14], ',', traits[15], ',', traits[16], ','));
        // attributes = string(abi.encodePacked(attributes, traits[17], ',', traits[18], ',', traits[19], ',', traits[20], ',', traits[21]));

        string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2], ',', traits[3], ',', traits[4], ',', traits[5], ',', traits[6], ',', traits[7], ','));
        attributes = string(abi.encodePacked(attributes, traits[8], ',', traits[9], ',', traits[10], ',', traits[11], ',', traits[12], ',', traits[13], ',', traits[14], ','));
        attributes = string(abi.encodePacked(attributes, traits[15], ',', traits[16], ',', traits[17], ',', traits[18], ',', traits[19], ',', traits[20], ',', traits[21]));

        return attributes;
    }

    // Token URI

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[49] memory p;
        
        // uint g = gEGR(tokenId);
        // string memory gS = toString(g);

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg"  viewBox="0 0 700 700"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="50" y="50" class="base">';

        p[1] = gHMP(tokenId);

        p[2] = '%</text><text x="50" y="70" class="base">';

        // p[3] = gS;
        p[3] = gEGR(tokenId);

        p[4] = '</text><text x="50" y="90" class="base">';

        p[5] = gLYT(tokenId);

        p[6] = '</text><text x="50" y="130" class="base">';

        p[7] = gB(tokenId)[0];

        p[8] = '</text><text x="50" y="150" class="base">';

        p[9] = gB(tokenId)[1];

        p[10] = '</text><text x="50" y="170" class="base">';

        p[11] = gB(tokenId)[2];

        p[12] = '</text><text x="50" y="190" class="base">';

        p[13] = gB(tokenId)[3];

        p[14] = '</text><text x="50" y="210" class="base">';

        p[15] = gB(tokenId)[4];

        p[16] = '</text><text x="50" y="250" class="base">';

        p[17] = gWP(tokenId)[0];

        p[18] = '</text><text x="50" y="270" class="base">';

        p[19] = gWP(tokenId)[1];

        p[20] = '</text><text x="50" y="290" class="base">';

        p[21] = gWP(tokenId)[2];

        p[22] = '</text><text x="50" y="310" class="base">';

        p[23] = gWP(tokenId)[3];

        p[24] = '</text><text x="50" y="330" class="base">';

        p[25] = gWP(tokenId)[4];

        p[26] = '</text><text x="50" y="350" class="base">';

        p[27] = gWP(tokenId)[5];

        p[28] = '</text><text x="50" y="370" class="base">';

        p[29] = gWP(tokenId)[6];

        p[30] = '</text><text x="50" y="390" class="base">';

        p[31] = gWP(tokenId)[7];

        p[32] = '</text><text x="50" y="410" class="base">';

        p[33] = gWP(tokenId)[8];

        p[34] = '</text><text x="50" y="430" class="base">';

        p[35] = gWP(tokenId)[9];

        p[36] = '</text><text x="50" y="450" class="base">';

        p[37] = gWP(tokenId)[10];

        p[38] = '</text><text x="50" y="470" class="base">';

        p[39] = gWP(tokenId)[11];

        p[40] = '</text><text x="50" y="490" class="base">';

        p[41] = gWP(tokenId)[12];

        p[42] = '</text><text x="50" y="510" class="base">';

        p[43] = gWP(tokenId)[13];

        p[44] = '</text><text x="50" y="530" class="base">';

        p[45] = gWP(tokenId)[14];

        p[46] = '</text><text x="650" y="650" class="base">';

        p[47] = insertBackpack();

        p[48] = '</text></svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]));
        o = string(abi.encodePacked(o, p[9], p[10], p[11], p[12], p[13], p[14], p[15], p[16]));
        o = string(abi.encodePacked(o, p[17], p[18], p[19], p[20], p[21], p[22], p[23], p[24]));
        o = string(abi.encodePacked(o, p[25], p[26], p[27], p[28], p[29], p[30], p[31], p[32]));
        o = string(abi.encodePacked(o, p[33], p[34], p[35], p[36], p[37], p[38], p[39], p[40]));
        o = string(abi.encodePacked(o, p[41], p[42], p[43], p[44], p[45], p[46], p[47], p[48]));

        // string memory name = string(abi.encodePacked("Intergalactic Backpack #', toString(tokenId) '"));
        // string memory description = "A space adventure generated on the Ethereum blockchain.";
        // string memory image = string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(o))));
        // string memory json = string(abi.encodePacked('{"name": "', name, '", "description": "', description, '", "image": "', image, '", "attributes": [', makeAttributes(tokenId), ']}'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Intergalactic Backpack #', toString(tokenId), '", "description": "A space adventure generated on the Ethereum blockchain.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
        o = string(abi.encodePacked('data:application/json;base64,', json));

        return o;
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