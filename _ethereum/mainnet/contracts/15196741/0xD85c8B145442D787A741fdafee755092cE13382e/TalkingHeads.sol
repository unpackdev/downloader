// SPDX-License-Identifier: MIT

/***
 __ _  _  _  _  _  ____   __  ____  ____  ____  ____  _  _
(  / )/ )( \/ )( \(  _ \ /  \(_  _)(_  _)(  __)(  _ \( \/ )
 )  ( ) \/ () \/ ( ) __/(  O ) )(    )(   ) _)  )   / )  /
(__\_)\____/\____/(__)   \__/ (__)  (__) (____)(__\_)(__/
*/

// Contract by @Montana_Wong

pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./Ownable.sol";
import "./IERC165.sol";
import "./ERC2981Collection.sol";

contract TalkingHeads is ERC721ABurnable, ERC2981Collection, Ownable {

    string public baseURI;

    constructor(string memory _baseTokenURI) ERC721A("Talking Heads", "TH") {
        setBaseURI(_baseTokenURI);
        _setRoyalties(0x18866C05Ac6BbdC0e0cB8Fc5E2e9be400aF516c3, 7);
    }

    function fireKiln(uint256 numPieces) external onlyOwner {
        _mint(msg.sender, numPieces);
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981Collection) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981Collection.supportsInterface(interfaceId);
    }
}
