// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";


contract LaunchPad is AccessControl, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event PreSaleClaimed(uint256 indexed roundID, address indexed sender, uint256 indexed preSaleID, uint256 preSaleNum);

    event Refund(uint256 indexed roundID, address indexed recipient, uint256 amount);

    struct Project {
        address target;             // nft or deposit or any contract
        address payable receipt;    // receive payment
        address payment;            // ETH or ERC20
        uint256 nftPrice;           // nft nftPrice
        uint256 totalSales;         // nft totalSales
        uint256 startTime;          // start
        uint256 endTime;            // end
        mapping(address => mapping(uint256 => uint256)) preSaleRecords;  //preSale records
    }

    // roundID => Project
    mapping(uint256 => Project) private round;

    constructor(address admin, address operator) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(OPERATOR_ROLE, operator);
    }

    receive() external payable {}

    /**
     * @dev Initializes a new presale round.
     * This function sets up the details for a new launchpad project with a specified ID. It requires several parameters:
     * - The target address of the presale.
     * - The receipt address where funds will be sent.
     * - The address of the ERC20 token to be used for payments (if any).
     * - The price of each NFT in the presale.
     * - The start and end times for the presale round.
     *
     * Note: This function can only be called by an account with the `OPERATOR_ROLE`.
     *
     * @param _roundID The ID of the presale round to set up.
     * @param _target The target address of the presale.
     * @param _receipt The receipt address where funds will be sent.
     * @param _payment The address of the ERC20 token to be used for payments (if any).
     * @param _nftPrice The price of each NFT in the presale.
     * @param _startTime The start time for the presale round.
     * @param _endTime The end time for the presale round.
     */
    function launchpad(uint256 _roundID, address _target, address payable _receipt, address _payment, uint256 _nftPrice, uint256 _startTime, uint256 _endTime) public onlyRole(OPERATOR_ROLE) {
        require(_endTime > block.timestamp, "Invalid time");
        require(_target != address(0), "Invalid target");
        require(_receipt != address(0), "Invalid receipt");
        require(_nftPrice > 0, "nftPrice > 0");

        Project storage project = round[_roundID];

        require(project.target == address(0), "Already setting");

        project.target = _target;
        project.receipt = _receipt;
        project.payment = _payment;
        project.nftPrice = _nftPrice;
        project.startTime = _startTime;
        project.endTime = _endTime;
    }

    /**
     * @dev Executes a presale transaction.
     * This function allows a user to participate in a presale round by purchasing a specific amount of tokens.
      * The function performs several checks to validate the transaction:
     * - Checks that the current time is within the project's start and end times.
     * - Verifies that the `preSaleID` has not been used before by the sender.
     * - Checks that the `preSaleNum` is greater than 0.
     * - If the project's payment address is the zero address, it checks that the value sent with the transaction is
     *   greater or equal to the total cost of the tokens. Any excess value is refunded to the sender.
     * - If the project's payment address is not the zero address, it checks that no ether was sent with the transaction,
     *   and transfers the total cost of tokens from the sender to the project's receipt address using an ERC20 token transfer.
     *
     * After the checks and transfers, the function increments the project's total sales by `preSaleNum`,
     * and records the total payment for the `preSaleID` of the sender.
     *
     * Finally, it emits a `PreSaleClaimed` event.
     *
     * @param roundID The ID of the Project.
     * @param preSaleID The ID of the presale.
     * @param preSaleNum The number of tokens to purchase in the presale.
     */
    function preSale(uint256 roundID, uint256 preSaleID, uint256 preSaleNum) public payable nonReentrant {
        Project storage project = round[roundID];

        // Verify time
        require(project.startTime <= block.timestamp, "The LaunchPad activity has not started");
        require(project.endTime >= block.timestamp, "The LaunchPad activity has ended");

        // Verify preSaleID and preSaleNum
        require(project.preSaleRecords[msg.sender][preSaleID] == 0, "Duplicate preSaleID");
        require(preSaleNum > 0, "preSaleNum>0");
        // Receipt token && Refund token
        uint256 total = project.nftPrice * preSaleNum;
        if (project.payment == address(0)) {
            require(msg.value >= total, "Insufficient token");
            uint256 _refund = msg.value - total;
            if (_refund > 0) {
                // Refund the excess token
                payable(msg.sender).transfer(_refund);
            }

            // Transfer the total payment to the project receipt address
            project.receipt.transfer(total);
        } else {
            require(msg.value == 0, "Needn't pay mainnet token");

            // Transfer the total payment from the sender to the project receipt address
            IERC20(project.payment).safeTransferFrom(msg.sender, project.receipt, total);
        }

        // Increment the total sales for the project
        unchecked{
            project.totalSales += preSaleNum;
        }

        // Record the total payment for the preSaleID of the sender
        project.preSaleRecords[msg.sender][preSaleID] = total;

        emit PreSaleClaimed(roundID, msg.sender, preSaleID, preSaleNum);
    }

    /**
     * @dev Initiates refunds for a special project.
     * This function allows the project owner to refund amounts to multiple recipients.
     * It requires the round ID, the source address of the funds, an array of recipient addresses and an array of amounts.
     *
     * The function performs several checks to validate the parameters:
     * - Verifies that the length of the recipients array is equal to the length of the amounts array.
     *
     * After the checks, it retrieves the ERC20 token used for payments in the presale round,
     * and for each recipient in the array, it transfers the corresponding amount from the source address to the recipient.
     * It then emits a `Refund` event for each transfer.
     *
     * Note: This function can only be called by an account with appropriate permissions (typically the contract owner).
     *
     * @param roundID The ID of the presale round.
     * @param recipients An array of addresses to refund.
     * @param amounts An array of amounts to refund to each recipient.
     */
    function refund(uint256 roundID, address[] calldata recipients, uint256[] calldata amounts) external payable nonReentrant {
        require(recipients.length == amounts.length, "Wrong senders array-length");
        uint256 total;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(amounts[i] > 0, "Amount should greater than zero");
            total += amounts[i];
        }
        // Get the project associated with the given roundID
        Project storage project = round[roundID];

        if (project.payment == address(0)) {
            require(msg.value >= total, "Insufficient amount token");
            uint256 _refund = msg.value - total;
            if (_refund > 0) {
                // Refund the excess token
                payable(msg.sender).transfer(_refund);
            }
            // Iterate over each recipient and transfer the corresponding amount of tokens
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                payable(recipients[i]).transfer(amounts[i]);

                emit Refund(roundID, recipients[i], amounts[i]);
            }
        } else {
            require(msg.value == 0, "Needn't pay mainnet token");
            address erc20Token = project.payment;
            // Iterate over each recipient and transfer the corresponding amount of tokens
            for (uint256 i = 0; i < recipients.length; i++) {
                // Transfer tokens to the recipient
                IERC20(erc20Token).safeTransferFrom(msg.sender, recipients[i], amounts[i]);

                emit Refund(roundID, recipients[i], amounts[i]);
            }
        }
    }

    // Returns project details by the roundID.
    function getProject(uint256 roundID) external view returns (address, address, address, uint256, uint256, uint256, uint256){
        Project storage project = round[roundID];
        return (project.target, project.receipt, project.payment, project.nftPrice, project.totalSales, project.startTime, project.endTime);
    }

    // Returns project totalSales by the roundID.
    function getProjectTotalSales(uint256 roundID) external view returns (uint256){
        Project storage project = round[roundID];
        return project.totalSales;
    }

    // Returns project preSaleRecords by the roundID.
    function getProjectPreSale(uint256 roundID, address user, uint256 preSaleID) external view returns (uint256){
        Project storage project = round[roundID];
        return project.preSaleRecords[user][preSaleID];
    }

    /**
     * @dev Executes a function call on another contract.
     * @param dest The address of the contract to call.
     * @param value The amount of ether/matic/mainnet token to send with the call.
     * @param func The function signature and parameters to call.
     */
    function execute(address dest, uint256 value, bytes calldata func) external onlyRole(OPERATOR_ROLE) {
        _call(dest, value, func);
    }

    /**
     * @dev Executes a batch of function calls on multiple contracts.
     * This function allows this contract to execute a batch of function calls on multiple contracts by specifying
     * an array of destination addresses, an array of values to send with each call, and an array of function signatures
     * and parameters for each call.
     * @param dest An array of addresses of the contracts to call.
     * @param value An array of amounts of ether/matic/mainnet token to send with each call.
     * @param func An array of function signatures and parameters to call for each destination.
     */
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external onlyRole(OPERATOR_ROLE) {
        require(dest.length == func.length && (value.length == 0 || value.length == func.length), "Wrong array lengths");
        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], 0, func[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], value[i], func[i]);
            }
        }
    }

    /**
     * @dev Executes a low-level call to another contract.
     * This internal function allows the contract to execute a low-level call to another contract,
     * by specifying the target address, the value to send with the call, and the data to send.
     *
     * It performs the call and checks if it was successful. If not, it reverts the transaction and returns
     * the error message from the failed call.
     *
     * Note: Use this function with caution as low-level calls can be dangerous.
     *
     * @param target The address of the contract to call.
     * @param value The amount of ether/mainnet token to send with the call.
     * @param data The data to send with the call.
     */
    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
