// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./IStaking.sol";
import "./IERC20.sol";

/**
 * An implementation of the {IStaking} interface.
 *
 * It allows users to stake their tokens for `x` days predetermined
 * during the time of stake and earn interest over time.
 *
 * The ROI can be changed but it's not influential on previous stakers
 * to maintain the integrity of the application.
 */

contract EdgeStakingV1 is ReentrancyGuard, Context, IStaking {
    mapping(address => uint256) public totalStakingContracts;
    mapping(address => mapping(uint256 => Stake)) public stakeContract;

    uint256 public currentROI;

    address public edgexContract;
    address public admin;

    /**
     * @dev represents the staking instance.
     *
     * Every user's stake is mapped to a staking instance
     * represented by `stakeId`
     */
    struct Stake {
        uint256 amount;
        uint256 maturesAt;
        uint256 createdAt;
        uint256 roiAtStake;
        bool isClaimed;
        uint256 interest;
    }

    /**
     * @dev Emitted when the `caller` the old admin
     * transfers the governance of the staking contract to a
     * `newOwner`
     */
    event RevokeOwnership(address indexed newOwner);

    /**
     * @dev Emitted when the `admin` who is the governor
     * of the contract changes the ROI for staking
     *
     * Effective for new stakers.
     */
    event ChangeROI(uint256 newROI);

    /**
     * @dev sanity checks the caller.
     * If the caller is not admin, the transaction is reverted.
     *
     * keeps the security of the platform and prevents bad actors
     * from executing sensitive functions / state changes.
     */
    modifier onlyAdmin() {
        require(_msgSender() == admin, "Error: caller not admin");
        _;
    }

    /**
     * @dev checks whether the address is a valid one.
     *
     * If it's a zero address returns an error.
     */
    modifier isZero(address _address) {
        require(_address != address(0), "Error: zero address");
        _;
    }

    /**
     * @dev sets the starting parameters of the SC.
     *
     * {_edgexContract} - address of the EDGEX token contract.
     * {_newROI} - the ROI in % represented in 13 decimals.
     * {_admin} - the controller of the contract.
     */
    constructor(
        address _edgexContract,
        uint256 _newROI,
        address _admin
    ) {
        edgexContract = _edgexContract;
        currentROI = _newROI;
        admin = _admin;
    }

    /**
     * @dev stakes the `amount` of tokens for `tenure`
     *
     * Requirements:
     * `amount` should be approved by the `caller`
     * to the staking contract.
     *
     * `tenure` shoulde be mentioned in days.
     */
    function stake(uint256 _amount, uint256 _tenureInDays)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        uint256 currentAllowance =
            IERC20(edgexContract).allowance(_msgSender(), address(this));
        uint256 currentBalance = IERC20(edgexContract).balanceOf(_msgSender());

        require(
            currentAllowance >= _amount,
            "Error: stake amount exceeds allowance"
        );
        require(
            currentBalance >= _amount,
            "Error: stake amount exceeds balance"
        );

        updateStakeData(_amount, _tenureInDays, _msgSender());
        totalStakingContracts[_msgSender()] += 1;

        return IERC20(edgexContract).transferFrom(
            _msgSender(),
            address(this),
            _amount
        );
    }

    /**
     * @dev creates the staking data in a new {Stake} strucutre.
     *
     * It records the current snapshots of ROI and other staking information available.
     */
    function updateStakeData(
        uint256 _amount,
        uint256 _tenureInDays,
        address _user
    ) internal {
        uint256 totalContracts = totalStakingContracts[_user] + 1;

        Stake storage sc = stakeContract[_user][totalContracts];
        sc.amount = _amount;
        sc.createdAt = block.timestamp;
        uint256 maturityInSeconds = _tenureInDays * 1 days;
        sc.maturesAt = block.timestamp + maturityInSeconds;
        sc.roiAtStake = currentROI;
    }

    /**
     * @dev claims the {amount} of tokens plus {earned} tokens
     * after the end of {tenure}
     *
     * Requirements:
     * `_stakingContractId` of the staking instance.
     *
     * returns a boolean to show the current state of the transaction.
     */
    function claim(uint256 _stakingContractId)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        Stake storage sc = stakeContract[_msgSender()][_stakingContractId];

        require(sc.maturesAt <= block.timestamp, "Not Yet Matured");
        require(!sc.isClaimed, "Already Claimed");

        uint256 total;
        uint256 interest;
        (total, interest) = calculateClaimAmount(
            _msgSender(),
            _stakingContractId
        );
        sc.isClaimed = true;
        sc.interest = interest;

        return IERC20(edgexContract).transfer(_msgSender(), total);
    }

    /**
     * @dev returns the amount of unclaimed tokens.
     *
     * Requirements:
     * `user` is the ethereum address of the wallet.
     * `contractId` is the id of the staking instance.
     *
     * returns the `total amount` and the `interest earned` respectively.
     */
    function calculateClaimAmount(address _user, uint256 _contractId)
        public
        view
        virtual
        override
        returns (uint256, uint256)
    {
        Stake storage sc = stakeContract[_user][_contractId];

        uint256 a = sc.amount * sc.roiAtStake;
        uint256 time = sc.maturesAt - sc.createdAt;
        uint256 b = a * time;
        uint256 interest = b / (31536 * 10**18);
        uint256 total = sc.amount + interest;

        return (total, interest);
    }

    /**
     * @dev transfers the governance from one account(`caller`) to another account(`_newOwner`).
     *
     * Note: Governors can only set / change the ROI.
     */

    function revokeOwnership(address _newOwner)
        public
        virtual
        override
        onlyAdmin
        isZero(_newOwner)
        returns (bool)
    {
        admin = payable(_newOwner);
        emit RevokeOwnership(_newOwner);
        return true;
    }

    /**
     * @dev will change the ROI on the staking yield.
     *
     * `_newROI` is the ROI calculated per second considering 365 days in a year.
     * It should be in 13 precision.
     *
     * The change will be effective for new users who staked tokens after the change.
     */
    function changeROI(uint256 _newROI)
        public
        virtual
        override
        onlyAdmin
        returns (bool)
    {
        currentROI = _newROI;
        emit ChangeROI(_newROI);
        return true;
    }

    /**
     * #@dev will change the token contract (EDGEX)
     *
     * If we're migrating / moving the token contract.
     * This prevents the need for migration of the staking contract.
     */
    function updateEdgexContract(address _contractAddress)
        public
        virtual
        override
        onlyAdmin
        isZero(_contractAddress)
        returns (bool)
    {
        edgexContract = _contractAddress;
        return true;
    }

    /**
     * @dev enables the governor to withdraw funds from the SC.
     *
     * this prevents tokens from getting locked in the SC.
     */
    function withdrawLiquidity(uint256 _edgexAmount, address _to)
        public
        virtual
        onlyAdmin
        isZero(_to)
        returns (bool)
    {
        return IERC20(edgexContract).transfer(_to, _edgexAmount);
    }
}
