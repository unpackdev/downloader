// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;

import "./ValidatorsRegister.sol";
import "./VaultStorage.sol";
import "./Utils.sol";

/// Contract wasn't properly initialized.
/// @param version required storage version.
error NotInitialized(uint8 version);
/// Not enough signatures where specified.
/// @param minAmount minimal amount of signature to release funds.
error NotEnoughSignatures(uint64 minAmount);
/// Not enough valid signatures where specified.
/// @param validAmount amount of valid signatures.
/// @param minAmount minimal amount of signature to release funds.
error NotEnoughValidSignatures(uint64 validAmount, uint64 minAmount);
/// Invalid address received
/// @param got received address
/// @param expected expected address
error WrongAddress(address got, address expected);
/// Invalid address received
/// @param got received chain id
/// @param expected expected chain id
error WrongChainId(uint32 got, uint32 expected);
/// Already used loot box
/// @param lootBoxId used loot box
error AlreadyUsed(uint64 lootBoxId);
/// The validators limit reached.
/// @param maxValidators validators limit.
error TooManyValidators(uint256 maxValidators);

contract Vault is VaultStorage, ValidatorsRegister {
    using TransferUtil for address;
    using BitMaps for BitMaps.BitMap;

    event Withdrawn(address indexed userAccount, uint64[] lootBoxIds, address lootBox, uint chainId);
    event ValidatorAdd(address indexed account);
    event ValidatorRemove(address indexed account);

    uint256 constant internal MAX_VALIDATORS = 1000;
    uint8 constant public STORAGE_VERSION = 3;

    modifier onlyInitialized() {
        if (_getInitializedVersion() != STORAGE_VERSION) {
            revert NotInitialized(STORAGE_VERSION);
        }
        _;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct NftPrize {
        address collection;
        uint256 tokenId;
    }

    struct Erc20Prize {
        address tokenAddress;
        uint256 amount;
    }

    function release(address userAccount, uint64[] calldata lootBoxIds, NftPrize[] calldata nftPrizes,
        Erc20Prize[] calldata erc20Prizes, Signature[] calldata signatures) public {
        // signatures count check
        uint32 requiredSignatures = getRequiredSignatures();
        if (signatures.length < requiredSignatures) {
            revert NotEnoughSignatures(requiredSignatures);
        }

        // loot box ids check
        _markIdsAsUsed(lootBoxIds);

        // get hash and validate signatures
        bytes32 hash = _getHash(userAccount, lootBoxIds, nftPrizes, erc20Prizes);
        _validateSignatures(hash, signatures, requiredSignatures);

        // release nft prizes
        for (uint256 i = 0; i < nftPrizes.length; ++i) {
            NftPrize calldata nft = nftPrizes[i];
            nft.collection.erc721Transfer(userAccount, nft.tokenId);
        }

        // release ERC20 prizes
        for (uint256 i = 0; i < erc20Prizes.length; ++i) {
            Erc20Prize calldata erc20Prize = erc20Prizes[i];
            address pool = address(this);
            erc20Prize.tokenAddress.erc20TransferFrom(pool, userAccount, erc20Prize.amount);
        }

        LootBoxInfo storage lbInfo = _getLootBoxInfo();

        emit Withdrawn(userAccount, lootBoxIds, lbInfo.lootBox, lbInfo.chainId);
    }

    function withdrawNft(address collection, uint256 tokenId) public onlyOwner {
        collection.erc721Transfer(_msgSender(), tokenId);
    }

    function withdrawERC20(address tokenAddress, uint256 amount) public onlyOwner {
        address pool = address(this);
        tokenAddress.erc20TransferFrom(pool, _msgSender(), amount);
    }

    function getRequiredSignatures() public view returns (uint32) {
        return totalValidators() * threshold() / THRESHOLD_DIVIDER;
    }

    function addValidator(address account, uint16 id) public onlyOwner {
        if (totalValidators() >= MAX_VALIDATORS) {
            revert TooManyValidators(MAX_VALIDATORS);
        }
        _addValidator(account, id);
        emit ValidatorAdd(account);
    }

    function removeValidator(address account) public onlyOwner {
        _removeValidator(account);
        emit ValidatorRemove(account);
    }

    function setThreshold(uint32 threshold) public onlyOwner {
        _setThreshold(threshold);
    }

    function _markIdsAsUsed(uint64[] calldata lootBoxIds) private {
        BitMaps.BitMap storage released = _readReleased();
        for (uint256 i = 0; i < lootBoxIds.length; i ++) {
            uint64 lootBoxId = lootBoxIds[i];

            // check if id already used
            if (released.get(lootBoxId)) {
                revert AlreadyUsed(lootBoxId);
            }

            // mark as used
            released.set(lootBoxId);
        }
    }

    function _getHash(
        address userAccount,
        uint64[] calldata lootBoxIds,
        NftPrize[] calldata nftPrizes,
        Erc20Prize[] calldata erc20Prizes)
            private view returns (bytes32) {

        bytes memory encoded = abi.encodePacked(address(this), uint32(block.chainid), userAccount, lootBoxIds,
            abi.encode(nftPrizes), abi.encode(erc20Prizes));
        return sha256(encoded);
    }

    function _validateSignatures(bytes32 hash, Signature[] calldata signatures, uint32 thresholdCount) private view {
        uint32 counter = 0;
        bool[] memory used = new bool[](_getLastValidatorId() + 1);
        for (uint256 i = 0; i < signatures.length; i ++) {
            address validator = ecrecover(hash, signatures[i].v, signatures[i].r, signatures[i].s);
            uint256 validatorId = _getValidator(validator);
            if (validatorId == 0 || used[validatorId]) {
                continue;
            }
            used[validatorId] = true;
            counter ++;
        }
        if (counter < thresholdCount) {
            revert NotEnoughValidSignatures(counter, thresholdCount);
        }
    }
}
