// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./BAPMethaneInterface.sol";

/**
 * A number of codes are defined as error messages.
 * Codes are resembling HTTP statuses. This is the structure
 * CODE:SHORT
 * Where CODE is a number and SHORT is a short word or phrase
 * describing the condition
 * CODES:
 * 100  contract status: open/closed, depleted. In general for any flag
 *     causing the mint too not to happen.
 * 200  parameters validation errors, like zero address or wrong values
 * 300  User payment amount errors like not enough funds.
 * 400  Contract amount/availability errors like not enough tokens or empty vault.
 * 500  permission errors, like not whitelisted, wrong address, not the owner.
 */
contract BAPVesting is ReentrancyGuard, Ownable {
    address public methContractAdress;
    uint256 public constant totalRewards = 210000000;
    uint256 public totalVested;
    // Emission left is the amount of Meth available for vesting
    // The initial value is maxSupply - totalRewards
    // It should always be less or equal than the total scheduled for vesting
    uint256 public emissionLeft = 327600000;
    BAPMethaneInterface private methContract;

    struct VestingScheduleStruct {
        uint256 totalAllocation;
        uint256 start;
        uint256 duration;
    }
    mapping(address => uint256) public vested;
    mapping(address => VestingScheduleStruct) public vestingWallets;

    constructor(
        address _methContractAdress,
        address treasuryWallet,
        address teamsWallet
    ) {
        methContractAdress = _methContractAdress;
        methContract = BAPMethaneInterface(methContractAdress);
        require(_methContractAdress != address(0), "200:ZERO_ADDRESS");
        require(treasuryWallet != address(0), "200:ZERO_ADDRESS");
        require(teamsWallet != address(0), "200:ZERO_ADDRESS");
        vestingWallets[treasuryWallet] = VestingScheduleStruct(
            187600000, // Distribute 187.76 mill
            block.timestamp + 90 days, // starting in 90 days
            24 * 30 days
        ); // for 24 months
        vestingWallets[teamsWallet] = VestingScheduleStruct(
            140000000, // Distribute 14 mill
            block.timestamp + 180 days, // starting in 180 days
            36 * 30 days
        ); // for 36 months

    }

    function setBAPMethaneAddress(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "200:ZERO_ADDRESS");
        methContractAdress = contractAddress;
        methContract = BAPMethaneInterface(methContractAdress);
    }

    function addVestingSchedule(
        address wallet,
        uint256 totalAllocation,
        uint256 start,
        uint256 duration
    ) external onlyOwner {
        require(wallet != address(0), "200:ZERO_ADDRESS");
        require(start > block.timestamp, "INVALID VESTING SCHEDULE START TIME");
        require(verifyMethSupply(totalAllocation), "200:ABOVE_SUPPLY");
        if (vestingWallets[wallet].start != 0) {
            emissionLeft -= vestingWallets[wallet].totalAllocation;
        }
        emissionLeft += totalAllocation;
        vestingWallets[wallet] = VestingScheduleStruct(
            totalAllocation,
            start,
            duration
        );
    }

    function verifyMethSupply(uint256 totalAllocation)
        internal
        view
        returns (bool)
    {
        return
            totalRewards + emissionLeft + totalAllocation <=
            methContract.maxSupply();
    }

    function vesting() public nonReentrant {
        require(vestingWallets[msg.sender].start != 0, "200:UNREGISTERED");
        uint256 methAmount = vestingAmount();
        require(methAmount > 0, "Meth Amount is Zero");
        methContract.claim(msg.sender, methAmount);
        vested[msg.sender] += methAmount;
        totalVested += methAmount;
        emissionLeft -= methAmount;
    }

    /**
     * Retrieve vesting amount available for wallet
     */
    function vestingAmount() internal view virtual returns (uint256) {
        require(vestingWallets[msg.sender].start != 0, "200:UNREGISTERED");
        VestingScheduleStruct memory schedule = vestingWallets[msg.sender];
        if (block.timestamp < schedule.start) {
            return 0;
        } else if (block.timestamp > schedule.start + schedule.duration) {
            return schedule.totalAllocation;
        } else {
            return
                (schedule.totalAllocation *
                    (block.timestamp - schedule.start)) /
                vestingWallets[msg.sender].duration;
        }
    }
}
