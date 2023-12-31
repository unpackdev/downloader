// SPDX-License-Identifier: MIT
// Zynga Web3 Contracts v1.0.0

pragma solidity ^0.8.19;

import "./ERC721Upgradeable.sol";

/**
 * @dev To reduce smart contract size & gas usages, we used custom errors rather than using require.
 */
error CantTransferStakedTokens();
error TokenIsAlreadyStaked();
error OnlyOwnerCanStake();
error TokenIsNotStaked();
error OnlyOwnerCanUnstake();

/**
 * @dev This is an extension of {ERC721} that introduces efficient staking and unstaking
 * functionality to the contract itself. Rather than traditional staking where users send
 * their assets to a custodial wallet / contract, assets here are not transferred to another
 * wallet / contract and only process being done is emiting {Transfer} event on stake and
 * flag the asset as staked. For outside world, we also override functions like balanceOf
 * and ownerOf to make assets look like they are under ownership of the NFT contract.
 */
abstract contract ERC721zUpgradeable is ERC721Upgradeable {
    /**
     * @dev Initializes the contract. Created for future use.
     */
    function __ERC721z_init() internal onlyInitializing {
    }

    function __ERC721z_init_unchained() internal onlyInitializing {
    }

    // Mapping for storing number of staked tokens of users
    mapping(address => uint256) internal _walletToStakedToken;

    // Mapping for storing stake owner of the staked asset
    mapping(uint256 => address) internal _tokenIdToStakeOwner;

    // Field to store total staked assets, used for balanceOf calculation
    uint256 internal _totalStakedTokens;

    /**
     * @dev Overridden _beforeTokenTransfer function to prevent users or the contract itself from transferring staked assets.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 /*batchSize*/
    ) internal virtual override {
        if (_tokenIdToStakeOwner[tokenId] != address(0))
            revert CantTransferStakedTokens();

        super._beforeTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Overridden ownerOf function to return owner as contract address for staked assets.
     */
    function ownerOf(uint256 tokenId) public view virtual override (ERC721Upgradeable) returns (address) {
        if (_tokenIdToStakeOwner[tokenId] != address(0)) {
            return address(this);
        }

        return super.ownerOf(tokenId);
    }

    /**
     * @dev Overridden balanceOf function to return balance of given address considering staked asset data.
     */
    function balanceOf(address owner) public view virtual override (ERC721Upgradeable) returns (uint256) {
        if(owner == address(this)) {
            return _totalStakedTokens;
        }
            
        return super.balanceOf(owner) - _walletToStakedToken[owner];
    }

    /**
     * @dev Internal function to stake given token ID
     * @param tokenId token ID of the asset that is asked to be staked
     * @param user user that wants to stake given token ID
     *
     * Logic of this function is simple. We set stake owner of given token ID as sender, and increment
     * number of staked tokens of that address. Total staked token counter is also incremented.
     * The last but not least, we emit {Transfer} event to let outside world know that the given
     * token ID is transferred to this contract. 
     *
     * CONSTRAINTS:
     * 1) Given token ID should not be staked beforehand
     * 2) User should be the owner of the given token ID
     */
    function _stake(uint256 tokenId, address user) internal virtual {
        if (_tokenIdToStakeOwner[tokenId] != address(0))
            revert TokenIsAlreadyStaked();

        if (super.ownerOf(tokenId) != user)
            revert OnlyOwnerCanStake();

        _tokenIdToStakeOwner[tokenId] = user;

        unchecked {
            ++_walletToStakedToken[user];
            ++_totalStakedTokens;
        }

        emit Transfer(user, address(this), tokenId);
    }

    /**
     * @dev Internal function to unstake given token ID
     * @param tokenId token ID of the asset that is asked to be unstaked
     * @param user user that wants to unstake given token ID
     *
     * Logic of this function is very similar to stake function, it is basically reverse of stake.
     * We set stake owner for the given token to zero address, and decrement staked token number
     * of the sender by one, as well as total staked token counter. A {Transfer} emission is also
     * triggered to let outside world know that the asset now transferred back to the actual owner.
     *
     * CONSTRAINTS:
     * 1) Given token ID should have been staked beforehand
     * 2) User should be the stake owner of given token ID
     */
    function _unstake(uint256 tokenId, address user) internal virtual {
        if (ownerOf(tokenId) != address(this))
            revert TokenIsNotStaked();

        if (_tokenIdToStakeOwner[tokenId] != user)
            revert OnlyOwnerCanUnstake();

        delete _tokenIdToStakeOwner[tokenId];

        unchecked {
            --_walletToStakedToken[user];
            --_totalStakedTokens;
        }

        emit Transfer(address(this), user, tokenId);
    }


    /**
     * @dev Internal function to stake all of the given token IDs
     * @param tokenIds token ID array of the assets that is asked to be staked
     * @param user user that wants to stake given token IDs
     *
     * This function's logic is very similar to stake function. The only difference here is, stake
     * data update on contract's storage is made for all the given token IDs instead of for one of them.
     * The reason we don't call stake function in a for loop is to update walletToStakedToken map and
     * totalStakedToken fields only once for the sake of efficiency.
     *
     * CONSTRAINTS:
     * 1) Given token IDs should not be staked beforehand
     * 2) User should be the owner of the given token IDs
     */
    function _stakeMultiple(uint256[] memory tokenIds, address user) internal virtual {
        uint256 length = tokenIds.length;

        for(uint256 i = 0; i < length;) {
            if (_tokenIdToStakeOwner[tokenIds[i]] != address(0))
                revert TokenIsAlreadyStaked();

            if (super.ownerOf(tokenIds[i]) != user)
                revert OnlyOwnerCanStake();

            _tokenIdToStakeOwner[tokenIds[i]] = user;

            emit Transfer(user, address(this), tokenIds[i]);

            unchecked {
                i++;
            }
        }

        unchecked {
            _walletToStakedToken[user] += length;
            _totalStakedTokens += length;
        }
    }

    /**
     * @dev Internal function to unstake given token ID
     * @param tokenIds token ID array of the asset that is asked to be unstaked
     * @param user user that wants to unstake given token IDs
     *
     * This function's logic is very similar to unstake function. The only difference here is, stake
     * data update on contract's storage is made for all the given token IDs instead of for one of them.
     * The reason we don't call unstake function in a for loop is to update walletToStakedToken map and
     * totalStakedToken fields only once for the sake of efficiency.
     *
     * CONSTRAINTS:
     * 1) Given token ID should have been staked beforehand
     * 2) User should be the stake owner of given token ID
     */
    function _unstakeMultiple(uint256[] memory tokenIds, address user) internal virtual {
        uint256 length = tokenIds.length;

        for(uint256 i = 0; i < length;) {
            if (ownerOf(tokenIds[i]) != address(this))
                revert TokenIsNotStaked();

            if (_tokenIdToStakeOwner[tokenIds[i]] != user)
                revert OnlyOwnerCanUnstake();

            delete _tokenIdToStakeOwner[tokenIds[i]];

            emit Transfer(address(this), user, tokenIds[i]);

            unchecked {
                i++;
            }
        }

        unchecked {
            _walletToStakedToken[user] -= length;
            _totalStakedTokens -= length;
        }
    }
}