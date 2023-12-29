// SPDX-License-Identifier: MIT

/*
Staking contract of the Otter protocol.

Telegram: https://t.me/otterprotocol
Website: https://otterprotocol.com/
X/Twitter: https://twitter.com/OtterProtocol 
Docs: https://otter-protocol.gitbook.io/otter-protocol/

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣤⣤⣤⣤⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⡿⡍⣀⠈⠉⠉⠙⣛⠻⠷⣶⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣧⡈⠲⢭⣑⣒⡠⠤⢈⡑⠢⢍⡛⠿⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠿⣶⣤⣄⣀⠈⠉⠑⠺⠵⣢⢌⡑⠮⣙⢿⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⣀⣀⡀⠀⠀⣀⣤⣴⣶⠶⠿⠿⠿⢷⣶⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠻⠿⣶⣦⣄⡈⠙⠪⣓⢌⠑⢭⡻⣷⣄⠀⠀⠀⠀⠀⠀⠀
⠀⠀⣠⣾⣟⣛⡛⢿⣷⡿⣛⠭⠗⠊⠉⠉⠉⠉⠉⠒⠯⣟⢿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢿⣦⣄⠈⠣⡑⢄⠙⢮⣿⣧⡀⠀⠀⠀⠀⠀
⠀⢰⣿⡿⠛⢉⣿⢟⡵⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠑⢝⢿⣿⠿⠿⣷⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣷⡀⠘⢦⠳⡀⠙⢝⣿⣄⠀⠀⠀⠀
⠀⠸⣿⣇⣠⡿⣣⠋⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢣⢻⣟⠛⢿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣆⠀⢣⡱⡀⠈⠋⢿⣆⠀⠀⠀
⠀⠀⠘⣿⡟⡼⠁⠀⠀⢠⣿⣟⡇⠀⠀⠀⠀⠀⠀⠀⢠⣶⣄⠀⠀⢣⢿⡆⠀⣻⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⡆⠀⢣⢱⠀⠀⠈⢿⣆⠀⠀
⠀⠀⣼⡟⡼⠀⠀⠀⠀⠘⢿⡿⠗⠊⣿⣿⣿⣷⡖⠦⣿⣾⣿⠀⠀⠈⡞⣿⣴⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⡀⠈⡆⡇⠀⠀⠈⣿⡆⠀
⠀⢰⣿⣱⠁⠀⠀⠀⠀⡴⠋⣦⡀⠀⣈⣿⣟⠋⠀⠀⠈⣟⠃⠀⠀⠀⢇⣿⡏⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⡾⢿⣿⡿⠷⣶⣿⡇⠀⢹⢸⠀⠀⠀⠸⣿⡀
⠀⣾⣏⠇⠀⠀⠀⢠⠎⠀⠀⠈⠹⣿⣟⠛⢿⣷⣶⠶⠟⠹⡄⠀⠀⠀⢸⢸⣇⠀⠀⠀⠀⢀⣴⣿⣿⠝⠊⠉⠀⠀⠀⠀⠈⠉⠻⣷⣼⠸⠀⠀⠀⠀⢿⡇
⢀⣿⡿⠀⠀⠀⢀⠏⠀⠀⠀⠀⠀⠈⠛⠛⠛⠋⠁⠀⠀⠀⡇⠀⠀⠀⢸⢸⣿⠀⠀⠀⣠⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣆⠀⠀⠀⠀⢸⣿
⢸⣿⠃⠀⠀⠀⡜⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡇⠀⠀⠀⢸⢸⣿⠀⠀⣰⣿⣽⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠙⣧⠀⠀⠀⢸⣿
⢸⣿⠀⠀⠀⢰⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⢸⠸⣿⠀⢠⣿⡿⢸⡇⣇⠀⠀⠀⠀⠀⠀⣠⡶⣶⣦⠀⠀⡸⠀⠀⠀⠀⠀⢸⣿
⢸⣿⠀⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡏⠀⣠⠀⠀⠈⡇⢿⣧⣿⡿⠁⢸⡇⠈⢦⡀⠀⠀⠀⠀⠀⠀⠈⢻⡇⢀⠇⠀⠀⠀⠀⢀⢸⣿
⠈⣿⣷⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠇⣴⠟⠀⠀⠀⠹⣌⠻⡟⠁⠀⢠⠿⣦⡀⠈⠑⣶⠆⠀⠀⣀⣄⣸⣇⠞⠀⠀⠀⠀⠀⡸⢸⡿
⠀⢻⣧⢇⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣼⡿⠀⠀⠀⠀⠀⠈⠑⠛⠀⢠⠏⢣⡙⠻⣶⣾⠏⠀⢠⠞⠁⢸⣿⠁⠀⠀⠀⠀⠀⢀⠇⣿⡇
⠀⠘⣿⡜⡆⠈⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⠃⠀⠀⠀⠀⢀⣰⠆⠀⣠⠋⠀⠀⠙⠆⣾⠇⠐⢢⠇⠀⢀⣾⠇⠀⠀⠀⠀⠀⠀⡜⣸⡿⠀
⠀⠀⠹⣷⡹⡄⢳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⠀⠀⠀⠀⠀⣼⡏⢀⡴⠃⠀⠀⠀⠀⠰⣿⣠⡄⢸⣀⣤⣿⢯⠃⠀⠀⠀⠀⠀⡸⢡⣿⠃⠀
⠀⠀⠀⢻⣷⡙⣌⢧⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣌⠀⠀⠀⠀⠀⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⢿⣯⣤⣤⣴⠿⢣⠏⠀⠀⠀⠀⠀⡼⢡⣿⠇⠀⠀
⠀⠀⠀⠀⠻⣷⡈⢢⡙⢳⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⢰⢿⡇⠀⠀⠀⠀⠀⠀⠀⠀⢠⡉⠉⠉⢁⡴⠃⠀⠀⠀⠀⢠⠎⢠⣿⠋⠀⠀⠀
⠀⠀⠀⠀⠀⠙⣿⣄⠙⢦⡈⠙⠻⢿⣶⣦⣄⡀⠀⠀⠘⢿⡄⠀⢀⠀⣮⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠒⠊⠉⠀⠀⠀⠀⣀⠔⠁⣴⡿⠃⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⢻⣷⣄⠈⠲⣄⡀⠀⠉⠺⢝⢷⡄⠈⢎⠻⢶⣼⣷⠿⣫⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠚⠁⣠⣾⠟⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣷⣄⠀⠙⠲⢄⣀⡈⢿⣿⠀⠈⠓⠤⠄⠤⠖⠁⣀⣀⣀⣀⠀⠀⠀⠀⠀⢀⣀⡀⢀⡠⠔⠉⠀⣠⣾⠟⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣷⣦⣤⣤⣤⣽⠿⠃⢀⣀⠀⠀⠀⠀⣴⠿⠿⠛⠛⠛⠋⢉⠉⠉⠉⠁⠈⣹⡆⠀⣠⣴⡿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⢿⣯⣌⡓⠢⢄⣀⠉⠀⠀⠀⣿⣛⣃⣀⠔⠋⠉⠀⠉⠙⣦⣒⣭⣿⣷⡿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠻⠿⣶⣦⣭⣵⣒⣒⣙⣿⣧⣬⣷⣤⣤⣤⣤⣶⡿⠿⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠛⠛⠛⠛⠛⠛⠋⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

*/

