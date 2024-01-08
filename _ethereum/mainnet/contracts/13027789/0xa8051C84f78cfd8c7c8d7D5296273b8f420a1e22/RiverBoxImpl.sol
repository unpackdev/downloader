// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma abicoder v2;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IRiverBox.sol";
import "./IRiverBoxRandom.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract RiverBoxImpl is
    IRiverBox,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    CountersUpgradeable.Counter private _tokenIds;

    uint16[] private _stockLocations;
    uint32[] private _stockSignatures;
    uint32 private _stockCounter;

    /* ================ GLOBAL CONFIGURATION ================ */

    // price per box - Pawn
    uint256 public boxPrice;

    uint256 public totalClaimableAmount;

    string public baseURI;

    address public randomGeneratorAddress;

    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => Product) private _tokenDetailsMapping;

    mapping(address => uint256) public paidBoxes; // number of boxes user has bought

    mapping(uint256 => Hierarchy) private _tokenHierarchyMapping;

    mapping(address => uint256) public claimableAmountMapping;

    mapping(address => uint256) public referrerContrib;

    uint256 public totalReferrerContrib;

    address proxyRegistryAddress;

    /* ================ SHARES ================ */
    address public funderAddress;
    address public devAddress;
    address public marketAddress;
    uint8 public devShare;
    uint8 public marketShare;
    bool public fuseLock;

    function initialize(
        uint256 _boxPrice,
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _proxyRegistryAddress
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __ERC721_init(_name, _symbol);
        __UUPSUpgradeable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _pause();
        fuseLock = true;
        boxPrice = _boxPrice;
        baseURI = _initBaseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /* ================ UTIL FUNCTIONS ================ */
    function _pickLocation(uint256 index) internal returns (uint16, uint32) {
        uint256 lastIndex = _stockLocations.length - 1;

        uint16 lastStockLocation = _stockLocations[lastIndex];
        uint16 locationId = _stockLocations[index];
        _stockLocations[index] = lastStockLocation;
        _stockLocations.pop();

        uint32 lastSignature = _stockSignatures[lastIndex];
        uint32 signature = _stockSignatures[index];
        _stockSignatures[index] = lastSignature;
        _stockSignatures.pop();
        return (locationId, signature);
    }

    /* ================ VIEWS ================ */
    function pawnsStock() public view returns (uint256) {
        return _stockLocations.length.sub(totalClaimableAmount);
    }

    function batchStockInfo(uint256 startIndex, uint256 length)
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        require(startIndex < _stockLocations.length, "startIndex cannot over stockLocationsLength");
        require(length > 0, "length cannot equal 0");
        uint256 endIndex = MathUpgradeable.min(startIndex + length, _stockLocations.length);
        uint256 realLength = endIndex - startIndex;
        uint256[] memory locationIds = new uint256[](realLength);
        uint256[] memory signatures = new uint256[](realLength);
        for (uint256 idx = 0; idx < realLength; ++idx) {
            locationIds[idx] = _stockLocations[startIndex.add(idx)];
            signatures[idx] = _stockSignatures[startIndex.add(idx)];
        }
        return (locationIds, signatures);
    }

    /**
     * @dev Ultimate view for inspecting a token
     * @param tokenId the unique ID of a RiverMenNFT token
     * @return [[locationId, fusionCount, signature, creationTime, parts], ownerAddress, tokenURI, dealId]
     * @notice dealId = 0 means the item is not listed in exchange
     */
    function allInfo(uint256 tokenId)
        public
        view
        returns (
            Product memory,
            address,
            string memory
        )
    {
        require(_exists(tokenId), "Token not exists");
        return (_tokenDetailsMapping[tokenId], ownerOf(tokenId), tokenURI(tokenId));
    }

    /**
     * @dev Get token detail information
     */
    function tokenHierarchy(uint256 locationId) public view override returns (Hierarchy memory) {
        return _tokenHierarchyMapping[locationId];
    }

    /**
     * @dev Get token detail information
     */
    function tokenDetail(uint256 tokenId) public view override returns (Product memory) {
        require(_exists(tokenId), "Token not exists");
        return _tokenDetailsMapping[tokenId];
    }

    /**
     * @dev Verify if a list of parts can be used to fuse new product
     */
    function verifyFusion(uint256[] memory tokenIds) public view override returns (bool) {
        if (tokenIds.length == 0) return false;
        require(_exists(tokenIds[0]), "Token not exists");
        uint16 parentLocationId = _tokenHierarchyMapping[_tokenDetailsMapping[tokenIds[0]].locationId].parentLocationId;
        if (parentLocationId == 0) return false;
        uint16[] memory childLocationIds = _tokenHierarchyMapping[parentLocationId].childLocationIds;
        if (childLocationIds.length != tokenIds.length) return false;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "Token not exists");
            if (_tokenDetailsMapping[tokenId].fusionCount > 0) return false;
            if (_tokenHierarchyMapping[_tokenDetailsMapping[tokenId].locationId].parentLocationId != parentLocationId)
                return false;
            if (ownerOf(tokenId) != _msgSender()) return false;
            // check duplicate TODO: find a more effective way and without using hash
            for (uint256 j = i + 1; j < tokenIds.length; ++j) {
                if (tokenId == tokenIds[j]) return false;
            }
        }
        return true;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(IRiverBox, ERC721Upgradeable) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        } else {
            return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : "";
        }
    }

    function implementationVersion() public pure override returns (string memory) {
        return "1.2.1";
    }

    /* ================ PRIVATE FUNCTIONS ================ */
    function _notContract() internal view {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
    }

    /**
     * @dev Mint a new Item
     * @param receiver account address to receive the new item
     */
    function _awardItem(address receiver) private returns (uint256) {
        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _safeMint(receiver, newId);
        return newId;
    }

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission to do upgrades");
    }

    /* ================ TRANSACTIONS ================ */
    /**
     * @dev Buy N (n<10) boxes, this function receive payment and
     * mint new product(s) to sender
     * @param quality number of boxes
     * @param referrer referrer account address
     */
    function buy(uint256 quality, address referrer) external payable override whenNotPaused nonReentrant {
        _notContract();
        require(quality <= pawnsStock(), "blind box sold out");
        require(quality <= 20, "exceed maximum quality 20");
        require(msg.value >= boxPrice.mul(quality), "payment is less than box price");
        boxesAward(quality, _msgSender());
        if (referrer != address(0)) {
            referrerContrib[referrer] = referrerContrib[referrer].add(quality);
            totalReferrerContrib = totalReferrerContrib.add(quality);
        }
        paidBoxes[_msgSender()] = paidBoxes[_msgSender()].add(quality);
    }

    function boxesAward(uint256 quality, address receiver) internal {
        uint256 salt = uint256(keccak256(abi.encodePacked(quality, receiver, totalSupply())));
        uint256 seed = IRiverBoxRandom(randomGeneratorAddress).generateSignature(salt);
        for (uint256 i = 0; i < quality; ++i) {
            seed = seed.add(totalSupply());
            uint256 randomIdx = uint256(keccak256(abi.encodePacked(seed))).mod(_stockLocations.length);
            (uint16 pawnLocationId, uint32 signature) = _pickLocation(randomIdx);
            Product memory newItem = Product(pawnLocationId, 0, signature, new uint256[](0));
            uint256 newId = _awardItem(receiver);
            _tokenDetailsMapping[newId] = newItem;
            emit BoxAwarded(receiver, newId, block.timestamp);
        }
    }

    /**
     * @dev Fuse a list of items to a next level product
     */
    function fuse(uint256[] memory tokenIds) external override whenNotPaused nonReentrant {
        _notContract();
        require(!fuseLock, "fusing is locked");
        require(verifyFusion(tokenIds), "not a valid list of tokens");
        uint16 parentLocationId = _tokenHierarchyMapping[_tokenDetailsMapping[tokenIds[0]].locationId].parentLocationId;
        Product memory newItem = Product(parentLocationId, 0, 0, tokenIds);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _tokenDetailsMapping[tokenIds[i]].fusionCount = _tokenDetailsMapping[tokenIds[i]].fusionCount + 1;
        }
        uint256 newId = _awardItem(_msgSender());
        _tokenDetailsMapping[newId] = newItem;
        emit FusedItemAwarded(_msgSender(), newId, block.timestamp);
    }

    /* ================ ADMIN ACTIONS ================ */
    /**
     * @dev Set a new base URI
     * param newBaseURI new baseURI address
     */
    function setBaseURI(string memory newBaseURI) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        baseURI = newBaseURI;
    }

    /**
     * @dev Set Hierarchy information to a specific node with locationId in batch
     * param locationIds A batch of locationId
     * param parentLocationIds A batch of parentLocationIds
     * param listChildLocationIds A batch of childLocationIds
     */
    function setHierarchy(
        uint16[] memory locationIds,
        uint16[] memory parentLocationIds,
        uint16[][] memory listChildLocationIds
    ) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        for (uint256 i = 0; i < locationIds.length; ++i) {
            _tokenHierarchyMapping[locationIds[i]] = Hierarchy(parentLocationIds[i], listChildLocationIds[i]);
        }
    }

    function batchSetPawnLocationStock(uint16[] memory locationIds, uint16[] memory locationIdStocks) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        for (uint16 locationIdx = 0; locationIdx < locationIds.length; ++locationIdx) {
            uint16 locationId = locationIds[locationIdx];
            uint16 locationIdStock = locationIdStocks[locationIdx];
            for (uint16 stockIdx = 0; stockIdx < locationIdStock; ++stockIdx) {
                _stockLocations.push(locationId);
                _stockCounter = _stockCounter + 1;
                require(_stockCounter >= 1, "SafeMath: addition overflow");
                _stockSignatures.push(_stockCounter);
            }
        }
    }

    /**
     * @dev Triggers stopped state.
     */
    function pause() external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        _pause();
    }

    /**
     * @dev Returns to normal state.
     */
    function unPause() external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        _unpause();
    }

    /**
     * @dev Triggers stopped state.
     * @param newPrice new box price
     */
    function setBoxPrice(uint256 newPrice) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        boxPrice = newPrice;
        emit BoxPriceChanged(boxPrice, newPrice);
    }

    function setFuseLock(bool lock) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        fuseLock = lock;
    }

    /**
     * @dev Set random generator contract address
     * @param newAddress new random generator address
     */
    function setRandomGenerator(address newAddress) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        randomGeneratorAddress = newAddress;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setShare(
        address _funderAddress,
        address _devAddress,
        address _marketAddress,
        uint8 _devShare,
        uint8 _marketShare
    ) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        funderAddress = _funderAddress;
        devAddress = _devAddress;
        marketAddress = _marketAddress;
        devShare = _devShare;
        marketShare = _marketShare;
    }

    function withdraw(uint256 amount) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        require(address(this).balance >= amount, "amount exceeds balance");
        uint256 devAmount = amount.mul(uint256(devShare)).div(100);
        uint256 marketAmount = amount.mul(uint256(marketShare)).div(100);
        payable(devAddress).transfer(devAmount);
        payable(marketAddress).transfer(marketAmount);
        payable(funderAddress).transfer(amount.sub(devAmount).sub(marketAmount));
    }

    function batchAirDrop(address[] memory receivers, uint256[] memory qualities) external override {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "require admin permission");
        require(receivers.length == qualities.length, "receivers length must equal qualities length");
        for (uint256 i = 0; i < qualities.length; ++i) {
            require(qualities[i] <= pawnsStock(), "out of stock");
            totalClaimableAmount = totalClaimableAmount.add(qualities[i]);
            claimableAmountMapping[receivers[i]] = claimableAmountMapping[receivers[i]].add(qualities[i]);
        }
    }

    function claim(uint256 amount) external override whenNotPaused nonReentrant {
        _notContract();
        require(amount <= claimableAmountMapping[_msgSender()], "out of claimable balance");
        boxesAward(amount, _msgSender());
        claimableAmountMapping[_msgSender()] = claimableAmountMapping[_msgSender()].sub(amount);
        totalClaimableAmount = totalClaimableAmount.sub(amount);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        //Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(owner, operator);
    }
}
