// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/** OpenZeppelin Dependencies (Via NodeModules) */
// import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
/** Local Interfaces */
import "./IToken.sol";
import "./IAuction.sol";
import "./IStaking.sol";
import "./IBPD.sol";
import "./IForeignSwap.sol";

contract ForeignSwap is IForeignSwap, Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    /** Events */
    event TokensClaimed(
        address indexed account,
        uint256 indexed stepsFromStart,
        uint256 userAmount,
        uint256 penaltyuAmount
    );

    /** Role Constants */
    bytes32 public constant MIGRATOR_ROLE = keccak256("MIGRATOR_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    /** Public */
    uint256 public start;
    uint256 public stepTimestamp;
    uint256 public stakePeriod;
    uint256 public maxClaimAmount;
    
    /** Public Addresses */
    address public mainToken;
    address public staking;
    address public auction;
    address public bigPayDayPool;
    address public signerAddress;

    /** Internals */
    uint256 internal claimedAmount;
    uint256 internal totalSnapshotAmount;
    uint256 internal claimedAddresses;
    uint256 internal totalSnapshotAddresses;

    /** Mappings */
    mapping(address => uint256) public claimedBalanceOf;

    /** Booleans */
    bool public init_;

    /** Variables after initial contract launch must go below here. https://github.com/OpenZeppelin/openzeppelin-sdk/issues/37 */
    /** End Variables after launch */

    /** Roles */
    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Caller is not a manager");
        _;
    }
    modifier onlyMigrator() {
        require(hasRole(MIGRATOR_ROLE, _msgSender()), "Caller is not a migrator");
        _;
    }

    /** Init fns*/
    function initialize(
        address _manager,
        address _migrator
    ) public initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(MIGRATOR_ROLE, _migrator);
        init_ = false;
    }

    function init(
        address _signer,
        uint256 _stepTimestamp,
        uint256 _stakePeriod,
        uint256 _maxClaimAmount,
        address _mainToken,
        address _auction,
        address _staking,
        address _bigPayDayPool,
        uint256 _totalSnapshotAmount,
        uint256 _totalSnapshotAddresses
    ) external onlyMigrator {
        require(!init_, "Init is active");
        init_ = true;
        /** Setup */
        if (start == 0) {
            start = now;
        }
        signerAddress = _signer;
        stepTimestamp = _stepTimestamp;
        stakePeriod = _stakePeriod;
        maxClaimAmount = _maxClaimAmount;
        mainToken = _mainToken;
        staking = _staking;
        auction = _auction;
        bigPayDayPool = _bigPayDayPool;
        totalSnapshotAmount = _totalSnapshotAmount;
        totalSnapshotAddresses = _totalSnapshotAddresses;
    }
    /** End Init Fns */

    function getCurrentClaimedAmount()
        external
        override
        view
        returns (uint256)
    {
        return claimedAmount;
    }

    function getTotalSnapshotAmount() external override view returns (uint256) {
        return totalSnapshotAmount;
    }

    function getCurrentClaimedAddresses()
        external
        override
        view
        returns (uint256)
    {
        return claimedAddresses;
    }

    function getTotalSnapshotAddresses()
        external
        override
        view
        returns (uint256)
    {
        return totalSnapshotAddresses;
    }

    function getMessageHash(uint256 amount, address account)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(amount, account));
    }

    function check(uint256 amount, bytes memory signature)
        public
        view
        returns (bool)
    {
        bytes32 messageHash = getMessageHash(amount, address(msg.sender));
        return ECDSAUpgradeable.recover(messageHash, signature) == signerAddress;
    }

    function getUserClaimableAmountFor(uint256 amount)
        public
        view
        returns (uint256, uint256)
    {
        if (amount > 0) {
            (
                uint256 amountOut,
                uint256 delta,
                uint256 deltaAuctionWeekly
            ) = getClaimableAmount(amount);
            uint256 deltaPenalized = delta.add(deltaAuctionWeekly);
            return (amountOut, deltaPenalized);
        } else {
            return (0, 0);
        }
    }

    function claimFromForeign(uint256 amount, bytes memory signature)
        public
        returns (bool)
    {
        require(amount > 0, "CLAIM: amount <= 0");
        require(
            check(amount, signature),
            "CLAIM: cannot claim because signature is not correct"
        );
        require(claimedBalanceOf[msg.sender] == 0, "CLAIM: cannot claim twice");

        (
            uint256 amountOut,
            uint256 delta,
            uint256 deltaAuctionWeekly
        ) = getClaimableAmount(amount);

        uint256 deltaPart = delta.div(stakePeriod);
        uint256 deltaAuctionDaily = deltaPart.mul(stakePeriod.sub(uint256(1)));

        IToken(mainToken).mint(auction, deltaAuctionDaily);
        IAuction(auction).callIncomeDailyTokensTrigger(deltaAuctionDaily);

        if (deltaAuctionWeekly > 0) {
            IToken(mainToken).mint(auction, deltaAuctionWeekly);
            IAuction(auction).callIncomeWeeklyTokensTrigger(deltaAuctionWeekly);
        }

        IToken(mainToken).mint(bigPayDayPool, deltaPart);
        IBPD(bigPayDayPool).callIncomeTokensTrigger(deltaPart);
        IStaking(staking).externalStake(amountOut, stakePeriod, msg.sender);

        claimedBalanceOf[msg.sender] = amount;
        claimedAmount = claimedAmount.add(amount);
        claimedAddresses = claimedAddresses.add(uint256(1));

        emit TokensClaimed(msg.sender, calculateStepsFromStart(), amountOut, deltaPart);

        return true;
    }

    function calculateStepsFromStart() public view returns (uint256) {
        return (now.sub(start)).div(stepTimestamp);
    }

    // function calculateStakeEndTime(uint256 startTime) internal view returns (uint256) {
    //     uint256 stakePeriod = stepTimestamp.mul(stakePeriod);
    //     return  startTime.add(stakePeriod);
    // }

    function getClaimableAmount(uint256 amount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 deltaAuctionWeekly = 0;
        if (amount > maxClaimAmount) {
            deltaAuctionWeekly = amount.sub(maxClaimAmount);
            amount = maxClaimAmount;
        }

        uint256 stepsFromStart = calculateStepsFromStart();
        uint256 daysPassed = stepsFromStart > stakePeriod ? stakePeriod : stepsFromStart;
        uint256 delta = amount.mul(daysPassed).div(stakePeriod);
        uint256 amountOut = amount.sub(delta);

        return (amountOut, delta, deltaAuctionWeekly);
    }

    /* Setter methods for contract migration */
    function setStateVariables(uint256 _claimedAmount, uint256 _claimedAddresses, uint256 _start) external onlyMigrator {
        claimedAmount = _claimedAmount;
        claimedAddresses = _claimedAddresses;
        start = _start;
    }

    function setClaimedBalanceOf(address[] calldata userAddresses, uint256[] calldata amounts) external onlyMigrator {
        for (uint256 idx = 0; idx < userAddresses.length; idx = idx.add(1)) {
            claimedBalanceOf[userAddresses[idx]] = amounts[idx];
        }
    }
}
