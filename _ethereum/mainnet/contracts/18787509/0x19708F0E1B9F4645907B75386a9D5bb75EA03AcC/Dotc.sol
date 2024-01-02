//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./Exports.sol";

import "./IDotcManager.sol";
import "./DotcStructures.sol";

/**
 * @title Open DOTCManager smart contract (as part of the "SwarmX.eth Protocol")
 * @notice This contract handles decentralized over-the-counter trading.
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
 * @dev It uses ERC1155 and ERC721 token standards for asset management and trade settlement.
 * @author Swarm
 */
contract Dotc is ReentrancyGuardUpgradeable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable {
    ///@dev Used for Safe transfer tokens
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Emitted when a new trading offer is created.
     * @param maker Address of the user creating the offer.
     * @param offerId Unique identifier of the created offer.
     * @param isFullType Indicates if the offer is of a full type.
     * @param depositAsset Asset to be deposited by the maker.
     * @param withdrawalAsset Asset to be withdrawn by the maker.
     * @param specialAddress A special address involved in the trade, if any.
     * @param expiryTime Expiry time of the offer.
     * @param timelockPeriod Timelock period for the offer.
     */
    event CreatedOffer(
        address indexed maker,
        uint256 indexed offerId,
        bool isFullType,
        Asset depositAsset,
        Asset withdrawalAsset,
        address specialAddress,
        uint256 expiryTime,
        uint256 timelockPeriod
    );
    /**
     * @notice Emitted when an offer is successfully taken.
     * @param offerId Unique identifier of the taken offer.
     * @param takenBy Address of the user taking the offer.
     * @param isFullyTaken Indicates if the offer is fully taken.
     * @param amountToReceive Amount received in the trade.
     * @param amountPaid Amount paid to take the offer.
     */
    event TakenOffer(
        uint256 indexed offerId,
        address indexed takenBy,
        bool indexed isFullyTaken,
        uint256 amountToReceive,
        uint amountPaid
    );
    /**
     * @notice Emitted when an offer is canceled.
     * @param offerId Unique identifier of the canceled offer.
     * @param canceledBy Address of the user who canceled the offer.
     * @param amountToReceive Amount that was to be received from the offer.
     */
    event CanceledOffer(uint256 indexed offerId, address indexed canceledBy, uint256 amountToReceive);
    /**
     * @notice Emitted when an existing offer is updated.
     * @param offerId Unique identifier of the updated offer.
     * @param newOffer Details of the new offer.
     */
    event OfferUpdated(uint256 indexed offerId, uint256 newOffer);
    /**
     * @notice Emitted when the expiry time of an offer is updated.
     * @param offerId Unique identifier of the offer with updated expiry.
     * @param newExpiryTimestamp The new expiry timestamp of the offer.
     */
    event UpdatedOfferExpiry(uint256 indexed offerId, uint256 newExpiryTimestamp);
    /**
     * @notice Emitted when the timelock period of an offer is updated.
     * @param offerId Unique identifier of the offer with updated timelock.
     * @param newTimelockPeriod The new timelock period of the offer.
     */
    event UpdatedTimeLockPeriod(uint256 indexed offerId, uint256 newTimelockPeriod);
    /**
     * @notice Emitted when the manager address is changed.
     * @param by Address of the user who changed the manager address.
     * @param manager New manager's address.
     */
    event ManagerAddressSet(address indexed by, IDotcManager manager);

    /**
     * @notice The instance of IDotcManager that manages this contract.
     * @dev Holds the address of the manager contract which provides key functionalities like escrow management.
     */
    IDotcManager public manager;
    /**
     * @notice Stores all the offers ever created.
     * @dev Maps an offer ID to its corresponding DotcOffer structure.
     */
    mapping(uint256 => DotcOffer) public allOffers;
    /**
     * @notice Keeps track of all offers created by a specific address.
     * @dev Maps an address to an array of offer IDs created by that address.
     */
    mapping(address => uint256[]) public offersFromAddress;
    /**
     * @notice Stores the timelock period for each offer.
     * @dev Maps an offer ID to its timelock period.
     */
    mapping(uint256 => uint256) public timelock;
    /**
     * @notice Tracks the ID to be assigned to the next created offer.
     * @dev Incremented with each new offer, ensuring unique IDs for all offers.
     */
    uint256 public currentOfferId;

    /**
     * @notice Ensures that the asset structure is valid.
     * @dev Checks for asset type, asset address, and amount validity.
     * @param asset The asset to be checked.
     */
    modifier checkAssetStructure(Asset memory asset) {
        require(asset.assetType != AssetType.NoType, "Dotc: Asset type should be defined");
        require(asset.assetAddress != address(0), "Dotc: Asset address should not be address zero");
        require(asset.amount > 0, "Dotc: Asset amount should be > 0");

        if (asset.assetType == AssetType.ERC721) {
            require(asset.amount == 1, "Dotc: ERC721 amount can not be > 0");
        }

        _;
    }

    /**
     * @notice Ensures that the offer is valid and available.
     * @dev Checks if the offer exists and has not been fully taken.
     * @param offerId The ID of the offer to be checked.
     */
    modifier checkOffer(uint256 offerId) {
        DotcOffer memory offer = allOffers[offerId];

        require(offer.maker != address(0), "Dotc: Offer does not exist");
        require(!offer.isFullyTaken, "Dotc: Offer is already fully taken");

        _;
    }

    /**
     * @notice Checks if the offer has not expired.
     * @dev Ensures the current time is before the offer's expiry time.
     * @param offerId The ID of the offer to check for expiry.
     */
    modifier notExpired(uint256 offerId) {
        require(allOffers[offerId].expiryTime > block.timestamp, "Dotc: This offer is already expired");
        _;
    }

    /**
     * @notice Ensures that the timelock period of the offer has passed.
     * @dev Checks if the current time is beyond the offer's timelock period.
     * @param offerId The ID of the offer to check for timelock expiry.
     */
    modifier timelockPassed(uint256 offerId) {
        require(allOffers[offerId].timelockPeriod < block.timestamp, "Dotc: This offer is in timelock");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract with a given manager.
     * @dev Sets up the reentrancy guard and ERC token holder functionalities.
     * @param _manager The address of the manager to be set for this contract.
     */
    function initialize(IDotcManager _manager) public initializer {
        __ReentrancyGuard_init();
        __ERC1155Holder_init();
        __ERC721Holder_init();

        manager = _manager;
    }

    /**
     * @notice Creates a new trading offer with specified assets and conditions.
     * @param depositAsset The asset to be deposited by the maker.
     * @param withdrawalAsset The asset desired by the maker in exchange.
     * @param _isFullType Boolean indicating if the offer is for the full amount.
     * @param _specialAddress An optional specific address allowed to take the offer.
     * @param _expiryTimestamp Timestamp when the offer expires.
     * @param _timelockPeriod Period before which the offer cannot be taken.
     * @dev Validates asset structure and initializes a new offer.
     */
    function makeOffer(
        Asset calldata depositAsset,
        Asset calldata withdrawalAsset,
        bool _isFullType,
        address _specialAddress,
        uint256 _expiryTimestamp,
        uint256 _timelockPeriod
    ) external checkAssetStructure(depositAsset) checkAssetStructure(withdrawalAsset) nonReentrant {
        require(_expiryTimestamp > _timelockPeriod, "Dotc: Timelock must be less than expiration time");
        require(_expiryTimestamp > block.timestamp, "Dotc: Expiration timestamp has already expired");
        require(_timelockPeriod == 0 || _timelockPeriod > block.timestamp, "Dotc: Timelock period has already expired");

        if (!_isFullType) {
            require(
                depositAsset.assetType == withdrawalAsset.assetType && depositAsset.assetType == AssetType.ERC20,
                "Dotc: ERC721/ERC1155 assets don't support partial offers"
            );
        }

        uint256 _currentOfferId = currentOfferId;

        DotcOffer memory _offer = _createOffer(
            depositAsset,
            withdrawalAsset,
            _isFullType,
            _specialAddress,
            _expiryTimestamp,
            _timelockPeriod
        );

        currentOfferId++;
        offersFromAddress[msg.sender].push(_currentOfferId);
        allOffers[_currentOfferId] = _offer;

        // Sending DepositAsset from Maker to Escrow
        assetTransfer(depositAsset, msg.sender, address(manager.escrow()), depositAsset.amount);

        require(
            manager.escrow().setDeposit(_currentOfferId, msg.sender, depositAsset),
            "Dotc: Escrow can't set new deposit"
        );

        emit CreatedOffer(
            msg.sender,
            _currentOfferId,
            _isFullType,
            depositAsset,
            withdrawalAsset,
            _specialAddress,
            _expiryTimestamp,
            _timelockPeriod
        );
    }

    /**
     * @notice Allows a user to take an available offer.
     * @param offerId The ID of the offer to take.
     * @param amountToSend The amount of the withdrawal asset to send.
     * @dev Handles the transfer of assets between maker and taker.
     */
    function takeOffer(
        uint256 offerId,
        uint256 amountToSend
    ) public checkOffer(offerId) notExpired(offerId) nonReentrant {
        DotcOffer memory offer = allOffers[offerId];

        if (offer.specialAddress != address(0))
            require(offer.specialAddress == msg.sender, "Dotc: You are not a designated buyer");

        uint256 amountToWithdraw = offer.depositAsset.amount;
        uint256 realAmount = amountToWithdraw;

        uint256 feesAmount;
        bool isFullyTaken;

        if (manager.checkAssetOwner(offer.withdrawalAsset, msg.sender, amountToSend) == AssetType.ERC20) {
            uint256 standardizedAmount = manager.standardizeNumber(amountToSend, offer.withdrawalAsset.assetAddress);

            feesAmount = (amountToSend * manager.feeAmount()) / manager.BPS();
            uint256 amountToPay = amountToSend - feesAmount;

            require(feesAmount > 0, "Dotc: Fees amount must be > 0");
            require(amountToPay > 0, "Dotc: Amount without fees must be > 0!");

            if (offer.isFullType) {
                require(
                    standardizedAmount == offer.withdrawalAsset.amount,
                    "Dotc: Amount to send is not passed for Full request"
                );

                isFullyTaken = _fullyTakeOffer(allOffers[offerId]);
            } else {
                (amountToWithdraw, realAmount, isFullyTaken) = _partiallyTakeOffer(
                    allOffers[offerId],
                    standardizedAmount,
                    amountToWithdraw
                );
            }

            // Send fees from taker to `feeReceiver`
            assetTransfer(offer.withdrawalAsset, msg.sender, manager.feeReceiver(), feesAmount);

            // Sending Withdrawal Asset from Taker to Maker
            assetTransfer(offer.withdrawalAsset, msg.sender, offer.maker, amountToPay);
        } else {
            isFullyTaken = _fullyTakeOffer(allOffers[offerId]);

            if (offer.depositAsset.assetType == AssetType.ERC20) {
                feesAmount = (offer.depositAsset.amount * manager.feeAmount()) / manager.BPS();

                amountToWithdraw -= feesAmount;

                manager.escrow().withdrawFees(offerId, feesAmount);
            }

            // Sending Withdrawal Asset from Taker to Maker
            assetTransfer(offer.withdrawalAsset, msg.sender, offer.maker, offer.withdrawalAsset.amount);
        }

        // Sending Deposit Asset from Escrow to Taker
        require(
            manager.escrow().withdrawDeposit(offerId, amountToWithdraw, msg.sender),
            "Dotc: Escrow Deposit asset withdrawal failed"
        );

        emit TakenOffer(offerId, msg.sender, isFullyTaken, realAmount, amountToSend);
    }

    /**
     * @notice Cancels an offer and refunds the maker.
     * @param offerId The ID of the offer to cancel.
     * @dev Can only be called by the offer's maker and when the timelock has passed.
     */
    function cancelOffer(uint256 offerId) external checkOffer(offerId) timelockPassed(offerId) nonReentrant {
        DotcOffer memory offer = allOffers[offerId];
        require(offer.maker == msg.sender, "Dotc: Only maker of this offer");

        delete allOffers[offerId];

        (bool success, uint256 amountToWithdraw) = manager.escrow().cancelDeposit(offerId, msg.sender);

        require(success, "Dotc: Escrow can not cancel deposit");

        emit CanceledOffer(offerId, msg.sender, amountToWithdraw);
    }

    /**
     * @notice Updates an existing offer's details.
     * @param offerId The ID of the offer to update.
     * @param newAmount New amount for the withdrawal asset.
     * @param _expiryTimestamp New expiry timestamp for the offer.
     * @param _timelockPeriod New timelock period for the offer.
     * @return status Boolean indicating the success of the operation.
     * @dev Only the maker of the offer can update it.
     */
    function updateOffer(
        uint256 offerId,
        uint256 newAmount,
        uint256 _expiryTimestamp,
        uint256 _timelockPeriod
    ) external checkOffer(offerId) timelockPassed(offerId) returns (bool status) {
        DotcOffer memory offer = allOffers[offerId];

        require(offer.maker == msg.sender, "Dotc: You are not the owner of this offer");

        if (newAmount != 0 && newAmount != manager.unstandardizeAsset(offer.withdrawalAsset)) {
            require(
                offer.withdrawalAsset.assetType != AssetType.ERC721,
                "Dotc: ERC721 offer amount can not be changed"
            );
            uint256 standardizedNewAmount = offer.withdrawalAsset.assetType == AssetType.ERC20
                ? manager.standardizeNumber(newAmount, offer.withdrawalAsset.assetAddress)
                : newAmount;

            allOffers[offerId].withdrawalAsset.amount = standardizedNewAmount;
            allOffers[offerId].unitPrice = (standardizedNewAmount * 10 ** manager.DECIMALS()) / offer.availableAmount;

            emit OfferUpdated(offerId, newAmount);
        }

        if (_expiryTimestamp > block.timestamp && _expiryTimestamp != offer.expiryTime && _expiryTimestamp != 0) {
            allOffers[offerId].expiryTime = _expiryTimestamp;
            emit UpdatedOfferExpiry(offerId, _expiryTimestamp);
        }

        if (_timelockPeriod > block.timestamp && _timelockPeriod != offer.timelockPeriod && _timelockPeriod != 0) {
            if (_expiryTimestamp == 0)
                require(offer.expiryTime > _timelockPeriod, "Dotc: Timelock must be less than expiration time");
            else require(_expiryTimestamp > _timelockPeriod, "Dotc: Timelock must be less than expiration time");

            allOffers[offerId].timelockPeriod = _timelockPeriod;
            emit UpdatedTimeLockPeriod(offerId, _timelockPeriod);
        }

        return true;
    }

    /**
     * @notice Changes the manager of the contract.
     * @param _manager The new manager address.
     * @return status Boolean indicating the success of the operation.
     * @dev Can only be called by the current manager.
     */
    function changeManager(IDotcManager _manager) external returns (bool status) {
        require(msg.sender == address(manager), "Dotc: Manager calls only");

        manager = _manager;

        emit ManagerAddressSet(msg.sender, _manager);

        return true;
    }

    /**
     * @notice Retrieves all offers made by a specific address.
     * @param account The address to query offers for.
     * @return A list of offer IDs created by the given account.
     */
    function getOffersFromAddress(address account) external view returns (uint256[] memory) {
        return offersFromAddress[account];
    }

    /**
     * @notice Gets the owner (maker) of a specific offer.
     * @param offerId The ID of the offer.
     * @return maker The address of the offer's maker.
     */
    function getOfferOwner(uint256 offerId) external view returns (address maker) {
        maker = allOffers[offerId].maker;
    }

    /**
     * @notice Retrieves details of a specific offer.
     * @param offerId The ID of the offer to retrieve.
     * @return offer The details of the specified offer.
     */
    function getOffer(uint256 offerId) external view returns (DotcOffer memory offer) {
        return allOffers[offerId];
    }

    /**
     * @notice Checks if the contract supports a specific interface.
     * @param interfaceId The interface identifier to check.
     * @return True if the interface is supported.
     * @dev Overridden to support ERC1155Receiver interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Internal function to create an offer.
    function _createOffer(
        Asset calldata depositAsset,
        Asset calldata withdrawalAsset,
        bool _isFullType,
        address _specialAddress,
        uint256 _expiryTimestamp,
        uint256 _timelockPeriod
    ) private view returns (DotcOffer memory _offer) {
        uint256 standardizedDepositAmount = manager.standardizeAsset(depositAsset, msg.sender);
        uint256 standardizedWithdrawalAmount = manager.standardizeAsset(withdrawalAsset);

        _offer.maker = msg.sender;
        _offer.isFullType = _isFullType;
        _offer.depositAsset = depositAsset;
        _offer.withdrawalAsset = withdrawalAsset;
        _offer.specialAddress = _specialAddress;
        _offer.expiryTime = _expiryTimestamp;
        _offer.timelockPeriod = _timelockPeriod;

        if (_offer.depositAsset.assetType == AssetType.ERC20) _offer.depositAsset.amount = standardizedDepositAmount;
        if (_offer.withdrawalAsset.assetType == AssetType.ERC20)
            _offer.withdrawalAsset.amount = standardizedWithdrawalAmount;

        _offer.availableAmount = _offer.depositAsset.amount;
        _offer.unitPrice = (_offer.withdrawalAsset.amount * 10 ** manager.DECIMALS()) / _offer.depositAsset.amount;
    }

    // Internal function to handle the full taking of an offer.
    function _fullyTakeOffer(DotcOffer storage offer) private returns (bool isFullyTaken) {
        isFullyTaken = true;

        offer.withdrawalAsset.amount = 0;
        offer.availableAmount = 0;
        offer.isFullyTaken = isFullyTaken;
    }

    // Internal function to handle the partial taking of an offer.
    function _partiallyTakeOffer(
        DotcOffer storage offer,
        uint standardizedAmount,
        uint amountToWithdraw
    ) private returns (uint256 amount, uint256 realAmount, bool isFullyTaken) {
        DotcOffer memory _offer = offer;

        if (standardizedAmount == _offer.withdrawalAsset.amount) {
            amountToWithdraw = _offer.availableAmount;
            offer.withdrawalAsset.amount = 0;
            offer.availableAmount = 0;
        } else {
            amountToWithdraw = (standardizedAmount * 10 ** manager.DECIMALS()) / _offer.unitPrice;

            offer.withdrawalAsset.amount -= standardizedAmount;
            offer.availableAmount -= amountToWithdraw;
        }

        if (offer.withdrawalAsset.amount == 0 || offer.availableAmount == 0) {
            isFullyTaken = true;
            offer.isFullyTaken = isFullyTaken;
        }

        amount = amountToWithdraw;
        realAmount = manager.unstandardizeNumber(amount, _offer.depositAsset.assetAddress);
    }

    /**
     * @dev Internal function to handle the transfer of different types of assets (ERC20, ERC721, ERC1155).
     * @param asset The asset to be transferred.
     * @param from The address sending the asset.
     * @param to The address receiving the asset.
     * @param amount The amount of the asset to transfer.
     */
    function assetTransfer(Asset memory asset, address from, address to, uint256 amount) private {
        if (asset.assetType == AssetType.ERC20) {
            IERC20Upgradeable(asset.assetAddress).safeTransferFrom(from, to, amount);
        } else if (asset.assetType == AssetType.ERC721) {
            IERC721Upgradeable(asset.assetAddress).safeTransferFrom(from, to, asset.tokenId);
        } else if (asset.assetType == AssetType.ERC1155) {
            IERC1155Upgradeable(asset.assetAddress).safeTransferFrom(from, to, asset.tokenId, asset.amount, "");
        }
    }
}
