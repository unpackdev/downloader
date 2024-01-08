// contracts/BW24.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface IChubbies {
    function ownerOf(uint _tokenId) external view returns (address owner);
    function tokensOfOwner(address _owner) external view returns(uint[] memory);
}

/// [MIT License]
/// @title ChubbiesCollections
/// @author solazy.eth
/// @notice An evergrowing collection of collections for Chubbies (0x1DB61FC42a843baD4D91A2D788789ea4055B8613). 
/// Whether its Chubbies-exlusive or open to public, all Chubbies in this collection will be free to claim with gas fee. 
contract ChubbiesCollections is ERC721Enumerable, Ownable {
    uint public constant MAX_COLLECTION_LIMIT = 10000;
    IChubbies public chubbiesContract;

    mapping(uint => uint) isCollectionSaleOpen; // 0: closed, 1: open for claim, 2: open for public
    mapping(uint => uint) collectionIdToTokenCount;
    mapping(uint => uint) collectionIdToTokenLimit;
    mapping(uint => string) collectionIdToBaseURI;
    mapping(uint => uint) chubbieIdToClaimedCollections;
    mapping(address => uint) addressToClaimedCollections;

    constructor() ERC721("ChubbiesCollections","CHUBC") {}

    /////////////
    // Minting //
    /////////////

    function chubbieClaimN(uint _collectionId, uint _numClaim) public {
        require(isCollectionSaleOpen[_collectionId] > 0, "Collection is not open to claim yet");
        uint currentTokenCount = collectionIdToTokenCount[_collectionId];
        require(currentTokenCount + _numClaim <= getCollectionTokenLimit(_collectionId), "Not enough chubbies remain");

        uint[] memory ownedChubbies = chubbiesContract.tokensOfOwner(msg.sender);
        uint claimed = 0;

        for (uint i = 0; i < ownedChubbies.length; i++) {
            if (isClaimedByChubbie(ownedChubbies[i], _collectionId) == false) {
                _mint(_collectionId, currentTokenCount + claimed, msg.sender);
                setClaimedByChubbie(ownedChubbies[i], _collectionId);
                claimed++;
            }
            if (claimed == _numClaim) {
                break;
            }
        }

        collectionIdToTokenCount[_collectionId] += claimed; 
    }

    function publicAdopt(uint _collectionId) public {
        require(isCollectionSaleOpen[_collectionId] > 1, "Collection is not open for public yet");
        uint currentTokenCount = collectionIdToTokenCount[_collectionId];
        require(currentTokenCount < getCollectionTokenLimit(_collectionId), "Token count has reached max limit");
        require(balanceOf(msg.sender) == 0 || isPublicAdopted(msg.sender, _collectionId) == false, "This wallet has claimed collection");

        _mint(_collectionId, currentTokenCount, msg.sender);
        collectionIdToTokenCount[_collectionId]++;
        setPublicAdopted(msg.sender, _collectionId);
    }

    //////////////////////
    // Helper functions //
    //////////////////////

    function getMappedTokenId(uint _collectionId, uint _tokenId) public pure returns (uint) {
        return _collectionId * MAX_COLLECTION_LIMIT + _tokenId;
    }

    function getCollectionId(uint _mappedTokenId) public pure returns (uint) {
        return _mappedTokenId / MAX_COLLECTION_LIMIT;
    }

    function exists(uint _collectionId, uint _tokenId) external view returns (bool) {
        return _exists((getMappedTokenId(_collectionId, _tokenId)));
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(collectionIdToBaseURI[getCollectionId(_tokenId)], Strings.toString(_tokenId % 10000)));
    }

    function tokensOfOwner(address _owner) external view returns(uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory result = new uint[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    function tokensOfOwnerInCollection(address _owner, uint _collectionId) external view returns (uint256[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory result = new uint[](tokenCount);
        uint resultIndex;
        for (uint i = 0; i < tokenCount; i++) {
            uint mappedTokenId = tokenOfOwnerByIndex(_owner, i);
            if (getCollectionId(mappedTokenId) == _collectionId) {
                result[resultIndex] = mappedTokenId;
                resultIndex++;
            }
        }

        uint[] memory resultPacked = new uint[](resultIndex);
        for (uint i = 0; i < resultIndex; i++) {
            resultPacked[i] = result[i];
        }
        return resultPacked;
    }

    function numEligibleClaims(address _address, uint _collectionId) external view returns (uint) {
        uint[] memory ownedChubbies = chubbiesContract.tokensOfOwner(_address);
        uint numEligible = 0;
        for (uint i = 0; i < ownedChubbies.length; i++) {
            if (isClaimedByChubbie(ownedChubbies[i], _collectionId) == false) {
                numEligible++;
            }
        }
        return numEligible;
    }

    function _mint(uint _collectionId, uint _tokenId, address _sendTo) private {
        _safeMint(_sendTo, getMappedTokenId(_collectionId, _tokenId));
    }

    function getClaimedByChubbie(uint _chubbieId) external view returns (uint) {
        return chubbieIdToClaimedCollections[_chubbieId];
    }

    function isClaimedByChubbie(uint _chubbieId, uint _collectionId) public view returns (bool) {
        return (chubbieIdToClaimedCollections[_chubbieId] & (1 << _collectionId)) > 0;
    }

    function setClaimedByChubbie(uint _chubbieId, uint _collectionId) private {
        chubbieIdToClaimedCollections[_chubbieId] |= (1 << _collectionId);
    }

    function isPublicAdopted(address _address, uint _collectionId) public view returns (bool) {
        return (addressToClaimedCollections[_address] & (1 << _collectionId)) > 0;
    }

    function setPublicAdopted(address _address, uint _collectionId) private {
        addressToClaimedCollections[_address] |= 1 << _collectionId;
    }

    function getCollectionTokenLimit(uint _collectionId) public view returns (uint) {
        return collectionIdToTokenLimit[_collectionId] > 0 ? collectionIdToTokenLimit[_collectionId] : MAX_COLLECTION_LIMIT;
    }

    function getCollectionTokenCount(uint _collectionId) external view returns (uint) {
        return collectionIdToTokenCount[_collectionId];
    }

    /////////////////////
    // Owner functions //
    /////////////////////

    function setChubbieContract(address _address) public onlyOwner {
        chubbiesContract = IChubbies(_address);
    }

    function setCollectionTokenLimit(uint _collectionId, uint _tokenLimit) public onlyOwner {
        collectionIdToTokenLimit[_collectionId] = _tokenLimit;
    }

    function setCollectionBaseURI(uint _collectionId, string memory _baseURI) external onlyOwner {
        collectionIdToBaseURI[_collectionId] = _baseURI;
    }

    function setCollectionSaleOpen(uint _collectionId, uint _state) public onlyOwner {
        isCollectionSaleOpen[_collectionId] = _state;
    }

    function ownerMint(address _sendTo, uint _collectionId, uint _numAirdrop) public onlyOwner {
        uint currentTokenCount = collectionIdToTokenCount[_collectionId];
        require(currentTokenCount + _numAirdrop <= getCollectionTokenLimit(_collectionId), "Not enough chubbies remain");
        for (uint i = 0; i < _numAirdrop; i++) {
            _mint(_collectionId, currentTokenCount + i, _sendTo);
        }
        collectionIdToTokenCount[_collectionId] += _numAirdrop;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        require(address(token) != address(0));
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}