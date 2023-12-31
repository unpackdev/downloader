// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ERC1155Upgradeable.sol";
import "./Ownable2StepUpgradeable.sol";

import "./IUnikuraMembership.sol";

library UnikuraMembershipMintLimitStorage {
    struct Layout {
        /// @notice Maximum allowed outstanding SILVER tokens.
        uint256 silverMintLimit;
        /// @notice Current amount of silver minted
        uint256 silverMinted;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("unikura.contracts.storage.unikuraMembership.mintLimit");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

library UnikuraMembershipStorage {
    struct Layout {
        /// @notice The only address that can burn tokens on this contract.
        address burnAddress;
        /// @notice The only address allowed to hold more than one token other than the owner
        address salesAddress;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("unikura.contracts.storage.unikuraMembership");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

contract UnikuraMembership is
    IUnikuraMembership,
    ERC1155Upgradeable,
    Ownable2StepUpgradeable
{
    using UnikuraMembershipStorage for UnikuraMembershipStorage.Layout;
    using UnikuraMembershipMintLimitStorage for UnikuraMembershipMintLimitStorage.Layout;

    uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;

    string public name;
    string public symbol;

    /**
     * @notice This error is emitted when an incorrect sender attempts to burn a token.
     * @dev The error includes the tokenId and the sender address, providing more context for the issue.
     * @param tokenId The token ID of the token that the sender attempted to burn.
     * @param sender The address of the sender that attempted the unauthorized burn.
     */
    error BurnIncorrectSender(uint256 tokenId, address sender);

    event SalesAddressChanged(address oldSalesAddress, address newSalesAddress);
    event BurnAddressChanged(address oldBurnAddress, address newBurnAddress);

    event NameChanged(string newName);
    event SymbolChanged(string newSymbol);

    event MintLimitChanged(uint256 limit);

    /**
     * @notice Modifier to ensure that the `receiver` does not already own a GOLD or SILVER membership token.
     * @dev This modifier checks whether the specified `receiver` owns any membership tokens and reverts if true.
     * @param to The address of the account to check for membership token ownership. The contract owner or sales address is allowed to own multiple
     * @param ids An array of token IDs being transferred.
     * @param amounts An array of token amounts being transferred.
     */
    modifier onlyOneToken(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) {
        if (to != owner() && to != getSalesAddress()) {
            require(
                ids.length == 1,
                "You can only transact one token at a time"
            );
            require(
                amounts[0] == 1,
                "You can only transact one token at a time"
            );
            if (ids[0] == GOLD) {
                require(
                    balanceOf(to, GOLD) == 0,
                    "You already own a gold membership token"
                );
            }
            if (ids[0] == SILVER) {
                require(
                    balanceOf(to, SILVER) == 0,
                    "You already own a silver membership token"
                );
            }
        }
        _;
    }

    /**
     * @notice Changes the token's name to `newName`.
     * @dev Only callable by the contract owner.
     * @param newName The new name for the token.
     */
    function setName(string calldata newName) external onlyOwner {
        require(bytes(newName).length > 0, "Token name should not be empty");
        name = newName;
        emit NameChanged(newName);
    }

    /**
     * @notice Changes the token's symbol to `newSymbol`.
     * @dev Only callable by the contract owner.
     * @param newSymbol The new symbol for the token.
     */
    function setSymbol(string calldata newSymbol) external onlyOwner {
        require(
            bytes(newSymbol).length > 0,
            "Token symbol should not be empty"
        );
        symbol = newSymbol;
        emit SymbolChanged(newSymbol);
    }

    /**
     * @notice Get the maximum allowed outstanding SILVER tokens.
     * @return The current mint limit for SILVER tokens.
     */
    function getSilverMintLimit() external view returns (uint256) {
        return UnikuraMembershipMintLimitStorage.layout().silverMintLimit;
    }

    /**
     * @notice Set the maximum allowed outstanding SILVER tokens.
     * @dev Only callable by the contract owner.
     * @param _limit The new mint limit for SILVER tokens.
     */
    function setSilverMintLimit(uint256 _limit) external onlyOwner {
        // Add any necessary restrictions for this setter like onlyOwner or any other modifiers if necessary
        UnikuraMembershipMintLimitStorage.layout().silverMintLimit = _limit;
        emit MintLimitChanged(_limit);
    }

    /**
     * @notice Get the current amount of minted SILVER tokens.
     * @return The current amount of minted SILVER tokens.
     */
    function getSilverMinted() external view returns (uint256) {
        return UnikuraMembershipMintLimitStorage.layout().silverMinted;
    }

    /**
     * @notice Any attempt to transfer a SILVER membership token will result in a transaction revert.
     * @dev This modifier ensures that the SILVER membership token is not transferable.
     * @param to The address of the account to check for membership token ownership.
     * @param ids An array of token IDs being checked for transfer restrictions.
     */
    modifier soulBound(address to, uint256[] memory ids) {
        if (ids[0] == SILVER) {
            require(
                _msgSender() == to,
                "You are not allowed to transfer silver membership tokens"
            );
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with the given token `uri` and `contractUri`.
     * @dev This function is marked as `initializer` to ensure it is only called once.
     * @param uri The base token URI for the ERC1155 token.
     */
    function initialize(string memory uri) public initializer {
        ERC1155Upgradeable.__ERC1155_init(uri);
        OwnableUpgradeable.__Ownable_init();
    }

    /**
     * @notice Checks whether the specified `account` owns a GOLD or SILVER membership token.
     * @dev This function is marked as `view` and does not modify the contract state.
     * @param account The address of the account to check for membership token ownership.
     * @return A boolean indicating whether the account owns a GOLD or SILVER membership token.
     */
    function ownsMembership(address account) public view returns (bool) {
        return true;
    }

    /**
     * @notice Hook that is called before any token transfer, including minting.
     * @dev This function enforces the `onlyOneToken` modifier for the `to` address.
     * @param operator The address performing the token transfer.
     * @param from The address tokens are being transferred from.
     * @param to The address tokens are being transferred to.
     * @param ids An array of token IDs being transferred.
     * @param amounts An array of token amounts being transferred.
     * @param data Additional data provided by the caller.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override onlyOneToken(to, ids, amounts) soulBound(to, ids) {}

    /**
     * @notice Mints `amount` tokens of token type `id` to `account`.
     * @dev This function is marked as `public` and can be called by any address.
     * @param account The address of the account to receive the minted tokens.
     * @param id The token type ID to be minted.
     * @param amount The amount of tokens to be minted.
     */
    function mint(address account, uint256 id, uint256 amount) public {
        require(
            id == GOLD || id == SILVER,
            "You can only mint GOLD or SILVER tokens"
        );
        require(
            account != address(0),
            "You cannot mint tokens to the zero address"
        );
        if (id == GOLD) {
            require(
                owner() == _msgSender(),
                "Only contract owner can mint GOLD tokens"
            );
            _mint(account, GOLD, amount, "");
        }
        if (id == SILVER) {
            require(
                UnikuraMembershipMintLimitStorage.layout().silverMinted +
                    amount <=
                    UnikuraMembershipMintLimitStorage.layout().silverMintLimit,
                "Maximum silver mint limit reached"
            );
            _mint(account, SILVER, amount, "");
            UnikuraMembershipMintLimitStorage.layout().silverMinted += amount;
        }
    }

    /**
     * @notice Sets the token URI for contract metadata.
     * @param newUri The new token URI.
     */
    function setURI(string calldata newUri) external onlyOwner {
        require(bytes(newUri).length != 0, "The new URI must not be empty");
        _setURI(newUri);

        // Emit an event with the update.
        emit TokenURIUpdated(newUri);
    }

    /**
     * @notice Sets the sales address to `newSalesAddress`.
     * @dev This function can only be called by the contract owner.
     * @param newSalesAddress The address to be set as the new sales address.
     */
    function setSalesAddress(address newSalesAddress) external onlyOwner {
        require(
            newSalesAddress != address(0),
            "The sales address must not be empty"
        );
        address oldSalesAddress = UnikuraMembershipStorage
            .layout()
            .salesAddress;
        UnikuraMembershipStorage.layout().salesAddress = newSalesAddress;
        emit SalesAddressChanged(oldSalesAddress, newSalesAddress);
    }

    /**
     * @notice Returns the current sales address.
     * @dev This function is marked as `view` and does not modify the contract state.
     * @return The address currently set as the sales address.
     */
    function getSalesAddress() public view returns (address) {
        return UnikuraMembershipStorage.layout().salesAddress;
    }

    /**
     * @notice Sets the burn address to `newBurnAddress`.
     * @dev This function can only be called by the contract owner.
     * @param newBurnAddress The address to be set as the new burn address.
     */
    function setBurnAddress(address newBurnAddress) external onlyOwner {
        require(
            newBurnAddress != address(0),
            "The burn address must not be empty"
        );
        address oldBurnAddress = UnikuraMembershipStorage.layout().burnAddress;

        UnikuraMembershipStorage.layout().burnAddress = newBurnAddress;
        emit BurnAddressChanged(oldBurnAddress, newBurnAddress);
    }

    /**
     * @notice Returns the current burn address.
     * @dev This function is marked as `view` and does not modify the contract state.
     * @return The address currently set as the burn address.
     */
    function getBurnAddress() public view returns (address) {
        return UnikuraMembershipStorage.layout().burnAddress;
    }

    /**
     * @notice Destroys the specified amount of tokens with the given `tokenId` from the `from` address. Only callable by the set burn address.
     * @param from The address to burn tokens from.
     * @param id The token identifier for the tokens to be burned.
     * @param amount The amount of tokens to be burned.
     * @dev This function can only be called by the address set as the burn address, otherwise it emits the `BurnIncorrectSender` error. The burn address can be any address with a long pattern such as 0x000000000000000000000etc or 0x12345678901234567890 since the chance of someone ever creating the private key for that address is essentially impossible [reddit.com](https://www.reddit.com/r/solidity/comments/nfu20e/burn_address_dead_address/). The ERC20 standard does not mention burning specifically, but it does specify the `Transfer` event as `event Transfer(address indexed _from, address indexed _to, uint256 _value)` to be compatible with any software that meets the standard [stackoverflow.com](https://stackoverflow.com/questions/46043783/solidity-burn-event-vs-transfer-to-0-address).
     */
    function burn(address from, uint256 id, uint256 amount) external {
        if (msg.sender != UnikuraMembershipStorage.layout().burnAddress) {
            revert BurnIncorrectSender(id, msg.sender);
        }

        _burn(from, id, amount);
    }

    /**
     * @notice Prevents renouncing ownership of the contract.
     * @dev Overrides the original renounceOwnership function to ensure that ownership cannot be renounced.
     *      This ensures that there will always be an owner for the contract.
     */
    function renounceOwnership()
        public
        view
        override(OwnableUpgradeable, IUnikuraMembership)
        onlyOwner
    {
        revert("Renouncing ownership is not allowed");
    }
}
