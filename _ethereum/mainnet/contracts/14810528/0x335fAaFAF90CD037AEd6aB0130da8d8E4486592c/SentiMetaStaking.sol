// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./ISentiMetaStaking.sol";

contract SentiMetaStaking is Ownable, ISentiMetaStaking {

    // Events
    event Stake(uint8 opType, address indexed owner, address indexed project, uint96 indexed tokenId, uint96 totalStaked);

    // Target NFT contract (OnChainPixels)
    IERC721Enumerable _targetContract;

    /* Stake mapping */
    mapping(address => uint96) _projectAddressToStakedCounts;
    mapping(uint256 => TokenStake) _storageIdToToken;
    mapping(uint96 => uint256) _tokenIdToStorageId;

    /* Approval mapping */
    mapping(address => mapping(address => address)) private _operatorApprovals;

    constructor(address target_){
        _targetContract = IERC721Enumerable(target_);
    }

    // Extensibility function to allow for er-targeting should the OnChainPixels contract ever need to be migrated
    function updateTarget (address target_) external onlyOwner {
        _targetContract = IERC721Enumerable(target_);
    }

    // Extracts an address from a uint256 sotage id
    function _extractProjectAddressFromStorageId(uint256 storageId_) private pure returns (address) {
        return address(uint160((storageId_ >> 96)));
    }

    // Creates a storage ID from an address and index
    function _createStorageId(address projectAddress_, uint256 index_) private pure returns (uint256) {
        return (uint256(uint160(projectAddress_)) << 96) + index_;
    }

    // Stakes at a new index
    function _stake(uint96 tokenId_, address projectAddress_, address owner_) private {
        uint256 newIndex = _projectAddressToStakedCounts[projectAddress_];
        uint256 newStorageId = _createStorageId(projectAddress_, newIndex);

        uint48 timestamp = uint48(block.timestamp);
        _storageIdToToken[newStorageId] = TokenStake({
            tokenId: tokenId_,
            timestamp: timestamp
        });
        _tokenIdToStorageId[tokenId_] = newStorageId;
        _projectAddressToStakedCounts[projectAddress_]++;

        emit Stake(uint8(1), owner_, projectAddress_, tokenId_, _projectAddressToStakedCounts[projectAddress_]);
    }

    // Unstakes, moving last index to deleted index and removing the last enty (allowing reuse of indexes and preventing potential overflow)
    function _unstake(address projectAddress_, uint256 storageId_, uint96 tokenId_, address owner_) private {
        _projectAddressToStakedCounts[projectAddress_]--;
        
        uint256 lastIndex = _projectAddressToStakedCounts[projectAddress_];
        uint256 lastStorageId = _createStorageId(projectAddress_, lastIndex);
        uint96 lastTokenId = _storageIdToToken[lastStorageId].tokenId;

        _storageIdToToken[storageId_] = _storageIdToToken[lastStorageId];
        _tokenIdToStorageId[lastTokenId] = storageId_;
        delete _storageIdToToken[lastStorageId];
        delete _tokenIdToStorageId[tokenId_];

        emit Stake(uint8(0), owner_, projectAddress_, tokenId_, uint96(lastIndex));
    }

    /**
        @dev Stakes a tokenId_ against a projectAddress_
    */
    function stake(uint96 tokenId_, address projectAddress_) public override {
        require(projectAddress_ != address(0), "Project address must not be 0");

        address owner = _targetContract.ownerOf(tokenId_);
        require(owner == msg.sender || isApprovedForProject(projectAddress_, owner, msg.sender), "Must own token or be approved");

        uint256 storageId = _tokenIdToStorageId[tokenId_];

        if(storageId == 0) {
            _stake(tokenId_, projectAddress_, owner);
        }
        else {
            address prevProjectAddress = _extractProjectAddressFromStorageId(storageId);

            require(projectAddress_ != prevProjectAddress, "Already staked");

            _unstake(prevProjectAddress, storageId, tokenId_, owner);

            _stake(tokenId_, projectAddress_,owner);
        }
    }

    /**
        @dev Untakes a tokenId_ from its currently staked project
    */
    function unstake(uint96 tokenId_) public override {
        uint256 storageId = _tokenIdToStorageId[tokenId_];
        require(storageId != 0, "Token not staked");

        address projectAddress = _extractProjectAddressFromStorageId(storageId);

        address owner = _targetContract.ownerOf(tokenId_);
        require(owner == msg.sender || isApprovedForProject(projectAddress, owner, msg.sender), "Must own token or be approved");

        _unstake(projectAddress, storageId, tokenId_, owner);
    }

    /**
        @dev Stakes multiple 
    */
    function stakeMultiple(uint96[] calldata tokenIds_, address[] calldata projectAddresses_) external override {
        require(tokenIds_.length == projectAddresses_.length, "Invalid input lengths");

        for(uint256 i = 0; i < tokenIds_.length; i++) {
            stake(tokenIds_[i], projectAddresses_[i]);
        }
    }

    /**
        @dev Untakes multiple 
    */
    function unstakeMultiple(uint96[] calldata tokenIds_) external override {
        require(tokenIds_.length > 0);

        for(uint256 i = 0; i < tokenIds_.length; i++) {
            unstake(tokenIds_[i]);
        }
    }

    /* APPROVALS */

    /**
        @dev Approves an address to be able to stake and unstake
    */
    function approveForProject(address projectAddress_, address operator_) external {
        _operatorApprovals[msg.sender][projectAddress_] = operator_;
    }

    /**
        @dev Revokes address approval
    */
    function revokeProjectApproval(address projectAddress_) external {
        delete _operatorApprovals[msg.sender][projectAddress_];
    }

    /**
        @dev Returns a boolean indicated whether am address is approved to stake/unstake by an owner
    */
    function isApprovedForProject(address projectAddress_, address owner_, address operator_) public view returns (bool) {
        return (_operatorApprovals[owner_][projectAddress_] == operator_);
    }

    /* VIEW UTILITIES */

    /**
        @dev Gets a count of how many projects are staked against a project
    */
    function getCountByProjectAddress(address projectAddress_) external view override returns (uint256) {
        return _projectAddressToStakedCounts[projectAddress_];
    }

    /**
        @dev Gets a tokenId at index that is staked against a project
    */
    function getTokenIdByProjectAddressAndIndex(address projectAddress_, uint96 index_) external view override returns (uint256) {
        uint256 count = _projectAddressToStakedCounts[projectAddress_];
        require(count > 0, "No tokens staked");
        
        uint256 storageId = _createStorageId(projectAddress_, index_);
        return _storageIdToToken[storageId].tokenId;
    }

    /**
        @dev Get project address that a token is currently staked against
    */
    function getProjectAddressByTokenId(uint96 tokenId_) public view override returns (address) {
        uint256 storageId = _tokenIdToStorageId[tokenId_];
        require(storageId != 0, "Token not staked");

        address projectAddress = _extractProjectAddressFromStorageId(storageId);

        return projectAddress;
    }

    /**
        @dev Get project addresses that an array of tokens are currently staked against
    */
    function getProjectAddressesByTokenIds(uint96[] calldata tokenIds_) external view override returns (address[] memory) {
        address[] memory result = new address[](tokenIds_.length);
        for(uint256 i = 0; i < tokenIds_.length; i++) {
            result[i] = getProjectAddressByTokenId(tokenIds_[i]);
        }

        return result;
    }

    /**
        @dev Returns an array of booleans indicated whether the tokens are currently staked
    */
    function checkTokenIdsStaked(uint96[] calldata tokenIds_) external view override returns (bool[] memory) {
        bool[] memory result = new bool[](tokenIds_.length);
        for(uint256 i = 0; i < tokenIds_.length; i++) {
            result[i] = (_tokenIdToStorageId[tokenIds_[i]] != 0);
        }

        return result;
    }

    /**
        @dev Returns an array of tokenIds that an account currently has staked
    */
    function getStakedTokenIdsOfOwner(address owner_) external view override returns (uint256[] memory) {
        uint256 balance = _targetContract.balanceOf(owner_);

        uint256 count = 0;
        uint256[] memory allTokenIds = new uint256[](balance);  
        for(uint256 i = 0; i < balance; i++) {
            uint256 tokenId = _targetContract.tokenOfOwnerByIndex(owner_, i);
            uint256 storageId = _tokenIdToStorageId[uint96(tokenId)];
            allTokenIds[i] = tokenId;
            if(storageId != 0) {
                count++;
            }
        }

        uint256 tokenCounter = 0;
        uint256[] memory tokenIds = new uint256[](count);  
        for(uint256 i = 0; i < allTokenIds.length; i++) {
            uint256 storageId = _tokenIdToStorageId[uint96(allTokenIds[i])];
            if(storageId != 0) {
                tokenIds[tokenCounter] = allTokenIds[i];
                tokenCounter++;
            }

            if(tokenCounter == count) {
                break;
            }
        }

        return tokenIds;
    }

    /* CONTRACT HELPER METHODS */

    /**
        @dev Returns a boolean indicating whether a token is staked against a particular project,
        needed for wrapper contracts to verufy that a token is staked against 1 or more projects that it approves rewards for
    */
    function checkTokenIdStakedToProject(uint96 tokenId_, address projectAddress_) external view override returns (bool) {
        uint256 storageId = _tokenIdToStorageId[tokenId_];
        if(storageId == 0) {
            return false;
        }

        address projectAddress = _extractProjectAddressFromStorageId(storageId);
        if(projectAddress != projectAddress_) {
            return false;
        }

        return true;
    }

    /**
        @dev Returns the TokenStake instance containing the tokennId and timstamp of when it was staked against the project
        allowing wrapper contracts to calculate the rewards
    */
    function getStakedTokenById(uint96 tokenId_) external view override returns (TokenStake memory) {
        uint256 storageId = _tokenIdToStorageId[tokenId_];
        require(storageId != 0, "Token not staked");

        return _storageIdToToken[storageId];
    }

    /* Only used for unit tests via a wrapper contract but may also be used by other wrapper contracts in the future */
    function getStorageIdByTokenId(uint96 tokenId_) external view returns (uint256) {
        return _tokenIdToStorageId[tokenId_];
    }
}