//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";

error NotYourStream();
error NotEnoughBalance();
error NotEnoughPledged();
error SendMore();
error IncreaseByMore();
error IncreasedByTooMuch();
error CantWithdrawToBurnAddress();
error CantDepositFromBurnAddress();
error StreamDisabled();
error StreamDoesNotExist();
error TransferFailed();
error DepositAmountTooSmall();
error DepositFailed();
error InvalidFrequency();
error InsufficientPrivileges();
error StreamAlreadyExists();

/// @title Organization Streams Contract
/// @author ghostffcode, jaxcoder, nowonder, qedk, supriyaamisshra
/// @notice the meat and potatoes of the stream
contract MultiStream is Ownable, AccessControl, ReentrancyGuard {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /// @dev Describe a stream 
    struct Stream {
        /// @dev stream cap
        uint256 cap;
        /// @dev stream frequency
        uint256 frequency;
        /// @dev last withdraw
        uint256 last;
        /// @dev tokens pledged to this stream
        uint256 pledged;
        ///@dev stream name 
        string name;
    }

    /// @dev Describe a stream for view purposes
    struct StreamView {
        /// @dev owner address
        address owner;
        /// @dev stream cap
        uint256 cap;
        /// @dev stream frequency
        uint256 frequency;
        /// @dev last withdraw
        uint256 last;
        /// @dev stream balance
        uint256 balance;
        /// @dev pledged/eligible balance
        uint256 pledged;
        ///@dev stream name 
        string name;
    }

    /// @dev organization info
    struct OrgInfo {
        /// @dev org name
        string name;
        /// @dev logo URI
        string logoURI;
        /// @dev description
        string description;
        /// @dev track total stream count
        uint256 totalStreams;
        /// @dev track total payouts for UI
        uint256 totalPaid;
        /// @dev token
        IERC20 dToken;
    }

    OrgInfo public orgInfo;
    uint256 streamCount;
    mapping(address => uint256) inverseOwnerIndex;
    mapping(uint256 => address) ownerIndex;
    mapping(address => Stream) streams;
    mapping(address => bool) disabled;

    event Withdraw(address indexed to, uint256 amount, string reason);
    event Deposit(address indexed stream, address indexed from, uint256 amount, string reason);
    /// @dev StreamAdded event to track the streams after creation
    event StreamAdded(address creator, address user, string name);

    modifier hasCorrectRole() {
        if (!hasRole(MANAGER_ROLE, _msgSender())) {
            if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
                revert InsufficientPrivileges();
            }
        }
        _;
    }

    constructor(
        string memory _orgName,
        string memory _orgLogoURI,
        string memory _orgDescription,
        address _owner,
        address[] memory _addresses,
        uint256[] memory _caps,
        uint256[] memory _frequency,
        bool[] memory _startsFull,
        string[] memory _name,
        address _tokenAddress
    ) {
        /* 
        @ note Init Org Details
        */
        orgInfo = OrgInfo(
            _orgName,
            _orgLogoURI,
            _orgDescription,
            _addresses.length,
            0,
            IERC20(_tokenAddress)
        );

        /* 
        @ note Init Streams
        */
        for (uint256 i = 0; i < _addresses.length; ++i) {
            ownerIndex[streamCount] = _addresses[i];
            inverseOwnerIndex[_addresses[i]] = streamCount;
            streamCount += 1;
            uint256 last;
            if (_startsFull[i] == true) {
                last = block.timestamp - _frequency[i];
            } else {
                last = block.timestamp;
            }
            Stream memory stream = Stream(_caps[i], _frequency[i], last, 0, _name[i]);
            streams[_addresses[i]] = stream;
            emit StreamAdded(_msgSender(), _addresses[i], _name[i]);
        }

        /* 
        @ note Init Roles
        */
        transferOwnership(_owner);
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function addManager(address _manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, _manager);
    }

    function removeManager(address _manager)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(MANAGER_ROLE, _manager);
    }

    /// @dev add a stream for user
    function addStream(
        address _beneficiary,
        uint256 _cap,
        uint256 _frequency,
        bool _startsFull,
        string calldata _name
    ) external hasCorrectRole {
        if (streams[_beneficiary].last > 0) {
            revert StreamAlreadyExists();
        }
        ownerIndex[streamCount] = _beneficiary;
        inverseOwnerIndex[_beneficiary] = streamCount;
        streamCount += 1;
        uint256 last;
        if (_startsFull == true) {
            last = block.timestamp - _frequency;
        } else {
            last = block.timestamp;
        }
        Stream memory stream = Stream(_cap, _frequency, last, 0, _name);
        streams[_beneficiary] = stream;
        orgInfo.totalStreams += 1;
        emit StreamAdded(_msgSender(), _beneficiary, _name);
    }

    /// @dev Transfers remaining balance and disables stream
    function disableStream(address _beneficiary) external hasCorrectRole {
        uint256 totalAmount = streamBalance(_beneficiary);

        uint256 cappedLast = block.timestamp - streams[_beneficiary].frequency;
        if (streams[_beneficiary].last < cappedLast) {
            streams[_beneficiary].last = cappedLast;
        }
        streams[_beneficiary].last =
            streams[_beneficiary].last +
            (((block.timestamp - streams[_beneficiary].last) * totalAmount) /
                totalAmount);

        if (!orgInfo.dToken.transfer(_beneficiary, totalAmount)) revert TransferFailed();

        disabled[_beneficiary] = true;
        streams[_beneficiary].cap = 0;
        orgInfo.totalStreams -= 1;
    }

    /// @dev Transfers remaining balance and deletes stream
    function deleteStream(address _beneficiary) external hasCorrectRole {
        uint256 totalAmount = streamBalance(_beneficiary);

        if(!orgInfo.dToken.transfer(msg.sender, totalAmount)) revert TransferFailed();

        streamCount -= 1;
        // Trigger gas refunds
        delete streams[_beneficiary];
        delete ownerIndex[inverseOwnerIndex[_beneficiary]];
        delete inverseOwnerIndex[_beneficiary];
        delete disabled[_beneficiary];
    }

    /// @dev Reactivates a stream for user
    function enableStream(
        address _beneficiary,
        uint256 _cap,
        uint256 _frequency,
        bool _startsFull
    ) external hasCorrectRole {

        streams[_beneficiary].cap = _cap;
        streams[_beneficiary].frequency = _frequency;

        if (_startsFull == true) {
            streams[_beneficiary].last = block.timestamp - _frequency;
        } else {
            streams[_beneficiary].last = block.timestamp;
        }

        disabled[_beneficiary] = false;
        orgInfo.totalStreams += 1;
    }

    /// @dev Get the balance of a stream by address
    /// @return balance of the stream by address
    function streamBalance(address _beneficiary) public view returns (uint256) {

        if (block.timestamp - streams[_beneficiary].last > streams[_beneficiary].frequency) {
            return streams[_beneficiary].cap;
        }
        return
            (streams[_beneficiary].cap * (block.timestamp - streams[_beneficiary].last)) /
            streams[_beneficiary].frequency;
    }

    /// @dev Withdraw from a stream
    /// @param payoutAddress account to withdraw into
    /// @param amount amount of withdraw
    /// @param reason a reason
    function streamWithdraw(address payoutAddress, uint256 amount, string calldata reason)
        external
    {
        if (payoutAddress == address(0)) revert CantWithdrawToBurnAddress();
        if (disabled[msg.sender] == true) revert StreamDisabled();

        uint256 totalAmountCanWithdraw = streamBalance(msg.sender);
        if (totalAmountCanWithdraw < amount) revert NotEnoughBalance();
        if (amount > streams[msg.sender].pledged) revert NotEnoughPledged();

        uint256 cappedLast = block.timestamp - streams[msg.sender].frequency;
        if (streams[msg.sender].last < cappedLast) {
            streams[msg.sender].last = cappedLast;
        }
        streams[msg.sender].last =
            streams[msg.sender].last +
            (((block.timestamp - streams[msg.sender].last) * amount) /
                totalAmountCanWithdraw);

        if (!orgInfo.dToken.transfer(payoutAddress, amount)) revert TransferFailed();

        orgInfo.totalPaid += amount;
        streams[msg.sender].pledged -= amount;
        emit Withdraw(payoutAddress, amount, reason);
    }

    /// @notice Deposits tokens into a specified stream
    /// @dev Deposit into stream
    /// @param _stream a user stream
    /// @param reason reason for deposit
    /// @param  value the amount of the deposit
    function streamDeposit(address _stream, string memory reason, uint256 value)
        external
        nonReentrant
    {
        if (_msgSender() == address(0)) revert CantDepositFromBurnAddress();
        if (disabled[_stream] == true) revert StreamDisabled();
        if (value < (streams[_stream].cap / 10)) revert DepositAmountTooSmall();
        if (!orgInfo.dToken.transferFrom(_msgSender(), address(this), value)) revert DepositFailed();
        streams[_stream].pledged += value;
        emit Deposit(_stream, _msgSender(), value, reason);
    }

    /// @dev Increase the cap of the stream
    /// @param _increase how much to increase the cap
    function increaseCap(uint256 _increase, address beneficiary)
        external
        hasCorrectRole
    {
        if (_increase == 0) revert IncreaseByMore();

        if ((streams[beneficiary].cap + _increase) >= 1 ether)
            revert IncreasedByTooMuch();
        streams[beneficiary].cap = streams[beneficiary].cap + _increase;
    }

    /// @dev Update the frequency of a stream
    /// @param _frequency the new frequency
    function updateFrequency(uint256 _frequency, address beneficiary)
        external
        hasCorrectRole
    {
        if(_frequency < 0) revert InvalidFrequency();
        if (_frequency == 0) revert IncreaseByMore();
        streams[beneficiary].frequency = _frequency;
    }

    /// @dev checks whether org has an active stream for user
    /// @param _userAddress a users address
    function hasStream(address _userAddress)
        public
        view
        returns (bool)
    {
        return streams[_userAddress].frequency != 0 && disabled[_userAddress] != true;
    }

    /// @dev gets stream details
    /// @param _userAddress a users address
    function getStreamView(address _userAddress)
        public
        view
        returns (StreamView memory)
    {
        return StreamView(_userAddress, streams[_userAddress].cap,
                    streams[_userAddress].frequency, streams[_userAddress].last,
                    streamBalance(_userAddress), streams[_userAddress].pledged, streams[_userAddress].name);
    }

    /// @dev gets a page of streams
    /// @param _page a page number
    /// @param _resultsPerPage number of results per page
    function getStreams(
        uint256 _page,
        uint256 _resultsPerPage
    )
        public
        view
        returns (StreamView[] memory)
    {
        uint256 _ownerIndex = _resultsPerPage * _page - _resultsPerPage;

        if (
            streamCount == 0 ||
            _ownerIndex > streamCount - 1
        ) {
            return new StreamView[](0);
        }

        StreamView[] memory _streams = new StreamView[](_resultsPerPage);
        uint256 _returnCounter = 0;
        uint256 _skipped = 0;
        address currentOwner = address(0);
        
        for (
            _ownerIndex;
            _ownerIndex < ((_resultsPerPage * _page) + _skipped);
            _ownerIndex++
        ) {
            if (_ownerIndex <= streamCount - 1) {
                currentOwner = ownerIndex[_ownerIndex];
                if (disabled[currentOwner]) {
                    _skipped++;
                    continue;
                }
                _streams[_returnCounter] = StreamView(currentOwner, streams[currentOwner].cap,
                    streams[currentOwner].frequency, streams[currentOwner].last,
                    streamBalance(currentOwner), streams[currentOwner].pledged, streams[currentOwner].name);
            } else {
                _streams[_returnCounter] = StreamView(address(0), 0,0,0,0,0, "");
            }
            _returnCounter++;
        }
        return _streams;
    }
}
