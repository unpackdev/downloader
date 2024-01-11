// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Andrew Mitchell's Manifold Extension
/// @author: Andrew Mitchell
/// @author: manifold.xyz

import "./IAdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./CreatorExtension.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./SafeMath.sol";

import "./IManifoldERC721Edition.sol";

/**
 * 72 101 108 108 111  87 111 114 108 100 
 * 
 * Andrew Mitchell's custom contract extension.
 * mitchel1.eth, mitchel1.tez
 * Uses the Manifold ERC721 Edition Controller Implementation
 */
contract MitchellsExtension is CreatorExtension, ICreatorExtensionTokenURI, IManifoldERC721Edition, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    struct IndexRange {
        uint256 startIndex;
        uint256 count;
    }

    mapping(address => mapping(uint256 => string)) public _tokenPrefix;
    mapping(address => mapping(uint256 => uint256)) public _maxSupply;
    mapping(address => mapping(uint256 => uint256)) public _price;
    mapping(address => mapping(uint256 => uint256)) public _totalSupply;
    mapping(address => mapping(uint256 => IndexRange[])) public _indexRanges;
    mapping(address => mapping(uint256 => mapping(uint256 => string))) public _scripts;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) _creationDates;
    mapping(address => mapping(uint256 => mapping(uint256 => address))) _creators;

    mapping(address => uint256) public _currentSeries;

    bool public pause = true;

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier creatorAdminRequired(address creator) {
        require(IAdminControl(creator).isAdmin(msg.sender), "Must be owner or admin of creator contract");
        _;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IManifoldERC721Edition).interfaceId ||
               CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IManifoldERC721Edition-totalSupply}.
     */
    function totalSupply(address creator, uint256 series) external view override returns(uint256) {
        return _totalSupply[creator][series];
    }

    /**
     * @dev See {IManifoldERC721Edition-maxSupply}.
     */
    function maxSupply(address creator, uint256 series) external view override returns(uint256) {
        return _maxSupply[creator][series];
    }

    /**
     * @dev See {IManifoldERC721Edition-createSeries}.
     */
    function createSeries(address creator, uint256 maxSupply_, string calldata prefix) external override creatorAdminRequired(creator) returns(uint256) {
        _currentSeries[creator] += 1;
        uint256 series = _currentSeries[creator];
        _maxSupply[creator][series] = maxSupply_;
        _tokenPrefix[creator][series] = prefix;
        emit SeriesCreated(msg.sender, creator, series, maxSupply_);
        return series;
    }

    /**
     * @dev See {IManifoldERC721Edition-latestSeries}.
     */
    function latestSeries(address creator) external view override returns(uint256) {
        return _currentSeries[creator];
    }

    /**
     * See {IManifoldERC721Edition-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(address creator, uint256 series, string calldata prefix) external override creatorAdminRequired(creator) {
        require(series > 0 && series <= _currentSeries[creator], "Invalid series");
        _tokenPrefix[creator][series] = prefix;
    }

     /**
     * Set price of a series
     */
    function setPrice(address creator, uint256 series, uint256 price) external creatorAdminRequired(creator) {
        require(series > 0 && series <= _currentSeries[creator], "Invalid series");
        _price[creator][series] = price;
    }
    
    /**
     * @dev See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        (uint256 series, uint256 index) = _tokenSeriesAndIndex(creator, tokenId);
        return string(abi.encodePacked(_tokenPrefix[creator][series], (index+1).toString()));
    }
    
    /**
     * @dev See {IManifoldERC721Edition-mint}.
     */
    function mint(address creator, uint256 series, address recipient, uint16 count) external override payable {
        require(!pause, "Sale has not started");
        require(count > 0, "Invalid amount requested");
        require(_totalSupply[creator][series]+count <= _maxSupply[creator][series], "Too many requested");
        require(msg.value >=_price[creator][series].mul(count), "Not enough ETH sent");
        uint256[] memory tokenIds = IERC721CreatorCore(creator).mintExtensionBatch(recipient, count);
        
        uint mintIndex = _totalSupply[creator][series];
        for (uint256 i = 0; i < count;) {
            _creators[creator][series][mintIndex] = recipient;
            _creationDates[creator][series][mintIndex] = block.number;
            mintIndex++;
            unchecked{i++;}
        }

        _updateIndexRanges(creator, series, tokenIds[0], count);
    }

    /**
     * @dev See {IManifoldERC721Edition-mint}.
     */
    function mintInternal(address creator, uint256 series, address[] calldata recipients) external override nonReentrant creatorAdminRequired(creator) {
        require(recipients.length > 0, "Invalid amount requested");
        require(_totalSupply[creator][series]+recipients.length <= _maxSupply[creator][series], "Too many requested");
        
        uint mintIndex = _totalSupply[creator][series];
        uint256 startIndex = IERC721CreatorCore(creator).mintExtension(recipients[0]);
        _creators[creator][series][mintIndex] = recipients[0];
        _creationDates[creator][series][mintIndex] = block.number;
        mintIndex ++;
        for (uint256 i = 1; i < recipients.length;) {
            IERC721CreatorCore(creator).mintExtension(recipients[i]);
            _creators[creator][series][mintIndex] = recipients[i];
            _creationDates[creator][series][mintIndex] = block.number;
            mintIndex++;
            unchecked{i++;}
        }
        _updateIndexRanges(creator, series, startIndex, recipients.length);
    }

    /**
     * @dev Update the index ranges, which is used to figure out the index from a tokenId
     */
    function _updateIndexRanges(address creator, uint256 series, uint256 startIndex, uint256 count) internal {
        IndexRange[] storage indexRanges = _indexRanges[creator][series];
        if (indexRanges.length == 0) {
           indexRanges.push(IndexRange(startIndex, count));
        } else {
          IndexRange storage lastIndexRange = indexRanges[indexRanges.length-1];
          if ((lastIndexRange.startIndex + lastIndexRange.count) == startIndex) {
             lastIndexRange.count += count;
          } else {
            indexRanges.push(IndexRange(startIndex, count));
          }
        }
        _totalSupply[creator][series] += count;
    }

    /**
     * @dev Index from tokenId
     */
    function _tokenSeriesAndIndex(address creator, uint256 tokenId) internal view returns(uint256, uint256) {
        require(_currentSeries[creator] > 0, "Invalid token");
        for (uint series=1; series <= _currentSeries[creator]; series++) {
            IndexRange[] memory indexRanges = _indexRanges[creator][series];
            uint256 offset;
            for (uint i = 0; i < indexRanges.length; i++) {
                IndexRange memory currentIndex = indexRanges[i];
                if (tokenId < currentIndex.startIndex) break;
                if (tokenId >= currentIndex.startIndex && tokenId < currentIndex.startIndex + currentIndex.count) {
                   return (series, tokenId - currentIndex.startIndex + offset);
                }
                offset += currentIndex.count;
            }
        }
        revert("Invalid token");
    }

    /**
     * @dev Token Hash used to generate art piece
     */
    function tokenHash(address creator, uint256 series, uint256 tokenId) public view returns (bytes32){
        require(_totalSupply[creator][series] >= tokenId, "Token nonexistent");
        return bytes32(keccak256(abi.encodePacked(address(this), _creationDates[creator][series][tokenId], _creators[creator][series][tokenId], tokenId)));
    }

    /**
     * @dev Pause is used to manage when mints can occur
     */
    function togglePause(address creator) public creatorAdminRequired(creator) {
        pause = !pause;
    }

    function addScriptChunk(address creator, uint256 series, uint256 index, string memory _chunk) public creatorAdminRequired(creator) {
        _scripts[creator][series][index]=_chunk;
    }

    function getScriptChunk(address creator, uint256 series, uint256 index) public view returns (string memory){
        return _scripts[creator][series][index];
    }

    function removeScriptChunk(address creator, uint256 series, uint256 index) public creatorAdminRequired(creator) {
        delete _scripts[creator][series][index];
    }

    function withdrawAll(address creator) public creatorAdminRequired(creator) payable {
        require(payable(msg.sender).send(address(this).balance));
    }
}