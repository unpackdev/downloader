// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "ERC1155.sol";
import "Counters.sol";
import "OwnableRoles.sol";
import "LibString.sol";
import "ITraits.sol";
import "ICoins.sol";
import "IShards.sol";

/// @title Prestige Traits for Isekai Meta Faction Wars.
/// @author ItsCuzzo

contract Traits is ITraits, OwnableRoles, ERC1155 {
    using Counters for Counters.Counter;
    using LibString for uint256;

    /// @dev Define `Trait` packed struct.
    struct Trait {
        uint232 supply;
        uint16 burnReq;
        bool claimable;
        mapping(address => bool) claimed;
    }

    Counters.Counter private _counter;

    mapping(uint256 => Trait) private _traits;

    IShards public shards;
    ICoins public coins;

    constructor(
        string memory uri_,
        address shards_,
        address coins_
    ) ERC1155(uri_) {
        _initializeOwner(msg.sender);
        shards = IShards(shards_);
        coins = ICoins(coins_);
    }

    /// @notice Function used to claim a Prestige Trait via burning Shards.
    function burnShardsForTrait(uint256 id) external {
        unchecked {
            if (!_exists(id)) revert NonExistent();
            if (!_traits[id].claimable) revert NotClaimable();
            if (_traits[id].claimed[msg.sender]) revert HasClaimed();

            shards.burn(msg.sender, _traits[id].burnReq);

            _traits[id].claimed[msg.sender] = true;
            ++_traits[id].supply;

            _mint(msg.sender, id, 1, "");
        }
    }

    /// @notice Function used to claim a Prestige Trait for winners.
    /// @param id Prestige Trait identifier.
    function claimTraitWithCoin(uint256 id) external {
        unchecked {
            if (!_exists(id)) revert NonExistent();
            if (!_traits[id].claimable) revert NotClaimable();
            if (_traits[id].claimed[msg.sender]) revert HasClaimed();
            if (!coins.holdsCoin(msg.sender)) revert NoCoin();

            _traits[id].claimed[msg.sender] = true;
            ++_traits[id].supply;

            _mint(msg.sender, id, 1, "");
        }
    }

    /// @notice Function used to add a new Prestige Trait.
    /// @param shardReq Number of shards to burn for the new Prestige Trait.
    function addTrait(uint256 shardReq) external onlyOwner {
        if (shardReq == 0) revert InvalidShards();
        _traits[_counter.current()].burnReq = uint16(shardReq);
        _counter.increment();
    }

    /// @notice Function used to add multiplie new Prestige Traits.
    /// @param shardReqs An array of shards to burn for a new Prestige Trait.
    function addTraits(uint256[] calldata shardReqs) external onlyOwner {
        unchecked {
            if (shardReqs.length == 0) revert InvalidLength();

            uint256 shardReq;

            for (uint256 i = 0; i < shardReqs.length; i++) {
                shardReq = shardReqs[i];

                if (shardReq == 0) revert InvalidShards();

                _traits[_counter.current()].burnReq = uint16(shardReq);
                _counter.increment();
            }
        }
    }

    /// @notice Function used to toggle Prestige Coin claim status.
    /// @param id Prestige Trait identifier.
    function toggleClaim(uint256 id) external onlyOwner {
        if (!_exists(id)) revert NonExistent();
        _traits[id].claimable = !_traits[id].claimable;
    }

    /// @notice Function used to toggle the claimability of many traits at once.
    /// @param ids An array of Prestige Trait identifiers.
    function toggleClaims(uint256[] calldata ids) external onlyOwner {
        unchecked {
            if (ids.length == 0) revert InvalidLength();

            uint256 id;

            for (uint256 i = 0; i < ids.length; i++) {
                id = ids[i];

                if (!_exists(id)) revert NonExistent();

                _traits[id].claimable = !_traits[id].claimable;
            }
        }
    }

    /// @notice Function used to set the `ICoins` address.
    function setCoinsContract(address coinsContract) external onlyOwner {
        coins = ICoins(coinsContract);
    }

    /// @notice Function used to set the `IShards` address.
    function setShardsContract(address shardsContrant) external onlyOwner {
        shards = IShards(shardsContrant);
    }

    /// @notice Function used to set a new `shardsToBurn` value.
    function setBurnReq(uint256 id, uint256 shards_) external onlyOwner {
        if (!_exists(id)) revert NonExistent();
        if (shards_ == 0) revert InvalidShards();

        _traits[id].burnReq = uint16(shards_);
    }

    function setBurnReqs(uint256[] calldata ids, uint256[] calldata shards_)
        external
        onlyOwner
    {
        unchecked {
            if (ids.length != shards_.length) revert ArrayLengthMismatch();

            uint256 id;
            uint256 shard_;

            for (uint256 i = 0; i < ids.length; i++) {
                id = ids[i];
                shard_ = shards_[i];

                if (!_exists(id)) revert NonExistent();
                if (shard_ == 0) revert InvalidShards();

                _traits[id].burnReq = uint16(shard_);
            }
        }
    }

    /// @notice Function used to set a new `_uri` value.
    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
    }

    function trait(uint256 id)
        external
        view
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (_traits[id].supply, _traits[id].burnReq, _traits[id].claimable);
    }

    /// @notice Function used to determine which traits `account` holds.
    /// @param account Address to check held traits of.
    /// @return results Array of values that represent the owned Traits of `account`.
    function traitsOfAccount(address account)
        external
        view
        returns (uint256[] memory results)
    {
        unchecked {
            uint256 items = _counter.current();
            uint256 count;
            uint256 index;

            for (uint256 id = 0; id < items; id++) {
                if (balanceOf(account, id) != 0) ++count;
            }

            results = new uint256[](count);

            for (uint256 id = 0; id < items; id++) {
                if (balanceOf(account, id) != 0) {
                    results[index] = id;
                    index++;
                }
            }
        }
    }

    /// @notice Function used to view the total number of traits.
    function traitCount() external view returns (uint256) {
        return _counter.current();
    }

    /// @notice Function used to determine if `account` has claimed Prestige Trait `id`.
    function hasClaimed(uint256 id, address account)
        external
        view
        returns (bool)
    {
        return _traits[id].claimed[account];
    }

    /// @notice Function used to view the URI value of `id`.
    function uri(uint256 id) public view override returns (string memory) {
        if (!_exists(id)) revert NonExistent();
        return string(abi.encodePacked(super.uri(id), id.toString()));
    }

    /// @notice Function used to determine if `id` exists.
    /// @param id Prestige Coin identifier.
    /// @return bool `true` if `id` exists, `false` otherwise.
    function exists(uint256 id) external view returns (bool) {
        return _exists(id);
    }

    /// @dev Prestige Traits are soulbound tokens that aren't tradeable.
    function safeTransferFrom(
        address from,
        address to,
        uint256,
        uint256,
        bytes memory
    ) public pure override(IERC1155, ERC1155) {
        if (from != to) revert Soulbound();
    }

    /// @dev Prestige Traits are soulbound tokens that aren't tradeable.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override(IERC1155, ERC1155) {
        if (from != to) revert Soulbound();
    }

    function _exists(uint256 id) internal view returns (bool) {
        return _counter.current() > id;
    }
}
