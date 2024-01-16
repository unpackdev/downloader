//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";
import "./ERC721A.sol";

/// @title Standard ERC721 NFT.
/// @author NitroLeague.
contract NLxTFI is ERC721A, Ownable {
    using Counters for Counters.Counter;
    string private baseURI;
    bool private _isMetaLocked;

    constructor()
        ERC721A("Nitro League x The Flashpoint Initiative", "NLxTFI")
    {}

    function setBaseURI(string memory _baseURI) public onlyOwner {
        require(bytes(_baseURI).length > 0, "baseURI cannot be empty");
        require(_isMetaLocked == false, "contract is locked, cannot modify");

        baseURI = _baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")
            );
    }

    function safeMint(address _to, uint256 _quantity) public onlyOwner {
        require(_quantity > 0, "quantity cannot be zero");
        _mintERC2309(_to, _quantity);
    }

    function bulkMint(address[] memory _to, uint[] memory _quantity)
        public
        onlyOwner
    {
        require(_to.length == _quantity.length, "data inconsistent");

        for (uint256 i = 0; i < _quantity.length; i++) {
            _mintERC2309(_to[i], _quantity[i]);
        }
    }

    function getIsMetaLocked() public view returns (bool isMetaLocked) {
        return _isMetaLocked;
    }

    function lockMetaData() external onlyOwner {
        _isMetaLocked = true;
    }

    function burn(uint tokenId) external {
        _burn(tokenId);
    }
}
