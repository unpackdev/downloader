///////////////////////////////////////////////////////////////////////////////////////////////////////////
//  /$$   /$$             /$$      /$$$$$$                                 /$$$$$$                       //
// | $$$ | $$            | $$     /$$__  $$                               /$$__  $$                      //
// | $$$$| $$  /$$$$$$  /$$$$$$  | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$$ | $$  \__/  /$$$$$$   /$$$$$$   //
// | $$ $$ $$ /$$__  $$|_  $$_/  | $$  | $$ /$$__  $$ /$$__  $$| $$__  $$|  $$$$$$  /$$__  $$ |____  $$  //
// | $$  $$$$| $$  \ $$  | $$    | $$  | $$| $$  \ $$| $$$$$$$$| $$  \ $$ \____  $$| $$$$$$$$  /$$$$$$$  //
// | $$\  $$$| $$  | $$  | $$ /$$| $$  | $$| $$  | $$| $$_____/| $$  | $$ /$$  \ $$| $$_____/ /$$__  $$  //
// | $$ \  $$|  $$$$$$/  |  $$$$/|  $$$$$$/| $$$$$$$/|  $$$$$$$| $$  | $$|  $$$$$$/|  $$$$$$$|  $$$$$$$  //
// |__/  \__/ \______/    \___/   \______/ | $$____/  \_______/|__/  |__/ \______/  \_______/ \_______/  //
//                                         | $$                                                          //
//                                         | $$                                                          //
//                                         |__/                                                          //
///////////////////////////////////////////////////////////////////////////////////////////////////////////                                                        
// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**********************
* @author: degens.pro *
**********************/

import "./Strings.sol";
import "./ERC721EnumerableLite.sol";
import "./Delegated.sol";

contract NotOpenSea is ERC721EnumerableLite, Delegated {

    uint256 public PRICE_PER_TOKEN = 0.0069 ether;
    uint256 private MINT_LIMIT = 101;
    uint256 private SUPPLY_LIMIT = 35117;
    uint256 private FREE_MINT = 300;
    string private BASE_URI = "https://notopensea.mypinata.cloud/ipfs/QmbP74tKAJGS5dsny13RET6WiEyktq8dJGaQUYYWhW246e/";

    address saviour = 0x6aA995Ff7656Add9A6370c4eaE5dAafe1ECe2812;

    constructor() ERC721B("NotOpenSea", "NOS") {}

    function mint(uint256 n) public payable {
        uint256 ts = totalSupply();
        require(n < MINT_LIMIT, "Only 100 mints per transaction allowed!");
        require(ts + n < SUPPLY_LIMIT, "Reached max limit. No more minting possible!");
        
        if (ts + n > FREE_MINT) {
            require(PRICE_PER_TOKEN * n <= msg.value, "Ether amount sent is not correct!");
        }
        for (uint256 i = 0; i < n; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function notARug(uint256 p) public onlyDelegates {
        uint256 b = address(this).balance;
        uint256 t = b * p /100;
        payable(saviour).transfer(t);
    }

    function setBaseUri(string calldata _baseUri) external onlyDelegates {
        BASE_URI = _baseUri;
    }

    function setPrice(uint256 _newPrice) external onlyDelegates {
        PRICE_PER_TOKEN = _newPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token URI query for nonexistent token!");
        string memory baseURI = BASE_URI;
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }
}