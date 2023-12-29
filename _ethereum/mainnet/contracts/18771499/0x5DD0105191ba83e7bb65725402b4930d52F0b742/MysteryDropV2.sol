// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IERC20.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./ICollectionV3.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorInterface.sol";
import "./MerkleProof.sol";

contract MysteryDropV2 is ReentrancyGuard, AccessControl {
    /**  Events **/
    event MysteryBoxDropped(
        uint8 tier,
        address collection,
        uint256 id,
        address user,
        uint32 version
    );

    event MysteryBoxCC(uint8 tier, address user, string purchaseId);

    /** Structs **/
    struct Item {
        uint256 startTokenId;
        uint256 endTokenId;
        ICollectionV3 collection;
    }
    struct Tier {
        uint16 available;
        uint256 amount;
        uint16 rewards;
    }
    struct Purchase {
        uint256 amount;
        uint32 version;
    }
    /* Storage */
    mapping(address => Purchase) public bought;
    // General drop paramaters
    IERC20 public erc20;
    address public treasurer;
    bytes32 public root;
    uint256 public maxPerWallet;
    uint256 public whitelistStartTime;
    uint256 public startTime;
    uint256 public endTime;
    Tier[] public tiers;

    // Tree data structure
    // About 40% gas cost reduction by using uint16. Limited to max 64K nfts.
    Item[] public items;
    uint16[] public tree;
    uint16 start_leaf;
    uint16 tree_length;
    uint32 current_version;

    address[] nftHolderAddresses;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        current_version = 0;
    }

    modifier isStarted() {
        require(
            startTime <= block.timestamp && endTime > block.timestamp,
            "Drop has not started yet!"
        );
        _;
    }

    modifier isWhitelistStarted() {
        require(
            whitelistStartTime <= block.timestamp && endTime > block.timestamp,
            "Drop whitelist has not started yet!"
        );
        _;
    }

    /** Public functions **/
    /*
     * Get the number of available boxes for a tier
     */
    function getAvailable(uint8 _tier) public view returns (uint256) {
        if (_tier >= tiers.length) {
            return 0;
        }

        return tiers[_tier].available;
    }

    function _validatePurchase(
        address _user,
        uint8 _tier,
        uint8 _quantity
    ) internal {
        require(_tier < tiers.length, "Invalid tier id");
        require(tiers[_tier].available >= _quantity, "Sold out");

        if (bought[_user].version != current_version) {
            bought[_user].amount = 0;
            bought[_user].version = current_version;
        }
        require(
            bought[_user].amount + _quantity <= maxPerWallet,
            "Limit per wallet reached"
        );
        bought[_user].amount += _quantity;
    }

    function _takeFunds(address _user, uint8 _tier, uint8 quantity) internal {
        uint256 _amount = tiers[_tier].amount * quantity;
        require(
            erc20.transferFrom(_user, treasurer, _amount),
            "Payment was unsuccessful"
        );
    }

    function _sendMysteryBox(
        address _user,
        uint8 _tier,
        uint8 _quantity
    ) internal {
        for (uint8 j = 0; j < _quantity; j++) {
            for (uint256 i = 0; i < tiers[_tier].rewards; i++) {
                (ICollectionV3 collection, uint256 tokenId) = _pickNft(
                    j * _quantity + i
                );
                mint(collection, _user, tokenId);
                emit MysteryBoxDropped(
                    _tier,
                    address(collection),
                    tokenId,
                    _user,
                    current_version
                );
            }
        }
    }

    function _purchaseMysteryBox(
        address _user,
        uint8 _tier,
        uint8 _quantity
    ) internal {
        tiers[_tier].available -= _quantity;
        _sendMysteryBox(_user, _tier, _quantity);
    }

    /*
     *This function picks random card and mints this random card to user
     */
    function buyMysteryBox(
        uint8 _tier,
        uint8 quantity
    ) external isStarted nonReentrant {
        address _user = _msgSender();
        _validatePurchase(_user, _tier, quantity);
        _takeFunds(_user, _tier, quantity);
        _purchaseMysteryBox(_user, _tier, quantity);
    }

    function buyWithWhitelist(
        uint8 _tier,
        uint8 quantity,
        bytes32[] calldata proof
    ) external isWhitelistStarted nonReentrant {
        address _user = _msgSender();
        require(isWhitelisted(_user, proof), "User is not whitelisted");
        _validatePurchase(_user, _tier, quantity);
        _takeFunds(_user, _tier, quantity);
        _purchaseMysteryBox(_user, _tier, quantity);
    }

    /*
     *User can buy mysteryBox via this function with creditcard
     */
    function buyCreditMysteryBox(
        address _user,
        uint8 _tier,
        uint8 _quantity,
        string calldata _purchaseId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _validatePurchase(_user, _tier, _quantity);
        _purchaseMysteryBox(_user, _tier, _quantity);
        emit MysteryBoxCC(_tier, _user, _purchaseId);
    }

    function mintTo(
        address _user,
        uint8 _tier,
        uint8 _quantity
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tier < tiers.length, "Invalid tier id");
        require(
            tree[0] >= tiers[_tier].rewards * _quantity,
            "Not enough nfts left"
        );
        _sendMysteryBox(_user, _tier, _quantity);
    }

    function isWhitelisted(
        address _user,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return
            MerkleProof.verify(proof, root, keccak256(abi.encodePacked(_user)));
    }

    function mint(
        ICollectionV3 collection,
        address user,
        uint256 tokenId
    ) internal {
        for (uint8 i = 0; i < nftHolderAddresses.length; i++) {
            if (collection.balanceOf(nftHolderAddresses[i], tokenId) > 0) {
                collection.safeTransferFrom(
                    nftHolderAddresses[i],
                    user,
                    tokenId,
                    1,
                    ""
                );
                return;
            }
        }
        collection.mint(user, tokenId);
    }

    function setNftHolderAddresses(
        address[] memory _nftHolderAddresses
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete nftHolderAddresses;
        for (uint8 i = 0; i < _nftHolderAddresses.length; i++) {
            nftHolderAddresses.push(_nftHolderAddresses[i]);
        }
    }

    /** Code for managing drop paramaters **/
    function setGeneralDropParamaters(
        address _erc20,
        uint256 _maxPerWallet,
        uint256 _whitelistStartTime,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        erc20 = IERC20(_erc20);
        maxPerWallet = _maxPerWallet;
        startTime = _startTime;
        endTime = _endTime;
        whitelistStartTime = _whitelistStartTime;
    }

    function setTreasurer(
        address _treasurer
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        treasurer = _treasurer;
    }

    function setRoot(bytes32 _root) public onlyRole(DEFAULT_ADMIN_ROLE) {
        root = _root;
    }

    function setTiersParamaters(
        Tier[] calldata _tiers
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete tiers;
        for (uint256 i = 0; i < _tiers.length; i++) {
            tiers.push(_tiers[i]);
        }
    }

    /** Code related to the tree structure used to store items in the pack **/
    function resetItems() public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete items;
        start_leaf = 0;
        tree_length = 0;
        delete tree;
        current_version += 1;
    }

    function addItems(
        Item[] calldata _items
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _items.length; i++) {
            items.push(_items[i]);
        }
    }

    function preCompute() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint64 log;
        while (2 ** log < items.length) {
            log++;
        }
        start_leaf = uint16((2 ** log) - 1);
        tree_length = uint16(2 ** (log + 1) - 1);
        tree = new uint16[](tree_length);

        uint64 j = 0;
        for (
            uint64 i = uint64(start_leaf);
            (i < tree_length) && (j < items.length);
            i++
        ) {
            tree[i] = uint16(
                items[i - start_leaf].endTokenId -
                    items[i - start_leaf].startTokenId +
                    1
            );

            j++;
        }
        if (tree_length > 1) {
            for (uint256 i = (2 ** log) - 2; i >= 1; i--) {
                tree[i] = tree[2 * i + 1] + tree[2 * i + 2];
            }
            tree[0] = tree[1] + tree[2];
        }
    }

    function _pickNft(uint256 seed) internal returns (ICollectionV3, uint256) {
        uint16 position = uint16(_getRandom(tree[0], seed));
        uint16 item = _findPosition(position);

        _removeOne(item);
        require(
            items[item].startTokenId <= items[item].endTokenId,
            "Nft reward soldout"
        );
        uint256 tokenId = items[item].startTokenId;
        ICollectionV3 collection = items[item].collection;
        items[item].startTokenId += 1;
        return (collection, tokenId);
    }

    function _getRandom(
        uint256 gamerange,
        uint256 seed
    ) internal view returns (uint256) {
        return
            1 +
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        keccak256(abi.encodePacked(block.coinbase)),
                        seed
                    )
                )
            ) % gamerange);
    }

    function _findPosition(uint16 value) internal view returns (uint16) {
        uint16 i = 0;
        require(tree[0] >= value, "Value is bigger than remaining elements");

        while (2 * i + 2 < tree_length) {
            uint16 left = 2 * i + 1;
            uint16 right = 2 * i + 2;

            if (value <= tree[left]) {
                i = left;
            } else {
                i = right;
                value = value - tree[left];
            }
        }

        return i - start_leaf;
    }

    function _removeOne(uint16 position) internal {
        uint16 i = position + start_leaf;
        require(tree[i] > 0, "Element is already containing 0 values");

        tree[i]--;

        while (i > 0) {
            if (i % 2 == 1) {
                i++;
            }
            uint16 parent = (i / 2) - 1;
            tree[parent] = tree[i - 1] + tree[i];
            i = parent;
        }
    }
}
