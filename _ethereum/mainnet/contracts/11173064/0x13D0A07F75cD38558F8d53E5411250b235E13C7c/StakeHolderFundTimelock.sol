// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";


contract StakeHolderFundTimeLock is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    struct CoFounder {
        address wallet;
        bool isActive; // if inactive, tokens don't get sent
    }

    // Min withdrawal interval in seconds (1 week)
    uint internal constant WITHDRAWAL_INTERVAL_SECS = 3600 * 24 * 7;
    // Total amount of withdrawal for one "interval"
    uint internal constant TOTAL_WITHDRAWAL_AMT_PER_INTERVAL = 2340000e18;

    // The king token
    IERC20 public king;

    // Timestamp of the last withdrawal
    uint public lastWithdrawTime;

    // Founder
    address public founder;

    // Co-founders
    CoFounder[] public cofounders;
    mapping(address => uint) public cofoundersIds;
    uint public cofoundersNum;

    constructor (address _king, address[] memory wallets, address _founder, uint delaySecs) public
    {
        require(_king != address(0), "invalid king address");
        king = IERC20(_king);

        revertZeroAddress(_founder);
        founder = _founder;

        for (uint i = 0 ; i < wallets.length; i++) {
            revertZeroAddress(wallets[i]);
            cofounders.push(CoFounder(wallets[i], true));
            cofoundersNum = cofoundersNum + 1;
            cofoundersIds[wallets[i]] = cofoundersNum;
        }

        lastWithdrawTime = block.timestamp.add(delaySecs);
    }

    // Anyone can call, but tokens get sent to registered addresses only
    function withdraw() public {
        uint timePast = block.timestamp > lastWithdrawTime ? block.timestamp.sub(lastWithdrawTime) : 0;
        uint intervalSecs = withdrawalIntervalInSeconds();
        require(timePast >= intervalSecs, "king locked");

        uint balance = king.balanceOf(address(this));
        require(balance > 10, "nothing to withdraw yet");

        uint intervals = timePast.mul(1000).div(intervalSecs);
        uint amountAllowed = withdrawalAmountPerInterval().mul(intervals).div(1000);

        uint amount = balance > amountAllowed ? amountAllowed : balance;
        lastWithdrawTime = block.timestamp;

        // co-founders get 720/1170
        uint share = amount.mul(72).div(cofoundersNum).div(117);
        for (uint i = 0 ; i < cofounders.length; i ++) {
            // for an active co-founder
            if(cofounders[i].isActive == true) {
                amount = amount.sub(share);
                king.safeTransfer(cofounders[i].wallet, share);
            }
        }
        // Founder gets 450/1170
        king.safeTransfer(founder, amount);
    }

    function addCofounder(address wallet) public onlyOwner {
        revertZeroAddress(wallet);

        uint id = cofoundersIds[wallet];
        if (id == 0) {
            cofounders.push(CoFounder(wallet, true));
            cofoundersNum = cofoundersNum + 1;
            cofoundersIds[wallet] = cofoundersNum;
        } else {
            cofounders[id - 1].isActive = true;
        }
    }

    function removeCofounder(address wallet) public onlyOwner {
        revertZeroAddress(wallet);

        uint id = cofoundersIds[wallet];
        require(id != 0, "wallet is not found");

        cofounders[id - 1].isActive = false;
        cofoundersNum = cofoundersNum - 1;
    }

    function updateFounder(address _founder) public onlyOwner {
        founder = _founder;
    }

    // @dev `virtual` to facilitate testing
    function withdrawalIntervalInSeconds() public pure returns (uint) {
        return WITHDRAWAL_INTERVAL_SECS;
    }

    // @dev `virtual` to facilitate testing
    function withdrawalAmountPerInterval() public pure returns (uint) {
        return TOTAL_WITHDRAWAL_AMT_PER_INTERVAL;
    }

    function revertZeroAddress(address wallet) private pure {
        require(wallet != address(0), "zero wallet address");
    }
}
