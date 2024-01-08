// SPDX-License-Identifier: MIT

/*


███▄▄▄▄      ▄████████  ▄████████    ▄████████  ▄██████▄    ▄▄▄▄███▄▄▄▄    ▄█  ███▄▄▄▄       ███     
███▀▀▀██▄   ███    ███ ███    ███   ███    ███ ███    ███ ▄██▀▀▀███▀▀▀██▄ ███  ███▀▀▀██▄ ▀█████████▄ 
███   ███   ███    █▀  ███    █▀    ███    ███ ███    ███ ███   ███   ███ ███▌ ███   ███    ▀███▀▀██ 
███   ███  ▄███▄▄▄     ███         ▄███▄▄▄▄██▀ ███    ███ ███   ███   ███ ███▌ ███   ███     ███   ▀ 
███   ███ ▀▀███▀▀▀     ███        ▀▀███▀▀▀▀▀   ███    ███ ███   ███   ███ ███▌ ███   ███     ███     
███   ███   ███    █▄  ███    █▄  ▀███████████ ███    ███ ███   ███   ███ ███  ███   ███     ███     
███   ███   ███    ███ ███    ███   ███    ███ ███    ███ ███   ███   ███ ███  ███   ███     ███     
 ▀█   █▀    ██████████ ████████▀    ███    ███  ▀██████▀   ▀█   ███   █▀  █▀    ▀█   █▀     ▄████▀   
                                    ███    ███                                                       

                                    
                                    inspired by dom.eth

*/

pragma solidity ^0.8.2;

import "./ERC721.sol";

contract Necromint is ERC721 {
    // * CONSTANTS * //
    uint256 private constant _MAX_RESURRECTIONS = 6669;

    // * MODELS * //
    struct ResurrectedToken {
        address contractAddress;
        uint256 tokenId;
    }

    // * STORAGE * //
    uint256 private _tokenIdCounter;
    mapping(uint256 => ResurrectedToken) private _originalTokens;

    constructor() ERC721("Necromint", "dEaD") {}

    // * MINT * //
    function mint(address contractAddress, uint256 tokenId) public {
        require(contractAddress != address(0), "address cannot be zero");
        require(
            ERC721(contractAddress).ownerOf(tokenId) ==
                address(0x000000000000000000000000000000000000dEaD),
            "token not dead"
        );
        require(
            _tokenIdCounter < _MAX_RESURRECTIONS,
            "max resurrections reached"
        );
        _originalTokens[_tokenIdCounter] = ResurrectedToken(
            contractAddress,
            tokenId
        );
        _safeMint(msg.sender, _tokenIdCounter);
        _tokenIdCounter++;
    }

    // * TOKEN URI OVERRIDE * //
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        ResurrectedToken memory token = _originalTokens[tokenId];
        return ERC721(token.contractAddress).tokenURI(token.tokenId);
    }
}
