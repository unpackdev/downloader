// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Strings.sol";
import "./ECDSA.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./EnumerableSet.sol";
import "./Math.sol";
import "./IDelegationRegistry.sol";
import "./IDelegateRegistry.sol";
import "./IMemecoinFiresale.sol";

/// @title A contract for reserving $MEME by ETH during the Firesale period set by the owner, and refunding users for any over-allocated reservations.
contract MemecoinFiresaleV1 is
    IMemecoinFiresale,
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private constant _MAX_REFUND_PERIOD = 69 days;

    // Address that signs messages used for reserve/refund
    address public signer;
    address public upgrader;

    uint256 public unitPrice;

    uint32 public firesaleTotal;
    IDelegationRegistry public dc;
    IDelegateRegistry public dcV2;
    FiresaleState public firesaleState;

    EnumerableSet.AddressSet internal _firesaleUsers;
    mapping(address user => uint256 userTotalReserved) public usersTotalReserved;
    mapping(address user => bool refunded) public usersRefunded;

    uint256 public totalWithdrawnSales;
    uint256 public refundStartDate;

    // required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyUpgrader {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _signer, uint256 _unitPrice) public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        signer = _signer;
        unitPrice = _unitPrice;
        dc = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);
        dcV2 = IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493);
    }

    /// @notice Reserve for Firesale allocation by committing ETH
    /// @dev Record user to reservation list if fund is sufficient and sig is valid, emit { UserReserved } event
    /// @param _vault Address to reserve for, could be a delegated wallet
    /// @param _amount Number of single unit to reserve
    /// @param _max Max number of single unit assigned, to be verified via provided signature
    /// @param _signature Signature generated from the backend
    function reserve(address _vault, uint32 _amount, uint32 _max, bytes calldata _signature)
        external
        payable
        nonReentrant
        onlyFiresaleOpening
    {
        if (_amount == 0 || _max == 0) revert ZeroInput();

        address requester = _getRequester(_vault);
        uint256 userTotalReserved = usersTotalReserved[requester] + _amount;
        if (userTotalReserved > _max) revert UserTotalReservedExceedMax();

        string memory action = string.concat("meme-firesale-", Strings.toString(_max));
        if (!_checkValidity(requester, _signature, action)) revert InvalidSignature();

        uint256 totalCost = _amount * unitPrice;
        if (msg.value != totalCost) revert UnequalFunds();

        usersTotalReserved[requester] = userTotalReserved;
        firesaleTotal += _amount;

        _firesaleUsers.add(requester);

        emit UserReserved(requester, _amount, userTotalReserved, _max);
    }

    /// @notice Refund excessed ETH back to users who reach their max allocation after the Firesale ends, user won't be able to refund after _MAX_REFUND_PERIOD has passed since refund starts
    /// @dev Calculate refunding amount and refund ETH if sig is valid, emit { UserRefunded } event
    /// @param _vault Address to refund to, could be a delegated wallet
    /// @param _allocatedAmount Number of single unit allocated, to be verified via provided signature
    /// @param _signature Signature generated from the backend
    function refund(address _vault, uint32 _allocatedAmount, bytes calldata _signature)
        external
        nonReentrant
        onlyFiresaleFinished
    {
        address requester = _getRequester(_vault);
        uint256 userTotalReserved = usersTotalReserved[requester];
        if (userTotalReserved == 0) revert NoFiresaleRecord();
        // skip the sig validation & refundAvailable calculation if input is already >= userTotalReserved
        if (_allocatedAmount >= userTotalReserved) revert NoRefundAvailable();
        if (usersRefunded[requester]) revert AlreadyRefunded();
        // refund will expire after _MAX_REFUND_PERIOD has passed since refund starts
        if (block.timestamp > refundStartDate + _MAX_REFUND_PERIOD) revert RefundExpired();

        string memory action = string.concat("meme-firesale-refund-won_amount-", Strings.toString(_allocatedAmount));
        if (!_checkValidity(requester, _signature, action)) revert InvalidSignature();

        usersRefunded[requester] = true;
        uint256 refundAvailable = (userTotalReserved - _allocatedAmount) * unitPrice;
        _withdraw(requester, refundAvailable);

        emit UserRefunded(requester, _allocatedAmount);
    }

    /// @notice Support both v1 and v2 delegate wallet during the v1 to v2 migration
    /// @dev Given _vault (cold wallet) address, verify whether _msgSender() is a permitted delegate to operate on behalf of it,
    /// we deliberately verify v1 before v2 first since Firesale is a relatively short-lived contract compared to Claim contract
    /// @param _vault Address to verify against _msgSender
    function _getRequester(address _vault) private view returns (address) {
        if (_vault == address(0)) return _msgSender();
        bool isDelegateValid = dc.checkDelegateForAll(_msgSender(), _vault);
        if (isDelegateValid) return _vault;
        isDelegateValid = dcV2.checkDelegateForAll(_msgSender(), _vault, "");
        if (!isDelegateValid) revert InvalidDelegate();
        return _vault;
    }

    function _checkValidity(address _requester, bytes calldata _signature, string memory _action)
        private
        view
        returns (bool)
    {
        bytes32 hashVal = keccak256(abi.encodePacked(_requester, _action));
        bytes32 signedHash = hashVal.toEthSignedMessageHash();

        return signedHash.recover(_signature) == signer;
    }

    /// @dev _address won't be zero as it will either be called by owner or return NoFiresaleRecord()
    function _withdraw(address _address, uint256 _amount) private {
        (bool sent,) = _address.call{value: _amount}("");
        if (!sent) revert WithdrawFailed();
    }

    // ===============
    // Owner Functions
    // ===============

    /// @notice Set the new Firesale state
    /// @param _state New Firesale state
    function setFiresaleState(FiresaleState _state) external onlyOwner {
        firesaleState = _state;

        emit FiresaleStatedUpdated(_state);
    }

    /// @notice Set the future refundStartDate to start the refund and expiry countdown
    /// @param _refundStartDate New date to start the refund
    function setRefundStartDate(uint256 _refundStartDate) external onlyOwner {
        if (_refundStartDate < block.timestamp || _refundStartDate <= refundStartDate) revert InvalidRefundSetup();

        refundStartDate = _refundStartDate;

        emit RefundStartDateUpdated(_refundStartDate);
    }

    /// @notice Set the new reserve/refund signer, allow setting address(0) to disable reserve/refund
    /// @param _signer New reserve/refund signer
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;

        emit SignerUpdated(_signer);
    }

    /// @dev Set the new UUPS proxy upgrader, allow setting address(0) to disable upgradeability
    /// @param _upgrader New upgrader
    function setUpgrader(address _upgrader) external onlyOwner {
        upgrader = _upgrader;

        emit UpgraderUpdated(_upgrader);
    }

    /// @notice Withdraw exact amount of ETH of final sales from contract
    /// @param _totalFiresaleItems Total amount of items to withdraw
    function withdrawSales(uint256 _totalFiresaleItems) public onlyOwner onlyFiresaleFinished {
        if (_totalFiresaleItems > firesaleTotal) revert WithdrawExceedTotalSales();

        uint256 sales = _totalFiresaleItems * unitPrice;
        uint256 available = sales - totalWithdrawnSales;
        if (available == 0) revert NoNewSales();

        totalWithdrawnSales += available;
        _withdraw(_msgSender(), available);
    }

    /// @notice Withdraw unclaimed refund that are expired after _MAX_REFUND_PERIOD has passed since refund starts
    /// @param _receiver Address to receive the ETH
    /// @param _amount Total amount to withdraw
    function withdrawRefund(address _receiver, uint256 _amount) public onlyOwner onlyFiresaleFinished {
        if (block.timestamp <= refundStartDate + _MAX_REFUND_PERIOD) revert RefundNotExpired();
        if (_receiver == address(0) || _amount == 0) revert ZeroInput();

        _withdraw(_receiver, _amount);
    }

    // ====================
    // Validation Modifiers
    // ====================
    modifier onlyFiresaleOpening() {
        if (firesaleState != FiresaleState.OPENING) revert FiresaleNotOpening();
        _;
    }

    modifier onlyFiresaleFinished() {
        if (firesaleState != FiresaleState.FINISHED) revert FiresaleNotFinished();
        _;
    }

    modifier onlyUpgrader() {
        if (_msgSender() != upgrader) revert Unauthorized();
        _;
    }

    // =======
    // Getters
    // =======

    /// @notice Get the number of users who participated in the Firesale
    /// @return Length of _firesaleUsers
    function getFiresaleUsersCount() external view returns (uint256) {
        return _firesaleUsers.length();
    }

    /// @notice Get the addresses of users who participated in the Firesale within a specific range
    /// @param _fromIdx Start index of the desired range
    /// @param _toIdx End index of the desired range
    /// @return partOfFiresaleUsers Array of addresses of the Firesale
    function getFiresaleUsers(uint256 _fromIdx, uint256 _toIdx)
        external
        view
        returns (address[] memory partOfFiresaleUsers)
    {
        _toIdx = Math.min(_toIdx, _firesaleUsers.length());
        uint256 range = _toIdx - _fromIdx;
        partOfFiresaleUsers = new address[](range);
        for (uint256 i = 0; i < range; i++) {
            partOfFiresaleUsers[i] = _firesaleUsers.at(i + _fromIdx);
        }
    }
}
