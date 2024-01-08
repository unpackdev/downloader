pragma solidity 0.8.0;

import "./IERC20.sol";

contract MuseStaker {
    IERC20 public MUSE = IERC20(0xB6Ca7399B4F9CA56FC27cBfF44F4d2e4Eef1fc81);

    mapping(address => uint256) public shares;
    mapping(address => uint256) public timeLock;
    mapping(address => uint256) public amountLocked;

    uint256 public totalShares;
    uint256 public unlockPeriod = 10 days;

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function changeUnlockPeriod(uint256 _period) external {
        require(msg.sender == owner, "forbidden");
        unlockPeriod = _period;
    }

    function stake(uint256 _amount) public {
        timeLock[msg.sender] = 0; //reset timelock in case they stake twice.
        amountLocked[msg.sender] = amountLocked[msg.sender] + _amount;
        uint256 totalMuse = MUSE.balanceOf(address(this));
        if (totalShares == 0 || totalMuse == 0) {
            shares[msg.sender] = _amount;
            totalShares += _amount;
        } else {
            uint256 bal = (_amount * totalShares) / (totalMuse);
            shares[msg.sender] += bal;
            totalShares += bal;
        }
        MUSE.transferFrom(msg.sender, address(this), _amount);
    }

    function startUnstake() public {
        timeLock[msg.sender] = block.timestamp + unlockPeriod;
    }

    // requires timeLock to be up to 2 days after release tiemstamp.
    function unstake() public {
        uint256 lockedUntil = timeLock[msg.sender];
        timeLock[msg.sender] = 0;
        require(
            lockedUntil != 0 &&
                block.timestamp >= lockedUntil &&
                block.timestamp <= lockedUntil + 2 days,
            "!still locked"
        );
        _unstake();
    }

    function _unstake() internal {
        uint256 bal =
            (shares[msg.sender] * MUSE.balanceOf(address(this))) /
                (totalShares);
        totalShares -= shares[msg.sender];
        shares[msg.sender] = 0; //burns the share from this user;
        amountLocked[msg.sender] = 0;
        MUSE.transfer(msg.sender, bal);
    }

    function claim() public {
        uint256 amount = amountLocked[msg.sender];
        _unstake(); // Send locked muse + reward to user
        stake(amount); // Stake back only the original stake
    }

    function balance(address _user) public view returns (uint256) {
        if (totalShares == 0) {
            return 0;
        }
        uint256 bal =
            (shares[_user] * MUSE.balanceOf(address(this))) / (totalShares);
        return bal;
    }

    function userInfo(address _user)
        public
        view
        returns (
            uint256 bal,
            uint256 claimable,
            uint256 deposited,
            uint256 timelock,
            bool isClaimable,
            uint256 globalShares,
            uint256 globalBalance
        )
    {
        bal = balance(_user);
        if (bal > amountLocked[_user]) {
            claimable = bal - amountLocked[_user];
        }
        deposited = amountLocked[_user];
        timelock = timeLock[_user];
        isClaimable = (timelock != 0 &&
            block.timestamp >= timelock &&
            block.timestamp <= timelock + 2 days);
        globalShares = totalShares;
        globalBalance = MUSE.balanceOf(address(this));
    }
}
