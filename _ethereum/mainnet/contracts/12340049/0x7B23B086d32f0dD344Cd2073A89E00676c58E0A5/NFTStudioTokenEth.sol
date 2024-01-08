// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./Ownable.sol";
import "./ERC721Mintable.sol";
import "./HasSecondarySaleFees.sol";
import "./Strings.sol";

contract NFTStudioTokenEth is
    ERC721Mintable,
    HasSecondarySaleFees
{
    using Strings for uint256;

    uint256 private totalCount = 0;
    string private _defaultURI;

    event UpdateDefaultURI(string defaultURI);

    constructor() ERC721("NFTStudio:Token", "STD") {
        setDefaultURI("https://nft-studio.com/api/metadata/");
    }

    function setDefaultURI(string memory defaultURI_) public onlyOperator() {
        _defaultURI = defaultURI_;
        emit UpdateDefaultURI(_defaultURI);
    }

    function tokenURI(uint256 tokenId) virtual public view override returns (string memory) {
        return string(abi.encodePacked(_defaultURI, tokenId.toString()));
    }

    function setDefaultRoyality(address payable[] memory _royaltyAddress, uint256[] memory _royalty) public onlyOwner {
        _setDefaultRoyality(_royaltyAddress, _royalty);
    }

    function setCustomRoyality(
        uint256 _tokenId,
        address payable[] memory _royaltyAddress,
        uint256[] memory _royalty
    ) public onlyOwner {
        _setRoyality(_tokenId, _royaltyAddress, _royalty);
    }

    function setCustomRoyality(
        uint256[] memory _tokenIdList,
        address payable[][] memory _royaltyAddressList,
        uint256[][] memory _royaltyList
    ) public onlyOwner {
        require(
            _tokenIdList.length == _royaltyAddressList.length && _tokenIdList.length == _royaltyList.length,
            "input length must be same"
        );
        for (uint256 i = 0; i < _tokenIdList.length; i++) {
            _setRoyality(_tokenIdList[i], _royaltyAddressList[i], _royaltyList[i]);
        }
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, HasSecondarySaleFees)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
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
