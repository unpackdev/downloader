//SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "./Strings.sol";
import "./ERC721A.sol";

contract SummerMoments is ERC721A {

    using Strings for uint256;

    address public owner;

    constructor() ERC721A("Summer Moments", "MOMENT") { owner = msg.sender; } 

    function mintForSummer(address summer_) external {
        require(msg.sender == owner, "SummerMoments: Only owner is able to call");
        require(totalSupply() == 0, "SummerMoments: Minted already");
        owner = summer_;
        _mint(summer_, 576, "", false);
    }

    function _startTokenId() internal pure override returns (uint256) { return 1; }
 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "SummerMoments: URI query for nonexistent token");
        require(ownerOf(tokenId) != owner, "SummerMoments: Summer holds this token");

        return string(abi.encodePacked("https://ipfs.io/ipfs/QmRcQfiQ3vbPDBdEd8a9oD6KEY14ev71H6JePPpBjH2mKR/", tokenId.toString(), ".json"));
    }

}
