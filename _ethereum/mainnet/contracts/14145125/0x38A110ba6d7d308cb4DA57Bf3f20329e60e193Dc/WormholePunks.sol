//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//      ___           ___           ___           ___           ___           ___                         ___       //
//     /\  \         /\  \         /\  \         /\  \         /\  \         /\  \                       /\__\      //
//    _\:\  \       /::\  \       /::\  \       |::\  \        \:\  \       /::\  \                     /:/ _/_     //
//   /\ \:\  \     /:/\:\  \     /:/\:\__\      |:|:\  \        \:\  \     /:/\:\  \                   /:/ /\__\    //
//  _\:\ \:\  \   /:/  \:\  \   /:/ /:/  /    __|:|\:\  \   ___ /::\  \   /:/  \:\  \   ___     ___   /:/ /:/ _/_   //
// /\ \:\ \:\__\ /:/__/ \:\__\ /:/_/:/__/___ /::::|_\:\__\ /\  /:/\:\__\ /:/__/ \:\__\ /\  \   /\__\ /:/_/:/ /\__\  //
// \:\ \:\/:/  / \:\  \ /:/  / \:\/:::::/  / \:\~~\  \/__/ \:\/:/  \/__/ \:\  \ /:/  / \:\  \ /:/  / \:\/:/ /:/  /  //
//  \:\ \::/  /   \:\  /:/  /   \::/~~/~~~~   \:\  \        \::/__/       \:\  /:/  /   \:\  /:/  /   \::/_/:/  /   //
//   \:\/:/  /     \:\/:/  /     \:\~~\        \:\  \        \:\  \        \:\/:/  /     \:\/:/  /     \:\/:/  /    //
//    \::/  /       \::/  /       \:\__\        \:\__\        \:\__\        \::/  /       \::/  /       \::/  /     //
//     \/__/         \/__/         \/__/         \/__/         \/__/         \/__/         \/__/         \/__/      //
//               ___         ___           ___           ___           ___                                          //
//              /\  \       /\  \         /\  \         /|  |         /\__\                                         //
//             /::\  \      \:\  \        \:\  \       |:|  |        /:/ _/_                                        //
//            /:/\:\__\      \:\  \        \:\  \      |:|  |       /:/ /\  \                                       //
//           /:/ /:/  /  ___  \:\  \   _____\:\  \   __|:|  |      /:/ /::\  \                                      //
//          /:/_/:/  /  /\  \  \:\__\ /::::::::\__\ /\ |:|__|____ /:/_/:/\:\__\                                     //
//          \:\/:/  /   \:\  \ /:/  / \:\~~\~~\/__/ \:\/:::::/__/ \:\/:/ /:/  /                                     //
//           \::/__/     \:\  /:/  /   \:\  \        \::/~~/~      \::/ /:/  /                                      //
//            \:\  \      \:\/:/  /     \:\  \        \:\~~\        \/_/:/  /                                       //
//             \:\__\      \::/  /       \:\__\        \:\__\         /:/  /                                        //
//              \/__/       \/__/         \/__/         \/__/         \/__/                                         //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./Strings.sol";
import "./ERC721EnumerableLite.sol";
import "./Delegated.sol";

contract WormholePunks is ERC721EnumerableLite, Delegated {

    uint256 public PRICE = 0.02 ether;
    uint256 private MINT_LIMIT = 101;
    uint256 private SUPPLY_LIMIT = 10000;
    uint256 private FREE_MINT = 500;
    string private BASE_URI = "";

    address devs = 0x246a3f32C9175deA92a1b86Ad3cC07c7af937A69;

    constructor() ERC721B("Wormhole Punks", "WPUNKS") {
    }

    function mint(uint256 n) public payable {
        uint256 ts = totalSupply();
        require(n < MINT_LIMIT, "100 mints per transaction!");
        require(ts + n < SUPPLY_LIMIT, "No more minting possible!");
        if (ts + n > FREE_MINT) {
            require(PRICE * n <= msg.value, "Ether value low!");
        }
        for (uint256 i = 0; i < n; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw(uint256 p) public onlyDelegates {
        uint256 b = address(this).balance;
        uint256 t = b * p /100;
        payable(devs).transfer(t);
    }

    function setBaseUri(string calldata _baseUri) external onlyDelegates {
        BASE_URI = _baseUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Non-existent token!");
        string memory baseURI = BASE_URI;
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }
}