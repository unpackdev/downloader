// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC165.sol";

/**
 * NessGraphics - Collectors Key
 */
contract NessGraphicsCollectorsKey is Ownable, ERC165, ICreatorExtensionTokenURI {

    using Strings for uint256;

    address private _creator;
    uint16 private _minted;
    mapping(uint256 => uint16) _tokenEdition;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _tokenEdition[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked('data:application/json;utf8,{"name":"NessGraphics - Collectors Key #',uint256(_tokenEdition[tokenId]).toString(),'","created_by":"NessGraphics","description":"A wise man once said, \\"A very little key will open a very heavy door.\\" Well, this is a set of two little keys, so just imagine what the future may very well bring. As a tribute to current collectors of NessGraphics\' pieces, this is your very own NessGraphics set of keys that will unlock access to NiftyGateway collector\'s only drawings. Use it wisely and know that this is just the first heavy door that can be opened. \\"The stupid mind thinks only in terms of possession. The man of insight thinks of utility.\\"","image":"https://arweave.net/coEVa_ou8ESl1FBoh4vCFKSWCBaTDgHCw0a_mAWHq3M","image_url":"https://arweave.net/coEVa_ou8ESl1FBoh4vCFKSWCBaTDgHCw0a_mAWHq3M","image_details":{"bytes":1040676,"format":"PNG","sha256":"1c2461e2cf9d4218d734f25d6f1f1f77fd6222516975e3654c8569c0e30658ef","width":1080,"height":1080},"animation":"https://arweave.net/ifnRPFugTJ4HljX-Xv7A0vjJRTFQbDooygHMY-x-vT0","animation_url":"https://arweave.net/ifnRPFugTJ4HljX-Xv7A0vjJRTFQbDooygHMY-x-vT0","animation_details":{"bytes":21239186,"format":"MP4","duration":7,"sha256":"0fd81db8573ad61a40eae69772a7160a6c33393c98ae2875f5fd1c387e4fe3a5","width":1080,"height":1080,"codecs":["H.264","AAC"]},"attributes":[{"trait_type":"Artist","value":"NessGraphics"},{"trait_type":"Key Edition","value":"First"}]}'));
    }

    function mint(address[] calldata receivers) external onlyOwner {
        for (uint i = 0; i < receivers.length; i++) {
            _minted += 1;
            _tokenEdition[IERC721CreatorCore(_creator).mintExtension(receivers[i])] = _minted;
        }
    }
}
