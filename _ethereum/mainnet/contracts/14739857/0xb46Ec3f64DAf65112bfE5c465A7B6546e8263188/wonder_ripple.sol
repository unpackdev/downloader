// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  *
  * ██████████████████████████████████████████████████████████████████████████████
  * █▄─█▀▀▀█─▄█─▄▄─█▄─▀█▄─▄█▄─▄▄▀█▄─▄▄─█▄─▄▄▀███▄─▄▄▀█▄─▄█▄─▄▄─█▄─▄▄─█▄─▄███▄─▄▄─█
  * ██─█─█─█─██─██─██─█▄▀─███─██─██─▄█▀██─▄─▄████─▄─▄██─███─▄▄▄██─▄▄▄██─██▀██─▄█▀█
  * ▀▀▄▄▄▀▄▄▄▀▀▄▄▄▄▀▄▄▄▀▀▄▄▀▄▄▄▄▀▀▄▄▄▄▄▀▄▄▀▄▄▀▀▀▄▄▀▄▄▀▄▄▄▀▄▄▄▀▀▀▄▄▄▀▀▀▄▄▄▄▄▀▄▄▄▄▄▀
  * 
  *                                                                      𝐛𝐲 𝐀𝐉 𝐀𝐑𝐓
  * 
*/

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";


contract wonder_ripple is ERC721A, Ownable {
    uint256 MAX_SUPPLY = 101;

    string public baseURI = "ipfs://bafybeid25ttkxjrksg3deab2g3gegfc4kalutticgdsfn2f5sj42ci6w5q/metadata/";

    constructor() ERC721A("wonder_ripple", "wori") {}

    /**
     * @dev Funtion to mint the token using ERC721A smart contract
     */

    function mint(address recipient, uint256 quantity) external payable{
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        require(recipient == owner(), "Only owner can mint the tokens");
        _safeMint(recipient, quantity);
    }

    /**
     * @dev Withdraw contract balance to owner
     */
    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Returns the metedata URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}