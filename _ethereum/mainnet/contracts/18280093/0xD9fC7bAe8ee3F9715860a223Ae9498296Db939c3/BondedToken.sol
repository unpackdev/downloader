// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./IToken.sol";

contract BondedToken is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant TRANSFERABLE_ADDRESS_ROLE =
        keccak256("TRANSFERABLE_ADDRESS_ROLE");
    bytes32 public constant BOOSTER_ROLE =
        keccak256("BOOSTER_ROLE");

    uint256 public tokenIdCounter;

    address public baseToken;

    address public treasury;

    bool public isPublicTransferEnabled;

    address[] public tokensWhitelist;

    mapping(address => bool) public isTokenWhitelisted;

    // NFT id => token address => locked amount
    mapping(uint256 => mapping(address => uint256)) public lockedOf;

    // NFT id => boosted amount
    mapping(uint256 => uint256) public boostedBalance;

    // NFT id => mint timestamp
    mapping(uint256 => uint256) public mintedAt;

    // token address => total locked amount
    mapping(address => uint256) public totalLocked;

    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------
    event Locked(
        address indexed from,
        uint256 indexed tokenId,
        address[] tokens,
        uint256[] amounts
    );

    event Merged(
        address indexed from,
        uint256 indexed tokenIdA,
        uint256 indexed tokenIdB
    );

    event Splited(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed newTokenId,
        address[] tokens,
        uint256[] amounts
    );

    event WhitelistTokensUpdated(address[] tokens);

    event PublicTransferStatusUpdated(bool publicTransferStatus);

    event TreasuryUpdated(address treasury);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // ------------------------------------------------------------------------
    // initializer
    // ------------------------------------------------------------------------

    function _initialize(
        address _token,
        address _treasury,
        string memory _name,
        string memory _symbol
    ) internal initializer {
        __ERC721_init(_name, _symbol);
        __Pausable_init();
        __ERC721Burnable_init();
        __AccessControl_init();
        __Ownable_init();

        require(
            _token != address(0) && _treasury != address(0),
            "Zero Address"
        );

        baseToken = _token;
        treasury = _treasury;

        // whitelist baseToken
        tokensWhitelist.push(baseToken);
        isTokenWhitelisted[baseToken] = true;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(TRANSFERABLE_ADDRESS_ROLE, address(0));
    }

    // ------------------------------------------------------------------------
    // External Functions
    // ------------------------------------------------------------------------

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice whitelists tokens
    /// @dev only whitelisted tokens can be locked
    /// @param tokens list of tokens to be whitelisted
    function whitelistTokens(address[] memory tokens) external onlyOwner {
        uint256 tokensLength = tokens.length;
        for (uint256 i; i < tokensLength; ++i) {
            require(!isTokenWhitelisted[tokens[i]], "Already Whitelisted");
            tokensWhitelist.push(tokens[i]);
            isTokenWhitelisted[tokens[i]] = true;
        }
        emit WhitelistTokensUpdated(tokens);
    }

    /// @notice enable/disable public transfer
    /// @param _isPublicTransferEnabled the status of public transfer
    function setPublicTransfer(
        bool _isPublicTransferEnabled
    ) external onlyOwner {
        isPublicTransferEnabled = _isPublicTransferEnabled;
        emit PublicTransferStatusUpdated(_isPublicTransferEnabled);
    }

    /// @notice sets treasury address
    /// @param _treasury new treasury address
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Zero Address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @notice mints a new NFT for requested address and locks tokens for that NFT
    /// @param tokens list of tokens to deposit for tokenId
    /// @param amounts list of amounts of each token to deposit
    /// @param to receiver of the NFT
    /// @return tokenId minted
    function mintAndLock(
        address[] memory tokens,
        uint256[] memory amounts,
        address to
    ) external whenNotPaused returns (uint256 tokenId) {
        tokenId = mint(to);
        lock(tokenId, tokens, amounts);
    }

    /// @notice merges two tokenId. Burns tokenIdA and add it's underlying assets to tokenIdB
    /// @dev msg.sender should be owner of tokenIdA (which will be burned)
    /// @param tokenIdA first tokenId to merge. Will be burned
    /// @param tokenIdB second tokenId to merge. It's underlying assets will increase
    function merge(uint256 tokenIdA, uint256 tokenIdB) external whenNotPaused {
        require(ownerOf(tokenIdA) == msg.sender, "Not Owned");
        require(ownerOf(tokenIdB) == msg.sender, "Not Owned");
        require(tokenIdA != tokenIdB, "Same Token ID");
        // require(_ownerOf(tokenIdB) != address(0), "ERC721: invalid token ID");

        uint256 tokensWhitelistLength = tokensWhitelist.length;
        for (uint256 i; i < tokensWhitelistLength; ++i) {
            if (lockedOf[tokenIdA][tokensWhitelist[i]] != 0) {
                lockedOf[tokenIdB][tokensWhitelist[i]] += lockedOf[tokenIdA][
                    tokensWhitelist[i]
                ];
                lockedOf[tokenIdA][tokensWhitelist[i]] = 0;
            }
        }

        // set mintedAt of the tokenIdB to the oldest mint timestamp of tokenIdA and tokenIdB
        if (mintedAt[tokenIdA] < mintedAt[tokenIdB]) {
            mintedAt[tokenIdB] = mintedAt[tokenIdA];
        }

        boostedBalance[tokenIdB] += boostedBalance[tokenIdA];
        _burn(tokenIdA);
        emit Merged(msg.sender, tokenIdA, tokenIdB);
    }

    /// @notice splits NFT into two NFTs
    /// @dev msg.sender should be owner of both tokenId
    /// @param tokenId id of the NFT to split
    /// @param tokens list of tokens to move to new NFT
    /// @param amounts list of amounts to move to new NFT
    // function split(
    //     uint256 tokenId,
    //     address[] memory tokens,
    //     uint256[] memory amounts
    // ) external whenNotPaused returns (uint256 newTokenId) {
    //     require(ownerOf(tokenId) == msg.sender, "Not Owned");

    //     uint256 len = tokens.length;
    //     require(len == amounts.length, "Length Mismatch");

    //     newTokenId = mint(msg.sender);

    //     // set new token mint timestamp to the origin token mint timestamp
    //     mintedAt[newTokenId] = mintedAt[tokenId];

    //     for (uint256 i; i < len; ++i) {
    //         require(
    //             lockedOf[tokenId][tokens[i]] >= amounts[i],
    //             "Insufficient Locked Amount"
    //         );
    //         lockedOf[tokenId][tokens[i]] -= amounts[i];
    //         lockedOf[newTokenId][tokens[i]] += amounts[i];
    //     }
    //     emit Splited(msg.sender, tokenId, newTokenId, tokens, amounts);
    // }

    /// @notice returns locked amount of requested tokens for given tokenId
    function getLockedOf(
        uint256 tokenId,
        address[] memory tokens
    ) external view returns (uint256[] memory amounts) {
        uint256 tokensLength = tokens.length;
        amounts = new uint256[](tokensLength);
        for (uint256 i; i < tokensLength; ++i) {
            amounts[i] = lockedOf[tokenId][tokens[i]];
        }
    }

    // ------------------------------------------------------------------------
    // Public Functions
    // ------------------------------------------------------------------------

    /// @notice mints a new NFT for requested address
    /// @param to receiver of the NFT
    /// @return Minted tokenId
    function mint(address to) public whenNotPaused returns (uint256) {
        tokenIdCounter += 1;
        uint256 tokenId = tokenIdCounter;
        _safeMint(to, tokenId);
        mintedAt[tokenId] = block.timestamp;
        return tokenId;
    }

    /// @notice burns the NFT
    /// @param tokenId tokenId
    function burn(uint256 tokenId) public virtual override whenNotPaused {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        uint256 tokensWhitelistLength = tokensWhitelist.length;
        for (uint256 i; i < tokensWhitelistLength; ++i) {
            if (lockedOf[tokenId][tokensWhitelist[i]] != 0) {
                totalLocked[tokensWhitelist[i]] -= lockedOf[tokenId][
                    tokensWhitelist[i]
                ];
                lockedOf[tokenId][tokensWhitelist[i]] = 0;
            }
        }
        _burn(tokenId);
    }

    /// @notice locks tokens for give tokenId
    /// @dev tokens should be whitelisted and require approval for each token. tokenId tier will be updated at the end
    /// @param tokenId tokenId to deposit tokens for
    /// @param tokens list of tokens to deposit for tokenId
    /// @param amounts list of amounts of each token to deposit
    function lock(
        uint256 tokenId,
        address[] memory tokens,
        uint256[] memory amounts
    ) public whenNotPaused {
        require(_ownerOf(tokenId) != address(0), "ERC721: invalid token ID");

        uint256 len = tokens.length;
        require(len == amounts.length, "Length Mismatch");

        uint256 receivedAmount;
        for (uint256 i; i < len; ++i) {
            require(isTokenWhitelisted[tokens[i]], "Not Whitelisted");
            require(amounts[i] > 0, "Cannot Lock Zero Amount");

            if (tokens[i] == baseToken) {
                IToken(baseToken).burnFrom(msg.sender, amounts[i]);
                receivedAmount = amounts[i];
            } else {
                receivedAmount = IERC20Upgradeable(tokens[i]).balanceOf(
                    treasury
                );
                IERC20Upgradeable(tokens[i]).safeTransferFrom(
                    msg.sender,
                    treasury,
                    amounts[i]
                );
                receivedAmount =
                    IERC20Upgradeable(tokens[i]).balanceOf(treasury) -
                    receivedAmount;
            }

            require(
                amounts[i] == receivedAmount,
                "Inconsistent amount of token"
            );

            lockedOf[tokenId][tokens[i]] += receivedAmount;
            totalLocked[tokens[i]] += receivedAmount;
        }
        emit Locked(msg.sender, tokenId, tokens, amounts);
    }


    /// @notice increases the boostedBalance for the given tokenId
    /// @dev can be called only by Booster
    /// @param tokenId tokenId to increase its boostedBalance
    /// @param amount the amount
    function addBoostedBalance(
        uint256 tokenId,
        uint256 amount
    ) public whenNotPaused onlyRole(BOOSTER_ROLE){
        require(_ownerOf(tokenId) != address(0), "ERC721: invalid token ID");
        boostedBalance[tokenId] += amount;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ------------------------------------------------------------------------
    // Internal Functions
    // ------------------------------------------------------------------------

    /// @notice transfer is limited to whitelisted contracts
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override whenNotPaused {
        if (!isPublicTransferEnabled) {
            require(
                hasRole(TRANSFERABLE_ADDRESS_ROLE, from) ||
                    hasRole(TRANSFERABLE_ADDRESS_ROLE, to),
                "Transfer is Limited"
            );
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
