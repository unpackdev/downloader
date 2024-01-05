// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Ownable.sol";
import "./ERC721Mintable.sol";
import "./Strings.sol";

contract TohokuZunko is
    ERC721Mintable
{
    using Strings for uint256;

    uint256 private totalCount = 0;
    string private _defaultURI;

    event UpdateDefaultURI(string defaultURI);

    constructor() ERC721("Tohoku Zunko and Friends Special Limited Edition NFT", "tZNK") {
        setDefaultURI("https://nftstudio.herokuapp.com/api/metadata/tohokuzunko/");
    }

    function setDefaultURI(string memory defaultURI_) public onlyOperator() {
        _defaultURI = defaultURI_;
        emit UpdateDefaultURI(_defaultURI);
    }

    function tokenURI(uint256 tokenId) virtual public view override returns (string memory) {
        return string(abi.encodePacked(_defaultURI, tokenId.toString()));
    }


    function mint(address to, uint256 tokenId) public override onlyMinter() {
        totalCount++;
        super.mint(to, tokenId);
    }

    function bulkMint(address[] memory _tos, uint256[] memory _tokenIds) public onlyMinter {
        require(_tos.length == _tokenIds.length);
        uint8 i;
        for (i = 0; i < _tos.length; i++) {
          mint(_tos[i], _tokenIds[i]);
        }
    }

    function totalSupply() public view returns (uint256) {
        return totalCount;
    }

}
