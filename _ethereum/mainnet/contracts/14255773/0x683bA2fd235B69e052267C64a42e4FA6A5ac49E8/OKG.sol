// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Pausable.sol";
import "./SafeMath.sol";

// An Omega Key and its owners
struct OmegaKey {
	bool active;
	bool removed; // whether a Key is removed by a successful Reward claim
	uint8 order; // Order of the Key will be released
	uint256 keyId; // equal to the Id of the Voxo this Key was assigned to
	address[] owners;
}

// A Player's Omega Key collection
struct Player {
	bool active;
	uint256[] keyids; // A Key # is equal to the Voxo's Id it was assigned to
}

/**
 * @title Omega Key Game Smart Contract
 * @dev All methods to conduct the Omega Key Game on-chain
 * @dev https://voxodeus.notion.site/Omega-Key-Game-143fcf958a254295a5a1e2b344867fca
 */

contract OKG is Ownable, Pausable {
	using SafeMath for uint256;
	using Address for address;

	// Mapping to handle Omega Keys
	mapping(uint256 => OmegaKey) public omegaKeys;
	// Mapping to handle Players
	mapping(address => Player) public players;
	// Event for when an Omega Key is released
	event OmegaKeyReleased(uint256[] OmegaKey, uint8[] order);
	// Event for when a Player registers their ownership of an Omega Key
	event OmegaKeyRegistered(address indexed Owner, uint256[]  OmegaKey);
	// Event for when an Omega Key is removed from the game
	event OmegaKeyRemoved(address indexed Winner, uint256 indexed OmegaKey, uint256 indexed Tier, address[] allOwners);
	// Event for when the removal of an Omega Key is reversed
	event OmegaKeyRestored(address[] oldOwners, uint256 indexed OmegaKey);
	// Event for when an Omega Reward is successfully claimed
	event RewardClaimed(address indexed Winner, uint256 indexed Tier, uint256 Amount);
	// Event for when an Omega Reward's claim status is reverted to being available
	event RewardRestored(uint256 indexed Tier, uint256 Amount);
	// General Order of Omega Keys Released
	uint8 public releaseOrder;
	// Address of the NFT contract
	address public nftContract;
	// Availability of the Diamond Reward
	bool public isDiamondRewardClaimed;
	// Availability of the Gold Reward
	bool public isGoldRewardClaimed;
	// Availability of the Silver Reward
	bool public isSilverRewardClaimed;
	// Availability of the Bronze Reward
	bool public isBronzeRewardClaimed;


    constructor(address NFT_contract_address) {
    	nftContract = NFT_contract_address;
    }

	modifier isReleased(uint256 _keyId) {
		require(isKey(_keyId), "VOXO: Omega Key not released");
		_;
	}

	modifier whenNotGameOver() {
		require(!isGameOver(), "VOXO: Game Over");
		_;
	}

	modifier isOmegaRewardAmount(uint256 _ethReward) {
		require(isOmegaReward(_ethReward), "VOXO: Reward for this ETH amount does not exist");
		_;
	}

	/**
     * @dev Implementation / Instance of paused methods() in the ERC20.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC20Pausable}.
     */
    function pause(bool status) public onlyOwner() {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

	/**
	 * @dev Method to record the release of a new Omega Key
	 * @dev A Key # is equal to the voxoId of the Voxo it is assigned to
	 * @param _ids The Array of keyids
	 */
	function release(uint256[] calldata _ids) external
		onlyOwner()
		whenNotGameOver()
		whenNotPaused()
	{
		require(!hasDuplicates(_ids), "VOXO: Duplicate Key Ids");
		uint8[] memory _order = new uint8[](_ids.length);
		for (uint i = 0; i < _ids.length; i++) {
			require((_ids[i] != uint(0)), "VOXO: Voxo Id cannot be Zero");
			require(!isKey(_ids[i]), "VOXO: Voxo can only be assigned 1 Omega Key");
			require(!isRemoved(_ids[i]), "VOXO: Voxo cannot be assigned to a removed Omega Key");

		}

		for (uint i = 0; i < _ids.length; i++) {
			releaseOrder++;
			_order[i] = releaseOrder;
			omegaKeys[_ids[i]] = OmegaKey({
				active: true,
				removed: false,
				order: releaseOrder,
				keyId: _ids[i],
				owners: new address[](0)
			});
		}
		// Emit Event for the released Omega Key
		emit OmegaKeyReleased(_ids, _order);
	}

	/**
	 * @dev Method to register a Player's ownership of an Omega Key
	 * @param _keyIds The Voxo Id / Key # a player intends to register
	 */
	function register(uint256[] calldata _keyIds) external
		whenNotGameOver()
		whenNotPaused()
	{
		require(!hasDuplicates(_keyIds), "VOXO: Duplicate Key Ids");
		// Instance of NFT VoxoDeus, to Verify the ownership
		IERC721 _token = IERC721(address(nftContract));
		for (uint i = 0; i < _keyIds.length; i++) {
			require((_keyIds[i] != uint(0)), "VOXO: Voxo Id cannot be Zero");
			require(isKey(_keyIds[i]), "VOXO: Omega Key not released");
			require(!isRegistered(_keyIds[i], _msgSender()), "VOXO: Omega Key already registered");
			require(_token.ownerOf(_keyIds[i]) == _msgSender(), "VOXO: You are not the owner of this KeyVoxo");
		}

		for (uint i = 0; i < _keyIds.length; i++) {
			// register Player as an owner of this Omega Key
			omegaKeys[_keyIds[i]].owners.push(_msgSender());
			// add Omega Key to a Player's Omega Key Collection
			if (players[_msgSender()].active) {
				players[_msgSender()].keyids.push(_keyIds[i]);
			} else {
				players[_msgSender()].active = true;
				players[_msgSender()].keyids.push(_keyIds[i]);
			}
		}
		// Emit Event for the Player registering an Omega Key
		emit OmegaKeyRegistered(_msgSender(), _keyIds);
	}

	/**
	 * @dev Method to claim an Omega Reward
	 * @dev To claim a Reward, a Player needs to have at least
	 * @dev the Reward's required number of Keys in their Collection
	 * @dev Key Requirements: 3 for Bronze, 4 for Silver, 6 for Gold, and 8 for Diamond.
	 * @param _ethClaim The ETH amount the Reward's winner will be awarded
	 */
	function claim(uint256 _ethClaim) public
		whenNotGameOver()
		whenNotPaused()
		isOmegaRewardAmount(_ethClaim)
	{
		require(players[_msgSender()].active, "VOXO: Player does not exist");

		// The Reward specifics
		uint256 noKeysRequired;
		// Tier Bronze
		if (_ethClaim == uint256(16)) {
			require(!isBronzeRewardClaimed, "VOXO: Bronze Reward already claimed");
			require(players[_msgSender()].keyids.length >= 3, "VOXO: Player Key collection insufficient for this Reward");
			noKeysRequired = 3;
			removeOmegaKeys(noKeysRequired);
			isBronzeRewardClaimed = true;
		}
		// Tier Silver
		if (_ethClaim == uint256(33))  {
			require(!isSilverRewardClaimed, "VOXO: Silver Reward already claimed");
			require(players[_msgSender()].keyids.length >= 4, "VOXO: Player Key collection insufficient for this Reward");
			noKeysRequired = 4;
			removeOmegaKeys(noKeysRequired);
			isSilverRewardClaimed = true;
		}
		// Tier Gold
		if (_ethClaim == uint256(66))  {
			require(!isGoldRewardClaimed, "VOXO: Gold Reward already claimed");
			require(players[_msgSender()].keyids.length >= 6, "VOXO: Player Key collection insufficient for this Reward");
			noKeysRequired = 6;
			removeOmegaKeys(noKeysRequired);
			isGoldRewardClaimed = true;
		}
		// Tier Diamond
		if (_ethClaim == uint256(135)) {
			require(!isDiamondRewardClaimed, "VOXO: Diamond Reward already claimed");
			require(players[_msgSender()].keyids.length >= 8, "VOXO: Player Key collection insufficient for this Reward");
			noKeysRequired = 8;
			removeOmegaKeys(noKeysRequired);
			isDiamondRewardClaimed = true;
		}

		emit RewardClaimed(_msgSender(), noKeysRequired, _ethClaim);
	}

	/**
	 * @dev Method to remove Omega Keys.
	 * @dev Omega Keys are removed from the game - burned - whenever a Player
	 * @dev uses that Key # to claim a Reward. This method doesn't check the
     * @dev ownership of the VoxoId, as Players can own Omega Keys without
     * @dev still holding the KeyVoxo.
	 * @dev
	 * @dev Omega Keys are removed in the order that they were registered.
	 * @dev Thus, a Player may still have Keys left after removing all the
	 * @dev Keys they used to claim a Reward.
	 * @dev
	 * @param _keys Number of keys to burn
	 */
	function removeOmegaKeys(uint256 _keys) private {
		for (uint i = 0; i < _keys; i++) {
			// Select the Player's oldest remaining Key to burn
			uint256 keyToRemove = players[_msgSender()].keyids[0];
			omegaKeys[keyToRemove].active = false;
			omegaKeys[keyToRemove].removed = true;
			// Remove all owners from that Key
			address[] memory allOwners = omegaKeys[keyToRemove].owners;
			// Likewise, the Omega Key must be removed from all Players whom
			// had previously registered it / added it to their Key Collection.
			for (uint j = 0; j < allOwners.length; j++) {
				players[allOwners[j]].keyids = removeKeyFromPlayer(keyToRemove, allOwners[j]);
				if (players[allOwners[j]].keyids.length > 0) {
					players[allOwners[j]].keyids.pop();
				}
			}
			emit OmegaKeyRemoved(_msgSender(), keyToRemove, _keys, allOwners);
		}
	}

	/**
	 * @dev Method to remove an Omega Key from a Player's Collection.
	 * @param _keyId The Voxo Id / Key # - The Omega Key to remove
	 * @param _player the owner of the Key Collection
	 * @return keyids Player's Collection with the removed Keys removed
	 */
	function removeKeyFromPlayer(uint256 _keyId, address _player) internal view returns (uint256[] memory keyids) {
		keyids = players[_player].keyids;
		uint256 index = keyids.length;
		for (uint i = 0; i < index; i++) {
			if (keyids[i] == _keyId) {
				keyids[i] = keyids[index - 1];
				delete keyids[index - 1];
			}
		}
	 }

	/**
	 * @dev Method reverting the game state following an invalidated Omega Reward Claim
	 * @dev Used exclusively in the unexpected case where a winning claim is found to be fraudulent
	 * @dev or otherwise in conflict with the terms governing a player's participation in the game.
	 * @param _ethReward the ETH payout amount corresponding to an Omega Reward tier
	 */
	function restoreReward(uint256 _ethReward) private
	{
		uint256 noKeysRequired = 0;
		if ((_ethReward == uint256(16)) && (isBronzeRewardClaimed)) {
			isBronzeRewardClaimed = false;
			noKeysRequired = 3;
		}
		if ((_ethReward == uint256(33)) && (isSilverRewardClaimed)) {
			isSilverRewardClaimed = false;
			noKeysRequired = 4;
		}
		if ((_ethReward == uint256(66)) && (isGoldRewardClaimed)) {
			isGoldRewardClaimed = false;
			noKeysRequired = 6;
		}
		if (_ethReward == uint256(135) && (isDiamondRewardClaimed)) {
			isDiamondRewardClaimed = false;
			noKeysRequired = 8;
		}
		emit RewardRestored(noKeysRequired, _ethReward);
	}

	/**
	 * @dev Method to revert a removed Omega Key for all previous Owners
	 * @dev Used exclusively in the unexpected case where a winning claim is found to be fraudulent
	 * @dev or otherwise in conflict with the terms governing a player's participation in the game.
	 * @param _keyIds an Array of Keys #s
	 */
	function revertRewardClaim(uint256 _ethReward, uint256[] memory _keyIds, address _disqualifiedPlayer) public
		onlyOwner()
		whenNotPaused()
		isOmegaRewardAmount(_ethReward)
	{
		require(!hasDuplicates(_keyIds), "VOXO: Duplicate Key Ids");
		// Verify that all the Keys-to-be-restored were previously removed
		for (uint j = 0; j < _keyIds.length; j++) {
			require ((omegaKeys[_keyIds[j]].removed && !omegaKeys[_keyIds[j]].active), "VOXO: Omega Key is not removed");
		}
		// Restore the Reward
		restoreReward(_ethReward);
		// Restore the Keys to the Player's Collection
		for (uint i = 0; i < _keyIds.length; i++) {
			address[] memory oldOwners;
			omegaKeys[_keyIds[i]].owners = removePlayer(_keyIds[i], _disqualifiedPlayer);
			if (omegaKeys[_keyIds[i]].owners.length > 0) {
				omegaKeys[_keyIds[i]].owners.pop();
				oldOwners = omegaKeys[_keyIds[i]].owners;
			}
			uint8 oldOrder = omegaKeys[_keyIds[i]].order;
			omegaKeys[_keyIds[i]] = OmegaKey({
				active: true,
				removed: false,
				order: oldOrder,
				keyId: _keyIds[i],
				owners: oldOwners
			});
			// Add Key back to each Owner's Key Collection
			for(uint k = 0; k < omegaKeys[_keyIds[i]].owners.length; k++) {
				players[omegaKeys[_keyIds[i]].owners[k]].keyids.push(_keyIds[i]);
			}
			emit OmegaKeyRestored(omegaKeys[_keyIds[i]].owners, _keyIds[i]);
		}
	}

	/**
	 * @dev Method to verify an Key # is among the released Omega Keys
	 * @param _keyId The Voxo Id / Key #
	 * @return True if the Key # was released, False if not
	 */
	function isKey(uint256 _keyId) public view returns (bool) {
		return omegaKeys[_keyId].active;
	}

	/**
	 * @dev Method to verify that an Omega Key was removed
	 * @param _keyId The Voxo Id / Key #
	 * @return True if the Omega Key was removed, False if not
	 */
	function isRemoved(uint256 _keyId) public view returns (bool) {
		return omegaKeys[_keyId].removed;
	}

	/**
	 * @dev Method to verify an ETH amount has a corresponding Omega Reward
	 * @param _ethReward The ETH amount an Omega Reward pays out
	 * @return True if Omega Reward with that ETH reward exists, False if not
	 */
	function isOmegaReward(uint256 _ethReward) public pure returns (bool) {
		return (_ethReward == uint256(16)) || (_ethReward == uint256(33)) || (_ethReward == uint256(66)) || (_ethReward == uint256(135));
	}

	/**
	 * @dev Method to verify that no Rewards are left unclaimed,
	 * @dev marking the end of the Omega Key Game
	 * @return True if all Reward are unavailable, False if at least one Reward is still available
	 */
	function isGameOver() public view returns (bool) {
		return (isDiamondRewardClaimed && isGoldRewardClaimed && isSilverRewardClaimed && isBronzeRewardClaimed);
	}

	/**
	 * @dev Method to verify that a Player has registered an Omega Key
	 * @param _keyId The Voxo Id / Key #
	 * @return registered True if the Omega Key is registered, False if not
	 */
	function isRegistered(uint256 _keyId, address _owner) public view isReleased(_keyId) returns (bool registered) {
		registered = false;
		for (uint i = 0; i < omegaKeys[_keyId].owners.length; i++) {
			if (omegaKeys[_keyId].owners[i] == _owner) {
				registered = true;
			}
		}
		return registered;
	}

	/**
	 * @dev Method returning the Player's Key Collection
	 * @param _player The owner of the Key Collection
	 * @return The list of Keys collected (and registered) by the Player
	 */
	function getKeyCollection(address _player) public view returns (uint256[] memory) {
		return players[_player].keyids;
	}

	/**
	 * @dev Method returning the Player's Key Collection size
	 * @param _player The owner of the Key Collection
	 * @return The number of keys collected (and registered) by the Player
	 */
	function getKeyCollectionSize(address _player) public view returns (uint256 ) {
		return players[_player].keyids.length;
	}

	/**
	 * @dev Method returning the Omega Key Collection without disqualified Player
	 * @param _keyIds The Voxo Id / Key #, where the disqualified Player will be removed from
	 * @param _disqualifiedPlayer The disqualifiedPlayer of the Key Collection
	 * @return owners The Omega Key Collection without disqualified Player
	 */
	function removePlayer(uint256 _keyIds, address _disqualifiedPlayer) internal view returns (address[] memory owners) {
		owners = omegaKeys[_keyIds].owners;
		uint256 index = owners.length;
		for (uint i = 0; i < index; i++) {
			if (owners[i] == _disqualifiedPlayer) {
				owners[i] = owners[index - 1];
				delete owners[index - 1];
			}
		}
	}

	/**
	* Returns whether or not there's a duplicate. Runs in O(n^2).
	* @param A Array to search
	* @return Returns true if duplicate, false otherwise
	*/
	function hasDuplicates(uint256[] memory A) internal pure returns (bool) {
		if (A.length == 0) {
		return false;
		}
		for (uint256 i = 0; i < A.length - 1; i++) {
			for (uint256 j = i + 1; j < A.length; j++) {
				if (A[i] == A[j]) {
				return true;
				}
			}
		}
		return false;
	}
}