pragma solidity =0.8.15;
import "./Context.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract OTStakingV1 is Ownable, ReentrancyGuard {
    struct StakingDetails {
        uint256 amount;
        uint256 deposit_time;
        uint256 unlock_time;
        uint256 last_claim_time;
        bool participant;
    }

    using SafeMath for uint256;

    address public LP_token_address;
    IERC20 public LP_token;

    uint256 public locking_period;

    bool public claim_enabled = false;

    uint256 public total_lp_tokens;
    uint256 public depositors;
    uint256 public eth_per_block = 10000000000000;
    uint256 public earlyExitTax = 33;

    uint256 minThreshold = 1000000000000000000;

    event RewardsAdded(uint256 deposit_amount, uint256 time);
    event RunningLowOnRewards(uint256 left_remaining, uint256 time);
    event Claimed(address account, uint256 amount_due, uint256 time);
    event LargeDeposit(address account, uint256 amount, uint256 time);

    mapping(address => StakingDetails) public stake_details;

    constructor() {
        LP_token_address = 0x181Eb1DB23ea646F286A1638FB44A634e0B62Acb;
        LP_token = IERC20(LP_token_address);
        locking_period = 50400; // one week
    }

    receive() external payable {}

    function ReturnLPbalance() public view returns (uint256) {
        return LP_token.balanceOf(address(this));
    }

    function ReturnETHbalance() public view returns (uint256) {
        return address(this).balance;
    }

    function FetchEthPerBlock() internal view returns (uint256) {
        return eth_per_block;
    }

    function DepositRewards() public payable onlyOwner {
        emit RewardsAdded(msg.value, block.timestamp);
    }

    function EnableClaim(bool state) public onlyOwner {
        claim_enabled = state;
    }

    function ChangeEthPerBlock(uint256 newvalue) public onlyOwner {
        eth_per_block = newvalue;
    }

    function ChangeEarlyExitTax(uint256 newvalue) public onlyOwner {
        earlyExitTax = newvalue;
    }

    function ChangeLockingPeriod(uint256 newtime) public onlyOwner {
        require(newtime <= 100800, "Can't set lock longer then 2 weeks.");
        locking_period = newtime;
    }

    // have to approve the vault on the pair contract first
    function Deposit_LP(uint256 amount) public nonReentrant {
        require(amount > 0);
        amount = amount * 10**18;
        if (stake_details[msg.sender].participant == true) {
            if (claim_enabled) {
                internalClaim(msg.sender);
            }
            stake_details[msg.sender].amount += amount;
            LP_token.transferFrom(msg.sender, address(this), amount);
            total_lp_tokens += amount;
        } else {
            bool success = LP_token.transferFrom(
                msg.sender,
                address(this),
                amount
            );
            require(success);
            depositors += 1;

            stake_details[msg.sender].amount += amount;

            stake_details[msg.sender].participant = true;

            stake_details[msg.sender].deposit_time = block.timestamp;

            stake_details[msg.sender].last_claim_time = block.timestamp;

            stake_details[msg.sender].unlock_time =
                block.timestamp +
                locking_period;

            total_lp_tokens += amount;
        }
    }

    function WithdrawLP() public nonReentrant {
        require(stake_details[msg.sender].participant == true);
        // If lock period didn't end, exit early with an early exit fee
        if (
            stake_details[msg.sender].deposit_time + locking_period >
            block.timestamp
        ) {
            uint256 fee = stake_details[msg.sender]
                .amount
                .mul(earlyExitTax)
                .div(100); //
            uint256 amount = stake_details[msg.sender].amount;
            stake_details[msg.sender].amount = amount.sub(fee);
            LP_token.transfer(owner(), fee); // Transfer fee to the owner
        }

        if (stake_details[msg.sender].last_claim_time < block.timestamp) {
            if (claim_enabled) {
                internalClaim(msg.sender);
            }
        }

        stake_details[msg.sender].participant = false;
        depositors -= 1;
        bool success = LP_token.transfer(
            msg.sender,
            stake_details[msg.sender].amount
        );
        require(success);
        total_lp_tokens -= stake_details[msg.sender].amount;
        stake_details[msg.sender].amount = 0;
    }

    function internalClaim(address account) private {
        require(claim_enabled, "Claim has not been enabled yet.");
        require(
            stake_details[account].participant == true,
            "Not recognized as acive staker."
        );
        require(
            block.timestamp > stake_details[account].last_claim_time,
            "You can only claim once per block."
        );

        stake_details[account].last_claim_time = block.timestamp;

        uint256 amount_due = getPendingReturns(account);

        if (amount_due == 0) {
            return;
        }

        (bool success, ) = payable(account).call{value: amount_due}("");
        require(success);

        emit Claimed(account, amount_due, block.timestamp);

        if (address(this).balance <= minThreshold) {
            emit RunningLowOnRewards(address(this).balance, block.timestamp);
        }
    }

    function Claim() public nonReentrant {
        require(claim_enabled, "Claim has not been enabled yet.");
        require(
            stake_details[msg.sender].participant == true,
            "Not recognized as active staker."
        );
        require(
            block.timestamp > stake_details[msg.sender].last_claim_time,
            "You can only claim once per block."
        );
        require(
            block.timestamp <=
                stake_details[msg.sender].deposit_time + locking_period,
            "You must re-lock your LP for another lock duration before claiming again. Withdraw will auto claim rewards."
        );

        uint256 amount_due = getPendingReturns(msg.sender);

        stake_details[msg.sender].last_claim_time = block.timestamp;

        if (amount_due == 0) {
            return;
        }

        (bool success, ) = payable(msg.sender).call{value: amount_due}("");
        require(success);

        emit Claimed(msg.sender, amount_due, block.timestamp);

        if (address(this).balance <= minThreshold) {
            emit RunningLowOnRewards(address(this).balance, block.timestamp);
        }
    }

    function Compound() public nonReentrant {
        require(
            stake_details[msg.sender].participant == true,
            "Not recognized as active staker."
        );
        require(
            stake_details[msg.sender].deposit_time + locking_period <=
                block.timestamp,
            "You're still locked. Wait for lock duration to time out."
        );

        if (stake_details[msg.sender].last_claim_time < block.timestamp) {
            internalClaim(msg.sender);
        }

        stake_details[msg.sender].deposit_time = block.timestamp;

        stake_details[msg.sender].last_claim_time = block.timestamp;
        stake_details[msg.sender].unlock_time =
            block.timestamp +
            locking_period;
    }

    function getTimeInPool(address account) public view returns (uint256) {
        return stake_details[account].deposit_time - block.timestamp;
    }

    function getTimeleftTillUnlock(address account)
        public
        view
        returns (uint256)
    {
        return
            stake_details[account].deposit_time +
            locking_period -
            block.timestamp;
    }

    function getPendingReturns(address account) public view returns (uint256) {
        uint256 reward_blocks = block.timestamp -
            stake_details[account].last_claim_time;
        uint256 reward_rate = FetchEthPerBlock();
        uint256 amount_due = ((reward_rate * users_pool_percentage(account)) /
            10000) * reward_blocks;
        return amount_due;
    }

    function users_pool_percentage(address account)
        public
        view
        returns (uint256)
    {
        uint256 userStake = stake_details[account].amount;
        uint256 totalSupply = LP_token.balanceOf(address(this));

        if (totalSupply == 0) {
            return 0; // Avoid division by zero
        }

        uint256 percentage = (userStake * 10000) / totalSupply;

        return percentage;
    }

    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function ForceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(owner()).call{value: ETHbalance}("");
        require(success);
    }
}
