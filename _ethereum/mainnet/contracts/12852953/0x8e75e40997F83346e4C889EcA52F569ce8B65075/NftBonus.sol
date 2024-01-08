/*
 * NFT Bonus
 *
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract NftBonus is Ownable {
    using SafeERC20 for IERC20;

    /// @notice A record of claimed rewards by tokenId
    mapping(uint256 => uint256) public claimed;

    /// @notice Array of nft collections
    address[] public collections;

    /// @notice Left end of the tokenId range (min)
    uint256 public tokenIdFrom;

    /// @notice Right end of the tokenId range (max)
    uint256 public tokenIdTo;

    /// @notice Left end of the reward range (min)
    uint256 public minReward;

    /// @notice Right end of the reward range (max)
    uint256 public maxReward;

    /// @notice Reward token
    IERC20 public rewardToken;

    /// @notice An event that is emitted when an account claim reward for its NFT
    event Claim(
        address indexed nftCollection,
        uint256 tokenId,
        address indexed nftOwner,
        uint256 reward
    );

    /// @notice An event that is emitted when the owner set tokenId range
    event SetTokenIdRange(uint256 tokenIdFrom, uint256 tokenIdTo);

    /// @notice An event that is emitted when the owner set reward range
    event SetRewardRange(uint256 minReward, uint256 maxReward);

    /// @notice An event that is emitted when the owner set a new nft collection
    event SetNewCollection(address nftCollection);

    /// @notice An event that is emitted when the owner replace collection
    event UpdateCollection(
        uint256 index,
        address prevCollection,
        address newCollection
    );

    /// @notice An event that is emitted when the owner withdraw tokens
    event WithdrawTokens(IERC20 token, uint256 amount);


    constructor(
        address _nftCollection,
        uint256 _minReward,
        uint256 _maxReward,
        uint256 _tokenIdFrom,
        uint256 _tokenIdTo,
        IERC20 _rewardToken
    ) {
        require(_minReward <= _maxReward, "constructor: invalid reward range");
        require(_tokenIdFrom <= _tokenIdTo, "constructor: invalid tokenId range");

        collections.push(_nftCollection);

        minReward = _minReward;
        maxReward = _maxReward;

        tokenIdFrom = _tokenIdFrom;
        tokenIdTo = _tokenIdTo;

        rewardToken = _rewardToken;
    }


    /**
     * @notice Claim random reward
     * @param _tokenId - msg.sender's nft id
     */
    function claim(uint256 _tokenId) external virtual {
        require(
            claimed[_tokenId] == 0,
            "claim: reward has already been received"
        );
        require(
            _tokenId >= tokenIdFrom && _tokenId <= tokenIdTo,
            "claim: tokenId out of range"
        );

        address sender = msg.sender;

        address owner;
        address nftCollection;

        // gas safe - max 10 iterations
        for (uint256 i = 0; i < collections.length; i++) {
            try IERC721(collections[i]).ownerOf(_tokenId) returns (
                address curOwner
            ) {
                if (curOwner == sender) {
                    owner = curOwner;
                    nftCollection = collections[i];
                    break;
                }
            } catch {
                continue;
            }
        }
        require(owner == sender, "claim: caller is not the NFT owner");

        uint256 amountReward = 0;
        if (_random(0, 1) == 1) {
            amountReward = _random(minReward, maxReward);
            claimed[_tokenId] = amountReward;
            rewardToken.safeTransfer(sender, amountReward);
        } else {
            claimed[_tokenId] = type(uint256).max;
        }

        emit Claim(nftCollection, _tokenId, sender, amountReward);
    }


    // ** ONLY OWNER functions **

    /**
     * @notice Set a new NFT collection
     * @param _nftCollection - nft collection address
     */
    function setNewCollection(address _nftCollection) external onlyOwner {
        require(
            collections.length < 10,
            "setNewCollection: collections length must be less than 10"
        );
        collections.push(_nftCollection);

        emit SetNewCollection(_nftCollection);
    }

    /**
     * @notice Replace nft collection with a new collection
     * @param _index - index of current nft collection
     * @param _nftCollection - nft collection address
     */
    function updateCollection(uint256 _index, address _nftCollection) external onlyOwner {
        address prevCollection = collections[_index];
        collections[_index] = _nftCollection;

        emit UpdateCollection(_index, prevCollection, _nftCollection);
    }

    /**
     * @notice Set a new tokenId range
     * @param _tokenIdFrom - left end of the tokenId range (min)
     * @param _tokenIdTo - right end of the tokenId range (max)
     */
    function setTokenIdRange(uint256 _tokenIdFrom, uint256 _tokenIdTo) external onlyOwner {
        require(
            _tokenIdFrom <= _tokenIdTo,
            "setTokenIdRange: invalid tokenId range"
        );

        tokenIdFrom = _tokenIdFrom;
        tokenIdTo = _tokenIdTo;

        emit SetTokenIdRange(_tokenIdFrom, _tokenIdTo);
    }

    /**
     * @notice Set a new reward range
     * @param _minReward - left end of the reward range (min)
     * @param _maxReward - right end of the reward range (max)
     */
    function setRewardRange(uint256 _minReward, uint256 _maxReward) external onlyOwner {
        require(
            _minReward <= _maxReward,
            "setRewardRange: invalid reward range"
        );

        minReward = _minReward;
        maxReward = _maxReward;

        emit SetRewardRange(_minReward, _maxReward);
    }

    /**
     * @notice Withdraw tokens to owner
     */
    function withdraw(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(owner(), _amount);

        emit WithdrawTokens(_token, _amount);
    }


    // ** INTERNAL functions **

    /// @dev Generate pseudorandom number
    function _random(uint256 _min, uint256 _max) internal view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encode(block.difficulty, block.timestamp)));
        return _min + randomHash % (_max - _min + 1);
    }
}
