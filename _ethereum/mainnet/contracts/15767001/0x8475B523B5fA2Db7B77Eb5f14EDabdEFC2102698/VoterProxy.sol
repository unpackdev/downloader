// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IDeposit.sol";
import "./IFeeDistro.sol";
import "./IVeAllocate.sol";
import "./IVeOcean.sol";
import "./IVeFeeDistributor.sol";
import "./IDFRewards.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";

/**
 * @title VoterProxy
 * @author Convex / H2O
 *
 * Contract that is holding all gathered veOcean, being responsible for all interaction with veOcean and related to veOcean,
 * like voting, claiming rewards or claiming fees. The only contract, that should not be upgradeable in whole protocol.
 */
contract OceanVoterProxy {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public immutable ocean; // address of Ocean token contract
    address public immutable escrow; // address of Ocean veOcean contract
    address public immutable allocate; // address of Ocean veAllocate contract
    address public immutable rewards; // address of Ocean DFRewards contract

    // Permissions
    address public owner;
    address public operator; // Contract, that is responsible for handling fees/rewards - ie. Booster
    address public depositor; // Contract, that is entry/exit for Ocean flowing into the system - ie. OceanDepositor

    /* ============ Modifiers ============ */

    modifier onlyOwner() {
        require(msg.sender == owner, "auth!");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "auth!");
        _;
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, "auth!");
        _;
    }

    /* ============ Constructor ============ */

    /**
     * Sets various contract addresses
     *
     * @param _ocean                 Address of Ocean token contract
     * @param _escrow                Address of Ocean veOcean contract
     * @param _allocate              Address of Ocean veAllocate contra
     * @param _rewards               Address of Ocean DFRewards contract
     */
    constructor(
        address _ocean,
        address _escrow,
        address _allocate,
        address _rewards
    ) {
        owner = msg.sender;
        ocean = _ocean;
        escrow = _escrow;
        allocate = _allocate;
        rewards = _rewards;
    }

    /* ============ External Functions ============ */

    /* ====== Getters ====== */
    function getName() external pure returns (string memory) {
        return "OceanVoterProxy";
    }

    /* ====== Setters ====== */

    /**
     * Sets new owner of the contract
     *
     * @param _owner                 Address of the new owner
     */
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    /**
     * Sets new operator of the contract
     *
     * @param _operator                 Address of the new operator
     */
    function setOperator(address _operator) external onlyOwner {
        require(
            operator == address(0) || IDeposit(operator).isShutdown() == true,
            "needs shutdown"
        );

        //require isShutdown interface
        require(
            IDeposit(_operator).isShutdown() == false,
            "New operator not in shutdown"
        );

        operator = _operator;
    }

    /**
     * Sets new depositor of the contract
     *
     * @param _depositor                 Address of the new depositor
     */
    function setDepositor(address _depositor) external onlyOwner {
        depositor = _depositor;
    }

    /* ====== Actions ====== */

    /**
     * Creates initial lock on veOcean
     *
     * @param _value                Amount of Ocean to lock in veOcean
     * @param _unlockTime           Time of unlocking veOcean
     *
     * @return True if call was successfull
     */
    function createLock(uint256 _value, uint256 _unlockTime)
        external
        onlyDepositor
        returns (bool)
    {
        IERC20(ocean).safeApprove(escrow, 0);
        IERC20(ocean).safeApprove(escrow, _value);

        IVeOcean(escrow).create_lock(_value, _unlockTime);
        return true;
    }

    /**
     * Increases amount of Ocean locked in veOcean
     *
     * @param _value                Amount of new Ocean to lock in veOcean
     *
     * @return True if call was successfull
     */
    function increaseAmount(uint256 _value)
        external
        onlyDepositor
        returns (bool)
    {
        IERC20(ocean).safeApprove(escrow, 0);
        IERC20(ocean).safeApprove(escrow, _value);
        IVeOcean(escrow).increase_amount(_value);
        return true;
    }

    /**
     * Increases time lock of locked Ocean in veOcean contract
     *
     * @param _value                A new time, untill which Ocean is locked in veOcean
     *
     * @return True if call was successfull
     */
    function increaseTime(uint256 _value)
        external
        onlyDepositor
        returns (bool)
    {
        IVeOcean(escrow).increase_unlock_time(_value);
        return true;
    }

    /**
     * Withdraws all Ocean from veOcean in the event of lock getting expired on veOcean side
     *
     * @return True if call was successfull
     */
    function release() external onlyDepositor returns (bool) {
        IVeOcean(escrow).withdraw();
        return true;
    }

    /**
     * Votes on selected Data NFTs on veAllocate contract, called every 1 week after snapshot vote
     * Needs to remove old allocations, if they are not included in the new vote.
     * Length of each array needs to be the same, as particular index in arrays corresponds to single allocation.
     *
     * @param amount                Array of shares, that we want to allocate to given Data Nft
     * @param nft                   Array of addresses of selected Data Nfts
     * @param chainId               Array of chain ids of selected Data Nfts
     *
     * @return True if call was successfull
     */
    function voteAllocations(
        uint256[] calldata amount,
        address[] calldata nft,
        uint256[] calldata chainId
    ) external onlyOperator returns (bool) {
        //vote
        IVeAllocate(allocate).setBatchAllocation(amount, nft, chainId);
        return true;
    }

    /**
     * Collects rewards from DFRewards contract and transfers to the requested contract - usually
     * Booster contract, which is responsible for distributing rewards to relevant RewardPools
     *
     * @param _token               Address of reward token, that was distributed
     * @param _claimTo             Address of receipient of rewards tokens, that will distribute it further to relevant RewardPools
     *
     * @return True if call was successfull
     */
    function claimRewards(address _token, address _claimTo)
        external
        onlyOperator
        returns (bool)
    {
        IDFRewards(rewards).claimFor(address(this), _token);
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_claimTo, _balance);
        return true;
    }

    /**
     * Collects rewards from veFeeDistributor contract and transfers to the requested contract - usually
     * Booster contract, which is responsible for distributing fees to relevant RewardPools
     *
     * @param _distroContract      Address of veFeeDistributor
     * @param _token               Address of fee token, that was distributed
     * @param _claimTo             Address of receipient of fee tokens, that will distribute it further to relevant RewardPools
     *
     * @return balance of token, that were claimed during this action
     */
    function claimFees(
        address _distroContract,
        address _token,
        address _claimTo
    ) external onlyOperator returns (uint256) {
        IFeeDistro(_distroContract).claim();
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(_claimTo, _balance);
        return _balance;
    }

    /**
     * Function to execute any arbitrary external contract call
     *
     * @param _to                  Address of contract to call
     * @param _value               Amount of ether to send
     * @param _data                Data to send to selected contract
     *
     * @return status and result of given contract call
     */
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOperator returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);

        return (success, result);
    }
}
