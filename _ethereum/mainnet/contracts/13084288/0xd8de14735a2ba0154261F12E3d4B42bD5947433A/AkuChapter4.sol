// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * Aku - Chapter 4
 * An airdrop for Chapter 1, 2, 3 complete set holders.
 */
contract AkuChapter4 is Ownable, ERC165, ICreatorExtensionTokenURI {

    using Strings for uint256;

    address private _creator;
    uint16 private _minted;
    bool private _finalized;
    mapping(uint256 => uint16) _tokenEdition;

    constructor(address creator) {
        _creator = creator;
        _finalized = false;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _tokenEdition[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked('data:application/json;utf8,{"name":"Aku Chapter IV: Aku x Ady #',uint256(_tokenEdition[tokenId]).toString(), _finalized ? '/' : '', _finalized ? uint256(_minted).toString() : '','","created_by":"Micah Johnson","description":"Chapter IV provides the first real clues into the background of the newest character in the Aku story, Ady. Right before Chapter III ends, we see Aku transport to a vibrant new world we\'ve never seen before. It turns out, this is the world that Ady lives in! Right away it\'s clear that Ady is a vibrant and strong character and only time will tell where their journey will take them.","image":"https://arweave.net/ybPJWdvcAXL_l6dNs3rXai9tptruCSuCnfChm-xU0FY","image_url":"https://arweave.net/ybPJWdvcAXL_l6dNs3rXai9tptruCSuCnfChm-xU0FY","image_details":{"bytes":7067169,"format":"PNG","sha256":"0fd90713aecfe89aac4007287df08751f5831b61520f9c5ebaaaf3062980d459","width":3840,"height":2160},"animation":"https://arweave.net/tP5VF3ULRE1n2hjd6ST3ZnChsYJiTyZ4YTr-lKByc54","animation_url":"https://arweave.net/tP5VF3ULRE1n2hjd6ST3ZnChsYJiTyZ4YTr-lKByc54","animation_details":{"bytes":68846166,"format":"MP4","duration":55,"sha256":"e28c256aa0ae8f3595514747496bf46191a44f2ca37749f64c34790acb380cda","width":3840,"height":2160,"codecs":["H.264","AAC"]},"attributes":[{"trait_type":"Artist","value":"Micah Johnson"},{"trait_type":"Chapter","value":"IV"},{"trait_type":"Collection","value":"Aku"},{"trait_type":"Music","value":"Miami by Valee feat. Pusha T"}]}'));
    }

    function mint(address[] calldata receivers) external onlyOwner {
        require(!_finalized, "Already finalized");
        require(_minted+receivers.length <= 570, "Maximum of 570 available complete sets");
        for (uint i = 0; i < receivers.length; i++) {
            _minted += 1;
            _tokenEdition[IERC721CreatorCore(_creator).mintExtension(receivers[i])] = _minted;
        }
    }

    function finalize() external onlyOwner {
        require(!_finalized, "Already finalized");
        _finalized = true;
    }
}