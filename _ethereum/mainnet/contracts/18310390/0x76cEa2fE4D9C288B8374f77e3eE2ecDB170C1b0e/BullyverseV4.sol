//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ECDSAUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./IBully.sol";

error InvalidInput();
error MaxSupplyReached();

contract BullyverseV4 is
    ERC721Upgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    UUPSUpgradeable
{
    string internal baseURI;

    uint256 public MAX_SUPPLY;
    uint256 public numberAirdropped;

    // =============== V2 ===============
    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp
    event Stake(uint256 indexed tokenId);
    event Unstake(uint256 indexed tokenId, uint256 stakedAtTimestamp, uint256 removedFromStakeAtTimestamp);

    // =============== V3 ===============
    bool public transferDisabled;
    mapping (address => bool) public admins;

    // =============== V4 ===============
    bool public useOldCollectionUrl;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address royaltyReceiver, uint96 royaltyFeeNumerator) public initializer {
        __ERC721_init("Bullyverse", "BV");
        __ERC2981_init();
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __UUPSUpgradeable_init();

        MAX_SUPPLY = 5000;
        baseURI = "https://cdn.bullyverse.io/nft/metadata/";
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
    }

    // =========================================================================
    //                              Token Logic
    // =========================================================================

    function airdrop(
        address[] calldata owners,
        uint256[] calldata tokenIds,
        uint256[] calldata airdropTokenIds
    ) external onlyOwner {
        uint256 size = tokenIds.length;
        if (owners.length != size || airdropTokenIds.length != size) {
            revert InvalidInput();
        }
        if (numberAirdropped + size + size > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        for (uint256 i = 0; i < size;) {
            address owner = owners[i];
            _mint(owner, tokenIds[i]);
            _mint(owner, airdropTokenIds[i]);
            unchecked {
                ++i;
            }
        }

        unchecked {
            numberAirdropped += size + size;
        }
    }

    function mintFor(address owner, uint256 tokenId) external onlyOwner {
        if (numberAirdropped + 1 > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }
        _mint(owner, tokenId);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // V2
    function batchStake(uint256[] calldata tokenIds) public {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            stake(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function batchUnstake(uint256[] calldata tokenIds) public {
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            unstake(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    function stake(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "Not token owner");
        require(tokensLastStakedAt[tokenId] == 0, "Token already staking");
        tokensLastStakedAt[tokenId] = block.timestamp;
        emit Stake(tokenId);
    }

    function unstake(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "Not token owner");
        require(tokensLastStakedAt[tokenId] > 0, "Token not staking");
        uint256 stakedAtTimestamp = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, stakedAtTimestamp, block.timestamp);
    }

    // V3
    function setAdmin(address admin, bool isAdmin) external onlyOwner {
        admins[admin] = isAdmin;
    }

    function _unstakeFor(uint256 tokenId) internal {
        require(tokensLastStakedAt[tokenId] > 0, "Token not staking");
        uint256 stakedAtTimestamp = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        emit Unstake(tokenId, stakedAtTimestamp, block.timestamp);
    }

    function unstakeFor(uint256 tokenId) external {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _unstakeFor(tokenId);
    }

    function batchUnstakeFor(uint256[] calldata tokenIds) external {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        uint256 len = tokenIds.length;
        for (uint256 i = 0; i < len;) {
            _unstakeFor(tokenIds[i]);
            unchecked { ++i; }
        }
    }

    // V4
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (useOldCollectionUrl) {
            return super.tokenURI(tokenId);
        }
        return "https://cdn.bullyverse.io/nft/metadata/dead_collection";
    }

    function setUseOldCollectionUrl(bool _useOldCollectionUrl) external onlyOwner {
        useOldCollectionUrl = _useOldCollectionUrl;
    }

    function setTransferDisabled(bool _transferDisabled) external onlyOwner {
        transferDisabled = _transferDisabled;
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        require(!transferDisabled, "Transfer disabled");
        require(tokensLastStakedAt[tokenId] == 0, "Cannot transfer staked token");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        require(!transferDisabled, "Transfer disabled");
        require(tokensLastStakedAt[tokenId] == 0, "Cannot transfer staked token");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        require(!transferDisabled, "Transfer disabled");
        require(tokensLastStakedAt[tokenId] == 0, "Cannot transfer staked token");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return ERC721Upgradeable.supportsInterface(interfaceId)
            || ERC2981Upgradeable.supportsInterface(interfaceId)
            || super.supportsInterface(interfaceId);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}
