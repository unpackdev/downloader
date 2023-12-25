// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./Metadata.sol";
import "./Util.sol";
import "./Traits.sol";
import "./Data.sol";
import "./Palette.sol";
import "./Background.sol";
import "./Body.sol";
import "./Face.sol";
import "./Motes.sol";
import "./Glints.sol";
import "./Traits.sol";
import "./SVG.sol";

library Render {
    string public constant description =
        "Floating. Hypnotizing. Divine? Bibos are 1111 friendly spirits for your wallet. Join the billions of people who love and adore bibos today.";

    /*//////////////////////////////////////////////////////////////
                                TOKENURI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 _tokenId, bytes32 _seed) internal pure returns (string memory) {
        return
            Metadata.encodeMetadata({
                _tokenId: _tokenId,
                _name: _name(_tokenId),
                _description: description,
                _attributes: Traits.attributes(_seed, _tokenId),
                _backgroundColor: Palette.backgroundFill(_seed, _tokenId),
                _svg: _svg(_seed, _tokenId)
            });
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _svg(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        return
            SVG.element(
                "svg",
                SVG.svgAttributes(),
                Data.defs(),
                Background.render(_seed, _tokenId),
                Body.render(_seed, _tokenId),
                Motes.render(_seed, _tokenId),
                Glints.render(_seed),
                Face.render(_seed)
            );
    }

    function _name(uint256 _tokenId) internal pure returns (string memory) {
        return string.concat("Bibo ", Util.uint256ToString(_tokenId, 4));
    }
}
