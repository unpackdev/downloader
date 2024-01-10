//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ERC721A.sol";

abstract contract ERC721aNFT is Ownable, ERC721A {
    using SafeMath for uint256;
    string internal _baseTokenURI;

    function _baseMint(uint256 quantity) internal {
        // mint the token
        _baseMint(msg.sender, quantity);
    }

    function _baseMint(address _address, uint256 quantity) internal {
        // mint the token to target address
        if ( quantity > 4) {
            for (uint256 i = 0; i < quantity; i++) {
                _safeMint(_address, 1);
            }
        } else {
             _safeMint(_address, quantity);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

         
        return
            bytes(_baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        _baseTokenURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function updateTokenURI(string memory _tokenURI) external onlyOwner {
        _baseTokenURI = _tokenURI;
    }


}
