// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSA.sol";
// import "./IERC721.sol";
// import "./Strings.sol";
import "./Erc721LockRegistry.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "./IERC721xHelper.sol";
import "./IStakable.sol";

// import "./console.sol";

// Dummy
contract Yogapetz is
    ERC721x,
    IStakable,
    DefaultOperatorFiltererUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721xHelper
{
    uint256 public MAX_SUPPLY;
    string public baseTokenURI;

    bool public canStake;
    mapping(uint256 => uint256) public tokensLastStakedAt; // tokenId => timestamp
    event Stake(uint256 indexed tokenId);
    event Unstake(
        uint256 indexed tokenId,
        uint256 stakedAtTimestamp,
        uint256 removedFromStakeAtTimestamp
    );

    mapping(address => bool) public whitelistedMarketplaces;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory baseURI) public initializer {
        ERC721x.__ERC721x_init("Yogapetz", "Yogapetz");
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        baseTokenURI = baseURI;
        MAX_SUPPLY = 10000;
    }

    // =============== AIR DROP ===============

    function airdrop(address receiver, uint256 tokenAmount) external onlyOwner {
        safeMint(receiver, tokenAmount);
    }

    function airdropListWithAmounts(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; ) {
            safeMint(receivers[i], amounts[i]);
            unchecked {
                i++;
            }
        }
    }

    function safeMint(address receiver, uint256 quantity) internal {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "exceed MAX_SUPPLY");
        _mint(receiver, quantity);
    }

    // =============== BASE URI ===============

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // function tokenURI(
    //     uint256 _tokenId
    // )
    //     public
    //     view
    //     override(ERC721AUpgradeable, IERC721AUpgradeable)
    //     returns (string memory)
    // {
    //     if (bytes(tokenURIOverride).length > 0) {
    //         return tokenURIOverride;
    //     }
    //     return string.concat(super.tokenURI(_tokenId), tokenURISuffix);
    // }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    // =============== MARKETPLACE CONTROL ===============
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        super.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual override(ERC721x) onlyAllowedOperator(_from) {
        super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    // =============== MARKETPLACE CONTROL ===============
    function whitelistMarketplaces(
        address[] calldata markets,
        bool whitelisted
    ) external onlyOwner {
        for (uint256 i = 0; i < markets.length; i++) {
            address market = markets[i];
            whitelistedMarketplaces[market] = whitelisted;
        }
    }

    // =============== Stake ===============
    function stake(uint256 tokenId) public {
        require(canStake, "staking not open");
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] == 0, "already staking");
        tokensLastStakedAt[tokenId] = block.timestamp;
        // emit Stake(tokenId, msg.sender, tokensLastStakedAt[tokenId]);
        emit Stake(tokenId);
    }

    function unstake(uint256 tokenId) public {
        require(
            msg.sender == ownerOf(tokenId) || msg.sender == owner(),
            "caller must be owner of token or contract owner"
        );
        require(tokensLastStakedAt[tokenId] > 0, "not staking");
        uint256 lsa = tokensLastStakedAt[tokenId];
        tokensLastStakedAt[tokenId] = 0;
        // emit Unstake(tokenId, msg.sender, lsa, block.timestamp);
        emit Unstake(tokenId, lsa, block.timestamp);
        _emitTokenStatus(tokenId);
    }

    function emitLockUnlockEvents(
        uint256[] calldata tokenIds,
        bool isTokenLocked,
        address approvedContract
    ) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            if (isTokenLocked) {
                emit TokenLocked(tokenId, approvedContract);
            } else {
                emit TokenUnlocked(tokenId, approvedContract);
            }
            unchecked {
                i++;
            }
        }
    }

    function setTokensStakeStatus(
        uint256[] memory tokenIds,
        bool setStake
    ) external {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (setStake) {
                stake(tokenId);
            } else {
                unstake(tokenId);
            }
        }
    }

    function setCanStake(bool b) external onlyOwner {
        canStake = b;
    }

    // =============== IERC721xHelper ===============
    function tokensLastStakedAtMultiple(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory) {
        uint256[] memory part = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokensLastStakedAt[tokenIds[i]];
        }
        return part;
    }

    function isUnlockedMultiple(
        uint256[] calldata tokenIds
    ) external view returns (bool[] memory) {
        bool[] memory part = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = isUnlocked(tokenIds[i]);
        }
        return part;
    }

    function ownerOfMultiple(
        uint256[] calldata tokenIds
    ) external view returns (address[] memory) {
        address[] memory part = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = ownerOf(tokenIds[i]);
        }
        return part;
    }

    function tokenNameByIndexMultiple(
        uint256[] calldata tokenIds
    ) external view returns (string[] memory) {
        string[] memory part = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            part[i] = tokenNameByIndex(tokenIds[i]);
        }
        return part;
    }

    function _emitTokenStatus(uint256 tokenId) internal {
        if (lockCount[tokenId] > 0) {
            emit TokenLocked(tokenId, msg.sender);
        }
        if (tokensLastStakedAt[tokenId] > 0) {
            emit Stake(tokenId);
        }
    }

    function unlockId(uint256 _id) external virtual override {
        require(_exists(_id), "Token !exist");
        _unlockId(_id);
        _emitTokenStatus(_id);
    }

    function freeId(uint256 _id, address _contract) external virtual override {
        require(_exists(_id), "Token !exist");
        _freeId(_id, _contract);
        _emitTokenStatus(_id);
    }
}
