// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./UUPSUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./ERC1155BurnableUpgradeable.sol";

import "./AccessControlledUpgradeable.sol";
import "./BlockAware.sol";
import "./IFragmentMiniGame.sol";
import "./FragmentMiniGameStorage.sol";
import "./FragmentMiniGameUtils.sol";

contract FragmentMiniGame is
    IFragmentMiniGame,
    ERC1155Upgradeable,
    ERC1155BurnableUpgradeable,
    UUPSUpgradeable,
    AccessControlledUpgradeable,
    BlockAware,
    FragmentMiniGameStorage
{
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.Bytes32ToBytes32Map;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using FragmentMiniGameUtils for bytes16;
    using FragmentMiniGameUtils for string;
    using FragmentMiniGameUtils for uint256;
    using FragmentMiniGameUtils for bytes32;
    using StringsUpgradeable for uint256;

    /// @dev Constructor that gets called for the implementation contract.
    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    // solhint-disable-next-line comprehensive-interface
    function initialize(
        address acl,
        string calldata baseUri,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        __BlockAware_init();
        __UUPSUpgradeable_init();
        __AccessControlled_init(acl);
        __ERC1155_init(baseUri);

        _setBaseURI(baseUri);
        _setName(name_);
        _setSymbol(symbol_);
    }

    /// @inheritdoc IFragmentMiniGame
    function setBaseURI(string calldata baseUri) external override onlyMaintainer {
        _setBaseURI(baseUri);
    }

    /// @inheritdoc IFragmentMiniGame
    function registerFragmentGroup(
        string calldata groupName,
        uint128[] calldata fragmentSupply,
        bytes32 secretHash,
        uint256 accountCap
    ) external override onlyMaintainer {
        // Construct the real group ID
        bytes16 groupId = groupName.constructGroupId();

        // Make sure that neither a fragment group nor an object group is registered under the same group id!
        _checkObjectGroup(groupId, false);
        FragmentGroup storage fragmentGroup = _checkFragmentGroup(groupId, false);
        if (_fragmentGroupIds[secretHash] != bytes16(0)) revert FragmentSecretAlreadyRegistered();
        if (accountCap == 0) revert AccountCapCannotBeZero();

        // Instantiate the fragment groups
        fragmentGroup.accountCap = accountCap;
        fragmentGroup.size = uint128(fragmentSupply.length);
        for (uint128 index = 0; index < fragmentSupply.length; index++) {
            if (fragmentSupply[index] == 0) revert FragmentSupplyMustBeGreaterThanZero();
            fragmentGroup.supply[index] = FragmentMiniGameUtils.constructFragmentSupply(
                fragmentSupply[index],
                fragmentSupply[index]
            );
        }

        // Associate the secret with the group id
        _fragmentGroupIds[secretHash] = groupId;

        emit FragmentGroupRegistered(groupId);
    }

    /// @inheritdoc IFragmentMiniGame
    /// @dev Never post the `mintingRequirements` with duplicate tokenIds! That will result in undefined behaviour!
    // solhint-disable-next-line code-complexity
    function registerObjectGroup(string calldata groupName, MintRequirement[] calldata mintingRequirements)
        external
        override
        onlyMaintainer
    {
        // Construct the real group ID
        bytes16 groupId = groupName.constructGroupId();

        // Make sure that neither a fragment group nor an object group is registered under the same group id!
        _checkFragmentGroup(groupId, false);
        (ObjectGroup storage objectGroup, ) = _checkObjectGroup(groupId, false);

        // Instantiate the object group
        for (uint256 index = 0; index < mintingRequirements.length; index++) {
            uint256 tokenId = mintingRequirements[index].tokenId;
            (bytes16 dependantGroupId, uint128 tokenIndex) = tokenId.deconstructTokenId();

            // Make sure that the dependant groups token id is valid
            FragmentGroup storage fg = _fragmentGroups[dependantGroupId];
            bool dependsOnFragmentGroup = fg.accountCap > 0;
            if (dependsOnFragmentGroup) {
                (, uint128 totalSupply) = fg.supply[tokenIndex].deconstructFragmentSupply();

                // We're checking a case where the expected token tokenIndex is not supported by the fragment group.
                if (fg.size <= tokenIndex) revert UnsupportedTokenIndex(dependantGroupId, tokenIndex);
                if (totalSupply < mintingRequirements[index].necessaryTokenCount)
                    revert ImpossibleExpectedSupply(tokenId, mintingRequirements[index].necessaryTokenCount);
            } else {
                // Depends on an object group.
                if (tokenIndex != 0) revert UnsupportedTokenIndex(dependantGroupId, tokenIndex);
                _checkObjectGroup(dependantGroupId, true);
            }

            bytes32 necessaryNumber = bytes32(uint256(mintingRequirements[index].necessaryTokenCount));
            bytes32 tokenIdKey = bytes32(tokenId);
            objectGroup.mintingRequirements.set(tokenIdKey, necessaryNumber);
        }

        emit ObjectGroupRegistered(groupId);
    }

    /// @inheritdoc IFragmentMiniGame
    function unregisterFragmentGroup(string calldata groupName, bytes32 secretHash) external override onlyMaintainer {
        // Construct the real group ID
        bytes16 groupId = groupName.constructGroupId();
        FragmentGroup storage fg = _checkFragmentGroup(groupId, true);
        if (_fragmentGroupIds[secretHash] != groupId) revert SecretHashDoesNotMatchGroup();

        for (uint128 index = 0; index < fg.size; index++) {
            delete fg.supply[index];
            // NOTE: not clearing `fragmentCount` because we don't know the keys!
        }

        delete _fragmentGroups[groupId];
        delete _fragmentGroupIds[secretHash];

        emit FragmentGroupUnregistered(groupId);
    }

    /// @inheritdoc IFragmentMiniGame
    function unregisterObjectGroup(string calldata groupName) external override onlyMaintainer {
        // Construct the real group ID
        bytes16 groupId = groupName.constructGroupId();
        _checkObjectGroup(groupId, true);

        delete _objectGroups[groupId];

        emit ObjectGroupUnregistered(groupId);
    }

    /// @inheritdoc IFragmentMiniGame
    function discover(string calldata fragmentSecret) external override {
        bytes32 secret = keccak256(abi.encodePacked(fragmentSecret));
        bytes16 groupId = _fragmentGroupIds[secret];
        FragmentGroup storage fg = _checkFragmentGroup(groupId, true);

        if (fg.fragmentCount[msg.sender] >= fg.accountCap) revert MintingCapReached(msg.sender, groupId, fg.accountCap);

        // Determine which token index to mint
        bytes32 sourceOfRandomness = keccak256(
            abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender)
        );
        uint128 endIndex = uint128(uint256(sourceOfRandomness) % fg.size);
        uint128 index = endIndex;
        do {
            // Go through each token index and check if we can mint it until we mint the first one.
            // This is needed because some of the index caps might be 0 (already emptied out).
            index = (index + 1) % fg.size;
            (uint128 iSupplyLeft, uint128 iTotalSupply) = fg.supply[index].deconstructFragmentSupply();

            if (iSupplyLeft > 0) {
                // Update the contracts mint state
                fg.supply[index] = FragmentMiniGameUtils.constructFragmentSupply(iSupplyLeft - 1, iTotalSupply);
                fg.fragmentCount[msg.sender] += 1;

                // Mint the Fragment NFT
                uint256 tokenId = groupId.constructFragmentTokenId(index);
                _mint(msg.sender, tokenId, 1, new bytes(0));

                return; // Early return if we have minted the token
            }
        } while (index != endIndex);

        // Revert in a case where we cannot mint any token.
        revert AllItemsDiscovered(groupId);
    }

    /// @inheritdoc IFragmentMiniGame
    function collect(string calldata groupName) external override {
        bytes16 groupId = groupName.constructGroupId();
        (ObjectGroup storage objectGroup, bytes32[] memory keys) = _checkObjectGroup(groupId, true);

        // iterate over all token ids and check if the user has enough of them
        for (uint256 index = 0; index < keys.length; index++) {
            bytes32 tokenIdKey = keys[index];
            uint256 tokenId = uint256(tokenIdKey);
            uint256 minRequirements = uint256(objectGroup.mintingRequirements.get(tokenIdKey));

            // NOTE: the balance is already checked in the `_burn` function
            _burn(msg.sender, tokenId, minRequirements);
        }

        // Mint the object NFT
        uint256 objectTokenId = groupId.constructObjectTokenId();
        _mint(msg.sender, objectTokenId, 1, new bytes(0));
    }

    /// @inheritdoc IFragmentMiniGame
    function canCollect(address account, string calldata groupName) external view override returns (bool) {
        bytes16 groupId = groupName.constructGroupId();
        (ObjectGroup storage objectGroup, bytes32[] memory keys) = _checkObjectGroup(groupId, true);

        // iterate over all token ids and check if the user has enough of them
        for (uint256 index = 0; index < keys.length; index++) {
            bytes32 tokenIdKey = keys[index];
            uint256 tokenId = uint256(tokenIdKey);
            uint256 minRequirements = uint256(objectGroup.mintingRequirements.get(tokenIdKey));

            if (balanceOf(account, tokenId) < minRequirements) return false;
        }

        return true;
    }

    /// @inheritdoc IFragmentMiniGame
    function getFragmentGroup(string calldata groupName)
        external
        view
        override
        returns (
            bytes16 groupId,
            uint256[] memory tokenIds,
            uint128[] memory supplyLeft,
            uint128[] memory totalSupply
        )
    {
        groupId = groupName.constructGroupId();
        FragmentGroup storage fg = _checkFragmentGroup(groupId, true);

        tokenIds = new uint256[](fg.size);
        supplyLeft = new uint128[](fg.size);
        totalSupply = new uint128[](fg.size);
        for (uint128 index = 0; index < fg.size; index++) {
            uint256 tokenId = groupId.constructFragmentTokenId(index);
            (uint128 iSupplyLeft, uint128 iTotalSupply) = fg.supply[index].deconstructFragmentSupply();

            tokenIds[index] = tokenId;
            supplyLeft[index] = iSupplyLeft;
            totalSupply[index] = iTotalSupply;
        }
    }

    /// @inheritdoc IFragmentMiniGame
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IFragmentMiniGame
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IFragmentMiniGame
    function owner() external view override returns (address) {
        return _getAcl().getRoleMember(Roles.NFT_OWNER, 0);
    }

    /// @inheritdoc IFragmentMiniGame
    function getMintedFragmentsCount(string calldata groupName, address account)
        external
        view
        override
        returns (uint256)
    {
        bytes16 groupId = groupName.constructGroupId();
        FragmentGroup storage fg = _checkFragmentGroup(groupId, true);

        return fg.fragmentCount[account];
    }

    /// @inheritdoc IFragmentMiniGame
    function getObjectGroup(string calldata groupName)
        external
        view
        override
        returns (
            bytes16 groupId,
            uint256 tokenId,
            MintRequirement[] memory mintingRequirements
        )
    {
        groupId = groupName.constructGroupId();
        (ObjectGroup storage og, bytes32[] memory dependantTokenIds) = _checkObjectGroup(groupId, true);
        tokenId = groupId.constructObjectTokenId();

        mintingRequirements = new MintRequirement[](dependantTokenIds.length);

        // Iterate over all of the keys (token Ids) and retrieve the necessary token count
        for (uint128 index = 0; index < dependantTokenIds.length; index++) {
            uint128 necessaryTokenCount = uint128(uint256(og.mintingRequirements.get(dependantTokenIds[index])));
            mintingRequirements[index] = MintRequirement({
                tokenId: uint256(dependantTokenIds[index]),
                necessaryTokenCount: necessaryTokenCount
            });
        }
    }

    /// @inheritdoc IFragmentMiniGame
    function constructTokenId(string calldata groupName, uint128 tokenIndex) external pure override returns (uint256) {
        return groupName.constructGroupId().constructFragmentTokenId(tokenIndex);
    }

    /// @inheritdoc IFragmentMiniGame
    function constructGroupId(string calldata groupName) external pure override returns (bytes16) {
        return groupName.constructGroupId();
    }

    /// @inheritdoc IFragmentMiniGame
    function deconstructTokenId(uint256 tokenId) external pure override returns (bytes16 groupId, uint128 tokenIndex) {
        return tokenId.deconstructTokenId();
    }

    /// @inheritdoc IFragmentMiniGame
    function burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) public override(ERC1155BurnableUpgradeable, IFragmentMiniGame) onlyRole(Roles.FRAGMENT_MINI_GAME_BURN) {
        ERC1155BurnableUpgradeable.burn(from, tokenId, amount);
    }

    /// @inheritdoc IFragmentMiniGame
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public override(ERC1155BurnableUpgradeable, IFragmentMiniGame) onlyRole(Roles.FRAGMENT_MINI_GAME_BURN) {
        ERC1155BurnableUpgradeable.burnBatch(account, ids, values);
    }

    /// @inheritdoc ERC1155Upgradeable
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString()));
    }

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IFragmentMiniGame).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyAdmin {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @dev set the base URI and emit an event.
    function _setBaseURI(string calldata baseUri) internal {
        _setURI(baseUri);

        emit UriSet(baseUri);
    }

    /// @dev Set the contract name and emit an event.
    function _setName(string calldata name_) internal {
        _name = name_;

        emit NameSet(name_);
    }

    /// @dev Set the contract symbol and emit an event.
    function _setSymbol(string calldata symbol_) internal {
        _symbol = symbol_;

        emit SymbolSet(symbol_);
    }

    /// @notice Assert that an Fragment group either exists or does not exist with a given groupId.
    /// @param groupId The Fragment group ID that we want to query.
    /// @param mustExist The sate of which the groupId must be in.
    /// @return fragmentGroup The Fragment group that's located at the corresponding `groupId`s location.
    function _checkFragmentGroup(bytes16 groupId, bool mustExist)
        internal
        view
        returns (FragmentGroup storage fragmentGroup)
    {
        fragmentGroup = _fragmentGroups[groupId];
        if ((_fragmentGroups[groupId].accountCap > 0) != mustExist) {
            if (mustExist) revert FragmentGroupShouldExist(groupId);
            revert FragmentGroupShouldNotExist(groupId);
        }
    }

    /// @notice Assert that an Object group either exists or does not exist with a given groupId.
    /// @param groupId the Object group ID that we want to query.
    /// @param mustExist The sate of which the groupId must be in.
    /// @return objectGroup The object group that's located at the corresponding `groupId`s location.
    /// @return dependantTokenIds minting requirement keys (tokenIds) for the amounts.
    function _checkObjectGroup(bytes16 groupId, bool mustExist)
        internal
        view
        returns (ObjectGroup storage objectGroup, bytes32[] memory dependantTokenIds)
    {
        objectGroup = _objectGroups[groupId];
        dependantTokenIds = objectGroup.mintingRequirements._keys.values();

        if ((dependantTokenIds.length > 0) != mustExist) {
            if (mustExist) revert ObjectGroupShouldExist(groupId);
            revert ObjectGroupShouldNotExist(groupId);
        }
    }
}
