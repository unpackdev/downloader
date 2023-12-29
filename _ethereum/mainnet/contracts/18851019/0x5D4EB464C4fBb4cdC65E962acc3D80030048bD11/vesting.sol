pragma solidity ^0.8.18;
// SPDX-License-Identifier: MIT

// ----------------------------------------------------------------------------
// 1ex Vesting factory contract 
// ----------------------------------------------------------------------------

import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

contract OneExVesting {
    using SafeERC20 for IERC20;
    address public owner;

    struct Schedule {
        address account;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 endTime;
        address asset;
        bool revokable;
        bool revoked;
    }

    Schedule public schedule;
    event Claim(address indexed claimer, uint256 amount);
    event Vest(address indexed account, uint256 amount);
    event Revoked(address indexed beneficiary, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Claim vested tokens by account sending 0 coins to contract address.
     */
    receive() external payable {
        require(msg.value == 0 && msg.sender == schedule.account);
        require(claimableAmount() != 0, "Vesting: No avaliable tokens to withdraw");
        claimInternal();
    }

    /**
     * @notice Sets up a vesting schedule for a set user.
     * @dev adds a new Schedule to the schedules mapping.
     * @param account the account that a vesting schedule is being set up for. Will be able to claim tokens after the cliff period.
     * @param amount the amount of tokens being vested for the user.
     * @param asset the asset that the user is being vested.
     * @param cliffDays the number of days that the cliff will be present at.
     * @param vestingDays the number of days the tokens will vest.
     * @param startTime the timestamp for when this vesting should have started.
     * @param revokable bool setting if these vesting schedules can be revoked or not.
     * @return bool success.
     */
    function vest(
        address account,
        uint256 amount,
        address asset,
        uint256 cliffDays,
        uint256 vestingDays,
        uint256 startTime,
        bool revokable
    ) external onlyOwner returns(bool) {
        require(vestingDays > 0 && amount > 0, "Vesting: invalid vesting params");
        require(IERC20(asset).balanceOf(address(this)) == amount, "Vesting: not enough tokens");
        schedule = Schedule(
            account,
            amount,
            0,
            startTime,
            startTime + (cliffDays * 1 days),
            startTime + (cliffDays * 1 days) + (vestingDays * 1 days),
            asset,
            revokable,
            false
        );
        emit Vest(account, amount);
        return true;
    }

    /**
     * @return Calculates the amount of tokens to distribute in time.
     * return uint256 all tokens to distribute.
     */
    function calcDistribution() internal view returns (uint256) {
        if (block.timestamp < schedule.cliffTime || schedule.revoked) { return 0; }
        uint256 time = block.timestamp;
        if (time > schedule.endTime) { time = schedule.endTime; }
        return (schedule.totalAmount * (time - schedule.cliffTime)) / (schedule.endTime - schedule.cliffTime);
    }

    /**
     * @return Calculates claimable amount of tokens.
     * return uint256 claimable amount.
     */
    function claimableAmount() public view returns (uint256) {
        if (schedule.revoked) { return 0; }
        return calcDistribution() - schedule.claimedAmount;
    }

    /**
     * @notice Claim vested tokens from VestingFactory.
     */
    function claim() external onlyOwner {
        claimInternal();
    }

    /**
     * @notice Claim vested tokens if the cliff time has passed.
     */
    function claimInternal() internal  {
        uint256 amountToTransfer = claimableAmount();
        if (claimableAmount() != 0) {      
        schedule.claimedAmount += amountToTransfer; // set new claimed amount based off the curve
        IERC20(schedule.asset).safeTransfer(schedule.account, amountToTransfer);
        emit Claim(schedule.account, amountToTransfer);
        }
    }

    /**
     * @notice Allows a vesting schedule to be cancelled.
     * @dev Any outstanding tokens are returned to the beneficiary.
     * @param beneficiary the account for tokens transfer.
     */
    function revoke(address beneficiary) external onlyOwner returns(bool) {
        require(schedule.revokable, "Vesting: Vesting is not revokable");
        uint256 outstandingAmount = schedule.totalAmount - schedule.claimedAmount;
        require(outstandingAmount != 0, "Vesting: no outstanding tokens");
        schedule.totalAmount = 0; schedule.revoked = true;
        IERC20(schedule.asset).safeTransfer(beneficiary, outstandingAmount);
        emit Revoked(beneficiary, outstandingAmount);
        return true;
    }
}

interface IVesting {
    function vest(address account,uint256 amount,address asset,uint256 cliffDays,uint256 vestingDays, uint256 startTime, bool isRevokable) external returns (bool);
    function revoke(address beneficiary) external returns (bool);
    function claim() external;
    function claimableAmount() external view returns (uint256);
}

contract OneExVestingFactory is AccessControl {
    using Address for address;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _allVestings;
    EnumerableSet.AddressSet private _revokableVestings;
    EnumerableSet.AddressSet private _supportedAssets;

    bytes32 public constant ADMIN = keccak256("ADMIN");

    struct Vestings{
        address[] vestings;
    }
    mapping(address => Vestings) private accountVestings;

    event NewVesting(address indexed newContract, address indexed account);
    event AddAsset(address indexed _asset);
    event RemoveAsset(address indexed _asset);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    /**
     * @notice all claim vested tokens by account sending 0 coins to contract address.
     */
    receive() external payable {
        require(msg.value == 0);
        claimAll();
    }

    /**
     * @notice Sets up a vesting schedule for a set user.
     * @dev adds a new Schedule to the schedules mapping.
     * @param account the account that a vesting schedule is being set up for. Will be able to claim tokens after the cliff period.
     * @param amount the amount of tokens being vested for the user.
     * @param asset the asset that the user is being vested.
     * @param cliffDays the number of Days that the cliff will be present at.
     * @param vestingDays the number of Days the tokens will vest.
     * @param startTime the timestamp for when this vesting should have started.
     * @param revokable bool setting if these vesting schedules can be rugged or not.
     * @return bool success.
     */
    function vest(
        address account,
        uint256 amount,
        address asset,
        uint256 cliffDays,
        uint256 vestingDays,
        uint256 startTime,
        bool revokable
    ) public onlyRole(ADMIN) returns (bool) {
        require(account != address(0), "VestingFactory: account zero address");
        require(_supportedAssets.contains(asset), "VestingFactory: asset not supported");
        address _contract = create(_allVestings.length());
        IERC20(asset).safeTransferFrom(msg.sender, _contract, amount);
        require(IVesting(_contract).vest(account, amount, asset, cliffDays, vestingDays, startTime, revokable));
        require(_allVestings.add(_contract));
        if (revokable) { require(_revokableVestings.add(_contract)); }
        accountVestings[account].vestings.push(_contract);
        emit NewVesting(_contract, account);
        return true;
    }

    /**
     * @notice Sets up vesting schedules for multiple users within 1 transaction.
     * @dev adds a new Schedule to the schedules mapping.
     * @param accounts an array of the accounts that the vesting schedules are being set up for.
     *                 Will be able to claim tokens after the cliff period.
     * @param amount an array of the amount of tokens being vested for each user.
     * @param asset the asset that the user is being vested.
     * @param cliffDays the number of Days that the cliff will be present at.
     * @param vestingDays the number of Days the tokens will vest.
     * @param startTime the timestamp for when this vesting should have started.
     * @param revokable bool setting if these vesting schedules can be revoked or not.
     * @return bool success.
     */
    function multiVest(
        address[] calldata accounts,
        uint256[] calldata amount,
        address asset,
        uint256 cliffDays,
        uint256 vestingDays,
        uint256 startTime,
        bool revokable
    ) external returns (bool) {
        uint256 numberOfAccounts = accounts.length;
        require(amount.length == numberOfAccounts, "VestingFactory: array lengths differ");
        for (uint256 i = 0; i < numberOfAccounts; i++) {
            vest(accounts[i], amount[i], asset, cliffDays, vestingDays, startTime, revokable);
        }
        return true;
    }

    /**
     * @notice Claim all vested tokens by msg.sender.
     */
    function claimAll() public {
        require(accountVestings[msg.sender].vestings.length != 0, "VestingFactory: no vesting contracts");
        require(claimableAmount(msg.sender) != 0, "VestingFactory: No avaliable tokens to withdraw");
        for (uint256 i = 0; i < accountVestings[msg.sender].vestings.length; i++) {  
            IVesting(accountVestings[msg.sender].vestings[i]).claim(); 
        }
    }

    /**
     * @notice Revoke tokens from vesting by contract ADMIN (if revokable is true in schedule).
     * @dev Any outstanding tokens are returned to the beneficiary.
     * @param vestingContract vesting contract.
     * @param beneficiary address to send tokens.
     * @return bool success.
     */
    function revoke(address vestingContract, address beneficiary) external onlyRole(ADMIN) returns (bool) {
        require(_revokableVestings.contains(vestingContract), "VestingFactory: not a revokable vesting contract");
        require(IVesting(vestingContract).revoke(beneficiary));
        require(_revokableVestings.remove(vestingContract));
        return true;
    }

    /**
     * @notice Adds asset to the list supported assets.
     * @dev Return value of claimableAmount function may cause confusion if used more whan 1 asset.
     * @param _asset ERC20 contract address.
     */
    function addAsset(address _asset) external onlyRole(ADMIN) {
        require(_asset.isContract(), "VestingFactory: Asset is not a contract");
        require(_supportedAssets.add(_asset), "VestingFactory: Asset is already in the list");
        emit AddAsset(_asset);
    }

    /**
     * @notice Remove asset to the list supported assets.
     * @dev Return value of claimableAmount function may cause confusion if used more whan 1 asset.
     * @param _asset ERC20 contract address.
     */
    function removeAsset(address _asset) external onlyRole(ADMIN) {
        require(_supportedAssets.remove(_asset), "VestingFactory: No asset in the list");
        emit RemoveAsset(_asset);
    }
    
    /**
     * @notice Create new contract with salt.
     */
    function create(uint256 _salt) internal returns (address) { 
        address _contract = deploy(getBytecode(), keccak256(abi.encodePacked(_salt)));
        return (_contract);
    }

    /**
     * @notice Deploy new contract with salt.
     */
    function deploy(bytes memory code, bytes32 salt) internal returns (address addr) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    /**
     * @notice Bytecode.
     */
    function getBytecode() internal pure returns (bytes memory) {
        bytes memory bytecode = abi.encodePacked(type(OneExVesting).creationCode, abi.encode());
        return bytecode;
    }

    /**
     * @notice Shows all claimable amount for specific account.
     * @param account the account that a vesting schedule is being set up for.
     * @return uint256 claimable amount for specific account.
     */
    function claimableAmount(address account) public view returns (uint256){
        require(accountVestings[account].vestings.length != 0, "VestingFactory: no vesting contracts");
        uint256 all;
        for (uint256 i = 0; i < accountVestings[account].vestings.length; i++) {
            all += IVesting(accountVestings[account].vestings[i]).claimableAmount();
        }
        return all;
    }

    /**
     * @notice Lists all vesting contracts of account.
     * @param account the account that a vesting schedule is being set up for.
     * @return address[] array of account contracts.
     */
    function vestingsOfAccount(address account) external view returns (address[] memory) {
        return accountVestings[account].vestings;
    }

    /**
     * @notice Total amount of vestings.
     * @return uint256 total amount.
     */
    function vestingsAmount() external view returns(uint256) {
        return _allVestings.length();
    }

    /**
     * @notice Lists all vesting contracts.
     * @return address[] array of contracts.
     */
    function allVestings() external view returns (address[] memory) {
        return _allVestings.values();
    }

    /**
     * @notice Lists all revokable vesting contracts.
     * @return address[] array of contracts.
     */
    function revokableVestings() external view returns (address[] memory) {
        return _revokableVestings.values();
    }
}
