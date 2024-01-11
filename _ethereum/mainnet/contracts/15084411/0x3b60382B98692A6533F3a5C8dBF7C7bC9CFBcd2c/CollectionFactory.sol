// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./ICollectionHelper.sol";
import "./ICollectionFactory.sol";
import "./IHinataStorage.sol";

contract CollectionFactory is ICollectionFactory, UUPSUpgradeable, OwnableUpgradeable {
    address public helper;
    address public hinataStorage;
    uint256 public royaltyLimit;
    uint256 public lastCollectionId;
    mapping(uint256 => Collection) public collections;
    mapping(address => uint256) public collectionIds;

    modifier notDuplicated(address collection) {
        require(
            collectionIds[collection] == 0 && collection != hinataStorage,
            "CollectionFactory: ALREADY_WHITELISTED"
        );
        _;
    }

    modifier checkRoyaltySum(address collection) {
        _;
        require(
            collections[collectionIds[collection]].royaltySum <= royaltyLimit,
            "CollectionFactory: ROYALTY_EXCEED"
        );
    }

    function initialize(
        address helper_,
        address storage_,
        uint256 limit_
    ) public initializer {
        require(helper_ != address(0), "CollectionFactory: INVALID_HELPER");
        require(storage_ != address(0), "CollectionFactory: INVALID_HINATA");
        require(limit_ <= 10000, "CollectionFactory: INVALID_LIMIT");

        __Ownable_init();
        __UUPSUpgradeable_init();

        helper = helper_;
        hinataStorage = storage_;
        royaltyLimit = limit_;
        _store(msg.sender, storage_, new Royalty[](0), false);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setHelper(address helper_) external onlyOwner {
        helper = helper_;
    }

    function setHinataStorage(address storage_) external onlyOwner {
        hinataStorage = storage_;
    }

    function setRoyaltyLimit(uint256 limit) external onlyOwner {
        royaltyLimit = limit;
    }

    function spawn(
        string memory name,
        string memory symbol,
        string memory uri,
        address[] memory beneficiaries,
        uint256[] memory percentages,
        bool is721
    ) external override returns (address) {
        Royalty[] memory royalties = _getRoyalties(beneficiaries, percentages);
        address nft = ICollectionHelper(helper).deploy(msg.sender, name, symbol, uri, is721);
        _store(msg.sender, address(nft), royalties, is721);
        return address(nft);
    }

    function register(
        address collection,
        address[] memory beneficiaries,
        uint256[] memory percentages
    ) external override notDuplicated(collection) {
        uint8 cType = ICollectionHelper(helper).getType(collection);
        require(cType > 0, "CollectionFactory: NOT_NFT_COLLECTION");

        (bool success, bytes memory data) = collection.call(
            abi.encodePacked(bytes4(keccak256("owner()")))
        );
        if (success) {
            address ret = abi.decode(data, (address));
            require(ret == msg.sender, "CollectionFactory: NOT_OWNER");
        }
        _store(msg.sender, collection, _getRoyalties(beneficiaries, percentages), cType == 1);
    }

    function _getRoyalties(address[] memory beneficiaries, uint256[] memory percentages)
        private
        pure
        returns (Royalty[] memory royalties)
    {
        require(beneficiaries.length == percentages.length, "CollectionFactory: INVALID_ARGUMENTS");

        royalties = new Royalty[](beneficiaries.length);
        for (uint256 i; i < beneficiaries.length; i += 1)
            royalties[i] = Royalty(beneficiaries[i], percentages[i], false);
    }

    function _store(
        address owner,
        address collection,
        Royalty[] memory royalties,
        bool is721
    ) private checkRoyaltySum(collection) {
        Collection storage collection_ = collections[lastCollectionId];
        collection_.owner = owner;
        collection_.collection = collection;
        uint256 sum;
        for (uint256 i; i < royalties.length; i += 1) {
            collection_.royalties.push(royalties[i]);
            sum += royalties[i].percentage;
        }
        collection_.royaltySum = sum;
        collection_.is721 = is721;
        collectionIds[collection] = lastCollectionId;
        lastCollectionId += 1;
        emit CollectionWhitelisted(lastCollectionId, owner, collection, royalties, is721);
    }

    function addRoyalty(
        address collection,
        address beneficiary,
        uint256 percentage
    ) external checkRoyaltySum(collection) {
        Collection storage collection_ = collections[collectionIds[collection]];
        require(collection_.owner == msg.sender, "CollectionFactory: NOT_OWER");
        require(percentage <= 10000, "CollectionFactory: INVALID_FEE");
        collection_.royalties.push(Royalty(beneficiary, percentage, false));
        collection_.royaltySum += percentage;
    }

    function removeRoyalties(address collection, uint256[] memory indexes) external {
        Collection storage collection_ = collections[collectionIds[collection]];
        require(collection_.owner == msg.sender, "CollectionFactory: NOT_OWER");
        for (uint256 i; i < indexes.length; i += 1) {
            collection_.royalties[indexes[i]].deleted = true;
            collection_.royaltySum -= collection_.royalties[indexes[i]].percentage;
        }
    }

    function isWhitelisted(address collection) external view override returns (bool) {
        return collectionIds[collection] != 0 || collection == hinataStorage;
    }

    function getCollection(address collection) external view override returns (Collection memory) {
        return collections[collectionIds[collection]];
    }

    function getCollectionRoyalties(address collection)
        external
        view
        override
        returns (Royalty[] memory)
    {
        Royalty[] memory royalties = collections[collectionIds[collection]].royalties;
        uint256 length;
        for (uint256 i; i < royalties.length; i += 1) if (!royalties[i].deleted) length += 1;
        Royalty[] memory activeRoyalties = new Royalty[](length);
        uint256 k;
        for (uint256 i; i < length; i += 1)
            if (!royalties[i].deleted) activeRoyalties[k++] = royalties[i];
        return activeRoyalties;
    }
}
