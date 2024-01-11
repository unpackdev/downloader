//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./console.sol";
import "./ISlayToEarnItems.sol";
import "./SlayToEarnAccessControl.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Math.sol";

// Immutable, unowned contract. In case of update requirements, the KMS key needs to be switched so that all previous
// signatures become invalid and we do not need to transfer the _claimedSeeds field to guard against replay attacks.
contract SlayToEarnClaimRewards is Ownable {
    using Math for uint256;

    mapping(uint256 => bool) private _claimedSeeds;
    address private _signerAddress;
    ISlayToEarnItems private _itemCollection;
    IERC20 private _slayToEarn;

    constructor(ISlayToEarnItems itemCollection, address signerAddress) {
        itemCollection.ping();

        _itemCollection = itemCollection;
        setSigner(signerAddress);
    }

    event ClaimRewards(address claimant, uint256 seed, uint256[] itemsRequired, uint256[] itemsBurned, uint256[] itemsMinted, uint256 tokensAwarded);

    function setSigner(address signerAddress) public onlyOwner {
        _signerAddress = signerAddress;
    }

    function getSigner() public view returns (address) {
        return _signerAddress;
    }

    function getItemCollection() public view returns (ISlayToEarnItems) {
        return _itemCollection;
    }

    function setItemCollection(ISlayToEarnItems itemCollection) public onlyOwner {
        _itemCollection = itemCollection;
    }

    function recoverTokens() public onlyOwner {
        if (_slayToEarn != IERC20(address(0))) {
            _slayToEarn.transfer(msg.sender, _slayToEarn.balanceOf(address(this)));
        }
    }

    function setSlayToEarnToken(IERC20 tokenContract) public onlyOwner {
        _slayToEarn = tokenContract;
        _slayToEarn.balanceOf(address(this));
    }

    function getSlayToEarnToken() public view returns (IERC20) {
        return _slayToEarn;
    }

    function claimRewards(
        uint256 seed,
        uint256[] memory itemsRequired,
        uint256[] memory itemsBurned,
        uint256[] memory itemsMinted,
        uint256 tokensAwarded,
        bytes memory signature
    ) public {

        require(signature.length == 64, "Signature must be 64 bytes in length.");
        require(!_claimedSeeds[seed], "Rewards have already been claimed for this seed.");

        _claimedSeeds[seed] = true;

        bytes memory message = abi.encodePacked(
            uint256(uint160(msg.sender)), // claimant
            seed, // game seed
            uint256(itemsRequired.length),
            itemsRequired,
            uint256(itemsBurned.length),
            itemsBurned,
            uint256(itemsMinted.length),
            itemsMinted,
            tokensAwarded
        );
        bytes32 messageHash = keccak256(message);
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
        }

        require(
            ecrecover(messageHash, 27, r, s) == _signerAddress
            || ecrecover(messageHash, 28, r, s) == _signerAddress,
            "The given signature is not valid for the provided parameters."
        );

        _requireItemsForPlayer(itemsRequired);
        _burnItemsForPlayer(itemsBurned);
        _mintItemsForPlayer(itemsMinted);

        if (_slayToEarn != IERC20(address(0))) {
            tokensAwarded = tokensAwarded.min(_slayToEarn.balanceOf(address(this)));

            if (tokensAwarded > 1_000 ether) {
                _slayToEarn.transfer(msg.sender, tokensAwarded);
            } else {
                tokensAwarded = 0;
            }
        } else {
            tokensAwarded = 0;
        }

        emit ClaimRewards(msg.sender, seed, itemsRequired, itemsBurned, itemsMinted, tokensAwarded);
    }

    function _requireItemsForPlayer(uint256[] memory requiredItemStacks) private {
        (uint256[] memory requiredItems, uint256[] memory amounts) = _unpackItemStacks(requiredItemStacks);

        _itemCollection.requireBatch(msg.sender, requiredItems, amounts);
    }

    function _burnItemsForPlayer(uint256[] memory burnedItemStacks) private {
        (uint256[] memory burnedItems, uint256[] memory amounts) = _unpackItemStacks(burnedItemStacks);

        _itemCollection.burnBatch(msg.sender, burnedItems, amounts);
    }

    function _mintItemsForPlayer(uint256[] memory mintedItemStacks) private {
        (uint256[] memory mintedItems, uint256[] memory amounts) = _unpackItemStacks(mintedItemStacks);

        bytes memory data;
        _itemCollection.mintBatch(msg.sender, mintedItems, amounts, data);
    }

    function _unpackItemStacks(uint256[] memory itemStacks) private view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory items = new uint256[](itemStacks.length);
        uint256[] memory amounts = new uint256[](itemStacks.length);

        for (uint i = 0; i < itemStacks.length; i++) {
            items[i] = (itemStacks[i] << 32) >> 32;
            amounts[i] = itemStacks[i] >> 224;
        }

        return (items, amounts);
    }
}
