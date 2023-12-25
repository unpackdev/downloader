//   _   _   _ _  _____  ___    _ __   ____  __      __  __ _               _   _             ___         _               _
//  | | | | | | |/ / __|/ _ \  | |\ \ / /\ \/ /___  |  \/  (_)__ _ _ _ __ _| |_(_)___ _ _    / __|___ _ _| |_ _ _ __ _ __| |_
//  | |_| |_| | ' <\__ \ (_) | | |_\ V /  >  </ -_) | |\/| | / _` | '_/ _` |  _| / _ \ ' \  | (__/ _ \ ' \  _| '_/ _` / _|  _|
//  |____\___/|_|\_\___/\___/  |____|_|  /_/\_\___| |_|  |_|_\__, |_| \__,_|\__|_\___/_||_|  \___\___/_||_\__|_| \__,_\__|\__|
//                                                           |___/

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.17;

// interfaces
import "./IERC1820Registry.sol";
import "./IERC165.sol";
import "./IERC777Recipient.sol";

// modules
import "./Ownable2Step.sol";

contract LUKSOMigrationDepositContract is
    IERC777Recipient,
    IERC165,
    Ownable2Step
{
    // The SenderDepositData struct stores the data of a deposit made by a sender
    struct SenderDepositData {
        address destinationAddress;
        uint96 amount;
        uint256 depositId;
    }

    // The DestinationDepositData struct stores the data of a deposit made to a destination
    struct DestinationDepositData {
        address senderAddress;
        uint96 amount;
        uint256 depositId;
    }

    // The DepositData struct stores the data of a deposit
    struct DepositData {
        address senderAddress;
        address destinationAddress;
        uint96 amount;
    }

    // The address of the LYXe token contract.
    address public constant LYX_TOKEN_CONTRACT_ADDRESS =
        0xA8b919680258d369114910511cc87595aec0be6D;

    // The address of the registry contract (ERC1820 Registry).
    address public constant ERC1820_REGISTRY_ADDRESS =
        0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;

    // The hash of the interface of the contract that receives tokens.
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
        0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

    // The deposit id
    uint256 public migrationDepositCount;

    // Determines whether the contract is paused or not. Deposits are disabled and not allowed while the contract is paused.
    bool public paused;

    // The '_senderDeposits' mapping stores an array of depositId for each sender address
    mapping(address => uint256[]) private _senderDeposits;

    // The '_destinationDeposits' mapping stores an array of depositId for each destination address
    mapping(address => uint256[]) private _destinationDeposits;

    // The '_deposits' mapping stores the DepositData struct of a depositId
    mapping(uint256 => DepositData) private _deposits;

    /**
     * @param sender The address of the sender migrating LYXe.
     * @param destinationAddress The address on the LUKSO main network that will receive the equivalent `amount` in LYX.
     * @param amount The amount of LYXe being migrated.
     * @param depositId The unique identifier associated with this particular migration transaction.
     * @param extraData Optional additional data related to the migration transaction.
     */
    event Deposit(
        address indexed sender,
        address indexed destinationAddress,
        uint256 amount,
        uint256 indexed depositId,
        bytes extraData
    );

    // Emits a pause status changed event.
    event PauseStatusChanged(bool newPauseStatus);

    constructor(address owner_) {
        // Set this contract as the implementer of the tokens recipient interface in the registry contract.
        IERC1820Registry(ERC1820_REGISTRY_ADDRESS).setInterfaceImplementer(
            address(this),
            TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );

        // Set the paused state to false
        paused = false;
        emit PauseStatusChanged(false);

        // Set the owner
        _transferOwnership(owner_);
    }

    /**
     * @dev Whenever this contract receives LYXe tokens, it must be for the reason of
     * migrating LYXe.
     */
    function tokensReceived(
        address /* operator */,
        address sender_,
        address /* to */,
        uint256 amount_,
        bytes calldata depositData_,
        bytes calldata /* operatorData */
    ) external {
        // Check if the caller is the LYXe token contract.
        require(
            msg.sender == LYX_TOKEN_CONTRACT_ADDRESS,
            "LUKSOMigrationDepositContract: Only LYXe can be migrated"
        );

        // Check that we are migrating at least 1 LYXe
        require(
            amount_ >= 1 ether,
            "LUKSOMigrationDepositContract: A minimum of 1 LYXe is required"
        );

        // Check if depositData length is superior to 20
        require(
            depositData_.length >= 20,
            "LUKSOMigrationDepositContract: depositData length must be superior to 20"
        );

        // Check that the contract is not paused.
        require(!paused, "LUKSOMigrationDepositContract: Contract is paused");

        // Check if the deposit amount is not bigger than the maximum uint96 value.
        require(
            amount_ < type(uint96).max,
            "LUKSOMigrationDepositContract: LYXe amount too large"
        );

        uint96 migrationDepositAmount = uint96(amount_);

        address destinationAddress = address(bytes20(depositData_));

        uint256 depositId = migrationDepositCount++;

        // Append the depositId to the sender's deposits array.
        _senderDeposits[sender_].push(depositId);

        // Append the depositId to the destination's deposits array.
        _destinationDeposits[destinationAddress].push(depositId);

        // Store the deposit data
        _deposits[depositId] = DepositData(
            sender_,
            destinationAddress,
            migrationDepositAmount
        );

        // Emit the Deposit event with the sender, the migration address and the amount.
        emit Deposit(
            sender_,
            destinationAddress,
            amount_,
            depositId,
            depositData_[20:]
        );
    }

    /**
     * @dev Only the owner can pause the contract.
     * @param pauseStatus The status of the pause.
     */
    function setPaused(bool pauseStatus) external onlyOwner {
        require(
            paused != pauseStatus,
            "LUKSOMigrationDepositContract: Pause status is already set to this value"
        );
        paused = pauseStatus;

        emit PauseStatusChanged(pauseStatus);
    }

    /**
     * @dev Query the deposits made by a given address.
     *
     * @param senderAddress_ The address of the sender whose deposits should be queried.
     * @return An array representing each SenderDepositData made successively by the `sender_`.
     */
    function getDepositsBySenderAddress(
        address senderAddress_
    ) external view returns (SenderDepositData[] memory) {
        uint256[] memory senderDepositsIds = _senderDeposits[senderAddress_];
        uint256 numberOfDeposits = senderDepositsIds.length;

        SenderDepositData[] memory senderDepositsList = new SenderDepositData[](
            numberOfDeposits
        );

        for (uint256 i = 0; i < numberOfDeposits; i++) {
            uint256 depositId = senderDepositsIds[i];
            DepositData memory deposit = _deposits[depositId];

            senderDepositsList[i] = SenderDepositData(
                deposit.destinationAddress,
                deposit.amount,
                depositId
            );
        }

        return senderDepositsList;
    }

    /**
     * @dev Query the migrations made to a given address.
     *
     * @param destinationAddress_ The address of the destination whose migrations should be queried.
     * @return An array representing each DestinationDepositData made successively to the `destinationAddress_`.
     */
    function getDepositsByDestinationAddress(
        address destinationAddress_
    ) external view returns (DestinationDepositData[] memory) {
        uint256[] memory destinationDepositsIds = _destinationDeposits[
            destinationAddress_
        ];
        uint256 numberOfDeposits = destinationDepositsIds.length;

        DestinationDepositData[]
            memory destinationDepositsList = new DestinationDepositData[](
                numberOfDeposits
            );

        for (uint256 i = 0; i < numberOfDeposits; i++) {
            uint256 depositId = destinationDepositsIds[i];
            DepositData memory deposit = _deposits[depositId];

            destinationDepositsList[i] = DestinationDepositData(
                deposit.senderAddress,
                deposit.amount,
                depositId
            );
        }

        return destinationDepositsList;
    }

    /**
     * @dev Query the deposit data of a given depositId.
     *
     * @param depositId_ The depositId of the deposit to query.
     * @return The DepositData of the deposit.
     */
    function getDeposit(
        uint256 depositId_
    ) external view returns (DepositData memory) {
        return _deposits[depositId_];
    }

    /**
     * @dev Determines whether the contract supports a given interface.
     *
     * @param interfaceId The interface ID to check.
     * @return True if the contract supports the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) external pure override returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC777Recipient).interfaceId;
    }
}
