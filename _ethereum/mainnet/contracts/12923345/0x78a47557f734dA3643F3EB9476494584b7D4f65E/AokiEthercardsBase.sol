// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";

import "./ERC721CreatorExtensionApproveTransfer.sol";


import "./ERC721OwnerEnumerableSingleCreatorExtension.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./ERC165.sol";

contract AokiEthercardsBase is AdminControl, ICreatorExtensionTokenURI, ERC721OwnerEnumerableSingleCreatorExtension {
    using Strings for uint256;

    bool    private _active;
    string  private _endpoint;

    // Mapping of tokenId to series
    mapping(uint256 => uint256) public tokenSeries;
    // Mapping of tokenId to index
    mapping(uint256 => uint256) private _tokenIndex;

    // Series info: _series is whether or not it has been created, _seriesPrefix is the path prefix for the series uri, _seriesCount is the total count of the series
    mapping(uint256 => bool)    private _series;
    mapping(uint256 => string)  public seriesPrefix;
    mapping(uint256 => uint256) private _seriesCount;

    uint256                     public  nextSeries = 1;

    constructor(address creator_) ERC721OwnerEnumerableSingleCreatorExtension(creator_)  { }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165, ERC721CreatorExtensionApproveTransfer) returns (bool) {
        return interfaceId == 
            type(ICreatorExtensionTokenURI).interfaceId || 
            AdminControl.supportsInterface(interfaceId) ||
            ERC721CreatorExtensionApproveTransfer.supportsInterface(interfaceId);
    }

    function activate() public adminRequired {
        require(!_active, "Already active");
        IERC721CreatorCore(_creator).setApproveTransferExtension(true);
        _active = true;
        _endpoint = 'https://api.ether.cards/';
    }

    function updateEndpoint(string calldata endpoint) public adminRequired {
        _endpoint = endpoint;
    }

    function updateSeriesPrefix(uint256 seriesNumber, string calldata prefix) public adminRequired {
        require(_series[seriesNumber], "Series not created");
        seriesPrefix[seriesNumber] = prefix;
    }

    function createNewSeries(string memory prefix) public adminRequired {
        uint256 seriesNumber = nextSeries++;
        require(!_series[seriesNumber], "Series already created");
        _series[seriesNumber] = true;
        seriesPrefix[seriesNumber] = prefix;
    }

    function mintSeries(uint256 seriesNumber, uint256 count, address recipient) public adminRequired  {
        require(_active, "Inactive");
        require(_series[seriesNumber], "Series not created");
        uint256 seriesCount = _seriesCount[seriesNumber];
        for (uint i = 0; i < count; i++) {
            uint256 tokenId = IERC721CreatorCore(_creator).mintExtension(recipient);
            tokenSeries[tokenId] = seriesNumber;
            _tokenIndex[tokenId] = seriesCount + i + 1;
        }
        _seriesCount[seriesNumber] += count;
    }
    
    // tokenURI extension
    function tokenURI(address creator, uint256 tokenId) public view override returns (string memory) {
        require(creator == _creator && _tokenIndex[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked(_endpoint, seriesPrefix[tokenSeries[tokenId]], _tokenIndex[tokenId].toString()));
    }    


}
