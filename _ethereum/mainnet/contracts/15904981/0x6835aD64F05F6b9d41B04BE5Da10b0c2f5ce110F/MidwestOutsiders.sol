//     __  ___________ _       ___________________       
//    /  |/  /  _/ __ \ |     / / ____/ ___/_  __/       
//   / /|_/ // // / / / | /| / / __/  \__ \ / /          
//  / /  / // // /_/ /| |/ |/ / /___ ___/ // /           
// /_/__/_/___/_____/_|__/|__/_____//____//_/_____  _____
//   / __ \/ / / /_  __/ ___//  _/ __ \/ ____/ __ \/ ___/
//  / / / / / / / / /  \__ \ / // / / / __/ / /_/ /\__ \ 
// / /_/ / /_/ / / /  ___/ // // /_/ / /___/ _, _/___/ / 
// \____/\____/ /_/  /____/___/_____/_____/_/ |_|/____/  
                            
// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./ERC721A.sol";
import "./Ownable.sol";

contract MidwestOutsiders is ERC721A, Ownable {
    string private _baseTokenURI;
    bool public mintEnabled = false;
    uint256 public constant MAX_PER_TX = 10;
    uint256 public constant MAX_SUPPLY = 2000;

    constructor() ERC721A("Midwest Outsiders", "MWO") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 quantity) external {
        require(quantity <= MAX_PER_TX, "Quantity exceeds max per transaction.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Mint quantity would exceed max supply.");
        require(mintEnabled, "Mint not yet enabled.");
        require(msg.sender == tx.origin, "No contracts allowed.");
        _mint(msg.sender, quantity);
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }
}
