// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

/**
 *    ______  _____ _    _ _____ __   _ _____ _______ __   __
 *    |     \   |    \  /    |   | \  |   |      |      \_/
 *    |_____/ __|__   \/   __|__ |  \_| __|__    |       |
 */

contract DivinityDrops is ERC1155, Ownable, ReentrancyGuard {
    uint256 public constant MAX_OG_TOKENS = 9;
    uint256 public constant QUANTITY_ONE = 1;
    string private _name = "Divinity Drops";
    string private _symbol = "DDROP";
    string private _baseTokenURI;
    bool public isClaimEnabled;
    uint256[] private idsBurn;
    uint256[] private idsClaim;
    uint256[] private amounts;

    // Custom errors for specific revert scenarios
    error UnableToClaim();
    error ClaimIsNotEnabled();
    error ArraysMismatchLength();

    // Events for tracking state changes and actions
    event ClaimMade(address indexed claimant);
    event ClaimEnabledStatusChanged(bool isEnabled);

    constructor(
        string memory uri_,
        address _owner
    ) ERC1155(uri_) Ownable(_owner) {
        _baseTokenURI = uri_;
        // Initialize idsBurn, idsMint, amounts here
        for (uint256 i = 1; i <= MAX_OG_TOKENS; ) {
            idsBurn.push(i);
            idsClaim.push(i + MAX_OG_TOKENS);
            amounts.push(QUANTITY_ONE);
            unchecked {
                ++i;
            }
        }
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @notice Performs batch airdrop to multiple addresses
    /// @dev Can only be called by the contract owner
    /// @param tokenIds Array of token IDs for each recipient
    /// @param quantities Array of quantities for each token ID
    /// @param wallets Array of recipient addresses
    function batchAirdrop(
        uint256[][] calldata tokenIds,
        uint256[][] calldata quantities,
        address[] calldata wallets
    ) external onlyOwner {
        if (tokenIds.length != quantities.length) revert ArraysMismatchLength();

        uint256 walletsLength = wallets.length;
        if (tokenIds.length != walletsLength) revert ArraysMismatchLength();

        for (uint256 i = 0; i < walletsLength; ) {
            _mintBatch(wallets[i], tokenIds[i], quantities[i], "");
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Allows a user to claim new tokens by burning existing ones
    /// @dev Tokens are burned and new tokens are minted in a 1:1 ratio
    function claim() external nonReentrant {
        if (!isClaimEnabled) revert ClaimIsNotEnabled();

        uint256[] memory amounts_ = amounts;
        address sender = _msgSender();

        for (uint256 i = 1; i <= MAX_OG_TOKENS; ) {
            if (balanceOf(sender, i) == 0) revert UnableToClaim();
            unchecked {
                ++i;
            }
        }

        // Burn the required tokens
        _burnBatch(sender, idsBurn, amounts_);

        // Mint new tokens
        _mintBatch(sender, idsClaim, amounts_, "");

        emit ClaimMade(sender);
    }

    /// @notice Enables or disables the claim functionality
    /// @dev Can only be called by the contract owner
    /// @param isEnabled Boolean indicating whether claiming should be enabled or disabled
    function setIsClaimEnabled(bool isEnabled) external onlyOwner {
        isClaimEnabled = isEnabled;
        emit ClaimEnabledStatusChanged(isEnabled);
    }

    /// @notice Function to set the token name and symbol
    function setTokenData(
        string memory tokenName,
        string memory tokenSymbol
    ) public onlyOwner {
        _name = tokenName;
        _symbol = tokenSymbol;
    }

    /// @notice Function to set the base URI for metadata
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /// @notice Function to get the URI for a specific token ID
    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        // Use the base URI with the {id} placeholder replaced by the actual token ID
        string memory tokenUri = string(
            abi.encodePacked(_baseTokenURI, Strings.toString(id))
        );
        return tokenUri;
    }
}
