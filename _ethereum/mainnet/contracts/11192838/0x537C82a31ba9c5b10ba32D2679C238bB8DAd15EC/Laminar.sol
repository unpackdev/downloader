// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IDEE.sol";
import "./Fountain.sol";


contract Laminar is ReentrancyGuard, Ownable {

    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    event Staked(address indexed from, address indexed referral, uint256 amountETH, uint256 amountLP);
    event Withdrawn(address indexed to, uint256 amountETH, uint256 amountLP);
    event Claimed(address indexed to, uint256 amount);
    event Halving(uint256 amount);
    event Received(address indexed from, uint256 amount);

    Fountain public token;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public weth;
    address payable public treasury;
    address payable public shareHolders;
    address public pairAddress;

    struct AccountInfo {
        // Staked LP token balance
        uint256 balance;
        uint256 peakBalance;
        uint256 withdrawTimestamp;
        uint256 reward;
        uint256 rewardPerTokenPaid;
    }
    mapping(address => AccountInfo) public accountInfos;

    // Staked LP token total supply
    uint256 private _totalSupply = 0;

    uint256 public constant HALVING_DURATION = 7 days;
    uint256 public rewardAllocation = 3750 * 1e18;
    uint256 public halvingTimestamp = 0;
    uint256 public lastUpdateTimestamp = 0;

    uint256 public rewardRate = 0;
    uint256 public rewardPerTokenStored = 0;

    // Farming will be open on this timestamp
    // Thursday, November 5, 2020 2:00:00 AM
    uint256 public farmingStartTimestamp = 1604541600;
    bool public farmingStarted = false;

    // Max 10% / day LP withdraw
    uint256 public constant WITHDRAW_LIMIT = 10;

    // Burn address
    address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Dev decided to launch without whitelist but since it has been coded and tested, so dev will be leave it here.
    // Whitelisted address
    mapping (address => bool) public whitelists;
    // Whitelist deposited balance
    mapping (address => uint256) public whitelistBalance;
    // End period for whitelist advantage
    uint256 public whitelistEndTimestamp = 0;
    // Max stake for whitelist
    uint256 public constant WHITELIST_STAKE_LIMIT = 3 ether;
    // Whitelist advantage duration (reduced to 1 minutes since we dont have whitelist)
    uint256 public constant WHITELIST_DURATION = 1 minutes;

    struct Fees {
        uint8 dev;
        uint8 ref;
        uint8 shares;
    }

    Fees public hotRef;
    Fees public coldRef;

    constructor(address _routerAddress, address[] memory _whitelists, address payable _shareHolders) public {
        router = IUniswapV2Router02(_routerAddress);
        factory = IUniswapV2Factory(router.factory());
        weth = router.WETH();
        treasury = msg.sender;
        shareHolders = _shareHolders;

        hotRef.dev = 35;
        hotRef.ref = 25;
        hotRef.shares = 15;

        coldRef.dev = 85;
        coldRef.ref = 0;
        coldRef.shares = 15;

        // Calc reward rate
        rewardRate = rewardAllocation.div(HALVING_DURATION);

        // Init whitelist
        _setupWhitelists(_whitelists);
        whitelistEndTimestamp = farmingStartTimestamp.add(WHITELIST_DURATION);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setMintable(address _token) external onlyOwner {
        require(address(token) == address(0), "Only Once");
        token = Fountain(_token);
        pairAddress = factory.createPair(_token, weth);
    }

    function stake(address payable _referral) external payable nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        _halving();

        require(msg.value > 0, 'Cannot stake 0');
        require(!address(msg.sender).isContract(), 'Please use your individual account');

        uint256 amount = msg.value.sub(_allocateFees(_referral));

        uint256 ethAmount = IERC20(weth).balanceOf(pairAddress);
        uint256 tokenAmount = token.balanceOf(pairAddress);

        // If eth amount = 0 then set initial price to 1 eth = 2 nami
        uint256 amountTokenDesired = ethAmount == 0 ? (amount * 5) : amount.mul(tokenAmount).div(ethAmount);
        // Mint borrowed nami
        token.mint(address(this), amountTokenDesired);

        // Add liquidity in uniswap
        uint256 amountETHDesired = amount;
        token.approve(address(router), amountTokenDesired);
        (,, uint256 liquidity) = router.addLiquidityETH{value : amountETHDesired}(address(token), amountTokenDesired, 1, 1, address(this), block.timestamp + 1 days);

        // Add LP token to total supply
        _totalSupply = _totalSupply.add(liquidity);

        // Add to balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.add(liquidity);
        // Set peak balance
        if (accountInfos[msg.sender].balance > accountInfos[msg.sender].peakBalance) {
            accountInfos[msg.sender].peakBalance = accountInfos[msg.sender].balance;
        }

        // Set stake timestamp as withdraw timestamp
        // to prevent withdraw immediately after first staking
        if (accountInfos[msg.sender].withdrawTimestamp == 0) {
            accountInfos[msg.sender].withdrawTimestamp = block.timestamp;
        }
        whitelists[msg.sender] = true;
        emit Staked(msg.sender, _referral, msg.value, liquidity);
    }

    function withdraw() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        _halving();

        require(accountInfos[msg.sender].withdrawTimestamp + 1 days <= block.timestamp, 'You must wait 1 day since your last withdraw or stake');
        require(accountInfos[msg.sender].balance > 0, 'Cannot withdraw 0');

        // Limit withdraw LP token
        uint256 amount = accountInfos[msg.sender].peakBalance.div(WITHDRAW_LIMIT);
        if (accountInfos[msg.sender].balance < amount) {
            amount = accountInfos[msg.sender].balance;
        }

        // Reduce total supply
        _totalSupply = _totalSupply.sub(amount);
        // Reduce balance
        accountInfos[msg.sender].balance = accountInfos[msg.sender].balance.sub(amount);
        // Set timestamp
        accountInfos[msg.sender].withdrawTimestamp = block.timestamp;

        // Remove liquidity in uniswap
        IERC20(pairAddress).approve(address(router), amount);
        (uint256 tokenAmount, uint256 ethAmount) = router.removeLiquidity(address(token), weth, amount, 0, 0, address(this), block.timestamp + 1 days);

        // Burn borrowed nami
        token.burn(address(this), tokenAmount);
        // Withdraw ETH and send to sender
        IWETH(weth).withdraw(ethAmount);
        msg.sender.transfer(ethAmount);

        emit Withdrawn(msg.sender, ethAmount, amount);
    }

    function claim() external nonReentrant {
        _checkFarming();
        _updateReward(msg.sender);
        _halving();

        uint256 reward = accountInfos[msg.sender].reward;
        require(reward > 0, 'There is no reward to claim');

        if (reward > 0) {
            // Reduce first
            accountInfos[msg.sender].reward = 0;
            // Apply tax
            uint256 taxDenominator = claimTaxDenominator();
            uint256 tax = taxDenominator > 0 ? reward.div(taxDenominator) : 0;
            uint256 net = reward.sub(tax);

            // Send reward
            token.mint(msg.sender, net);
            if (tax > 0) {
                // Burn taxed token
                token.mint(address(shareHolders), tax);
                IDEE(shareHolders).addPendingTokenRewards(tax, address(token));
            }

            emit Claimed(msg.sender, reward);
        }
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return accountInfos[account].balance;
    }

    function burnedTokenAmount() public view returns (uint256) {
        return token.balanceOf(BURN_ADDRESS);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored
        .add(
            lastRewardTimestamp()
            .sub(lastUpdateTimestamp)
            .mul(rewardRate)
            .mul(1e18)
            .div(_totalSupply)
        );
    }

    function lastRewardTimestamp() public view returns (uint256) {
        return Math.min(block.timestamp, halvingTimestamp);
    }

    function rewardEarned(address account) public view returns (uint256) {
        return accountInfos[account].balance.mul(
            rewardPerToken().sub(accountInfos[account].rewardPerTokenPaid)
        )
        .div(1e18)
        .add(accountInfos[account].reward);
    }

    // Token price in eth
    function tokenPrice() public view returns (uint256) {
        uint256 ethAmount = IERC20(weth).balanceOf(pairAddress);
        uint256 tokenAmount = IERC20(token).balanceOf(pairAddress);
        return tokenAmount > 0 ?
        // Current price
        ethAmount.mul(1e18).div(tokenAmount) :
        // Initial price
        (uint256(1e18).div(2));
    }

    function claimTaxDenominator() public view returns (uint256) {
        if (block.timestamp < farmingStartTimestamp + 1 days) {
            return 4;
        } else if (block.timestamp < farmingStartTimestamp + 2 days) {
            return 5;
        } else if (block.timestamp < farmingStartTimestamp + 3 days) {
            return 10;
        } else if (block.timestamp < farmingStartTimestamp + 4 days) {
            return 20;
        } else {
            return 0;
        }
    }

    function _updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTimestamp = lastRewardTimestamp();
        if (account != address(0)) {
            accountInfos[account].reward = rewardEarned(account);
            accountInfos[account].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    // Do halving when timestamp reached
    function _halving() internal {
        if (block.timestamp >= halvingTimestamp) {
            rewardAllocation = rewardAllocation.div(2);

            rewardRate = rewardAllocation.div(HALVING_DURATION);
            halvingTimestamp = halvingTimestamp.add(HALVING_DURATION);

            _updateReward(msg.sender);
            emit Halving(rewardAllocation);
        }
    }

    // Check if farming is started
    function _checkFarming() internal {
        require(farmingStartTimestamp <= block.timestamp, 'Please wait until farming started');
        if (!farmingStarted) {
            farmingStarted = true;
            halvingTimestamp = block.timestamp.add(HALVING_DURATION);
            lastUpdateTimestamp = block.timestamp;
        }
    }

    function _setupWhitelists(address[] memory addresses) internal {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelists[addresses[i]] = true;
        }
    }

    function _allocateFees(address payable _referral) internal returns(uint256) {
        if(msg.value < 1000) return 0;
        Fees memory active = hotRef;
        if(_referral == address(0) || !whitelists[_referral]) active = coldRef;
        uint256 forDev = percent(active.dev, msg.value);
        uint256 forRef = percent(active.ref, msg.value);
        uint256 forShares = percent(active.shares, msg.value);
        IDEE(shareHolders).addPendingETHRewards{value: forShares}();
        treasury.transfer(forDev);
        if(forRef > 0) _referral.transfer(forRef);
        return forDev.add(forRef).add(forShares);
    }

    function percent(uint256 perc, uint256 whole) private pure returns(uint256) {
        uint256 a = (whole / 1000).mul(perc);
        return a;
    }    
}