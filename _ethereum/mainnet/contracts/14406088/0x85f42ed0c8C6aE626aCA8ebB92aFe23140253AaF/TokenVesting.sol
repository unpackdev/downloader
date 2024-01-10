// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract TokenVesting is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeERC20 for IERC20;

    uint256 internal constant SECONDS_PER_WEEK = 604800;

    struct VestingSchedule {
        bool isValid;
        uint256 startTime;
        uint256 amount;
        uint16 duration;
        uint16 delay;
        uint16 weeksClaimed;
        uint256 totalClaimed;
        address recipient;
    }

    event VestingAdded(
        address indexed recipient,
        uint256 vestingId,
        uint256 startTime,
        uint256 amount,
        uint16 duration,
        uint16 delay
    );
    event VestingTokensClaimed(address indexed recipient, uint256 vestingId, uint256 amountClaimed);
    event VestingRemoved(address recipient, uint256 vestingId, uint256 amountVested, uint256 amountNotVested);
    event VestingRecipientUpdated(uint256 vestingId, address oldRecipient, address newRecipient);
    event TokenWithdrawn(address indexed recipient, uint256 tokenAmount);

    IERC20 public immutable token;

    mapping(uint256 => VestingSchedule) public vestingSchedules;
    mapping(address => uint256) private activeVesting;
    uint256 public totalVestingCount;
    uint256 public totalVestingAmount;
    bool public allocInitialized;

    constructor(IERC20 _token, address aragonAgent) {
        require(address(aragonAgent) != address(0), "invalid aragon agent address");
        require(address(_token) != address(0), "invalid token address");
        token = _token;
        _transferOwnership(aragonAgent);
    }

    function addVestingSchedule(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint16 _durationInWeeks,
        uint16 _delayInWeeks
    ) public onlyOwner {
        require(_amount <= token.balanceOf(address(this)) - totalVestingAmount, "Insufficient token balance");
        require(activeVesting[_recipient] == 0, "active vesting already exists");

        uint256 amountVestedPerWeek = _amount.div(_durationInWeeks);
        require(amountVestedPerWeek > 0, "amountVestedPerWeek > 0");

        VestingSchedule memory vesting = VestingSchedule({
            isValid: true,
            startTime: _startTime == 0 ? currentTime() : _startTime,
            amount: _amount,
            duration: _durationInWeeks,
            delay: _delayInWeeks,
            weeksClaimed: 0,
            totalClaimed: 0,
            recipient: _recipient
        });

        totalVestingCount++;
        vestingSchedules[totalVestingCount] = vesting;
        activeVesting[_recipient] = totalVestingCount;
        emit VestingAdded(_recipient, totalVestingCount, vesting.startTime, _amount, _durationInWeeks, _delayInWeeks);
        totalVestingAmount += _amount;
    }

    function getActiveVesting(address _recipient) public view returns (uint256) {
        return activeVesting[_recipient];
    }

    function calculateVestingClaim(uint256 _vestingId) public view returns (uint16, uint256) {
        require(_vestingId > 0, "invalid vestingId");
        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        return _calculateVestingClaim(vestingSchedule);
    }

    function _calculateVestingClaim(VestingSchedule storage vestingSchedule) internal view returns (uint16, uint256) {
        if (currentTime() < vestingSchedule.startTime || !vestingSchedule.isValid) {
            return (0, 0);
        }

        uint256 elapsedTime = currentTime().sub(vestingSchedule.startTime);
        uint256 elapsedWeeks = elapsedTime.div(SECONDS_PER_WEEK);

        if (elapsedWeeks < vestingSchedule.delay) {
            return (uint16(elapsedWeeks), 0);
        }

        if (elapsedWeeks >= vestingSchedule.duration + vestingSchedule.delay) {
            uint256 remainingVesting = vestingSchedule.amount.sub(vestingSchedule.totalClaimed);
            return (vestingSchedule.duration, remainingVesting);
        } else {
            uint16 claimableWeeks = uint16(elapsedWeeks.sub(vestingSchedule.delay));
            uint16 weeksVested = uint16(claimableWeeks.sub(vestingSchedule.weeksClaimed));
            uint256 amountVestedPerWeek = vestingSchedule.amount.div(uint256(vestingSchedule.duration));
            uint256 amountVested = uint256(weeksVested.mul(amountVestedPerWeek));
            return (weeksVested, amountVested);
        }
    }

    function claimVestedTokens() external {
        uint256 _vestingId = activeVesting[msg.sender];
        require(_vestingId > 0, "no active vesting found");

        uint16 weeksVested;
        uint256 amountVested;

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];

        require(vestingSchedule.recipient == msg.sender, "only recipient can claim");

        (weeksVested, amountVested) = _calculateVestingClaim(vestingSchedule);
        require(amountVested > 0, "amountVested is 0");

        vestingSchedule.weeksClaimed = uint16(vestingSchedule.weeksClaimed.add(weeksVested));
        vestingSchedule.totalClaimed = uint256(vestingSchedule.totalClaimed.add(amountVested));

        require(token.balanceOf(address(this)) >= amountVested, "no tokens");
        token.safeTransfer(vestingSchedule.recipient, amountVested);
        emit VestingTokensClaimed(vestingSchedule.recipient, _vestingId, amountVested);
    }

    function removeVestingSchedule(uint256 _vestingId) external onlyOwner {
        require(_vestingId > 0, "invalid vestingId");

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        require(activeVesting[vestingSchedule.recipient] == _vestingId, "inactive vesting");
        address recipient = vestingSchedule.recipient;
        uint16 weeksVested;
        uint256 amountVested;
        (weeksVested, amountVested) = _calculateVestingClaim(vestingSchedule);

        uint256 amountNotVested = (vestingSchedule.amount.sub(vestingSchedule.totalClaimed)).sub(amountVested);

        vestingSchedule.isValid = false;
        activeVesting[recipient] = 0;

        require(token.balanceOf(address(this)) >= amountVested, "not enough balance");
        token.safeTransfer(recipient, amountVested);

        totalVestingAmount -= amountNotVested;
        emit VestingRemoved(recipient, _vestingId, amountVested, amountNotVested);
    }

    function updateVestingRecipient(uint256 _vestingId, address recipient) external onlyOwner {
        require(_vestingId > 0, "invalid vestingId");
        require(activeVesting[recipient] == 0, "recipient has an active vesting");
        require(address(recipient) != address(0), "invalid recipient address");

        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        require(activeVesting[vestingSchedule.recipient] == _vestingId, "inactive vesting");
        activeVesting[vestingSchedule.recipient] = 0;

        emit VestingRecipientUpdated(_vestingId, vestingSchedule.recipient, recipient);

        vestingSchedule.recipient = recipient;
        activeVesting[recipient] = _vestingId;
    }

    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    function tokensVestedPerWeek(uint256 _vestingId) public view returns (uint256) {
        require(_vestingId > 0, "invalid vestingId");
        VestingSchedule storage vestingSchedule = vestingSchedules[_vestingId];
        return vestingSchedule.amount.div(uint256(vestingSchedule.duration));
    }

    function withdrawToken(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "invalid token address");
        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, "amount should not exceed balance");
        token.safeTransfer(recipient, amount);
        emit TokenWithdrawn(recipient, amount);
    }

    function initializeAllocation(uint256 startTime) external onlyOwner {
        require(!allocInitialized, "allocation already initialized.");

        // Early Contributors
        addVestingSchedule(0x07A8c46530ADf39bbd2791ac5f5e477011C42A9f, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0xa23CB57ccC903e18dd5B4399826B7FC8c68D0C9C, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0xC31cc7B4a202eAFfd571D0895033ffa7986d181f, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x84a9a19dC122e472493E3E21d25469Be8b3d47Fc, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x5132d87c57598c4d10A9ab188DdCCc061531cc99, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0x29488965c47A61f476a798B40a669cf7cdBcF805, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0xb2695290A04d2a61b1fE6c89EaF9298B3534d3bD, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x9E59Ea877e5aDB95cF6a82618a910F855568d6ff, startTime, 4768000 * 10**18, 50, 0);
        addVestingSchedule(0xa665a0507Ad4B0571B12B1f59FA7e8d2BF63C65F, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0xC6b6896A9e0131820b10B586dadBAc4E9ACfb86A, startTime, 596000 * 10**18, 50, 0);
        addVestingSchedule(0x32802F989B4348A51DD0E61D23B78BE1a0543469, startTime, 1788000 * 10**18, 50, 0);
        addVestingSchedule(0x09443af3e8bf03899A40d6026480fAb0E44D518E, startTime, 1192000 * 10**18, 50, 0);
        addVestingSchedule(0xCA63CD425d0e78fFE05a84c330Bfee691242113d, startTime, 2384000 * 10**18, 50, 0);
        addVestingSchedule(0x3eF7f258816F6e2868566276647e3776616CBF4d, startTime, 23840000 * 10**18, 50, 0);
        addVestingSchedule(0x1e550B93a628Dc2bD7f6A592f23867241e562AeE, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0x3BB9378a2A29279aA82c00131a6046aa0b5F6A79, startTime, 17880000 * 10**18, 50, 0);
        addVestingSchedule(0x6AB0a3F3B01653295c0DC2eCeD5c4EaD099c3f9D, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x31476BE87e39722488b9B228284B1Fe0A6deD88c, startTime, 23840000 * 10**18, 50, 0);
        addVestingSchedule(0xB66e29158d18c34097a199624e5B126703B346C3, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x33f4BeBbc43Bc5725F4eD64629E7022a46eD9146, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0x61F85f43e275Fda8b5E122C7738Fe188C92385c0, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0xfE8420a2758c303ADC5f6C3125FDa7E9eD96A1E3, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x2630b80F4fD862aca4010fBFeFA2081FC631D20C, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x58791B7d2CFC8310f7D2032B99B3e9DfFAAe4f17, startTime, 1192000 * 10**18, 50, 0);
        addVestingSchedule(0xDD1b2aeD364f3532A90dAcB5d9ba8D47b11Cdea3, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x58d0f3dA9C97dE3c39f481e146f3568081d328a2, startTime, 1788000 * 10**18, 50, 0);
        addVestingSchedule(0xC71F1e087AadfBaE3e8578b5eFAFDeC8aFA95a16, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x683E0fCB25A2A84Bf9f5850a47d88Ad9c38C2a2f, startTime, 17880000 * 10**18, 50, 0);
        addVestingSchedule(0x1856D5e4767737a4051ae61c7852acdF8DFFb27b, startTime, 8940000 * 10**18, 50, 0);
        addVestingSchedule(0xDeCf6cC45e4F1816fC75C3b2AeD1e7BF02C43E52, startTime, 596000 * 10**18, 50, 0);
        addVestingSchedule(0x77aB3a45Fb6A48Ed390ae75D7812e4BD8ACe5A17, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x99F229481Bbb6245BA2763f224f733A7Cd784f0c, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x55E1e020Ca8f589b691Dbc3E9CBCe8845a400f97, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x4caeDdE6188c8c452556A141aA463999b4cF2ffc, startTime, 1788000 * 10**18, 50, 0);
        addVestingSchedule(0xb9FeCf6dC7F8891721d98825De85516e67922772, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0xf83A22e3eF017AdA8f4DCE1D534532d6e7000795, startTime, 23840000 * 10**18, 50, 0);
        addVestingSchedule(0xDA51f23515Bf0FF319FfD5727e22C1Aa114B392C, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0xC7fC3d9820c9803d788369E9129ACA7C16abe96D, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0xb8F03E0a03673B5e9E094880EdE376Dc2caF4286, startTime, 11920000 * 10**18, 50, 0);
        addVestingSchedule(0x0cf02f3a7B424dD8AA57A550B3c0362aa0146E95, startTime, 2980000 * 10**18, 50, 0);
        addVestingSchedule(0x05AE0683d8B39D13950c053E70538f5810737bC5, startTime, 1192000 * 10**18, 50, 0);
        addVestingSchedule(0xf2d876D0621Ee340aFcD37ea6F49733982b08bC2, startTime, 23840000 * 10**18, 50, 0);
        addVestingSchedule(0x1887D97F9C875108Aa6bE109B282f87A666472f2, startTime, 3576000 * 10**18, 50, 0);
        addVestingSchedule(0xB7A210a2786fF2B22786e4C082d2a6FF6775CB68, startTime, 5960000 * 10**18, 50, 0);
        addVestingSchedule(0x480F32b9B5BBCD188501C9FA74FE23D6Eb037BDf, startTime, 5960000 * 10**18, 50, 0);

        // Ecosystem Development
        addVestingSchedule(0xdBB0FfAFD38A61A1C06BA0C40761355F9F50a01E, startTime, 2384000 * 10**18, 104, 0);
        addVestingSchedule(0xe4382f06191cb158515A763E2ED5c573d7b3E4C0, startTime, 1192000 * 10**18, 104, 0);
        addVestingSchedule(0xB9BbB220D5eB660BBB634805dfF8cBDacb732cB4, startTime, 4768000 * 10**18, 104, 0);
        addVestingSchedule(0xf4a3F5bC8FAD4C49f0a0102b410Dcbfa29406D50, startTime, 5960000 * 10**18, 104, 0);
        addVestingSchedule(0x4Eee8BA6724Ca5cEc0E1433B9f613936C774b9F5, startTime, 11920000 * 10**18, 104, 0);

        // Advisors
        addVestingSchedule(0x3cEaFDFcA243AEfef6c2360B549B22b9c118744e, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xa11f5Aecf3D5d5A17FF16dA1dDdc2bA43A6c5Fe1, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0x747dfb7D6D27671B4e3E98087f00e6B023d0AAb7, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xDA223201df90Fe53CA5C9282BE932F876F6FA2F1, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xaBBDe42239e98FE42e732961F25cf0cfFF68e107, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xd051a1170e3c336D95397208ae58Fa4b22e92A97, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0x9796260c3D8E52f2c053D27Dcb382b7f2a504522, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0xCc7357203C0D1C0D64eD7C5605a495C8FBEBAC8c, startTime, 2980000 * 10**18, 104, 12);
        addVestingSchedule(0x88C3531B54Dde2438b10107e352551521B4319bD, startTime, 2980000 * 10**18, 104, 12);

        // ASM Gnosis Safe
        addVestingSchedule(0xEcbc5C456D9508A441254A6dA7d51C693A206eCf, startTime, 381440000 * 10**18, 104, 12);

        allocInitialized = true;
    }
}
