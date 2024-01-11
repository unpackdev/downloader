// SPDX-License-Identifier: MIT

//       ██╗░░██╗███╗░░██╗██╗░██████╗░██╗░░██╗████████╗░██████╗  ░██████╗░░█████╗░███╗░░░███╗███████╗       //
//       ██║░██╔╝████╗░██║██║██╔════╝░██║░░██║╚══██╔══╝██╔════╝  ██╔════╝░██╔══██╗████╗░████║██╔════╝       //
//       █████═╝░██╔██╗██║██║██║░░██╗░███████║░░░██║░░░╚█████╗░  ██║░░██╗░███████║██╔████╔██║█████╗░░       //
//       ██╔═██╗░██║╚████║██║██║░░╚██╗██╔══██║░░░██║░░░░╚═══██╗  ██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░       //
//       ██║░╚██╗██║░╚███║██║╚██████╔╝██║░░██║░░░██║░░░██████╔╝  ╚██████╔╝██║░░██║██║░╚═╝░██║███████╗       //
//       ╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═════╝░  ░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝       //

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

interface IKnightsGame {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract KGVX is ERC721Enumerable, Ownable {
    address public kgAddress;
    string public baseURI;

    constructor() ERC721("KnightsGameVoxel", "KGVX") {
        baseURI = "https://viewer.knights.game/api/knight/";
        kgAddress = 0xeD4Ca345536F4617916dC00368B291e0CC4A7876;
    }

    function isExists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function claim(uint256[] memory tokenIds) external {
        require(tokenIds.length <= 50, "Limit Reached!");
        IKnightsGame knights = IKnightsGame(kgAddress);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 knightsId = tokenIds[i];

            if (
                knights.ownerOf(knightsId) == msg.sender && !_exists(knightsId)
            ) {
                _safeMint(msg.sender, knightsId);
            }
        }
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }
}
