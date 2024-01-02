//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./Exports.sol";

import "./DotcStructures.sol";
import "./IDotcManager.sol";
import "./IDotcEscrow.sol";

/**
 * @title Escrow Contract for DOTC (Decentralized Over-The-Counter) Trading (as part of the "SwarmX.eth Protocol")
 * @notice It allows for depositing, withdrawing, and managing of assets in the course of trading.
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 * Please read the Disclaimer featured on the SwarmX.eth website ("Terms") carefully before accessing,
 * interacting with, or using the SwarmX.eth Protocol software, consisting of the SwarmX.eth Protocol
 * technology stack (in particular its smart contracts) as well as any other SwarmX.eth technology such
 * as e.g., the launch kit for frontend operators (together the "SwarmX.eth Protocol Software").
 * By using any part of the SwarmX.eth Protocol you agree (1) to the Terms and acknowledge that you are
 * aware of the existing risk and knowingly accept it, (2) that you have read, understood and accept the
 * legal information and terms of service and privacy note presented in the Terms, and (3) that you are
 * neither a US person nor a person subject to international sanctions (in particular as imposed by the
 * European Union, Switzerland, the United Nations, as well as the USA). If you do not meet these
 * requirements, please refrain from using the SwarmX.eth Protocol.
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 * @dev This contract handles the escrow of assets for DOTC trades, supporting ERC20, ERC721, and ERC1155 assets.
 * @author Swarm
 */
