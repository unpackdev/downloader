pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

//   __  __                    ___                   _         _                        _     
//  |  \/  | ___   ___  _ __  / _ \ _   _  __ _  ___| | __    / \__      ____ _ _ __ __| |___ 
//  | |\/| |/ _ \ / _ \| '_ \| | | | | | |/ _` |/ __| |/ /   / _ \ \ /\ / / _` | '__/ _` / __|
//  | |  | | (_) | (_) | | | | |_| | |_| | (_| | (__|   <   / ___ \ V  V / (_| | | | (_| \__ \
//  |_|  |_|\___/ \___/|_| |_|\__\_\\__,_|\__,_|\___|_|\_\ /_/   \_\_/\_/ \__,_|_|  \__,_|___/                                                                                         
//
//  Contract by @nft_ved
contract MoonQuackAwards is ERC1155, Ownable {
    //Initialization
    string public name;
    string public symbol;
    mapping(uint256 => string) private _uris;

    constructor() public ERC1155("") {
        name = "MoonQuack Awards";
        symbol = "MQA";
        setTokenURI(
            0,
            "ipfs://QmXaSo6bDg41pfC9DL3WeNc7kPPcaUUmsZeaVR8yhJ27Mx/0.json"
        );
        setTokenURI(
            1,
            "ipfs://QmXaSo6bDg41pfC9DL3WeNc7kPPcaUUmsZeaVR8yhJ27Mx/1.json"
        );

        mint(msg.sender, 0, 15);
        mint(msg.sender, 1, 15);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_uris[tokenId]);
    }

    function setTokenURI(uint256 tokenId, string memory _uri) public onlyOwner {
        _uris[tokenId] = _uri;
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _mint(account, id, amount, "");
    }
}
