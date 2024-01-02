// SPDX-License-Identifier: GPL-3.0

/// @title The ArrakisPass ERC-721 token

pragma solidity ^0.8.17;

import "./ERC721ACommon.sol";
import "./BaseTokenURI.sol";
import "./FixedPriceSeller.sol";
import "./SignatureChecker.sol";
import "./SignerManager.sol";
import "./Monotonic.sol";

import "./AccessControlEnumerable.sol";
import "./EnumerableSet.sol";

contract ArrakisPass is
    ERC721ACommon,
    BaseTokenURI,
    FixedPriceSeller,
    SignerManager,
    AccessControlEnumerable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;

    enum MintPhase {
        NONE,
        PAUSED,
        ALLOWLIST_SALE,
        PUBLIC_SALE,
        SOLD_OUT
    }

    /**
    @notice Role of administrative users allowed to expel a ArrakisPass from the
    rack.
    @dev See expelFromRack().
     */
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

    MintPhase public mintPhase = MintPhase.NONE;

    constructor(
        string memory name,
        string memory symbol,
        address payable beneficiary,
        address payable royaltyReciever,
        uint256 totalInventory,
        uint256 maxPerAddress,
        uint256 maxPerTx,
        uint248 freeQuota
    )
        ERC721ACommon(name, symbol, royaltyReciever, 500)
        BaseTokenURI("")
        FixedPriceSeller(
            0 ether,
            Seller.SellerConfig({
                totalInventory: totalInventory,
                lockTotalInventory: false,
                maxPerAddress: maxPerAddress,
                maxPerTx: maxPerTx,
                freeQuota: freeQuota,
                lockFreeQuota: false,
                reserveFreeQuota: true
            }),
            beneficiary
        )
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ////////////////////////
    // MODIFIER FUNCTIONS //
    ////////////////////////

    /**
     * @notice Ensure function cannot be called outside of a given mint phase
     * @param _mintPhase Correct mint phase for function to execute
     */
    modifier inMintPhase(MintPhase _mintPhase) {
        if (mintPhase != _mintPhase) {
            revert IncorrectMintPhase();
        }
        _;
    }

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    /**
    @dev Mint tokens purchased via the Seller.
     */
    function _handlePurchase(address to, uint256 n, bool) internal override {
        _safeMint(to, n);
    }

    /**
    @dev Record of already-used signatures.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Allowlist Mint Function
     */
    function mintAllowlist(
        address to,
        bytes32 nonce,
        bytes calldata sig,
        uint256 requested
    ) external payable inMintPhase(MintPhase.ALLOWLIST_SALE) {
        signers.requireValidSignature(
            signaturePayload(to, nonce),
            sig,
            usedMessages
        );
        _purchase(to, requested);
    }

    /**
    @notice Public Mint Function
     */
    function mintPublic(
        address to,
        uint256 requested
    ) external payable inMintPhase(MintPhase.PUBLIC_SALE) {
        _purchase(to, requested);
    }

    /**
    @notice Returns whether the address has minted with the particular nonce. If
    true, future calls to mint() with the same parameters will fail.
    @dev In production we will never issue more than a single nonce per address,
    but this allows for testing with a single address.
     */
    function alreadyMinted(
        address to,
        bytes32 nonce
    ) external view returns (bool) {
        return
            usedMessages[
                SignatureChecker.generateMessage(signaturePayload(to, nonce))
            ];
    }

    /**
    @dev Constructs the buffer that is hashed for validation with a minting
    signature.
     */
    function signaturePayload(
        address to,
        bytes32 nonce
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(to, nonce);
    }

    /**
     * @notice Set the mint phase
     * @notice Use restricted to contract owner
     * @param _mintPhase New mint phase
     */
    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    ////////////////////////
    // STAKING //
    ////////////////////////

    /**
    @dev tokenId to staking start time (0 = not staking).
     */
    mapping(uint256 => uint256) private stakingStarted;

    /**
    @dev Cumulative per-token staking, excluding the current period.
     */
    mapping(uint256 => uint256) private stakingTotal;

    /**
    @notice Returns the length of time, in seconds, that the ArrakisPass has
    staked.
    @dev Staking is tied to a specific ArrakisPass, not to the owner, so it doesn't
    reset upon sale.
    @return staking Whether the ArrakisPass is currently staking. MAY be true with
    zero current staking if in the same block as staking began.
    @return current Zero if not currently staking, otherwise the length of time
    since the most recent staking began.
    @return total Total period of time for which the ArrakisPass has staked across
    its life, including the current period.
     */
    function stakingPeriod(
        uint256 tokenId
    ) external view returns (bool staking, uint256 current, uint256 total) {
        uint256 start = stakingStarted[tokenId];
        if (start != 0) {
            staking = true;
            current = block.timestamp - start;
        }
        total = current + stakingTotal[tokenId];
    }

    /**
    @dev MUST only be modified by safeTransferWhileStaking(); if set to 2 then
    the _beforeTokenTransfer() block while staking is disabled.
     */
    uint256 private stakingTransfer = 1;

    /**
    @notice Transfer a token between addresses while the ArrakisPass is minting,
    thus not resetting the staking period.
     */
    function safeTransferWhileStaking(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(ownerOf(tokenId) == _msgSender(), "ArrakisPass: Only owner");
        stakingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        stakingTransfer = 1;
    }

    /**
    @dev Block transfers while staking.
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(
                stakingStarted[tokenId] == 0 || stakingTransfer == 2,
                "ArrakisPass: staking"
            );
        }
    }

    /**
    @dev Emitted when a ArrakisPass begins staking.
     */
    event Staked(uint256 indexed tokenId); // Staked

    /**
    @dev Emitted when a ArrakisPass stops staking; either through standard means or
    by expulsion.
     */
    event Unstaked(uint256 indexed tokenId); // Unstaked

    /**
    @dev Emitted when a ArrakisPass is expelled.
     */
    event Expelled(uint256 indexed tokenId);

    /**
    @notice Whether staking is currently allowed.
    @dev If false then staking is blocked, but unstaking is always allowed.
     */
    bool public stakingOpen = false; // stakingOpen

    /**
    @notice Toggles the `stakingOpen` flag.
     */
    function setStakingOpen(bool open) external onlyOwner {
        stakingOpen = open;
    }

    /**
    @notice Changes the ArrakisPass's staking status.
    */
    function toggleStaking(
        uint256 tokenId
    ) internal onlyApprovedOrOwner(tokenId) {
        uint256 start = stakingStarted[tokenId];
        if (start == 0) {
            require(stakingOpen, "ArrakisPass: staking closed");
            stakingStarted[tokenId] = block.timestamp;
            emit Staked(tokenId);
        } else {
            stakingTotal[tokenId] += block.timestamp - start;
            stakingStarted[tokenId] = 0;
            emit Unstaked(tokenId);
        }
    }

    /**
    @notice Changes multiple ArrakisPass's staking status
     */
    function toggleStaking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleStaking(tokenIds[i]);
        }
    }

    /**
    @notice Admin-only ability to expel a ArrakisPass from staking.
    @dev As most sales listings use off-chain signatures it's impossible to
    detect someone who has staked and then deliberately undercuts the floor
    price in the knowledge that the sale can't proceed. This function allows for
    monitoring of such practices and expulsion if abuse is detected, allowing
    the undercutting bird to be sold on the open market. Since OpenSea uses
    isApprovedForAll() in its pre-listing checks, we can't block by that means
    because staking would then be all-or-nothing for all of a particular owner's
    ArrakisPass.
     */
    function expelFromStake(uint256 tokenId) external onlyRole(EXPULSION_ROLE) {
        require(stakingStarted[tokenId] != 0, "ArrakisPass: not staked");
        stakingTotal[tokenId] += block.timestamp - stakingStarted[tokenId];
        stakingStarted[tokenId] = 0;
        emit Unstaked(tokenId);
        emit Expelled(tokenId);
    }

    ////////////////////////
    // BURNING //
    ////////////////////////

    /**
    @notice Whether burning is currently allowed.
    @dev If false then burning is blocked
     */
    bool public burningOpen = false; // burningOpen

    /**
    @notice Toggles the `burningOpen` flag.
     */
    function setBurningOpen(bool open) external onlyOwner {
        burningOpen = open;
    }

    function burn(uint256 tokenId) public virtual onlyApprovedOrOwner(tokenId) {
        require(burningOpen, "ArrakisPass: burning not enabled");
        _burn(tokenId);
    }

    ////////////////////////
    // MISC. //
    ////////////////////////

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721ACommon, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ////////////////////////
    // ERRORS //
    ////////////////////////

    /**
     * Incorrect mint phase for action
     */
    error IncorrectMintPhase();
}
