// contracts/Franklin.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "IERC20Upgradeable.sol";
import "SafeERC20Upgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";
import "PausableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "UUPSUpgradeable.sol";
import "ERC2771ContextUpgradeable.sol";
import "FranklinTokenWhitelist.sol";
import "IFranklinTokenWhitelist.sol";

/// @title Franklin
/// @author Franklin Systems Inc.
/** @notice

**/
/** @dev
    NEED TO UPDATE PERMISSIONS TO FIT BETA USERS (OWNER VS ADMIN)
**/

contract Franklin is
    OwnableUpgradeable,
    ERC2771ContextUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ============ EVENTS ============
    /// @notice Emits address added to admin permissions
    event AdminAdded(address _admin);
    /// @notice Emits address removed from admin permissions
    event AdminRemoved(address _admin);
    /// @notice Emits address added as a worker, eligible for payroll
    event WorkerAdded(address _worker);
    /// @notice Emits addresses added as workers, eligible for payroll
    event WorkersBulkAdded(address[] _workerAddresses);
    /// @notice Emits worker address and their last day
    event WorkerTerminated(address _worker, uint256 _lastDay);
    /// @notice Emits amount and token address deposited into static treasury
    event StaticDeposit(uint256 _amount, address _token);
    /// @notice Emits amount & token address deposited for streaming treausry
    event StreamingDeposit(uint256 _amount, address _token);
    /// @notice Emits amount and token address withdrawn from nonstreaming treasury
    event StaticWithdrawal(uint256 _amount, address _token);
    // @notice Emits amount and token address withdrawn from streaming treasury
    event StreamingWithdrawal(uint256 _amount, address _token);
    /// @notice Emits old address and new address for a worker when updated
    event WorkerAddressUpdated(address _oldAddress, address _newAddress);
    /// @notice Emits arrays of payroll information after successful execution
    event WorkersBulkPaid(
        address[] _workerAddresses,
        address[] _tokenAddresses,
        uint256[] _amounts
    );
    /** @notice
        Emits information of funds transfered out of contract ownership when a
        _worker claims their Payroll.
    **/
    event PayrollClaimed(address _worker, uint256 _amount, address _token);

    /// @notice Emits details of changing balances in the Franklin ecosystem
    event TransferToWorkerBalance(
        uint256 _amount,
        address _worker,
        address _token
    );

    /// @notice Emits details of a transfer directly to a worker's wallet
    event DirectTransfer(uint256 _amount, address _worker, address _token);

    /// @notice Emits details of a new stream that has been created
    event StreamCreated(
        address _worker,
        address _token,
        uint256 _start,
        uint256 _end,
        uint256 _rate
    );

    /// @notice Emits details of a stream which has been updated
    event StreamEdited(
        address _worker,
        address _token,
        uint256 _start,
        uint256 _end,
        uint256 _rate
    );
    /// @notice Emits details of a stream which has been terminated
    event StreamEnded(address _worker, address _token, uint256 _end);

    /// @notice Emits details of a stream which has been deleted
    event StreamDeleted(address _worker, address _token);

    // ============ STORAGE VARIABLES ============

    /// @dev FranklinTokenWhitelist contract managing approved tokens, defined in initialize
    IFranklinTokenWhitelist tokenWhiteList;

    /// @dev Mapping for managing admin permissions
    mapping(address => bool) private admins;

    /// @dev Mapping for managing workers
    mapping(address => bool) private workers;

    /// @dev Treasury struct managing company treasury per _token
    /// @param staticBalance is the account of funds not allocated to streaming
    /// @param settledStreamingBalance is the account of settled funds for streaming
    /** @param workersWithStream is an array of workers that have a payroll
               stream in the associated token */
    struct Treasury {
        uint256 staticBalance;
        uint256 settledStreamingBalance;
        address[] workersWithStream;
    }

    /// @dev A worker's balance combining settled and streaming funds (per _token)
    /// @param settled is the account of funds owned by a worker not in a stream
    /** @param streamIndex is the location of the worker in the associated
               treasury.workersWithStream array if they exist*/
    struct Balance {
        uint256 settled;
        Stream current;
        Stream next;
        uint256 streamIndex;
    }

    /// @dev Represents a payroll stream that is part of a worker's balance
    struct Stream {
        uint256 start;
        uint256 end;
        uint256 withdrawn;
        uint256 rate;
    }

    /** @dev
        Mapping to manage balances.
        The first address in the mapping is the worker address, the second
        address is the ERC20 address of the _token. It returns the Balance
        struct for that _worker for that _token */
    mapping(address => mapping(address => Balance)) private tokenBalance;

    /** @dev
        Mapping to manage the Payroll Treasury owned by the organization.
        This may be different than the total funds "owned" by the contract
        as Users will not instantly claim payroll. Takes the address of the
        ERC20 _token and returns the Treasury struct representing the balance
        of that _token */
    mapping(address => Treasury) private tokenTreasury;

    // ============ MODIFIERS ============

    modifier onlyWorker() {
        _isWorker();
        _;
    }

    function _isWorker() internal view {
        require(workers[_msgSender()], "Must be a worker");
    }

    modifier onlyAdminOrOwner() {
        _isAdminOrOwner();
        _;
    }

    function _isAdminOrOwner() internal view {
        address owner = owner();
        require(
            admins[_msgSender()] || _msgSender() == owner,
            "Must be admin or owner"
        );
    }

    modifier onlyApprovedTokens(address _token) {
        _isApprovedToken(_token);
        _;
    }

    function _isApprovedToken(address _token) internal view {
        bool approved = tokenWhiteList.isApprovedToken(_token);
        require(approved, "Token is not approved");
    }

    modifier onlyExistingWorker(address _worker) {
        _isExistingWorker(_worker);
        _;
    }

    function _isExistingWorker(address _worker) internal view {
        require(workers[_worker], "Worker does not exist");
    }

    // ============ CONSTRUCTOR ============
    constructor() {
        _disableInitializers();
    }

    // ============ INITIALIZERS ============

    /// @notice Called by the proxy when it is deployed
    /// @param forwarder The trusted forwarder for the proxy initializing
    /// @param tokenWhiteListAddress The address of the FranklinTokenWhitelist contract
    function initialize(address forwarder, address tokenWhiteListAddress)
        public
        initializer
    {
        require(forwarder != address(0), "No 0x0 address");
        require(forwarder != address(this), "Cant be this contract");
        require(tokenWhiteListAddress != address(0), "No 0x0 address");
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ERC2771Context_init(forwarder);
        tokenWhiteList = IFranklinTokenWhitelist(tokenWhiteListAddress);
    }

    /// @notice Overrides UUPS implementation to set upgrade permissions
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// Protect owner by overriding renounceOwnership
    function renounceOwnership() public virtual override {
        revert("Cant renounce");
    }

    // ============ VIEW FUNCTIONS ============

    /// @notice Returns True if address is a worker, False otherwise
    /// @param _worker The address being checked for worker permissions
    function isWorker(address _worker)
        external
        view
        onlyAdminOrOwner
        returns (bool)
    {
        return (workers[_worker]);
    }

    /// @notice Returns True if address is an admin, False otherwise
    /// @param _admin The address being checked for admin permissions
    function isAdmin(address _admin)
        external
        view
        onlyAdminOrOwner
        returns (bool)
    {
        return (admins[_admin]);
    }

    /// @notice Returns True if token is approved, False otherwise
    /// @param _token The address being checked for token approval
    function isApprovedToken(address _token)
        external
        view
        onlyAdminOrOwner
        returns (bool)
    {
        return (tokenWhiteList.isApprovedToken(_token));
    }

    /** @notice
        Gets the quantity of funds in the treasury for the requested ERC20
        _token, including the streaming and static treasury balances */
    /// @param _token The address of the ERC20 _token contract
    /// @return The quantity of funds in the treasury for the requested _token
    function getTotalTreasury(address _token)
        external
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        return (getStreamingTreasury(_token) + getStaticTreasury(_token));
    }

    /// @notice Provides the quantity of funds not being used for streams
    /// @param _token The address of the ERC20 _token contract
    /// @return The quantity of funds in the static treasury
    function getStaticTreasury(address _token)
        public
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        return (tokenTreasury[_token].staticBalance);
    }

    /// @notice Provides the quantity of funds available for streaming payroll
    /// @param _token The address of the ERC20 _token contract
    /// @return The quantity of funds in the streaming treasury
    function getStreamingTreasury(address _token)
        public
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        Treasury storage treasury = tokenTreasury[_token];
        address[] storage workerArray = treasury.workersWithStream;
        uint256 streamed = 0;

        /* For each worker that has a stream of the associated token,
           sum the value streamed and add to the `streamed` var which will be
           subtracted from the settled amount to get the balance*/
        for (uint256 i = 1; i < workerArray.length; ) {
            Balance storage b = tokenBalance[workerArray[i]][_token];
            Stream storage current = b.current;
            Stream storage next = b.next;

            if (current.start < block.timestamp) {
                //check if current stream has ended
                if (current.end < block.timestamp) {
                    // add value streamed in current stream
                    streamed += (current.end - current.start) * current.rate;
                    //check if next stream has started
                    if (next.start < block.timestamp) {
                        //check if next stream has ended
                        if (next.end < block.timestamp) {
                            // add value of "next" stream to streamed
                            streamed += (next.end - next.start) * next.rate;
                        } else {
                            // if next hasn't ended, add the amount streamed up to now
                            streamed +=
                                (block.timestamp - next.start) *
                                next.rate;
                        }
                    }
                } else {
                    streamed +=
                        (block.timestamp - current.start) *
                        current.rate;
                }
            }
            unchecked {
                i++;
            }
        }

        return (treasury.settledStreamingBalance - streamed);
    }

    /// @notice Provides the current _rate that funds are streamed out of the Treasury
    /// @param _token The address of the ERC20 _token contract
    /// @return The _rate funds are streaming out of the treasury
    function getStreamingTreasuryRate(address _token)
        external
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        Treasury storage t = tokenTreasury[_token];
        address[] memory workerArray = t.workersWithStream;
        uint256 totalRate = 0;

        for (uint256 i = 1; i < workerArray.length; ) {
            Balance storage b = tokenBalance[workerArray[i]][_token];
            // check if current stream is in effect (assumes started or rate = 0);
            if (
                b.current.start < block.timestamp &&
                block.timestamp < b.current.end
            ) {
                totalRate += b.current.rate;
            } else if (
                b.next.start < block.timestamp && block.timestamp < b.next.end
            ) {
                totalRate += b.next.rate;
            }
            unchecked {
                i++;
            }
        }

        return (totalRate);
    }

    /// @notice Allows workers to check their accumulated payroll by token
    /// @param _token The token address for which they are checking payroll
    /// @return The quantity of payroll accumulated in the specified token
    function getPayrollAsWorker(address _token)
        external
        view
        onlyApprovedTokens(_token)
        returns (uint256)
    {
        return (getSettledBalance(_msgSender(), _token) +
            getStreamBalance(_msgSender(), _token));
    }

    /// @notice Provides the settled balance of a worker
    /// @param _worker The address of the worker being looked up
    /// @param _token The address of the token being looked up
    /// @return The settled balance of the specified token for that worker
    function getSettledBalance(address _worker, address _token)
        public
        view
        onlyWorker
        onlyExistingWorker(_worker)
        returns (uint256)
    {
        return (tokenBalance[_worker][_token].settled);
    }

    /// @notice Provides the streaming balance of a worker
    /// @param _worker The address of the worker being looked up
    /// @param _token The address of the _oken being looked up
    /// @return The stream balance of the specified token for that worker
    function getStreamBalance(address _worker, address _token)
        public
        view
        onlyWorker
        onlyExistingWorker(_worker)
        returns (uint256)
    {
        uint256 currentBalance = _getCurrentStreamBalance(_worker, _token);
        // nextBalance > 0 only if current stream balance has expired
        uint256 nextBalance = _getNextStreamBalance(_worker, _token);

        return (currentBalance + nextBalance);
    }

    /// @notice Gets the balance of balance.current
    /// @param _worker The address of the worker being looked up
    /// @param _token The address of the token being looked up
    /// @return Value of balance.current stream for defined worker/token
    function _getCurrentStreamBalance(address _worker, address _token)
        internal
        view
        returns (uint256)
    {
        Balance storage b = tokenBalance[_worker][_token];
        Stream storage current = b.current; // gets current stream object

        if (current.end < block.timestamp) {
            return ((current.end - current.start) *
                current.rate -
                current.withdrawn);
        } else if (
            current.start < block.timestamp && block.timestamp < current.end
        ) {
            return ((block.timestamp - current.start) *
                current.rate -
                current.withdrawn);
        }
        return (0);
    }

    /** @notice Gets the balance of balance.next. This can be non-zero when
        the current stream has ended and the next stream is accruing value.
        The balance object isn't always immediately updated so this function
        allows us to check if the balance.next stream is accruing value. */
    /// @param _worker The address of the worker being looked up
    /// @param _token The address of the _oken being looked up
    /// @return Value of balance.current stream for defined worker/token
    function _getNextStreamBalance(address _worker, address _token)
        internal
        view
        returns (uint256)
    {
        Balance storage b = tokenBalance[_worker][_token];
        Stream storage next = b.next;

        //check if next stream has ended
        if (next.end < block.timestamp) {
            return ((next.end - next.start) * next.rate - next.withdrawn);
        } else if (next.start < block.timestamp && block.timestamp < next.end) {
            return ((block.timestamp - next.start) *
                next.rate -
                next.withdrawn);
        }

        return (0);
    }

    /// @notice gets the parameters of the current stream in a worker's balance
    /// @param _worker The worker for which you are checking stream parameters
    /// @param _token The token for the balance being checked
    function getCurrentStream(address _worker, address _token)
        external
        view
        onlyAdminOrOwner
        onlyExistingWorker(_worker)
        onlyApprovedTokens(_token)
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Stream storage current = tokenBalance[_worker][_token].current;
        return (current.start, current.end, current.withdrawn, current.rate);
    }

    /// @notice gets the parameters of the next stream in a worker's balance
    /// @param _worker The worker for which you are checking stream parameters
    /// @param _token The token for the balance being checked
    function getNextStream(address _worker, address _token)
        external
        view
        onlyAdminOrOwner
        onlyExistingWorker(_worker)
        onlyApprovedTokens(_token)
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Stream storage next = tokenBalance[_worker][_token].next;
        return (next.start, next.end, next.withdrawn, next.rate);
    }

    /** @notice
        Allows the owner and admin to check payroll accumulated by a specific
        worker, includes settled and streaming balance */
    /// @param _worker The wallet address of the worker requested
    /// @param _token The token address which they are querying
    /// @return The quantity of payroll owed to a worker in the specified token
    function getPayrollAsAdminOrOwner(address _worker, address _token)
        external
        view
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
        returns (uint256)
    {
        return (getSettledBalance(_worker, _token) +
            getStreamBalance(_worker, _token));
    }

    // ============ Public Effects & Interactions Functions ============

    /*** Admin Functions ***/

    /// @notice Adds an address to admin permissions for this contract
    /// @param _admin The address added to admin permissions
    function addAdmin(address _admin) external whenNotPaused onlyOwner {
        require(_admin != address(this), "Cant be this contract");
        require(!admins[_admin], "Admin exists");
        require(_admin != address(0), "No 0x0 address");

        admins[_admin] = true;

        if (!workers[_admin]) {
            workers[_admin] = true;
        }

        emit AdminAdded(_admin);
    }

    /// @notice Removes an address from admin permissions for this contract
    /// @param _admin The address removed from admin permissions
    function removeAdmin(address _admin) external whenNotPaused onlyOwner {
        require(admins[_admin] == true, "Admin doesnt exist");

        admins[_admin] = false;

        emit AdminRemoved(_admin);
    }

    /*** Worker Management ***/

    /// @notice Adds workers address so that it is eligible for payroll
    /// @param _worker The address of the worker being added
    function addWorker(address _worker)
        external
        whenNotPaused
        onlyAdminOrOwner
    {
        require(_worker != address(this), "Cant be this contract");
        require(!workers[_worker], "Worker exists");
        require(_worker != address(0), "No 0x0 address");

        workers[_worker] = true;

        emit WorkerAdded(_worker);
    }

    /// @notice Bulk adds workers so they are eligible for payroll. Max 250 at once
    /// @param _workerAddresses Array of worker addresses being added
    function bulkAddWorkers(address[] calldata _workerAddresses)
        external
        whenNotPaused
        onlyAdminOrOwner
    {
        require(_workerAddresses.length < 250, "Max add is 250");
        for (uint256 i = 0; i < _workerAddresses.length; ) {
            require(!workers[_workerAddresses[i]], "Worker exists");
            require(_workerAddresses[i] != address(0), "No 0x0 address");

            workers[_workerAddresses[i]] = true;
            unchecked {
                i++;
            }
        }

        emit WorkersBulkAdded(_workerAddresses);
    }

    /// @notice Removes a worker from the system. Sends all earned funds earned by their last day to their wallet
    /// @param _worker The worker being removed
    /// @param _lastDay When the worker stops earning funds
    function terminateWorker(address _worker, uint256 _lastDay)
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyExistingWorker(_worker)
    {
        address[] memory approvedTokens = tokenWhiteList.getApprovedTokens();
        // get total balance for each token and force send to their wallet
        for (uint256 i = 0; i < approvedTokens.length; ) {
            Balance storage balance = tokenBalance[_worker][approvedTokens[i]];
            Stream storage current = balance.current;
            Stream storage next = balance.next;
            uint256 streamBalance = 0;
            Treasury storage treasury = tokenTreasury[approvedTokens[i]];

            if (current.start < _lastDay) {
                // get value in current stream
                if (current.end >= _lastDay) {
                    uint256 quantity = (_lastDay - current.start) *
                        current.rate -
                        current.withdrawn;
                    streamBalance += quantity;
                    treasury.settledStreamingBalance -=
                        quantity +
                        current.withdrawn;
                } else if (current.end < _lastDay) {
                    uint256 quantity = (current.end - current.start) *
                        current.rate -
                        current.withdrawn;
                    streamBalance += quantity;
                    treasury.settledStreamingBalance -=
                        quantity +
                        current.withdrawn;
                }
                // get value in next stream
                if (next.start < _lastDay && next.end >= _lastDay) {
                    uint256 quantity = (_lastDay - next.start) *
                        next.rate -
                        next.withdrawn;
                    streamBalance += quantity;
                    treasury.settledStreamingBalance -=
                        quantity +
                        next.withdrawn;
                } else if (next.end < _lastDay) {
                    uint256 quantity = (next.end - next.start) *
                        next.rate -
                        next.withdrawn;
                    streamBalance += quantity;
                    treasury.settledStreamingBalance -=
                        quantity +
                        next.withdrawn;
                }
            }
            uint256 totalBalance = balance.settled + streamBalance;
            delete (tokenBalance[_worker][approvedTokens[i]]);
            IERC20Upgradeable(approvedTokens[i]).safeTransfer(
                _worker,
                totalBalance
            );
            unchecked {
                i++;
            }
        }
        workers[_worker] = false;

        emit WorkerTerminated(_worker, _lastDay);
    }

    /** @notice
        Updates an workers wallet address and transfers payroll from the
        previous wallet address to the new wallet address. This can only be
        called by a worker, and the input is the new address */
    /// @param _newAddress The new address used by the worker
    function updateWorkerAddress(address _newAddress)
        external
        whenNotPaused
        onlyWorker
    {
        require(!workers[_newAddress], "New address exists");
        require(_newAddress != address(0), "No 0x0 address");

        address[] memory approvedTokens = tokenWhiteList.getApprovedTokens();
        // loop through funds to re-assign balances
        for (uint256 i = 0; i < approvedTokens.length; ) {
            Balance memory oldAddressBalance = tokenBalance[_msgSender()][
                approvedTokens[i]
            ];

            Treasury storage treasury = tokenTreasury[approvedTokens[i]];
            address[] storage workerArray = treasury.workersWithStream;
            // replace old address with new address in array
            if (oldAddressBalance.streamIndex != 0) {
                workerArray[oldAddressBalance.streamIndex] = _newAddress;
            }

            // delete old balance mapping to protect against re-entrancy
            delete (tokenBalance[_msgSender()][approvedTokens[i]]);
            tokenBalance[_newAddress][approvedTokens[i]] = oldAddressBalance;
            unchecked {
                i++;
            }
        }

        delete (workers[_msgSender()]);
        workers[_newAddress] = true;

        emit WorkerAddressUpdated(_msgSender(), _newAddress);
    }

    /** ============== PAYROLL FUNCTIONS =================== **/

    /** @notice
        Bulk executes payroll by updating the amount of funds that workers
        can claim from the contract. Accepts ordered arrays, must be smaller
        than length 500 to protect function from dynamic array loop */
    /** @dev
        The input arrays must be aligned such that if worker A is owed 15
        USDC:
        _workerAddresses[0] = worker A address
        _tokenAddresses[0] = USDC
        _amounts[0] = 15 */
    /// @param _workerAddresses The array of workers being paid
    /// @param _tokenAddresses The array of tokens corresponding to payments
    /// @param _amounts The array of amounts corresponding to payments
    function bulkPayWorkers(
        address[] calldata _workerAddresses,
        address[] calldata _tokenAddresses,
        uint256[] calldata _amounts
    ) external whenNotPaused onlyAdminOrOwner {
        require(_workerAddresses.length <= 500, "Batch max size is 500");
        require(
            _workerAddresses.length == _tokenAddresses.length &&
                _workerAddresses.length == _amounts.length,
            "Array lengths inequal"
        );

        for (uint256 i = 0; i < _workerAddresses.length; ) {
            require(workers[_workerAddresses[i]], "Worker doesnt exist");
            require(_amounts[i] > 0, "Must be non-zero");
            require(
                tokenWhiteList.isApprovedToken(_tokenAddresses[i]),
                "Token unapproved"
            );
            require(
                tokenTreasury[_tokenAddresses[i]].staticBalance >= _amounts[i],
                "Insufficient funds"
            );

            // decrement treasury owned funds
            tokenTreasury[_tokenAddresses[i]].staticBalance -= _amounts[i];

            // send funds directly
            IERC20Upgradeable(_tokenAddresses[i]).safeTransfer(
                _workerAddresses[i],
                _amounts[i]
            );
            unchecked {
                i++;
            }
        }

        emit WorkersBulkPaid(_workerAddresses, _tokenAddresses, _amounts);
    }

    /// @notice Sends funds directly from the treasury to the worker's wallet
    /// @param _amount The amount to send to the worker
    /// @param _token The address of the token being sent
    /// @param _worker The address of the worker's wallet to send funds to
    function directTransfer(
        uint256 _amount,
        address _token,
        address _worker
    )
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_amount <= getStaticTreasury(_token), "Insufficient funds");
        require(_amount > 0, "Must be non-zero");

        // Decrement treasury accounting before sending funds
        tokenTreasury[_token].staticBalance -= _amount;

        emit DirectTransfer(_amount, _worker, _token);

        IERC20Upgradeable(_token).safeTransfer(_worker, _amount);
    }

    /// @notice Increments the account of the user's settled funds
    /// @param _amount The amount to add to the worker's balance
    /// @param _token The address of the token being sent
    /// @param _worker The address of the worker
    function transferToWorkerBalance(
        uint256 _amount,
        address _token,
        address _worker
    )
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_amount != 0, "Must be non-zero");

        // Decrement funds from treasuries nonStreaming funds
        tokenTreasury[_token].staticBalance -= _amount;

        // Add funds to user's balance in the contracts
        Balance storage b = tokenBalance[_worker][_token];
        b.settled += _amount;

        emit TransferToWorkerBalance(_amount, _worker, _token);
    }

    /* ============= STREAMING PAYROLL FUNCTIONS =============== */

    /// @notice Creates a new payroll stream
    /// @param _worker The address of the worker receiving the stream
    /// @param _token The address of the token being streamed
    /// @param _start When the stream begins (in seconds past the epoch)
    /// @param _end When the stream ends (in seconds past the epoch)
    /// @param _rate The rate at which the stream is paying the worker
    function createStream(
        address _worker,
        address _token,
        uint256 _start,
        uint256 _end,
        uint256 _rate
    )
        public
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_start < _end, "start > end");
        require(_rate > 0, "rate == 0");
        require(_start > block.timestamp, "Start cant be in past");

        Balance storage b = tokenBalance[_worker][_token];
        Treasury storage t = tokenTreasury[_token];

        require(b.current.rate == 0, "Stream already created");
        require(t.workersWithStream.length < 500, "Max streams reached");

        if (t.workersWithStream.length == 0) {
            // if this is the first stream created, capture the 0 spot to prevent
            // a worker from having an index of 0
            t.workersWithStream.push(address(0x0));
        }

        // add worker to treasury.workersWithStream array if not already present
        if (b.streamIndex == 0) {
            b.streamIndex = t.workersWithStream.length;
            t.workersWithStream.push(_worker);
        }

        Stream memory newStream = Stream({
            start: _start,
            end: _end,
            withdrawn: 0,
            rate: _rate
        });

        b.current = newStream;

        emit StreamCreated(_worker, _token, _start, _end, _rate);
    }

    /// @notice Creates a new payroll stream
    /// @param _workerAddresses The addresses of the workers receiving the stream
    /// @param _tokenAddresses The addresses of the tokens being streamed
    /// @param _startTimes When the streams begins (in seconds past the epoch)
    /// @param _endTimes When the streams ends (in seconds past the epoch)
    /// @param _rates The rate at which the stream is paying the worker
    function bulkCreateStreams(
        address[] calldata _workerAddresses,
        address[] calldata _tokenAddresses,
        uint256[] calldata _startTimes,
        uint256[] calldata _endTimes,
        uint256[] calldata _rates
    ) external whenNotPaused onlyAdminOrOwner {
        require(_workerAddresses.length <= 100, "Bulk max size is 100");
        require(
            _workerAddresses.length == _tokenAddresses.length &&
                _workerAddresses.length == _startTimes.length &&
                _workerAddresses.length == _endTimes.length &&
                _workerAddresses.length == _rates.length,
            "Arrays must be equal length"
        );

        for (uint256 i = 0; i < _workerAddresses.length; ) {
            createStream(
                _workerAddresses[i],
                _tokenAddresses[i],
                _startTimes[i],
                _endTimes[i],
                _rates[i]
            );
            unchecked {
                i++;
            }
        }
    }

    /// @notice Edits an existing payroll stream
    /// @param _worker The address of the worker receiving the stream
    /// @param _token The address of the token being streamed
    /// @param _start When the stream begins (in seconds past the epoch)
    /// @param _end When the stream ends (in seconds past the epoch)
    /// @param _rate The rate at which the stream is paying the worker
    function editStream(
        address _worker,
        address _token,
        uint256 _start,
        uint256 _end,
        uint256 _rate
    )
        external
        onlyAdminOrOwner
        whenNotPaused
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_start < _end, "start > end");
        require(_rate > 0, "rate==0 ");
        require(_start > block.timestamp, "Start cant be in the past");

        Balance storage b = tokenBalance[_worker][_token];
        require(b.current.start != 0, "No stream exists");
        Stream memory newStream = Stream({
            start: _start,
            end: _end,
            withdrawn: 0,
            rate: _rate
        });

        if (b.next.rate != 0) {
            /* Update balance object before editing. If the current stream has
            ended, the struct needs to be updated so that the next stream is
            swapped into the current stream location. */
            _updateBalance(_worker, _token);
        }

        if (_start < b.current.start) {
            b.current = newStream;
            if (_end > b.next.start) {
                b.next.start = _end;
            }
            return ();
        }

        // can not have 2 streams exist at the same time.
        if (b.current.end >= _start) {
            b.current.end = _start; //current stream ends when new stream starts
        }

        b.next = newStream;

        _updateBalance(_worker, _token);

        emit StreamEdited(_worker, _token, _start, _end, _rate);
    }

    /// @notice terminates the active payroll stream at specified time
    /// @param _worker The address of the worker receiving the stream
    /// @param _token The address of the token being streamed
    /// @param _end When the stream ends (in seconds past the epoch)
    function endStream(
        address _worker,
        address _token,
        uint256 _end
    )
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        require(_end > block.timestamp, "End time in past");

        Balance storage b = tokenBalance[_worker][_token];
        require(b.current.start != 0, "No stream exists");

        // if current stream is ongoing, set its end time
        // if current stream has ended, set end time of next stream if it exists
        if (b.current.end > block.timestamp) {
            require(_end <= b.current.end, "new end > existing end");
            require(_end > b.current.start, "end < start time");
            b.current.end = _end;
        } else if (b.current.end < block.timestamp) {
            require(b.next.start != 0, "No stream exists");
            require(_end <= b.next.end, "new end > existing end");
            require(_end > b.next.start, "end < start");

            b.next.end = _end;
        }

        emit StreamEnded(_worker, _token, _end);
    }

    /*  @notice This function deletes a stream. It returns any unclaimed value
        to the streaming treasury */
    /// @param _worker The worker whos stream is being deleted
    /// @param _token  The token balance in which the stream is being deleted
    function deleteStream(address _worker, address _token)
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
        onlyExistingWorker(_worker)
    {
        Treasury storage t = tokenTreasury[_token];
        Balance storage b = tokenBalance[_worker][_token];
        require(b.current.start != 0 || b.next.start != 0, "No stream exists");

        // if current stream hasn't ended, delete current stream
        if (block.timestamp < b.current.end) {
            t.settledStreamingBalance -= b.current.withdrawn;
            b.current = b.next;
            delete (b.next);
            // if current stream has ended, delete next stream
        } else if (b.current.end < block.timestamp) {
            t.settledStreamingBalance -= b.next.withdrawn + b.current.withdrawn;
            delete (b.current);
            delete (b.next);
        }

        emit StreamDeleted(_worker, _token);
    }

    /** @notice Updates the Balance struct. If the stream in the balance.current
        position has expired, the stream in balance.new will move to the
        balance.current position. This ensures that, as streams are edited,
        no stream currently streaming is overridden */
    /// @param _worker The address of the worker associated with the stream
    /// @param _token The address of the token in the stream
    function _updateBalance(address _worker, address _token) internal {
        Balance storage b = tokenBalance[_worker][_token];
        Treasury storage t = tokenTreasury[_token];
        // Check current stream has expired and that it exists
        if (b.current.end <= block.timestamp && b.current.end != 0) {
            // sweep funds from expired stream to the users settled balance
            b.settled += _getCurrentStreamBalance(_worker, _token);
            // subtract settled stream amount from the settled streaming balance
            t.settledStreamingBalance -=
                (b.current.end - b.current.start) *
                b.current.rate;

            b.current = b.next;
            // delete new stream so slot is empty
            delete (b.next);
        }
    }

    /** @notice Allows workers to claim their funds. Funds are pulled from the
        settled funds before pulling from stream balances */
    /// @param _amount The amount to be claimed by the worker
    /// @param _token The token being claimed by the worker
    function claimPayroll(uint256 _amount, address _token)
        external
        whenNotPaused
        onlyWorker
    {
        require(_amount > 0, "amount==0");

        // ensure that balance object is current before a user claims
        _updateBalance(_msgSender(), _token);

        Balance storage b = tokenBalance[_msgSender()][_token];
        uint256 totalBalance = b.settled +
            getStreamBalance(_msgSender(), _token);

        require(_amount <= totalBalance, "Insufficient balance");

        if (_amount <= b.settled) {
            b.settled -= _amount;

            emit PayrollClaimed(_msgSender(), _amount, _token);
            IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
        } else {
            uint256 amountDue = _amount;
            amountDue -= b.settled;
            b.settled = 0;
            // account for funds withdrawn from stream
            /* because Balance object is updated at start of function, the
            balance.current object will always be the active stream */
            b.current.withdrawn += amountDue;

            emit PayrollClaimed(_msgSender(), _amount, _token);
            IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
        }
    }

    /* ============== Treasury Management =========== */

    /// @notice Deposit funds to the non-streaming treasury (static treasury)
    /// @param _amount The amount of funds to be deposited
    /// @param _token The token to be deposited
    function depositStaticFunds(uint256 _amount, address _token)
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
    {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 allowance = token.allowance(_msgSender(), address(this));

        require(_amount > 0, "amount==0");
        require(allowance >= _amount, "Insufficient allowance approved");

        Treasury storage t = tokenTreasury[_token];
        t.staticBalance += _amount;

        emit StaticDeposit(_amount, _token);
        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /// @notice Deposit funds to the streaming treasury
    /// @param _amount The amount of funds to be deposited
    /// @param _token The token to be deposited
    function depositStreamingFunds(uint256 _amount, address _token)
        external
        whenNotPaused
        onlyAdminOrOwner
        onlyApprovedTokens(_token)
    {
        IERC20Upgradeable token = IERC20Upgradeable(_token);
        uint256 allowance = token.allowance(_msgSender(), address(this));

        require(_amount > 0, "amount==0");
        require(allowance >= _amount, "Insufficient allowance");

        Treasury storage treasury = tokenTreasury[_token];
        treasury.settledStreamingBalance += _amount;

        emit StreamingDeposit(_amount, _token);
        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    /// @notice Withdraw funds from the static treasury
    /// @param _token The token to withdraw
    /// @param _amount The amount being withdrawn from the treasury
    function withdrawStaticFunds(address _token, uint256 _amount)
        external
        whenNotPaused
        onlyAdminOrOwner
    {
        require(_amount != 0, "amount==0");

        uint256 staticBalance = getStaticTreasury(_token);

        require(_amount <= staticBalance, "Insufficient funds");

        Treasury storage treasury = tokenTreasury[_token];
        treasury.staticBalance -= _amount;

        emit StaticWithdrawal(_amount, _token);
        IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
    }

    /// @notice This function withdraws funds from the Streaming Treasury only
    /// @param _token The token treasury from which funds are being withdrawn
    /// @param _amount The amount to be withdrawn from the treasury
    function withdrawStreamingFunds(address _token, uint256 _amount)
        external
        whenNotPaused
        onlyAdminOrOwner
    {
        require(_amount != 0, "amount==0");
        uint256 streamingBalance = getStreamingTreasury(_token);

        require(_amount <= streamingBalance, "Insufficient funds");

        Treasury storage treasury = tokenTreasury[_token];
        treasury.settledStreamingBalance -= _amount;

        emit StreamingWithdrawal(_amount, _token);
        IERC20Upgradeable(_token).safeTransfer(_msgSender(), _amount);
    }

    /*** Contract Operations ***/

    // @notice Pause the smart contract
    function pause() external onlyOwner {
        _pause();
    }

    // @notice UnPause the contract. Ensure contract is in a secure state
    function unpause() external onlyOwner {
        _unpause();
    }

    /** MsgSender() inheritance resolution **/
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}
