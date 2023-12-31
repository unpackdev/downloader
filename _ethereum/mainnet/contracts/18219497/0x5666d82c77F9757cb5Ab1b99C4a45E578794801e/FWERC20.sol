// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC4626.sol";
import "./ERC20.sol";
import "./Math.sol";
import "./Messaging.sol";
import "./ErrorLib.sol";

/**
 * @title FWERC20
 * @dev A contract that makes faster the transfer of assets between Starknet and ETH.
 */
contract FWERC20 is Ownable, ERC4626, Messaging, ReentrancyGuard, Pausable {
    using Math for uint256;

    // Events
    event RelayerAdded(address indexed newRelayer);
    event RelayerRemoved(address indexed relayer);
    event L2FWSet(uint256 indexed newL2FW);
    event L2TokenSet(uint256 indexed newL2Token);
    event LpFeesSet(uint256 newLpFees);
    event LiquidityProvidersAdded(address[] liquidityProviders);
    event LiquidityProvidersRemoved(address[] liquidityProviders);
    event BridgeUserHandled(RecipientInfo[] recipients);
    event BatchProcessed(RequestPayload payload);

    // State variables
    address public _l1Bridge;
    uint256 public _l2Bridge;
    uint256 public _l2FW;
    mapping(address => bool) public _relayer;
    mapping(address => bool) public _lpAllowance;
    uint256 public _underlyingBalance;
    int256 public _dueAmount;
    uint256 public _batchCounter;
    uint256 public _lastL2Block;
    uint256 public constant WAD = 10 ** 18;
    uint256 public constant FIELD_PRIME =
        0x800000000000011000000000000000000000000000000000000000000000001;

    struct RequestPayload {
        uint256 nonce;
        uint256 amountUnderlying;
        uint256 amountLpFees;
    }

    struct RecipientInfo {
        address payable user;
        uint256 debt;
        uint256 l2Block;
    }

    constructor(
        IERC20 asset,
        string memory name,
        string memory symbol,
        address relayer,
        address starknetCore,
        address l1Bridge,
        uint256 l2Bridge,
        uint256 l2FW
    ) ERC4626(asset) ERC20(name, symbol) Ownable() Pausable() {
        _addRelayer(relayer);
        _setL2FW(l2FW);
        Messaging.initializeMessaging(starknetCore);
        _l1Bridge = l1Bridge;
        _checkValidL2Address(l2Bridge);
        _l2Bridge = l2Bridge;
        _lastL2Block = 1;
    }

    /**
     * @dev Receive Ether function
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}

    /**
     * @dev Modifier that restricts the function to be accessible only by the relayer.
     */
    modifier onlyRelayer() {
        _checkRelayer();
        _;
    }

    /**
     * @dev Modifier that restricts the function to be accessible only by allowed liquidity providers.
     */
    modifier onlyAllowedLiquidityProviders() {
        _checkAllowedLiquidityProvider();
        _;
    }

    /**
     * @dev Add the address to allowed relayer Only the contract owner can perform this action.
     * @param newRelayer The address of the new relayer.
     */
    function addRelayer(address newRelayer) external onlyOwner {
        _addRelayer(newRelayer);
        emit RelayerAdded(newRelayer);
    }

    /**
     * @dev Remove the address to allowed relayer Only the contract owner can perform this action.
     * @param relayer The address of the relayer to remove.
     */
    function removeRelayer(address relayer) external onlyOwner {
        _removeRelayer(relayer);
        emit RelayerRemoved(relayer);
    }

    /**
     * @dev Sets the L2FW address. Only the contract owner can perform this action.
     * @param newL2FW The new L2FW address.
     */
    function setL2FW(uint256 newL2FW) external onlyOwner {
        if (_l2FW != 0) revert ErrorLib.FWAlreadySet();
        _setL2FW(newL2FW);
        emit L2FWSet(newL2FW);
    }

    /**
     * @dev Adds multiple addresses to the list of allowed liquidity providers.
     * Only the contract owner can perform this action.
     * @param liquidityProviders An array of addresses representing liquidity providers to be added.
     */
    function addAllowedLiquidityProviders(
        address[] memory liquidityProviders
    ) external onlyOwner {
        if (liquidityProviders.length == 0) revert ErrorLib.EmptyArray();
        for (uint256 i = 0; i < liquidityProviders.length; ) {
            _lpAllowance[liquidityProviders[i]] = true;
            unchecked {
                i++;
            }
        }
        emit LiquidityProvidersAdded(liquidityProviders);
    }

    /**
     * @dev Removes multiple addresses from the list of allowed liquidity providers.
     * Only the contract owner can perform this action.
     * @param liquidityProviders An array of addresses representing liquidity providers to be removed.
     */
    function removeAllowedLiquidityProviders(
        address[] memory liquidityProviders
    ) external onlyOwner {
        if (liquidityProviders.length == 0) revert ErrorLib.EmptyArray();
        for (uint256 i = 0; i < liquidityProviders.length; ) {
            _lpAllowance[liquidityProviders[i]] = false;
            unchecked {
                i++;
            }
        }
        emit LiquidityProvidersRemoved(liquidityProviders);
    }

    /**
     * @dev Pauses the contract, preventing further execution of transactions. Only the contract owner can perform this action.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing execution of transactions. Only the contract owner can perform this action.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw excess amount of ERC20 tokens from the contract.
     * @param erc20 The address of the ERC20 token to be withdrawn.
     */
    function harvestErc20(address erc20) external onlyOwner {
        if (erc20 == super.asset()) {
            IERC20(erc20).transfer(
                msg.sender,
                IERC20(erc20).balanceOf(address(this)) - _underlyingBalance
            );
        } else {
            IERC20(erc20).transfer(
                msg.sender,
                IERC20(erc20).balanceOf(address(this))
            );
        }
    }

    /**
     * @dev Allows the contract owner to withdraw excess amount of ETH from the contract.
     */
    function harvestEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Handles bridge users' transactions, distributing tokens
     * Only the relayer can call this function.
     * @param recipients An array of recipient information for handling transactions.
     */
    function handleBridgeUsers(
        RecipientInfo[] memory recipients
    ) external onlyRelayer {
        if (recipients.length == 0) revert ErrorLib.EmptyArray();
        for (uint256 i = 0; i < recipients.length; ) {
            if (_lastL2Block > recipients[i].l2Block)
                revert ErrorLib.BlockAleadyProcessed();
            _lastL2Block = recipients[i].l2Block;
            _handleBridge(recipients[i].user, recipients[i].debt);
            unchecked {
                i++;
            }
        }
        emit BridgeUserHandled(recipients);
    }

    /**
     * @dev Handles bridge users' transactions manually, function used only if we missed users
     * Only the relayer can call this function.
     * @param recipients An array of recipient information for handling transactions.
     */
    function handleBridgeUsersManually(
        RecipientInfo[] memory recipients
    ) external onlyRelayer {
        if (recipients.length == 0) revert ErrorLib.EmptyArray();
        for (uint256 i = 0; i < recipients.length; ) {
            _handleBridge(recipients[i].user, recipients[i].debt);
            unchecked {
                i++;
            }
        }
        emit BridgeUserHandled(recipients);
    }

    /**
     * @dev Executes a batch of transactions, processing messages from L2 and handling refunding + paying liquidity providers
     * Can only be called when the contract is not paused and is non-reentrant.
     * @param _payload The payload containing batch information.
     */
    function executeBatch(
        RequestPayload calldata _payload
    ) external virtual nonReentrant whenNotPaused {
        if (_batchCounter != _payload.nonce)
            revert ErrorLib.InvalidBatchNonce();

        _batchCounter += 1;
        _consumeL2Message(_l2FW, _getRequestMessageData(_payload));

        _dueAmount -= int256(_payload.amountUnderlying);

        uint256 totalAmountRefunded = _payload.amountUnderlying +
            _payload.amountLpFees;

        _underlyingBalance += totalAmountRefunded;

        _withdrawTokenFromBridge(
            _l1Bridge,
            _l2Bridge,
            address(this),
            totalAmountRefunded
        );
        _wrap(totalAmountRefunded);
        emit BatchProcessed(_payload);
    }

    /**
     * @dev Overrides the deposit function from ERC4626. Allows liquidity providers to deposit assets.
     * Increases the underlying balance by the deposited assets.
     * @param assets The amount of assets to be deposited.
     * @param receiver The receiver of the deposited shares.
     * @return shares The amount of shares received.
     */
    function deposit(
        uint256 assets,
        address receiver
    ) public override onlyAllowedLiquidityProviders returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        _underlyingBalance += assets;
        return shares;
    }

    /**
     * @dev Overrides the mint function from ERC4626. Allows liquidity providers to mint shares.
     * Increases the underlying balance by the minted assets.
     * @param shares The amount of shares to be minted.
     * @param receiver The receiver of the minted shares.
     * @return assets The amount of assets minted.
     */
    function mint(
        uint256 shares,
        address receiver
    ) public override onlyAllowedLiquidityProviders returns (uint256) {
        uint256 assets = super.mint(shares, receiver);
        _underlyingBalance += assets;
        return assets;
    }

    /**
     * @dev Overrides the withdraw function from ERC4626. Allows liquidity providers to withdraw assets.
     * Decreases the underlying balance by the withdrawn assets.
     * @param assets The amount of assets to be withdrawn.
     * @param receiver The receiver of the withdrawn assets.
     * @param owner The owner of the shares being withdrawn.
     * @return shares The amount of shares burned.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override onlyAllowedLiquidityProviders returns (uint256) {
        _checkEnoughBalance(assets);
        uint256 shares = super.withdraw(assets, receiver, owner);
        _underlyingBalance -= assets;
        return shares;
    }

    /**
     * @dev Overrides the redeem function from ERC4626. Allows liquidity providers to redeem shares.
     * Decreases the underlying balance by the redeemed assets.
     * @param shares The amount of shares to be redeemed.
     * @param receiver The receiver of the redeemed assets.
     * @param owner The owner of the shares being redeemed.
     * @return assets The amount of assets redeemed.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override onlyAllowedLiquidityProviders returns (uint256) {
        uint256 assets = super.redeem(shares, receiver, owner);
        _checkEnoughBalance(assets);
        _underlyingBalance -= assets;
        return assets;
    }

    /**
     * @dev Overrides the totalAssets function from ERC4626. Returns the total balance of underlying assets.
     * @return The sum of underlying balance and due amount.
     */
    function totalAssets() public view virtual override returns (uint256) {
        return uint256(int256(_underlyingBalance) + _dueAmount);
    }

    /**
     * @dev Handles the bridge operation for transferring assets between L1 and L2.
     * Transfers assets from the contract to a user, processes fees.
     * @param user The address of the user receiving assets.
     * @param amount The amount of assets to be transferred.
     */
    function _handleBridge(
        address payable user,
        uint256 amount
    ) internal virtual {
        if (user == address(0)) revert ErrorLib.AddressNul();
        if (amount == 0) revert ErrorLib.AmountNul();

        _checkEnoughBalance(amount);
        _sendToUser(user, amount);

        unchecked {
            _dueAmount += int256(amount);
            _underlyingBalance -= amount;
        }
    }

    /**
     * @dev Sends assets to a user.
     * @param user The address of the user receiving assets.
     * @param amount The amount of assets to be sent.
     */
    function _sendToUser(
        address payable user,
        uint256 amount
    ) internal virtual {
        IERC20(super.asset()).transfer(user, amount);
    }

    /**
     * @dev Checks if the caller is the designated relayer.
     */
    function _checkRelayer() internal view {
        if (_relayer[_msgSender()] != true) revert ErrorLib.CallerNotRelayer();
    }

    /**
     * @dev Checks if the caller is an allowed liquidity provider.
     */
    function _checkAllowedLiquidityProvider() internal view {
        if (!_lpAllowance[_msgSender()])
            revert ErrorLib.CallerNotAllowedLiquidityProvider();
    }

    /**
     * @dev Add the address to allowed relayer
     * @param newRelayer The address of the new relayer.
     */
    function _addRelayer(address newRelayer) internal {
        _relayer[newRelayer] = true;
    }

    /**
     * @dev Remove the address to allowed relayer
     * @param newRelayer The address of the new relayer.
     */
    function _removeRelayer(address newRelayer) internal {
        _relayer[newRelayer] = false;
    }

    /**
     * @dev Sets the L2FW contract address and validates the address format.
     * @param newL2FW The address of the new L2FW contract.
     */
    function _setL2FW(uint256 newL2FW) internal {
        _checkValidL2Address(newL2FW);
        _l2FW = newL2FW;
    }

    /**
     * @dev Retrieves the message data for a request payload.
     * @param _payload The request payload for which to retrieve the message data.
     * @return data The message data containing payload details.
     */
    function _getRequestMessageData(
        RequestPayload memory _payload
    ) internal pure returns (uint256[] memory data) {
        (uint256 lowNonce, uint256 highNonce) = u256(_payload.nonce);
        (uint256 lowAmountUnderlying, uint256 highAmountUnderlying) = u256(
            _payload.amountUnderlying
        );
        (uint256 lowAmountLpFees, uint256 highAmountLpFees) = u256(
            _payload.amountLpFees
        );

        data = new uint256[](6);
        data[0] = lowNonce;
        data[1] = highNonce;
        data[2] = lowAmountUnderlying;
        data[3] = highAmountUnderlying;
        data[4] = lowAmountLpFees;
        data[5] = highAmountLpFees;
    }

    /**
     * @dev Placeholder function for wrapping assets (override in derived contracts if needed).
     * @param amount The amount of assets to be wrapped.
     */
    function _wrap(uint256 amount) internal virtual {}

    /**
     * @dev Checks if the provided L2 address is valid.
     * @param l2Address The L2 address to be validated.
     */
    function _checkValidL2Address(uint256 l2Address) internal pure {
        if (!_isValidL2Address(l2Address)) revert ErrorLib.InvalidL2Address();
    }

    /**
     * @dev Checks if the contract has enough underlying balance for a given amount.
     * @param amount The amount to be checked.
     */
    function _checkEnoughBalance(uint256 amount) internal view {
        bool isEnoughBalance = (amount <= _underlyingBalance);
        if (!isEnoughBalance) revert ErrorLib.InsufficientUnderlying();
    }

    /**
     * @dev Checks if the provided L2 address is valid within the FIELD_PRIME range.
     * @param l2Address The L2 address to be validated.
     * @return bool Whether the address is valid.
     */
    function _isValidL2Address(uint256 l2Address) internal pure returns (bool) {
        return (l2Address > 0 && l2Address < FIELD_PRIME);
    }
}
