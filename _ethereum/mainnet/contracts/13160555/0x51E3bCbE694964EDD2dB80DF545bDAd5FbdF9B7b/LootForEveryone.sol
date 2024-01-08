// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./ERC721Base.sol";
import "./ISyntheticLoot.sol";
import "./ILoot.sol";
import "./ECDSA.sol";

contract LootForEveryone is ERC721Base {
    using EnumerableSet for EnumerableSet.UintSet;
    using ECDSA for bytes32;

    struct TokenData {
        uint256 id;
        string tokenURI;
        bool claimed;
    }

    ILoot private immutable _loot;
    ISyntheticLoot private immutable _syntheticLoot;

    constructor(ILoot loot, ISyntheticLoot syntheticLoot) {
        _loot = loot;
        _syntheticLoot = syntheticLoot;
    }

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string memory) {
        return "Loot For Everyone";
    }

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string memory) {
        return "LOOT";
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        return _tokenURI(id);
    }

    ///@notice get all info in the minimum calls
    function getTokenDataOfOwner(
        address owner,
        uint256 start,
        uint256 num
    ) external view returns (TokenData[] memory tokens) {
        require(start < 2**160 && num < 2**160, "INVALID_RANGE");
        EnumerableSet.UintSet storage allTokens = _holderTokens[owner];
        uint256 balance = allTokens.length();
        (, bool registered) = _ownerOfAndRegistered(uint256(owner));
        if (!registered) {
            // owned token was never registered, add balance
            balance++;
        }
        require(balance >= start + num, "TOO_MANY_TOKEN_REQUESTED");
        tokens = new TokenData[](num);
        uint256 i = 0;
        uint256 offset = 0;
        if (start == 0 && !registered) {
            // if start at zero consider unregistered token
            tokens[0] = TokenData(uint256(owner), _tokenURI(uint256(owner)), false);
            offset = 1;
            i = 1;
        }
        while (i < num) {
            uint256 id = allTokens.at(start + i - offset);
            tokens[i] = TokenData(id, _tokenURI(id), true);
            i++;
        }
    }

    ///@notice get all info in the minimum calls
    function getTokenDataForIds(uint256[] memory ids) external view returns (TokenData[] memory tokens) {
        tokens = new TokenData[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            (, bool registered) = _ownerOfAndRegistered(id);
            tokens[i] = TokenData(id, _tokenURI(id), registered);
        }
    }

    /// @notice utility function to claim a token when you know the private key of an address, go hunt for your loot!
    function pickLoot(address to, bytes memory signature) external {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(to != address(this), "NOT_TO_THIS");
        bytes32 hashedData = keccak256(abi.encodePacked("LootForEveryone", to));
        address signer = hashedData.toEthSignedMessageHash().recover(signature);
        (, bool registered) = _ownerOfAndRegistered(uint256(signer));
        require(!registered, "ALREADY_CALIMED");
        _safeTransferFrom(signer, to, uint256(signer), false, "");
    }

    ///@notice return true if the loot has been picked up or been transfered at least once
    function isLootPicked(uint256 id) external view returns(bool) {
        (address owner, bool registered) = _ownerOfAndRegistered(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        return registered;
    }

    /// @notice lock your original but limited loot so that you get a LootForEveryone like everyone else
    function transmute(uint256 id, address to) external {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(to != address(this), "NOT_TO_THIS");
        _loot.transferFrom(msg.sender, address(this), id);
        (address owner, bool registered) = _ownerOfAndRegistered(id);
        if (registered) {
            require(owner == address(this), "ALREADY_CLAIMED"); // unlikely to happen, would need to find the private key for its adresss (< 8001)
            _safeTransferFrom(address(this), to, id, false, "");
        } else {
            _safeTransferFrom(address(id), to, id, false, "");
        }
    }

    /// @notice unlock your original loot back
    function transmuteBack(uint256 id, address to) external {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(to != address(this), "NOT_TO_THIS");
        (address owner, bool registered) = _ownerOfAndRegistered(id);
        require(msg.sender == owner, "NOT_OWNER");
        _transferFrom(owner, address(this), id, registered);
        _loot.transferFrom(address(this), to, id);
    }

    // -------------------------------------------------------------------------------------------------
    // INTERNAL
    // -------------------------------------------------------------------------------------------------

    function _tokenURI(uint256 id) internal view returns (string memory) {
        require(id > 0 && id < 2**160, "NONEXISTENT_TOKEN");
        if (id < 8001) {
            return _loot.tokenURI(id);
        }
        return _syntheticLoot.tokenURI(address(id));
    }
}
