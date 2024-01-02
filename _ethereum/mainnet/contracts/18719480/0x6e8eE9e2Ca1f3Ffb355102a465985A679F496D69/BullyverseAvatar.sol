//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721AQueryableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

interface IBully {
    function batchStakeFor(address owner, uint256[] calldata tokenIds) external;
    function batchUnstakeFor(address owner, uint256[] calldata tokenIds) external;
    function adminStake(uint256[] calldata maleTokenIds, uint256[] calldata femaleTokenIds) external;
    function adminUnstake(uint256[] calldata maleTokenIds, uint256[] calldata femaleTokenIds) external;
}

// Mint errors
error SignatureMismatch();
error InvalidQuantity();
error IncorrectPrice();
error MaxSupplyExceeded();
error MaxMintPerAddressExceeded();
error AllowlistMintNotStarted();
error PublicMintNotStarted();
error TransferDisabled();
error ContractsNotAllowed();
error ContractPaused();

// Staking errors
error InvalidToken();
error AlreadyStaking();
error NotStaking();

contract BullyverseAvatar is
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public allowlistMintStartTime;
    uint256 public allowlistMintEndTime;
    uint256 public allowlistMintPrice;
    uint256 public allowlistMintDiscountPrice;

    uint256 public publicMintStartTime;
    uint256 public publicMintEndTime;
    uint256 public publicMintPrice;
    uint256 public publicMintDiscountPrice;

    uint256 public MAX_SUPPLY;

    uint256 public MAX_PUBLIC1_MINTS;
    uint256 public MAX_MINT_PER_ADDRESS;

    address private signer;

    string private tokenBaseURI;
    string private hiddenMetadataURI;
    bool public transferEnabled;
    bool public paused;

    IBully public maleBully;
    IBully public femaleBully;

    mapping (address => bool) public admins;
    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp
    event Stake(uint256 indexed tokenId);
    event Unstake(uint256 indexed tokenId, uint256 stakedAtTimestamp, uint256 removedFromStakeAtTimestamp);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _signer, address _maleBully, address _femaleBully) public initializer initializerERC721A {
        __ERC721A_init("Bullyverse Avatars", "BVA");
        __Ownable_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();

        signer = _signer;

        allowlistMintPrice = 0.0369 ether;
        allowlistMintDiscountPrice = 0.03338 ether;

        publicMintPrice = 0.045 ether;
        publicMintDiscountPrice = 0.043 ether;

        MAX_PUBLIC1_MINTS = 5;
        MAX_MINT_PER_ADDRESS = 20;

        MAX_SUPPLY = 2500;

        maleBully = IBully(_maleBully);
        femaleBully = IBully(_femaleBully);

        hiddenMetadataURI = "https://cdn.bullyverse.io/nft/metadata/avatar/avatar_pre_reveal.json";
    }

    // =========================================================================
    //                              Token Logic
    // =========================================================================

    function mintAllowlist(uint256 quantity, uint256 allowedQuantity, bool staked, bytes calldata signature) external payable whenNotPaused {
        if (allowlistMintStartTime == 0 || block.timestamp < allowlistMintStartTime || block.timestamp >= allowlistMintEndTime) revert AllowlistMintNotStarted();
        bytes32 hash = ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    allowedQuantity
                )
            )
        );
        if (ECDSAUpgradeable.recover(hash, signature) != signer) revert SignatureMismatch();

        if (quantity > allowedQuantity) revert InvalidQuantity();

        uint256 allowListMints = getBits(_getAux(msg.sender), 0, 8);
        if (allowListMints + quantity > allowedQuantity) revert MaxMintPerAddressExceeded();

        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();

        uint256 mintPrice;
        if (staked && quantity == allowedQuantity) {
            mintPrice = allowlistMintDiscountPrice;
        } else {
            mintPrice = allowlistMintPrice;
        }
        if (msg.value != mintPrice * quantity) revert IncorrectPrice();

        _setAux(msg.sender, _getAux(msg.sender) + uint64(quantity));
        uint256 nextTokenId = _nextTokenId();
        _mint(msg.sender, quantity);
        if (staked) {
            for (uint256 i = 0; i < quantity; i++) {
                _stake(nextTokenId + i);
            }
        }

        if (totalSupply() == MAX_SUPPLY) {
            transferEnabled = true;
        }
    }

    function mintPublic1(uint256 quantity, bool staked) external payable whenNotPaused {
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        if (publicMintStartTime == 0 || block.timestamp < publicMintStartTime || block.timestamp >= publicMintEndTime) revert PublicMintNotStarted();
        if (quantity > MAX_PUBLIC1_MINTS) revert InvalidQuantity();

        uint256 allowListMints = getBits(_getAux(msg.sender), 0, 8);
        uint256 public1Mints = getBits(_getAux(msg.sender), 8, 8);
        if (allowListMints + public1Mints + quantity > MAX_PUBLIC1_MINTS) revert MaxMintPerAddressExceeded();

        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();

        uint256 mintPrice;
        if (staked && quantity == MAX_PUBLIC1_MINTS) {
            mintPrice = publicMintDiscountPrice;
        } else {
            mintPrice = publicMintPrice;
        }
        if (msg.value != mintPrice * quantity) revert IncorrectPrice();

        _setAux(msg.sender, _getAux(msg.sender) + uint64(quantity << 8));
        uint256 nextTokenId = _nextTokenId();
        _mint(msg.sender, quantity);
        if (staked) {
            for (uint256 i = 0; i < quantity; i++) {
                _stake(nextTokenId + i);
            }
        }

        if (totalSupply() == MAX_SUPPLY) {
            transferEnabled = true;
        }
    }

    function mintPublic2(uint256 quantity) external payable whenNotPaused {
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        if (publicMintEndTime == 0 || block.timestamp < publicMintEndTime) revert PublicMintNotStarted();

        uint256 public2Mints = getBits(_getAux(msg.sender), 16, 8);
        if (public2Mints + quantity > MAX_MINT_PER_ADDRESS) revert MaxMintPerAddressExceeded();

        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
        if (msg.value != publicMintPrice * quantity) revert IncorrectPrice();

        _setAux(msg.sender, _getAux(msg.sender) + uint64(quantity << 16));
        _mint(msg.sender, quantity);
        if (totalSupply() == MAX_SUPPLY) {
            transferEnabled = true;
        }
    }

    function mintPublic2WithDiscount(uint256 quantity, bool staked) external payable whenNotPaused {
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        if (publicMintEndTime == 0 || block.timestamp < publicMintEndTime) revert PublicMintNotStarted();

        uint256 public2Mints = getBits(_getAux(msg.sender), 16, 8);
        if (public2Mints + quantity > MAX_MINT_PER_ADDRESS) revert MaxMintPerAddressExceeded();

        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();

        uint256 mintCost = getMintCost(quantity, staked);
        if (msg.value != mintCost) revert IncorrectPrice();

        _setAux(msg.sender, _getAux(msg.sender) + uint64(quantity << 16));
        uint256 nextTokenId = _nextTokenId();
        _mint(msg.sender, quantity);
        if (staked) {
            for (uint256 i = 0; i < quantity; i++) {
                _stake(nextTokenId + i);
            }
        }

        if (totalSupply() == MAX_SUPPLY) {
            transferEnabled = true;
        }
    }

    function mintReserved(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY) revert MaxSupplyExceeded();
        _mint(to, quantity);
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from == address(0)) {
            return;
        }
        if (!transferEnabled) revert TransferDisabled();
    }

    // External functions

    function getBits(uint256 n, uint256 start, uint256 len) internal pure returns (uint256) {
        uint256 mask = ((1 << len) - 1) << start;
        uint256 ret = n & mask;
        return ret >> start;
    }

    function getAllowListMints(address minter) public view returns (uint256) {
        return getBits(_getAux(minter), 0, 8);
    }

    function getPublic1Mints(address minter) public view returns (uint256) {
        return getBits(_getAux(minter), 8, 8);
    }

    function getPublic2Mints(address minter) public view returns (uint256) {
        return getBits(_getAux(minter), 16, 8);
    }

    function getTotalMints(address minter) external view returns (uint256) {
        return _numberMinted(minter);
    }

    function getMintCost(uint256 quantity, bool staked) public view returns (uint256) {
        uint256 cost = publicMintPrice * quantity;

        // quantity < 10 || !staked
        if (quantity < 10 || !staked) {
            return cost;
        }

        // 10 <= quantity < 20
        if (quantity < 20) {
            return cost * 75 / 100;
        }

        // 20 <= quantity
        return cost * 50 / 100;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        bool revealed = bytes(tokenBaseURI).length > 0;
        if (revealed) {
            return super.tokenURI(tokenId);
        } else {
            return hiddenMetadataURI;
        }
    }

    // =========================================================================
    //                              Staking
    // =========================================================================
    function _stake(uint256 tokenId) internal {
        if (tokensLastStakedAt[tokenId] > 0) {
            revert AlreadyStaking();
        }
        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId);
    }

    function _unstake(uint256 tokenId) internal {
        if (tokensLastStakedAt[tokenId] == 0) {
            revert NotStaking();
        }
        uint256 stakedAtTimestamp = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, stakedAtTimestamp, block.timestamp);
    }

    function batchStake(uint256[] calldata tokenIds, uint256[] calldata maleTokenIds, uint256[] calldata femaleTokenIds) external {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            stake(tokenIds[i]);
            unchecked { ++i; }
        }
        if (maleTokenIds.length > 0) {
            maleBully.batchStakeFor(msg.sender, maleTokenIds);
        }
        if (femaleTokenIds.length > 0) {
            femaleBully.batchStakeFor(msg.sender, femaleTokenIds);
        }
    }

    function batchUnstake(uint256[] calldata tokenIds, uint256[] calldata maleTokenIds, uint256[] calldata femaleTokenIds) external {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            unstake(tokenIds[i]);
            unchecked { ++i; }
        }
        if (maleTokenIds.length > 0) {
            maleBully.batchUnstakeFor(msg.sender, maleTokenIds);
        }
        if (femaleTokenIds.length > 0) {
            femaleBully.batchUnstakeFor(msg.sender, femaleTokenIds);
        }
    }

    function adminStake(uint256[] calldata tokenIds, uint256[] calldata maleTokenIds, uint256[] calldata femaleTokenIds) external onlyOperator {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            _stake(tokenIds[i]);
            unchecked { ++i; }
        }
        maleBully.adminStake(maleTokenIds, femaleTokenIds);
    }

    function adminUnstake(uint256[] calldata tokenIds, uint256[] calldata maleTokenIds, uint256[] calldata femaleTokenIds) external onlyOperator {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            _unstake(tokenIds[i]);
            unchecked { ++i; }
        }
        maleBully.adminUnstake(maleTokenIds, femaleTokenIds);
    }

    function stake(uint256 tokenId) public {
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidToken();
        }
        _stake(tokenId);
    }

    function unstake(uint256 tokenId) public {
        if (msg.sender != ownerOf(tokenId)) {
            revert InvalidToken();
        }
        _unstake(tokenId);
    }

    /* Modifiers */

    modifier onlyOperator() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    // =========================================================================
    //                              Admin Functions
    // =========================================================================

    function setMintStartTime(
        uint256 _allowlistMintStartTime,
        uint256 _allowlistMintEndTime,
        uint256 _publicMintStartTime,
        uint256 _publicMintEndTime
    ) external onlyOwner {
        allowlistMintStartTime = _allowlistMintStartTime;
        allowlistMintEndTime = _allowlistMintEndTime;

        publicMintStartTime = _publicMintStartTime;
        publicMintEndTime = _publicMintEndTime;
    }

    function setSupply(uint256 _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function setMaxPublic1Mints(uint256 _maxPublic1Mints) external onlyOwner {
        MAX_PUBLIC1_MINTS = _maxPublic1Mints;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress) external onlyOwner {
        MAX_MINT_PER_ADDRESS = _maxMintPerAddress;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function setTokenBaseURI(string memory _tokenBaseURI) external onlyOwner {
        tokenBaseURI = _tokenBaseURI;
    }

    function setHiddenMetadataURI(string memory _hiddenURI) external onlyOwner {
        hiddenMetadataURI = _hiddenURI;
    }

    function setAllowlistMintPrice(uint256 _mintPrice, uint256 _discountPrice) external onlyOwner {
        allowlistMintPrice = _mintPrice;
        allowlistMintDiscountPrice = _discountPrice;
    }

    function setPublicMintPrice(uint256 _mintPrice, uint256 _discountPrice) external onlyOwner {
        publicMintPrice = _mintPrice;
        publicMintDiscountPrice = _discountPrice;
    }

    function emergencySetTransferEnabled(bool _enabled) external onlyOwner {
        transferEnabled = _enabled;
    }

    function setAdmin(address admin, bool status) external onlyOwner {
        admins[admin] = status;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(address token) external onlyOwner {
        uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20Upgradeable(token).safeTransfer(owner(), balance);
        }
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setApprovalForAll(address operator, bool approved)
        public
        override (IERC721AUpgradeable, ERC721AUpgradeable)
    {
        if (!transferEnabled) revert TransferDisabled();
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override (IERC721AUpgradeable, ERC721AUpgradeable)
    {
        if (!transferEnabled) revert TransferDisabled();
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721AUpgradeable, ERC721AUpgradeable)
    {
        if (!transferEnabled) revert TransferDisabled();
        if (tokensLastStakedAt[tokenId] > 0) revert AlreadyStaking();
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override (IERC721AUpgradeable, ERC721AUpgradeable)
    {
        if (!transferEnabled) revert TransferDisabled();
        if (tokensLastStakedAt[tokenId] > 0) revert AlreadyStaking();
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override (IERC721AUpgradeable, ERC721AUpgradeable)
    {
        if (!transferEnabled) revert TransferDisabled();
        if (tokensLastStakedAt[tokenId] > 0) revert AlreadyStaking();
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =========================================================================
    //                                  ERC721A
    // =========================================================================

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return ERC721AUpgradeable.supportsInterface(interfaceId)
            || ERC2981Upgradeable.supportsInterface(interfaceId);
    }
}
