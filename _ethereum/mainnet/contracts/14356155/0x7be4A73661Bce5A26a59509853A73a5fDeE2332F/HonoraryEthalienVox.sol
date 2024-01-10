// SPDX-License-Identifier: MIT
//
// ETHALIEN VOX - HONORARY
/*
 *       |\/\/|
 *    _.,|____|,._
 *   / _        _ \
 *  / / o\    /o \ \
 *  \ \___\  /___/ /
 *   \__        __/
 *      \  ''  /
 *       \\__//
 *        '..'
 *
 * ASTERIA LABS
 * @Danny_One_
 *
 */

import "./ERC721_minimal.sol";

pragma solidity ^0.8.0;

contract HonoraryEthalienVox is ERC721Enumerable, Ownable, nonReentrant {
    uint256 public constant MAX_SUPPLY = 1000;

    constructor() ERC721("Honorary Ethalien Vox", "HVAlien") {}

    function mintTo(address receiver_, uint256 mintAmount_) public onlyOwner {
        uint256 supply = totalSupply();

        require(
            supply + mintAmount_ < MAX_SUPPLY + 1,
            "max NFT limit exceeded"
        );

        unchecked {
            for (uint256 i = 0; i < mintAmount_; i++) {
                _safeMint(receiver_, supply + i);
            }
        }
    }

    // ONLY OWNER FUNCTIONS

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }
}
