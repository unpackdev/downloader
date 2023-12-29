// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721A.sol";
import "./MultiSigOwnable.sol";
import "./IProxyRegistry.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

error ZeroAddressWhitelistSigner();
error ZeroAddressTeamMultiSig();
error PublicReleaseDateBeforeWhitelist();
error WhitelistSaleNotActive();
error PublicSaleNotActive();
error IncorrectEtherAmount();
error MaximumTooHigh();
error QuantityTooHigh();
error MaxSupplyReached();
error InvalidWhitelistSigner();
error WithdrawFailed();

/// @title ToyzNFT ERC721 token
/// @author ToyzNFT Team
contract ToyzNFT is ERC721A, MultiSigOwnable, Pausable, ReentrancyGuard {
    // Provenance hash of all tokens
    bytes32 public constant PROVENANCE_HASH = 0xd2846c87a11a566ccc4610695fb2a26fa582b5cf5cf92f8e5c2a91dadd3ab509;

    // Price of a token
    uint256 public constant PRICE = 0.07 ether;

    // Max supply of the tokens
    uint256 public constant MAX_SUPPLY = 5555;

    // Max quantity per account during public sale
    uint256 public constant MAX_PER_ACCOUNT = 3;

    // Number of tokens for the project, for future use
    uint256 public constant PROJECT_ALLOCATION = 55;

    // Base URL for the token
    string private baseTokenURI;

    // Address of the signer used to sign request for whitelist mint
    address public immutable whitelistSigner;

    // Timestamp of whitelist release to user with valid signature to mint
    uint256 public immutable whitelistReleaseTime;

    // Timestamp of public release to allow anyone to mint
    uint256 public immutable publicReleaseTime;

    // Map of balance per address during the mint periode for enforce the limit per account
    mapping(address => uint256) public mintBalance;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    /// @dev constructor of the contract
    /// @param whitelistSigner_ address of the signer used to sign request for whitelist mint
    /// @param whitelistReleaseTime_ timestamp of whitelist release to user with valid signature to mint
    /// @param publicReleaseTime_ timestamp of public release to allow anyone to mint
    /// @param baseURI_ base URI of the contract
    /// @param teamMultiSig_ address of the team multisig wallet to manage the contract and withdraw funds
    /// @param proxyRegistry_ OpenSea proxy registry address to make exchanges easier
    constructor(
        address whitelistSigner_,
        uint256 whitelistReleaseTime_,
        uint256 publicReleaseTime_,
        string memory baseURI_,
        address teamMultiSig_,
        address proxyRegistry_
    ) ERC721A("ToyzNFT", "TOYZ") {
        if (whitelistSigner_ == address(0)) {
            revert ZeroAddressWhitelistSigner();
        }

        if (teamMultiSig_ == address(0)) {
            revert ZeroAddressTeamMultiSig();
        }

        if (publicReleaseTime_ <= whitelistReleaseTime_) {
            revert PublicReleaseDateBeforeWhitelist();
        }

        whitelistSigner = whitelistSigner_;
        whitelistReleaseTime = whitelistReleaseTime_;
        publicReleaseTime = publicReleaseTime_;
        baseTokenURI = baseURI_;
        proxyRegistry = IProxyRegistry(proxyRegistry_);

        // Transfer ownership to the team multisig
        // Zero address is checked in transferMultiSigOwnership()
        transferMultiSigOwnership(teamMultiSig_);

        // Mint `PROJECT_ALLOCATION` tokens to the team multisig
        _mint(teamMultiSig_, PROJECT_ALLOCATION, "", false);
    }

    /// @dev change the starting index to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev set base URI for token metadata
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /// @notice change the base URI for token metadata
    /// @param url new base URI
    function updateBaseURI(string memory url) external onlyMultiSigOwner {
        baseTokenURI = url;
    }

    /// @dev pause the contract, preventing any actions from being taken
    function pause() public onlyMultiSigOwner {
        _pause();
    }

    /// @dev unpause the contract, allowing actions to be taken
    function unpause() public onlyMultiSigOwner {
        _unpause();
    }

    /// @notice mint a new token during the whitelist period
    /// @param quantity of tokens to mint
    /// @param maximum of tokens allowed for the sender, provided by the backend, verified in the signature
    /// @param v, r, s  the signature of `_msgSender()` and `maximum` by the whitelist signer
    function mintWhitelist(
        uint256 quantity,
        uint256 maximum,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable whenNotPaused nonReentrant {
        // Check if whitelist sale period is open
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < whitelistReleaseTime) {
            revert WhitelistSaleNotActive();
        }

        // Check if the max supply is reached
        if (totalSupply() + quantity > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        // Check if the maximum is not above public MAX_PER_ACCOUNT to limit backend issues
        if (maximum > MAX_PER_ACCOUNT) {
            revert MaximumTooHigh();
        }

        // Check the amount of ethers sent
        if (msg.value != PRICE * quantity) {
            revert IncorrectEtherAmount();
        }

        // Check if max tokens have been reached
        if (mintBalance[_msgSender()] + quantity > maximum) {
            revert QuantityTooHigh();
        }

        // Check the signature, and recover the signer address
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encode(_msgSender(), maximum))), v, r, s);

        // Verify the signer is the whitelist signer
        if (signer != whitelistSigner) {
            revert InvalidWhitelistSigner();
        }

        // Update mint balance
        mintBalance[_msgSender()] += quantity;

        // Mint the token
        _safeMint(_msgSender(), quantity);
    }

    /// @notice mint a new token after the public release
    /// @param quantity of tokens to mint
    function mintPublic(uint256 quantity) external payable whenNotPaused nonReentrant {
        // Check if public sale period is open
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < publicReleaseTime) {
            revert PublicSaleNotActive();
        }

        // Check the amount of ethers sent
        if (msg.value != PRICE * quantity) {
            revert IncorrectEtherAmount();
        }

        // Check if the max supply is reached
        if (totalSupply() + quantity > MAX_SUPPLY) {
            revert MaxSupplyReached();
        }

        // Check if max tokens have been reached
        if (mintBalance[_msgSender()] + quantity > MAX_PER_ACCOUNT) {
            revert QuantityTooHigh();
        }

        // Update mint balance
        mintBalance[_msgSender()] += quantity;

        // Mint the token
        _safeMint(_msgSender(), quantity);
    }

    /// @dev override _beforeTokenTransfers to add `whenNotPaused` check before token transfers
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @dev override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /// @notice withdraw all funds to the team multisig wallet
    /// @dev the ownership of the contract is transferred to the team multisig wallet
    /// so `_msgSender()` is the multisig aka `multisigOwner()`
    function withdraw() external onlyMultiSigOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = payable(_msgSender()).call{value: address(this).balance}("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }
}
