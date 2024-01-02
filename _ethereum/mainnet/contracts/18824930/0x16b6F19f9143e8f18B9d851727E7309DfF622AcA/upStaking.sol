/*
.___________. __    __   _______      ______   .__   __.  __      ____    ____    ____    __    ____      ___      ____    ____     __       _______.    __    __  .______    __
|           ||  |  |  | |   ____|    /  __  \  |  \ |  | |  |     \   \  /   /    \   \  /  \  /   /     /   \     \   \  /   /    |  |     /       |   |  |  |  | |   _  \  |  |
`---|  |----`|  |__|  | |  |__      |  |  |  | |   \|  | |  |      \   \/   /      \   \/    \/   /     /  ^  \     \   \/   /     |  |    |   (----`   |  |  |  | |  |_)  | |  |
    |  |     |   __   | |   __|     |  |  |  | |  . `  | |  |       \_    _/        \            /     /  /_\  \     \_    _/      |  |     \   \       |  |  |  | |   ___/  |  |
    |  |     |  |  |  | |  |____    |  `--'  | |  |\   | |  `----.    |  |           \    /\    /     /  _____  \      |  |        |  | .----)   |      |  `--'  | |  |      |__|
    |__|     |__|  |__| |_______|    \______/  |__| \__| |_______|    |__|            \__/  \__/     /__/     \__\     |__|        |__| |_______/        \______/  | _|      (__)

Welcome to UP Staking Dapp! Here we share 50% of the trading revenue to our stakers! 
Stake your $UP and claim your rewards in real ETH any where any time!

Dapp: https://www.upstaking.today
TG: https://t.me/upStakingDappPortal
X: https://www.x.com/UpStakingDapp

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

contract UpStakingDapp is Ownable, ReentrancyGuard {
    struct Share {
        uint stakingTime;
        uint tokenStaked;
        uint sumETH;
    }

    mapping(address => Share) public shares;
    IERC20 public token;
    uint public sumETH;
    uint private constant DECIMAL = 1e18;
    address private _taxWallet;
    uint public totalETH;

    modifier onlyToken() {
        assert(msg.sender == address(token));
        _;
    }

    constructor() Ownable(_msgSender()) {
        _taxWallet = msg.sender;
    }

    function initiateDapp(IERC20 token_) external onlyOwner {
        token = token_;
        super.renounceOwnership();
    }

    function stake(address staker, uint amount) external onlyToken {
        require(amount > 0, "Amount must be greater than zero");
        Share memory share = shares[staker];
        updateShare(staker, share, share.tokenStaked + amount, true);
    }

    function withdrawToken() external nonReentrant {
        Share memory share = shares[msg.sender];
        require(share.tokenStaked > 0, "No initial deposit");
        require(
            share.stakingTime + 1 weeks < block.timestamp,
            "withdraw after one week"
        );
        token.transfer(msg.sender, share.tokenStaked);
        updateShare(msg.sender, share, 0, true);
    }

    function claimETH() external nonReentrant {
        Share memory share = shares[msg.sender];
        require(share.tokenStaked > 0, "No initial deposit");
        updateShare(msg.sender, share, share.tokenStaked, false);
    }

    function updateShare(
        address staker,
        Share memory share,
        uint newAmount,
        bool resetTimer
    ) private {
        uint gains;
        if (share.tokenStaked != 0)
            gains = (share.tokenStaked * (sumETH - share.sumETH)) / DECIMAL;

        if (newAmount == 0) delete shares[staker];
        else if (resetTimer)
            shares[staker] = Share(block.timestamp, newAmount, sumETH);
        else shares[staker] = Share(share.stakingTime, newAmount, sumETH);

        if (gains > 0) Address.sendValue(payable(staker), gains);
    }

    function pendingETH(address staker) external view returns (uint) {
        Share memory share = shares[staker];
        return (share.tokenStaked * (sumETH - share.sumETH)) / DECIMAL;
    }

    receive() external payable {
        if (msg.value == 0) return;

        uint balance = token.balanceOf(address(this));
        if (balance == 0)
            return Address.sendValue(payable(_taxWallet), msg.value);

        uint amount = msg.value / 2;
        uint profit = (amount * DECIMAL) / balance;
        sumETH += profit;
        totalETH += amount;

        uint taxAmount = msg.value - amount;
        if (taxAmount > 0) Address.sendValue(payable(_taxWallet), taxAmount);
    }
}