contract DotcEscrow is ERC1155HolderUpgradeable, ERC721HolderUpgradeable, IDotcEscrow {
    ///@dev Used for Safe transfer tokens
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Emitted when an offer's assets are deposited into escrow.
     * @param offerId Unique identifier of the offer.
     * @param maker Address of the user who made the offer.
     * @param amount Amount of the asset deposited.
     */

    event OfferDeposited(uint256 indexed offerId, address indexed maker, uint256 indexed amount);
    /**
     * @dev Emitted when assets are withdrawn from escrow for an offer.
     * @param offerId Unique identifier of the offer.
     * @param taker Address of the user who is taking the offer.
     * @param amount Amount of the asset withdrawn.
     */
    event OfferWithdrawn(uint256 indexed offerId, address indexed taker, uint256 indexed amount);
    /**
     * @dev Emitted when an offer is cancelled and its assets are returned.
     * @param offerId Unique identifier of the cancelled offer.
     * @param maker Address of the user who made the offer.
     * @param amountToWithdraw Amount of the asset returned to the maker.
     */
    event OfferCancelled(uint256 indexed offerId, address indexed maker, uint256 indexed amountToWithdraw);
    /**
     * @dev Emitted when fees are withdrawn from the escrow.
     * @param offerId Unique identifier of the relevant offer.
     * @param to Address to which the fees are sent.
     * @param amountToWithdraw Amount of fees withdrawn.
     */
    event FeesWithdrew(uint256 indexed offerId, address indexed to, uint256 indexed amountToWithdraw);
    /**
     * @dev Emitted when the manager address of the escrow is changed.
     * @param by Address of the user who changed the manager address.
     * @param manager New manager's address.
     */
    event ManagerAddressSet(address indexed by, IDotcManager manager);

    /**
     * @dev Hash of the string "ESCROW_MANAGER_ROLE", used for access control.
     */
    bytes32 public constant ESCROW_MANAGER_ROLE = keccak256("ESCROW_MANAGER_ROLE");
    /**
     * @dev Reference to the DOTC Manager contract which governs this escrow.
     */
    IDotcManager public manager;
    /**
     * @dev Mapping from offer IDs to their corresponding deposited assets.
     */
    mapping(uint256 offerId => Asset asset) public assetDeposits;

    /**
     * @notice Ensures that the function is only callable by the DOTC contract.
     * @dev Modifier that restricts function access to the address of the DOTC contract set in the manager.
     */
    modifier onlyDotc() {
        require(msg.sender == address(manager.dotc()), "Escrow: Dotc calls only");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the escrow contract with a DOTC Manager.
     * @param _manager Address of the DOTC Manager.
     * @dev Sets up the contract to handle ERC1155 and ERC721 tokens.
     */
    function initialize(IDotcManager _manager) public initializer {
        __ERC1155Holder_init();
        __ERC721Holder_init();

        manager = _manager;
    }

    /**
     * @notice Sets the initial deposit for a maker's offer.
     * @param offerId The ID of the offer being deposited.
     * @param maker The address of the maker making the deposit.
     * @param asset The asset being deposited.
     * @return True if the operation was successful.
     * @dev Only callable by DOTC contract, ensures the asset is correctly deposited.
     */
    function setDeposit(uint offerId, address maker, Asset calldata asset) external onlyDotc returns (bool) {
        assetDeposits[offerId] = asset;

        emit OfferDeposited(offerId, maker, asset.amount);

        return true;
    }

    /**
     * @notice Withdraws a deposit from escrow to the taker's address.
     * @param offerId The ID of the offer being withdrawn.
     * @param amountToWithdraw Amount of the asset to withdraw.
     * @param taker The address receiving the withdrawn assets.
     * @return True if the operation was successful.
     * @dev Ensures that the withdrawal is valid and transfers the asset to the taker.
     */
    function withdrawDeposit(
        uint256 offerId,
        uint256 amountToWithdraw,
        address taker
    ) external onlyDotc returns (bool) {
        Asset memory asset = assetDeposits[offerId];
        require(asset.amount > 0, "Escrow: assets amount = 0");

        if (asset.assetType == AssetType.ERC20)
            amountToWithdraw = manager.unstandardizeNumber(amountToWithdraw, asset.assetAddress);

        require(amountToWithdraw > 0, "Escrow: amount to withdraw = 0");

        assetDeposits[offerId].amount -= amountToWithdraw;

        _assetTransfer(asset, address(this), taker, amountToWithdraw);

        emit OfferWithdrawn(offerId, taker, amountToWithdraw);

        return true;
    }

    /**
     * @notice Cancels a deposit in escrow, returning it to the maker.
     * @param offerId The ID of the offer being cancelled.
     * @param maker The address of the maker to return the assets to.
     * @return status True if the operation was successful.
     * @return amountToCancel Amount of the asset returned to the maker.
     * @dev Only callable by DOTC contract, ensures the asset is returned to the maker.
     */
    function cancelDeposit(
        uint256 offerId,
        address maker
    ) external onlyDotc returns (bool status, uint256 amountToCancel) {
        Asset memory asset = assetDeposits[offerId];

        amountToCancel = asset.amount;

        require(amountToCancel > 0, "Escrow: amount to cancel = 0");

        delete assetDeposits[offerId];

        _assetTransfer(asset, address(this), maker, amountToCancel);

        emit OfferCancelled(offerId, maker, amountToCancel);

        status = true;
    }

    /**
     * @notice Withdraws fee amount from escrow.
     * @param offerId The ID of the offer related to the fees.
     * @param amountToWithdraw The amount of fees to withdraw.
     * @return status True if the operation was successful.
     * @dev Ensures that the fee withdrawal is valid and transfers the fee to the designated receiver.
     */
    function withdrawFees(uint256 offerId, uint256 amountToWithdraw) external onlyDotc returns (bool status) {
        Asset memory asset = assetDeposits[offerId];

        uint256 amount = manager.unstandardizeNumber(amountToWithdraw, asset.assetAddress);

        require(amount > 0, "Escrow: fees amount = 0");

        address to = manager.feeReceiver();

        assetDeposits[offerId].amount -= amount;

        _assetTransfer(asset, address(this), to, amount);

        emit FeesWithdrew(offerId, to, amount);

        return true;
    }

    /**
     * @notice Changes the manager of the escrow contract.
     * @param _manager The new manager's address.
     * @return status True if the operation was successful.
     * @dev Ensures that only the current manager can perform this operation.
     */

    function changeManager(IDotcManager _manager) external returns (bool status) {
        require(msg.sender == address(manager), "Escrow: Manager calls only");

        manager = _manager;

        emit ManagerAddressSet(msg.sender, _manager);

        return true;
    }

    /**
     * @notice Checks if the contract supports a specific interface.
     * @param interfaceId The interface identifier to check.
     * @return True if the interface is supported.
     * @dev Overridden to support AccessControl and ERC1155Receiver interfaces.
     */

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal function to handle the transfer of different types of assets (ERC20, ERC721, ERC1155).
     * @param asset The asset to be transferred.
     * @param from The address sending the asset.
     * @param to The address receiving the asset.
     * @param amount The amount of the asset to transfer.
     */
    function _assetTransfer(Asset memory asset, address from, address to, uint256 amount) private {
        if (asset.assetType == AssetType.ERC20) {
            IERC20Upgradeable(asset.assetAddress).safeTransfer(to, amount);
        } else if (asset.assetType == AssetType.ERC721) {
            IERC721Upgradeable(asset.assetAddress).safeTransferFrom(from, to, asset.tokenId);
        } else if (asset.assetType == AssetType.ERC1155) {
            IERC1155Upgradeable(asset.assetAddress).safeTransferFrom(from, to, asset.tokenId, asset.amount, "");
        }
    }
}
