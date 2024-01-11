// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./SignatureAccessControl.sol";
import "./TokenMintingPool.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./Context.sol";

/**
 * @title Base contract to handle an NFT drop.
 */
abstract contract PackDropBase is
    Context,
    ReentrancyGuard,
    AccessControl,
    SignatureAccessControl,
    TokenMintingPool
{

    /* ========================================== DROP VARIABLES ==================================================== */
    string public name; // the name of this drop
    uint256 public maxPerTx; // maximum of tokens that can be minted per transaction
    uint256 public maxPerAddress; // maximum of tokens that can be minted by a specific address.
    uint256 public mintPrice; // mint price per token, in the selected ERC20.
    mapping(address => uint256) internal _mintsPerAddress; // keeps track of how many tokens were minted per address.

    bool private _presaleIsOpen = false; // flag used to control the presale opening
    bool private _publicSaleIsOpen = false; // flag used to control the public sale opening

    /* ============================================== EVENTS ======================================================== */

    event PresaleOpened();
    event PublicSaleOpened();
    event MintPriceChanged(uint256 indexed oldPrice, uint256 indexed newPrice);
    event SubscriptionIdChanged(uint256 indexed oldId, uint256 indexed newId);

    /* ========================================== CONSTRUCTOR AND HELPERS ========================================== */

    /**
     * @dev Constructor.
     *  - Sets the name of the drop
     *  - Sets the mint limitations
     *  - Sets the mint price
     *  - Sets the {ERC20PaymentProcessor} parameters
     *  - Sets the {TokenMintingPool} parameters
     */
    constructor(
        string memory dropName,
        uint256 _maxPerTx,
        uint256 _maxPerAddress,
        uint256 mintPriceERC20,
        address signingAddress,
        address _altEscrowAdmin,
        address _altMintingAdmin,
        address vaultAddress,
        address vrfCoordinator,
        bytes32 vrfKeyHash,
        uint64 vrfSubscriptionId
    )
        SignatureAccessControl(signingAddress)
        TokenMintingPool(vaultAddress, vrfCoordinator, vrfKeyHash, vrfSubscriptionId)
    {
        name = dropName;
        maxPerTx = _maxPerTx;
        maxPerAddress = _maxPerAddress;
        mintPrice = mintPriceERC20;

        _grantRole(MINTING_ADMIN_ROLE(), _altMintingAdmin);
        _setRoleAdmin(MINTING_ADMIN_ROLE(), MINTING_ADMIN_ROLE());

        _grantRole(ESCROW_ROLE(), _altEscrowAdmin);
        _setRoleAdmin(ESCROW_ROLE(), ESCROW_ROLE());
    }

    /**
     * @dev Updates the subscription id.
     */
    function updateSubscriptionId(uint64 _newId) external onlyAdmin {
        emit SubscriptionIdChanged(vrfSubscriptionId, _newId);
        vrfSubscriptionId = _newId;
    }

    /**
     * @dev Updates the mint price.
     * Requirement: the drop hasn't started (i.e. the contract is not in presale or in public sale).
     */
    function updateMintPrice(uint256 _mintPrice) external onlyAdmin {
        require(
            !(_presaleIsOpen || _publicSaleIsOpen),
            'PackDropBase: The drop already started - cannot update the mint price.'
        );
        emit MintPriceChanged(mintPrice, _mintPrice);
        mintPrice = _mintPrice;
    }

    /* ============================================ TOKEN SUPPLY HELPERS ============================================ */

    /**
     * @dev See {TokenMintingPool._addTokens}.
     */
    function addTokens(bytes32[] calldata tokenHashes)
        external
        onlyAdmin
    {
        _addTokens(tokenHashes);
    }

    /**
     * @dev See {TokenMintingPool._removeTokens}.
     */
    function removeTokens(bytes32[] calldata tokenHashes)
        external
        onlyAdmin
    {
        _removeTokens(tokenHashes);
    }

    /**
     * @dev See {TokenMintingPool._lockTokenSupply}.
     */
    function lockTokenSupply(uint32 callbackGasLimit, uint32 numberSeeds) external onlyAdmin {
        _lockTokenSupply(callbackGasLimit, numberSeeds);
    }

    /* =========================================== ALLOWLIST LIST HELPERS =========================================== */

    /**
     * @dev Modify the signing address for computing signatures
     */
    function changeSigningAddress(address newSigningAddress) external onlyAdmin {
        emit SigningAddressChanged(signingAddress, newSigningAddress);
        signingAddress = newSigningAddress;
    }

    /* ========================================= PRESALE AND SALE HELPERS ========================================= */

    /**
     * @dev Check that the presale is open. Note that opening the public sale does not close the presale access.
     */
    modifier onlyPresale() {
        require(_presaleIsOpen, 'PackDropBase: The presale is closed.');
        _;
    }

    /**
     * @dev Opens the presale. This cannot be undone.
     */
    function openPresale() external onlyAdmin {
        require(tokenSupplyLocked(), 'PackDropBase: The token supply needs to be locked.');
        _presaleIsOpen = true;
        emit PresaleOpened();
    }

    /**
     * @dev Opens the public sale. This cannot be undone.
     * Requirements:
     *  - presale is already open
     */
    function openPublicSale() external onlyAdmin onlyPresale {
        _publicSaleIsOpen = true;
        emit PublicSaleOpened();
    }

    /**
     * @dev Get the sale status of the drop.
     */
    function saleStatus() external view returns (string memory) {
        bool tokenSupplyIsEmpty = remainingSupplyCount() <= 0;
        return
            _presaleIsOpen
                ? (
                    _publicSaleIsOpen
                        ? (tokenSupplyIsEmpty ? 'SOLD_OUT' : 'PUBLIC_SALE')
                        : (tokenSupplyIsEmpty ? 'SOLD_OUT' : 'PRESALE')
                )
                : 'CLOSED';
    }

    /**
     * @dev allows users to check how many tokens they minted already at their own discretion.
     */
    function selfCheckTokensMinted() external view returns (uint256) {
        return _mintsPerAddress[_msgSender()];
    }

    /**
     * @dev External function to check how many tokens an address can still mint
     */
    function checkMintableAmountPerAddress(address _address) external view returns(uint256) {
        return maxPerAddress - _mintsPerAddress[_address];
    }


    /* ================================================== MINTING ================================================== */

    /**
     * @dev Helper to process a mint request.
     *
     * Requirements:
     *  - the requested amount must be > 0
     *  - the remaining supply must be > 0
     *  - the caller must not have reached {maxPerAddress}
     *  - {amount} must be less or equal to {maxPerTx}
     *
     * Notes:
     *  - Ensures that the address is eligible to mint tokens.
     *  - Calls {_mintableAmountForAddress} to calculate the actual number of tokens that can be minted by that
     *    address, if differs from the requested amount.
     *  - Processes payment for the tokens through a call to transfer ERC20 tokens from the minter to this contract.
     *    If this fails for any reason (including insufficient funds or lack of authorization) the contract call will be reverted.
     *  - Mints the tokens to the minter.
     */
    function _processMintRequest(
        address minter,
        uint256 requestedAmount
    ) private {
        uint256 remainingSupply = remainingSupplyCount();
        require(requestedAmount > 0, 'PackDropBase: Invalid request for zero tokens.');
        require(remainingSupply > 0, 'PackDropBase: No more tokens left.');
        require(_mintsPerAddress[minter] + requestedAmount < maxPerAddress + 1, 'PackDropBase: Token limit per wallet reached.');
        require(requestedAmount < maxPerTx + 1, 'PackDropBase: Token limit per transaction exceeded.');
        require(requestedAmount < remainingSupply + 1, 'PackDropBase: Not enough tokens left.');
        require(msg.value == requestedAmount * mintPrice, 'PackDropBase: Incorrect amount sent.');
        _mintsPerAddress[minter] += requestedAmount;
        _mintTokens(minter, requestedAmount);
}

    /**
     * @dev Claim tokens.
     *
     * Requirements:
     *  - the call should come from an EOA
     *  - if the public sale is not open:
     *      - the presale must be open
     *      - sender must be allowed to access the presale
     *      - sender hasn't used their presale access yet
     *  - see {_processMintRequest}
     */
    function claimTokens(
        uint256 amount,
        bytes calldata _signature
    ) external payable nonReentrant {
        address caller = _msgSender();
        require(caller == tx.origin, 'PackDropBase: No DelegateCall authorized');
        require(_hasAccess(caller, _signature), 'PackDropBase: This address does not have access to the drop.');
        if (!_publicSaleIsOpen) {
                require(_presaleIsOpen, 'PackDropBase: The presale is not open yet.');
            }
        _processMintRequest(caller, amount);
    }

    /* ========================================== ACCESS CONTROL HELPERS ========================================== */

    /**
     * @dev the escrow role.
     */
    function ESCROW_ROLE() internal pure returns (bytes32) {
        return keccak256('ESCROW_ROLE');
    }

    /**
     * @dev the admin role.
     */
    function MINTING_ADMIN_ROLE() internal pure returns (bytes32) {
        return keccak256('MINTING_ADMIN_ROLE');
    }

    /**
     * @dev modifier for minting admin role.
     */
    modifier onlyAdmin() {
        _checkRole(MINTING_ADMIN_ROLE(), _msgSender());
        _;
    }

    /**
     * @dev modifier for the escrow role.
     */
    modifier onlyEscrow() {
        _checkRole(ESCROW_ROLE(), _msgSender());
        _;
    }

    /* ========================================== WITHDRAW FUNCTION ========================================== */

    /**
     * @dev Withdraw amount from minter contract
     *
     * Call Value is used here instead of transfer to allow withdrawal to smart contracts
     * with possible fallback function.
     *
     * Reentrancy attacks do not apply here because we withdraw all contract funds in the first call
     */
    function withdraw(address payable receiver) external onlyEscrow {
        require(receiver != address(0),'PackDropBase: Cannot set the receiver address to the null address.');
        receiver.call{value:address(this).balance}("");
    }
}
