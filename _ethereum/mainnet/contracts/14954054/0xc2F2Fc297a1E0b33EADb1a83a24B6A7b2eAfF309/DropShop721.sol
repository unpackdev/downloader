// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IVoid721.sol";

error CannotExceedPerTransactionCap();
error CannotExceedPerCallerCap();
error CannotExceedPrereleaseCap();
error CannotExceedTotalCap();
error InvalidPaymentAmount();
error WithdrawalFailed();
error MintPhaseNotOpen();
error MerkleProofInvalid();
error TooManyStaffMints();

// mint stages
enum Phase {
    OFF,
    ALLOWLIST,
    FRIENDS,
    PUBLIC
}

/**
  @title Sells NFTs for a flat price, with presales
  @notice This contract encapsulates all minting-related business logic, allowing
          the associated ERC-721 token to focus solely on ownership, metadata,
          and on-chain data storage

  Forked from DropShop721, by the SuperFarm team
  https://etherscan.io/address/ef1CE3D419D281FCBe9941F3b3A81299DD438C20#code

  Heavily upgraded for use by Void Runners
  https://voidrunners.io

  Featuring:

  - immutable shop configuration, set at construction.
    to change minting rules (e.g. lowering price), just deploy another DropShop
  - various minting rules and restrictions:
    - totalCap: limit total # of items this DropShop can createl; distinct from token totalSupply
    - callerCap: a per-address limit; easily avoided, but useful for allowlist/prerelase minting
    - transactionCap: a per-transaction limit, particularly useful for keeping ERC721A batches reasonable
  - withdrawal functions for both Ether and ERC-20 tokens
  - mint() calls our configured Void21 token, which provides privileges to this contract
     a `setAdmin` function and an `onlyAdmin` modifier

  Void Runners extensions to DropShop721:

  - mint phase control, instead of startTime/endTime
  - a merkle-tree-based allowlist, letting defined addresses mint early
  - "friend" contract allowlist, allowing holders of specified contracts to mint early
  - the two prerelease phases above are subject to an aggregate `prereleaseCap`,
    which counts against the buyer's total `callerCap`
  - staff minting, with an immutable `staffCap` maximum
  - removed refunds for excess payments; please only pay exact amount
  - individual requires() have been replaced with modifiers; which are cleaner
    and more composable, but slightly less gas-efficient
  - the custom Tiny721 token has been replaced with an ERC721A-based token, and
    ERC721's storage optimizations are leveraged for supply and `prereleaseCap` tracking
*/
contract DropShop721 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- STORAGE --- //

    /// address of the ERC-721 item being sold.
    address public immutable collection;

    /// maximum number of items from the `collection` that may be sold.
    uint256 public immutable totalCap;

    /// The maximum number of items that a single address may purchase.
    uint256 public immutable callerCap;

    /// The maximum number of items that may be purchased in a single transaction.
    uint256 public immutable transactionCap;

    /// limit number of items that can be purchased per-person during the pre-release window (allowlist/friends)
    uint256 public immutable prereleaseCap;

    /// limit to number of items that can be claimed by the staff
    uint256 public immutable staffCap;

    /// price at which to sell the item
    uint256 public immutable price;

    /// destination of withdrawn payments
    address public immutable paymentDestination;

    /// current phase of the mint; off -> allowlist -> friends -> public
    Phase public mintingPhase;

    /// Merkle tree roots for our two prerelease address lists
    bytes32 public allowlistMerkleRoot;
    bytes32 public friendlistMerkleRoot;

    /// list of other NFT contracts that are allowed to mint early
    mapping(address => bool) public friendContracts;

    /*
    @notice a struct for passing shop configuration details upon contract construction
            this is passed to constructor as a struct to help avoid stack-to-deep errors

    @param totalCap maximum number of items from the `collection` that may be sold.
    @param callerCap maximum number of items that a single address may purchase.
    @param transactionCap maximum number of items that may be purchased in a single transaction.
    @param prereleaseCap maximum number of items that may be purchased during the allowlist and friendlist phases (in aggregate)
    @param staffCap maximum number of items that staff can mint (for free)
    @param price the price for each item, in wei
    @param paymentDestination where to send withdrawals()
  */
    struct ShopConfiguration {
        uint256 totalCap;
        uint256 callerCap;
        uint256 transactionCap;
        uint256 prereleaseCap;
        uint256 staffCap;
        uint256 price;
        address paymentDestination;
    }

    // --- EVENTS --- //

    event MintingPhaseStarted(Phase phase);

    // --- MODIFIERS --- //

    /// @dev forbid minting until the allowed phase
    modifier onlyIfMintingPhaseIsSetToOrAfter(Phase minimumPhase) {
        if (mintingPhase < minimumPhase) revert MintPhaseNotOpen();
        _;
    }

    /// @dev do not allow minting past our totalCap (maxSupply)
    ///      we are re-using our ERC721's token totalMinted() for efficiency,
    ///      but this means DropShop.totalCap is directly tied to the token's totalSupply
    ///      if you want a shop to allow minting 1000, it needs to be "totalSupply + 1000"
    modifier onlyIfSupplyMintable(uint256 amount) {
        if (_totalMinted() + amount > totalCap) revert CannotExceedTotalCap();
        _;
    }

    /// @dev reject purchases that exceed the per-transaction cap.
    modifier onlyIfBelowTransactionCap(uint256 amount) {
        if (amount > transactionCap) {
            revert CannotExceedPerTransactionCap();
        }
        _;
    }

    /// @dev reject purchases that exceed the per-caller cap.
    modifier onlyIfBelowCallerCap(uint256 amount) {
        if (purchaseCounts(_msgSender()) + amount > callerCap) {
            revert CannotExceedPerCallerCap();
        }
        _;
    }

    /// @dev reject purchases that exceed the pre-release (allowlist/friends) per-caller cap.
    modifier onlyIfBelowPrereleaseCap(uint256 amount) {
        if (prereleasePurchases(_msgSender()) + amount > prereleaseCap) {
            revert CannotExceedPrereleaseCap();
        }
        _;
    }

    /// @dev requires msg.value be exactly the specified amount
    modifier onlyIfValidPaymentAmount(uint256 amount) {
        uint256 totalCharge = price * amount;
        if (msg.value != totalCharge) {
            revert InvalidPaymentAmount();
        }
        _;
    }

    /// @notice verify user's merkle proof is correct
    modifier onlyIfValidMerkleProof(
        bytes32[] calldata proof,
        bytes32 merkleRoot
    ) {
        if (!_verifyMerkleProof(proof, _msgSender(), merkleRoot)) {
            revert MerkleProofInvalid();
        }
        _;
    }

    // --- SETUP & CONFIGURATION --- //

    /// @notice construct a new shop with details about the intended sale, like price and mintable supply
    /// @param _collection address of the ERC-721 item being sold
    /// @param _configuration shop configuration information, passed as a struct to avoid stack-to-deep errors
    constructor(address _collection, ShopConfiguration memory _configuration) {
        collection = _collection;

        price = _configuration.price;
        totalCap = _configuration.totalCap;
        callerCap = _configuration.callerCap;
        transactionCap = _configuration.transactionCap;
        prereleaseCap = _configuration.prereleaseCap;
        staffCap = _configuration.staffCap;
        paymentDestination = _configuration.paymentDestination;
    }

    /// @notice set the phase of the mint. e.g. closed at first, then allowlist, then public to all
    /// @param _phase which phase to activate; an enum
    function setMintingPhase(Phase _phase) external onlyOwner {
        mintingPhase = _phase;
        emit MintingPhaseStarted(_phase);
    }

    // --- TREASURY MGMNT --- //

    /// @notice allow anyone to send this contract's ETH balance to the (hard-coded) payment destination
    function withdraw() external nonReentrant {
        (bool success, ) = payable(paymentDestination).call{
            value: address(this).balance
        }("");
        if (!success) {
            revert WithdrawalFailed();
        }
    }

    /// @notice allow anyone to claim ERC-20 tokens that might've been sent to this contract, e.g. airdrops (or accidents)
    /// @param _token the token to sweep
    /// @param _amount the amount of token to sweep
    function withdrawTokens(address _token, uint256 _amount)
        external
        nonReentrant
    {
        IERC20(_token).safeTransfer(paymentDestination, _amount);
    }

    // --- SHARED MERKLE-TREE LOGIC --- //

    /// @dev verify a given Merkle proof against a given Merkle tree
    function _verifyMerkleProof(
        bytes32[] calldata proof,
        address sender,
        bytes32 merkleRoot
    ) internal pure returns (bool) {
        return
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(sender))
            );
    }

    // --- ALLOWLIST --- //

    /// @notice Test if a given **allowlist** merkle proof is valid for a given sender
    function verifyAllowlistProof(bytes32[] calldata proof, address sender)
        external
        view
        returns (bool)
    {
        return _verifyMerkleProof(proof, sender, allowlistMerkleRoot);
    }

    /// @notice Allows owner to set a merkle root for the Allowlist
    function setAllowlistMerkleRoot(bytes32 newRoot) external onlyOwner {
        allowlistMerkleRoot = newRoot;
    }

    // --- FRIENDLIST --- //

    /// @notice Test if a given **friendlist** merkle proof is valid for a given sender
    function verifyFriendlistProof(bytes32[] calldata proof, address sender)
        external
        view
        returns (bool)
    {
        return _verifyMerkleProof(proof, sender, friendlistMerkleRoot);
    }

    /// @notice Allows owner to set a merkle root for the friendlist
    function setFriendlistMerkleRoot(bytes32 newRoot) external onlyOwner {
        friendlistMerkleRoot = newRoot;
    }

    // --- MINTING --- //

    /// @notice total number of items minted; this is distinct from totalSupply(), which subtracts totalBurned()
    /// @dev in general we try to re-use data stored efficiently in our ERC721A token
    /// @dev this is only used inside one of our modifiers and could be confusing to external users, so we are keeping internal
    function _totalMinted() internal view returns (uint256) {
        return IVoid721(collection).totalMinted();
    }

    /// @notice how many tokens have been minted by given buyer, across all phases?
    function purchaseCounts(address buyer) public view returns (uint256) {
        return IVoid721(collection).numberMinted(buyer);
    }

    /// @notice how many tokens have been minted by given buyer during the prerelease phases? allowlist + friendlist
    function prereleasePurchases(address buyer) public view returns (uint64) {
        return IVoid721(collection).prereleasePurchases(buyer);
    }

    /// @dev update how many tokens a given buyer has bought during allowlist+friendlist period
    function _incrementPrereleasePurchases(address buyer, uint256 amount)
        internal
    {
        uint64 newTotal = prereleasePurchases(buyer) + uint64(amount);
        IVoid721(collection).setPrereleasePurchases(buyer, newTotal);
    }

    /// @dev a shared function for actually minting the specified tokens to the specified recipient
    function _mint(address recipient, uint256 amount)
        internal
        onlyIfSupplyMintable(amount)
        onlyIfBelowTransactionCap(amount)
    {
        IVoid721(collection).mint(recipient, amount);
    }

    /// @notice staff can mint up to staffCap, for free, at any point in the sale
    /// @param amount how many to mint
    function mintStaff(uint256 amount) external onlyOwner nonReentrant {
        if (purchaseCounts(paymentDestination) + amount > staffCap) {
            revert TooManyStaffMints();
        }
        _mint(paymentDestination, amount);
    }

    /// @notice mint NFTs if you're on the allowlist, a manually-curated list of addresses
    /// @param merkleProof a Merkle proof of the caller's address
    /// @param amount how many to mint
    function mintAllowlist(bytes32[] calldata merkleProof, uint256 amount)
        external
        payable
        onlyIfMintingPhaseIsSetToOrAfter(Phase.ALLOWLIST)
        onlyIfValidMerkleProof(merkleProof, allowlistMerkleRoot)
        onlyIfBelowPrereleaseCap(amount)
        onlyIfBelowCallerCap(amount)
        onlyIfValidPaymentAmount(amount)
        nonReentrant
    {
        _incrementPrereleasePurchases(_msgSender(), amount);
        _mint(_msgSender(), amount);
    }

    /// @notice mint NFTs if you're on the friendlist, a compilation of owners of friendly NFT contracts
    /// @param merkleProof a Merkle proof of the caller's address
    /// @param amount how many to mint
    function mintFriendlist(bytes32[] calldata merkleProof, uint256 amount)
        external
        payable
        onlyIfMintingPhaseIsSetToOrAfter(Phase.FRIENDS)
        onlyIfValidMerkleProof(merkleProof, friendlistMerkleRoot)
        onlyIfBelowPrereleaseCap(amount)
        onlyIfBelowCallerCap(amount)
        onlyIfValidPaymentAmount(amount)
        nonReentrant
    {
        _incrementPrereleasePurchases(_msgSender(), amount);
        _mint(_msgSender(), amount);
    }

    /// @notice mint NFTs during the public sale
    /// @param amount number of tokens to mint
    function mint(uint256 amount)
        public
        payable
        virtual
        onlyIfMintingPhaseIsSetToOrAfter(Phase.PUBLIC)
        onlyIfBelowCallerCap(amount)
        onlyIfValidPaymentAmount(amount)
        nonReentrant
    {
        _mint(_msgSender(), amount);
    }
}
