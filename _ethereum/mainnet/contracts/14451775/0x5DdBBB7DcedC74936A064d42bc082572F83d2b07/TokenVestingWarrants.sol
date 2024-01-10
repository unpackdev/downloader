// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./ITokenVesting.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TokenVestingWarrants is ReentrancyGuard, Ownable {
    ITokenVesting public immutable vestingContract;

    constructor(address aragonAgent, address _vestingContract) {
        require(aragonAgent != address(0), "invalid aragon agent address");
        require(_vestingContract != address(0), "invalid vesting contract address");
        vestingContract = ITokenVesting(_vestingContract);
        _transferOwnership(aragonAgent);
    }

    /**
     * @notice Add new schedule to vesting contract for `_recipient`
     * @param _recipient Vesting recipient wallet address
     * @param _startTime Vesting start timestamp
     * @param _amount Vesting token amount
     * @param _durationInWeeks Vesting duration in weeks
     * @param _delayInWeeks Vesting delay in weeks
     */
    function addNewSchedule(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint16 _durationInWeeks,
        uint16 _delayInWeeks
    ) internal {
        uint256 activeVestingId = vestingContract.getActiveVesting(_recipient);
        if (activeVestingId > 0) {
            ITokenVesting.VestingSchedule memory vs = vestingContract.vestingSchedules(activeVestingId);
            require(vs.duration == _durationInWeeks, "vesting duration didn't match");
            require(vs.delay == _delayInWeeks, "vesting delay didn't match");
            _amount += vs.amount;
            vestingContract.removeVestingSchedule(activeVestingId);
        }

        vestingContract.addVestingSchedule(_recipient, _startTime, _amount, _durationInWeeks, _delayInWeeks);
    }

    /**
     * @notice Add vesting schedules to vesting contract for Warrants. The vestings start from `startTime`
     * @param startTime Vesting schedules start timestamp: `startTime`
     */
    function addNewSchedules(uint256 startTime) external onlyOwner nonReentrant {
        addNewSchedule(0x1E8Bc927e3e21cc78dAFf453aeb857032EAe4C25, startTime, 49_897_674 * 10**18, 50, 0);
        addNewSchedule(0x3AbE443904BD79BA03e8F5CDe12E211cCE2E8c72, startTime, 7_761_860 * 10**18, 50, 0);
        addNewSchedule(0x3eF7f258816F6e2868566276647e3776616CBF4d, startTime, 7_761_860 * 10**18, 50, 0);
        addNewSchedule(0x29501657ceAd09579991f0674F8d7A20e38a011c, startTime, 7_207_442 * 10**18, 50, 0);
        addNewSchedule(0x3BB9378a2A29279aA82c00131a6046aa0b5F6A79, startTime, 4_435_349 * 10**18, 50, 0);
        addNewSchedule(0xCa7a491524BD6AaD034067F7EBDdc7475aD4e751, startTime, 4_435_349 * 10**18, 50, 0);
        addNewSchedule(0x31476BE87e39722488b9B228284B1Fe0A6deD88c, startTime, 2_772_093 * 10**18, 50, 0);
        addNewSchedule(0x44944113c500d5D656Bc49bd019168F05a238553, startTime, 2_709_091 * 10**18, 50, 0);
        addNewSchedule(0x3A2CE76BCd1B9bC0Dfbe271bbCdc0d599245B2bD, startTime, 2_772_093 * 10**18, 50, 0);
        addNewSchedule(0x8842F97d36913C09d640EB0e187260429E87d78A, startTime, 2_167_273 * 10**18, 50, 0);
        addNewSchedule(0xB88F61E6FbdA83fbfffAbE364112137480398018, startTime, 2_217_674 * 10**18, 50, 0);
        addNewSchedule(0x06AAEa0884eCc5f7A6d1c5ae328db63E5A6e3B5b, startTime, 2_217_674 * 10**18, 50, 0);
        addNewSchedule(0x34Fd314838A4E5E920A073dA05FfFEFC4295aAa3, startTime, 874_133 * 10**18, 50, 0);
        addNewSchedule(0x58791B7d2CFC8310f7D2032B99B3e9DfFAAe4f17, startTime, 794_666 * 10**18, 50, 0);
        addNewSchedule(0xBbb6e8eabFBF4D1A6ebf16801B62cF7Bdf70cE57, startTime, 715_200 * 10**18, 50, 0);
        addNewSchedule(0x0b8b0a626a397aF6448D2a400f4798d897582cD9, startTime, 397_333 * 10**18, 50, 0);
        addNewSchedule(0x59AA30950270Ffd59e9A9166AD1d34Be151BeED7, startTime, 596_000 * 10**18, 50, 0);
        addNewSchedule(0x34bcBCc1F494402C5d9739C26721a0BB386fDCfd, startTime, 397_333 * 10**18, 50, 0);
        addNewSchedule(0xFb3aB0f8542D8f8F9F24b6dD211F31d76999b365, startTime, 317_867 * 10**18, 50, 0);
        addNewSchedule(0x27aaD4D768f91Fa60f824DC3153FaaEc25b06f4D, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x1afA0452bCa780A54f265290371798130601e23A, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x5a3338e833D0b947089E7A4cb76f1FdE73702E59, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x49ca963Ef75BCEBa8E4A5F4cEAB5Fd326beF6123, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x5Ef418b862a5356C30Ab1eaC52076bdc79Dd2029, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x26c8208804de8Cae08f367d985a5e0DC3CE639B0, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0x70499eeB16D5D3B6313f5ca2b6c4F17e684e7fE9, startTime, 198_667 * 10**18, 50, 0);
        addNewSchedule(0xCE95E48Bb08346798b56dFdEbecB5DAD5cC8b273, startTime, 309_920 * 10**18, 50, 0);
        addNewSchedule(0x0549613eb7310733dE690e59deEed1289409061d, startTime, 79_466 * 10**18, 50, 0);
        addNewSchedule(0x0060B0f5986185d06100A3F555c28F615A5D0CCe, startTime, 47_680 * 10**18, 50, 0);
        addNewSchedule(0x8dc61C26709159cB5907b38b4659da907e0C4a00, startTime, 39_733 * 10**18, 50, 0);
        addNewSchedule(0x73A540D80AF861645431e60Cf1D9eBc55aEa835b, startTime, 210_007 * 10**18, 50, 0);
        addNewSchedule(0x8de30775Ee5c4164E6754A6280eabe6A5Ad520E0, startTime, 210_007 * 10**18, 50, 0);
        addNewSchedule(0x8e1fb83D27f9eb464472aC7a74c01E89e2fBe99e, startTime, 210_007 * 10**18, 50, 0);
    }

    /**
     * @notice Transfer the ownership back to AragonDAO Agent
     * @param aragonAgent AragonDAO agent contract address
     */
    function updateVestingContractOwner(address aragonAgent) external onlyOwner nonReentrant {
        require(aragonAgent == owner(), "invalid aragon agent address");
        vestingContract.transferOwnership(aragonAgent);
    }
}
