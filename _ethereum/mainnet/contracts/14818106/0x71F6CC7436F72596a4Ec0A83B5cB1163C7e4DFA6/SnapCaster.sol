//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "./ERC721.sol";

contract SnapCaster is ERC721 {
    uint256 lastTokenId = 1;
    mapping(address => uint256) public tokenForUser;

    constructor() ERC721("SnapCaster", "SNAP") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://snapcaster.xyz/stories/";
    }

    function storyEvent() public {
        uint256 tokenId = tokenForUser[msg.sender];
        if (tokenId > 0) {
            emit Transfer(msg.sender, msg.sender, tokenId);
        }
    }

    function mint() public {
        if (tokenForUser[msg.sender] == 0) {
            _safeMint(msg.sender, lastTokenId);
            tokenForUser[msg.sender] = lastTokenId;
            lastTokenId += 1;
        }
    }
}
