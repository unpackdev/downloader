// SPDX-License-Identifier: MIT

// ████████ ██   ██ ███████      ██████   █████  ████████ ███████ ██   ██ ███████ ███████ ██████  ███████ ██████
//    ██    ██   ██ ██          ██       ██   ██    ██    ██      ██  ██  ██      ██      ██   ██ ██      ██   ██
//    ██    ███████ █████       ██   ███ ███████    ██    █████   █████   █████   █████   ██████  █████   ██████
//    ██    ██   ██ ██          ██    ██ ██   ██    ██    ██      ██  ██  ██      ██      ██      ██      ██   ██
//    ██    ██   ██ ███████      ██████  ██   ██    ██    ███████ ██   ██ ███████ ███████ ██      ███████ ██   ██

pragma solidity 0.8.12;

import "./ERC721.sol";

contract GateKeeper is ERC721 {
    uint256 public totalSupply = 1;

    constructor() ERC721("GateKeeper", "GK") {
        _safeMint(msg.sender, 0);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Nonexistent");
        return "https://api.jsonbin.io/b/6219525f24f17933e49f58df";
    }
}
