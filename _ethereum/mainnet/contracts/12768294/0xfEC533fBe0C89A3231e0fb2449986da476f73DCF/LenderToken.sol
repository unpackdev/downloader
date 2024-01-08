// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract LenderToken is
    ERC721URIStorage,
    ERC721Enumerable,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public prefix = "http://app.kyoko.finance/ltoken/";

    string public suffix = ".png";

    constructor() ERC721("KyokoLToken", "KL") {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function mint(address player) public onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        string memory _index = uint2str(newItemId);
        string memory _URI = strConcat(prefix, _index, suffix);
        _mint(player, newItemId);
        _setTokenURI(newItemId, _URI);
        return newItemId;
    }

    function burn(uint256 tokenId) public virtual override(ERC721Burnable) {
        super._burn(tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function uint2str(uint256 _i)
        public
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) public pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        string memory ret = new string(_ba.length + _bb.length + _bc.length);
        bytes memory bret = bytes(ret);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) bret[k++] = _bc[i];
        return string(ret);
    }
}
