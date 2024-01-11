// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creators: Chiru Labs

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*       ,(@@@@/ ( ((@@@ @      @@@@@@@(     @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@&         @@@@@@ @@@@@@  @@@@@@ @@@@@@  @@@   @@@@@@@@* @@@   *@@@@@@@    @@@@@@@@  @@@@@@@  @@( @@@@@%   @@@@@@@
@@@@ @@@@@@@   #@@@@   &@@@@ .@@@@%* @@@@@@ *@@@@@@@  ,@@@@/   /@@@@  .@@@@ , @@  *  @@@@@    @@  @@@@@@@@@#  @@@@@@@@@  @@@@@@@, @ , @@@@@@@@@@@@@@@@
@@@@   %@@@     @@@@  ( @@@@  @@@@@ @@@@@@@  @@ @@@@@   @@@@  @  %@@@    @@@(  @@*  @  @@@  (  @@  @@@@@@@@@#  @@@@@@@@@      #  @@@@ ,  ( @ @@@@@@@@@@
@@@@  #      %  @@@* @@  @@@      @ @@@@@@@  @@@@@@@   @@@ .@@@  @@@  @   @@  @@@  @@/    @@  @@        %@@#       *@@@   @@   @@@@@@@@@#&*     @@@@@@
@@@@  @@ ,  &@  @@@       @@  @@   @@@@@@@@  @@@@@@@   @@         @@  *@,  (  @@@  @@@@ # @@  @@  .@@@@@@@@@  @@@@@@@@@   @@@   @@@@@@@@@@@@@@@ /@@@@@
@@@@   @@@@@@@  @@  @@@@@  @   @@@  @@@@@@@  @@@@@@@   @@  @@@@@  %@@  @@@    .@@ .@@@@@@@@@  @@  @@@@@@@@@#  @@@@@@@@@   @@@@ . %@@@@@@@@@@@@@ /@@@@@
@@@@   @@@@@@@  @@  @@@@@@  @ *@@@@  @@@@@@  @@@@@@@   @  @@@@@@@  @@  @@@@    @@  @@@@@@@@@  @@  @@@@@@@@@#  @@@@@@@@@@  @@@@@@   @@ @@@@@@@@  @@@@@@
@@@@ @@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@  @,@@@@@@@@@@@@/@@@@@@@@@@@@@ @ @@@@@@@@@  ,(@@@@@@@@@&@@@@@@@@@@@@@        @@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

contract MartianMfers is ERC721A, Ownable {

    uint256 public maxSupply = 8888;

    string private storedBaseURI = "";

    bool public isSaleActive = false;

    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {
        teamMint();
    }

    function setBaseURI(string memory _storedBaseURI) external onlyOwner {
        storedBaseURI = _storedBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return storedBaseURI;
    }

    // Someone needs to start the sale. It's me. Fuck you.
    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function mint() external {
        // You can mint only one per wallet, sneaky fucker.
        require(_numberMinted(msg.sender) < 1);
        // You need to interact directly with the smart contract. Fuck you.
        require(msg.sender == tx.origin);
        // I'm not explaining this to you. Read the code.
        require(isSaleActive);

        require(_totalMinted() < maxSupply);
        
        _mint(msg.sender, 1);
    }

    // We are reserving 888 MMfers
    // We call _mint() multiple times
    // due to the way that ERC721A works.
    // Only called in the constructor.
    function teamMint() internal {

        for(uint256 i = 0; i < 8; i++) {
            _mint(msg.sender, 100);
        }

        _mint(msg.sender, 88);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function getOwnershipOf(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipOf(index);
    }

}

// sha256(id + id)
// c29aa3c0a38440204cb9c7231d3f7eba6324a7d80a76722b8466c3b673448eb8