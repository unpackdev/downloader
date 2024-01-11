//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract comebacksartoshi is ERC721A, Ownable {

    string baseURI;
    mapping(address => bool) wallettracker;
    uint supply = 1337 + 1; // supply 1337

    constructor(string memory baseURI_) ERC721A("come back sartoshi", "comeback") {
        baseURI = baseURI_;
    }

    function mint() external {
        
        require(!wallettracker[msg.sender], "u already minted, mfer");
        require(_totalMinted() + 2 < supply, "exceeds supply, mfer");

        wallettracker[msg.sender] = true;

        _mint(msg.sender, 2);
    }

   function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
   }

   function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
        ) : "";
    }
}