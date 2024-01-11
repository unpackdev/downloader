//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*

 /$$$$$$$                                            /$$                        /$$       /$$          
| $$__  $$                                          | $$                       | $$      |__/          
| $$  \ $$  /$$$$$$   /$$$$$$$  /$$$$$$  /$$$$$$$  /$$$$$$    /$$$$$$  /$$$$$$ | $$$$$$$  /$$  /$$$$$$$
| $$  | $$ /$$__  $$ /$$_____/ /$$__  $$| $$__  $$|_  $$_/   /$$__  $$|____  $$| $$__  $$| $$ /$$_____/
| $$  | $$| $$$$$$$$| $$      | $$$$$$$$| $$  \ $$  | $$    | $$  \__/ /$$$$$$$| $$  \ $$| $$|  $$$$$$ 
| $$  | $$| $$_____/| $$      | $$_____/| $$  | $$  | $$ /$$| $$      /$$__  $$| $$  | $$| $$ \____  $$
| $$$$$$$/|  $$$$$$$|  $$$$$$$|  $$$$$$$| $$  | $$  |  $$$$/| $$     |  $$$$$$$| $$$$$$$/| $$ /$$$$$$$/
|_______/  \_______/ \_______/ \_______/|__/  |__/   \___/  |__/      \_______/|_______/ |__/|_______/ 
                                                                                                       
*/

import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ERC721A.sol";

contract Decentrabis is ERC721A, Ownable, Pausable {
    using SafeMath for uint256;

    uint public MAX_SUPPLY = 4200;
    string public BASE_URI = "ipfs://Qme3sZwm9jcUVQbJj8uAKHiXC6LvAE9C5QpEGAKR285omN/";
    uint public RESERVE_SUPPLY = 1000;
    
    constructor() ERC721A("Decentrabis", "DCB") {
        reserve(RESERVE_SUPPLY);
    }

    function updateBaseUri(string memory baseUri) public onlyOwner {
        BASE_URI = baseUri;
    }
    
    function update(uint maxSupply, string memory baseUri) public onlyOwner {
        MAX_SUPPLY = maxSupply;
        BASE_URI = baseUri;
    }

    function reserve(uint256 quantity) public onlyOwner {
        reserve(msg.sender, quantity);
    }

    function reserve(address to, uint256 quantity) public onlyOwner {
        require(quantity > 0, "Quantity cannot be zero");
        uint totalMinted = totalSupply();
        require(totalMinted.add(quantity) < MAX_SUPPLY, "No items left to mint");

        _safeMint(to, quantity);
    }

    function batchTransfer(address[] memory toAddrs, uint[] memory tokenIds) external onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++) {
            address to = toAddrs[i];
            uint tokenId = tokenIds[i];
            transferFrom(msg.sender, to, tokenId);
        }
    }

    function mint() external whenNotPaused {
        require(balanceOf(msg.sender) == 0, "Already minted one");
        uint totalMinted = totalSupply();
        require(totalMinted.add(1) < MAX_SUPPLY, "No items left to mint");

        _safeMint(msg.sender, 1);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
}