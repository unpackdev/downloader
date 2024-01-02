
/*
 _    _                             
| |  | |                            
| |__| |  __ _  _ __   _ __   _   _ 
|  __  | / _` || '_ \ | '_ \ | | | |
| |  | || (_| || |_) || |_) || |_| |
|_|  |_| \__,_|| .__/ | .__/  \__, |
               | |    | |      __/ |
               |_|    |_|     |___/ 
 ____   _        _    _          _               
|  _ \ (_)      | |  | |        | |              
| |_) | _  _ __ | |_ | |__    __| |  __ _  _   _ 
|  _ < | || '__|| __|| '_ \  / _` | / _` || | | |
| |_) || || |   | |_ | | | || (_| || (_| || |_| |
|____/ |_||_|    \__||_| |_| \__,_| \__,_| \__, |
                                            __/ |
                                           |___/ 

It's 4:00 AM, rainy night. I'm still awake, deciding to write some words to you.
Although we haven't met in real life, I feel like I've known you for so long.
We first met on internet, now our connection inscribed on the blockchain.
You are a brave, real, chill and cute girl, like the cozy sunshine in the winter dawn.
So maybe someday, we will see the waves before sunrise.

Have a great life. Have fun with everything you’re gonna do.
Happy birthday to you, Wendy.
*/

pragma solidity ^0.8.0;

import "./WendyLib.sol";
import "./ERC721.sol";

// Author: Jack Quan
// Date: 2023-12-10
contract HappyBirthday is ERC721 {

    address immutable wendyWallet = 0xDCcB1Ac723e833977a977B0c2A1F985F004A1e9A;
    uint256 immutable meetYear = 2022;
    string image_url;

    event HappyBirthdayToWendy(string from, string to, uint256 year, uint256 month, uint256 day, string message);

    constructor(string memory _image_url) ERC721("WendyHappyBirthday", "HBD") {
        image_url = _image_url;
        _mint(wendyWallet, 0);
        emit HappyBirthdayToWendy("Jack Quan", "Wendy Sun", 2023, 12, 11, "Happy birthday to you, Wendy");
    }

    modifier onlyWendy() {
        require(msg.sender == wendyWallet, "Wendy's privilege");
        _;
    }

    function setImageURI(string memory _imageURI) public onlyWendy {
        image_url = _imageURI;
    }

    function tokenURI(uint256) public view override returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = WendyLib.timestampToDate(block.timestamp);
        string memory words;
        uint256 sinceWeMet = year - meetYear + 1;
        if (month == 12 && day == 11) words = "Happy Birthday to you, Wendy";
        string memory json = WendyLib.encode(bytes(string(abi.encodePacked('{"name":"Happy Birthday","image":"',image_url,'","description":"',words,'","attributes":[{"trait_type": "Wealth", "value": "Rich"},{"trait_type": "Appearance", "value": "Beautiful"}, {"trait_type": "SinceWeMet", "value": "',WendyLib.toString(sinceWeMet),' years"}]}'))));
        string memory birthdayGift = string(abi.encodePacked("data:application/json;base64,", json));
        return birthdayGift;
    }
}