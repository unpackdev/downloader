pragma solidity 0.5.16;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./IUniswapV2Router01.sol";
import "./BasisPoints.sol";
import "./LidSimplifiedPresaleTimer.sol";
import "./LidSimplifiedPresaleRedeemer.sol";
import "./LidSimplifiedPresaleAccess.sol";


contract LidSimplifiedPresale is Initializable, Ownable, ReentrancyGuard, Pausable {
    using BasisPoints for uint;
    using SafeMath for uint;

    uint public maxBuyPerAddress;

    uint public uniswapEthBP;
    uint public lidEthBP;

    uint public uniswapTokenBP;
    uint public presaleTokenBP;
    address[] public tokenPools;
    uint[] public tokenPoolBPs;

    uint public hardcap;
    uint public totalTokens;

    bool public hasSentToUniswap;
    bool public hasIssuedTokens;

    uint public finalEndTime;
    uint public finalEth;

    IERC20 private token;
    IUniswapV2Router01 private uniswapRouter;
    LidSimplifiedPresaleTimer private timer;
    LidSimplifiedPresaleRedeemer private redeemer;
    LidSimplifiedPresaleAccess private access;
    address payable private lidFund;

    mapping(address => uint) public earnedReferrals;

    mapping(address => uint) public referralCounts;

    mapping(address => uint) public refundedEth;

    bool public isRefunding;

    modifier whenPresaleActive {
        require(timer.isStarted(), "Presale not yet started.");
        require(!isPresaleEnded(), "Presale has ended.");
        _;
    }

    modifier whenPresaleFinished {
        require(timer.isStarted(), "Presale not yet started.");
        require(isPresaleEnded(), "Presale has not yet ended.");
        _;
    }

    function initialize(
        uint _maxBuyPerAddress,
        uint _uniswapEthBP,
        uint _lidEthBP,
        uint _hardcap,
        address owner,
        LidSimplifiedPresaleTimer _timer,
        LidSimplifiedPresaleRedeemer _redeemer,
        LidSimplifiedPresaleAccess _access,
        IERC20 _token,
        IUniswapV2Router01 _uniswapRouter,
        address payable _lidFund
    ) external initializer {
        Ownable.initialize(msg.sender);
        Pausable.initialize(msg.sender);
        ReentrancyGuard.initialize();

        token = _token;
        timer = _timer;
        redeemer = _redeemer;
        access = _access;
        lidFund = _lidFund;

        maxBuyPerAddress = _maxBuyPerAddress;

        uniswapEthBP = _uniswapEthBP;
        lidEthBP = _lidEthBP;

        hardcap = _hardcap;

        uniswapRouter = _uniswapRouter;
        totalTokens = token.totalSupply();
        token.approve(address(uniswapRouter), token.totalSupply());

        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function deposit() external payable whenNotPaused {
        deposit(address(0x0));
    }

    function setTokenPools(
        uint _uniswapTokenBP,
        uint _presaleTokenBP,
        address[] calldata _tokenPools,
        uint[] calldata _tokenPoolBPs
    ) external onlyOwner whenNotPaused {
        require(_tokenPools.length == _tokenPoolBPs.length, "Must have exactly one tokenPool addresses for each BP.");
        delete tokenPools;
        delete tokenPoolBPs;
        uniswapTokenBP = _uniswapTokenBP;
        presaleTokenBP = _presaleTokenBP;
        for (uint i = 0; i < _tokenPools.length; ++i) {
            tokenPools.push(_tokenPools[i]);
        }
        uint totalTokenPoolBPs = uniswapTokenBP.add(presaleTokenBP);
        for (uint i = 0; i < _tokenPoolBPs.length; ++i) {
            tokenPoolBPs.push(_tokenPoolBPs[i]);
            totalTokenPoolBPs = totalTokenPoolBPs.add(_tokenPoolBPs[i]);
        }
        require(totalTokenPoolBPs == 10000, "Must allocate exactly 100% (10000 BP) of tokens to pools");
    }

    function sendToUniswap() external whenPresaleFinished nonReentrant whenNotPaused {
        require(msg.sender == tx.origin, "Sender must be origin - no contract calls.");
        require(tokenPools.length > 0, "Must have set token pools");
        require(!hasSentToUniswap, "Has already sent to Uniswap.");
        finalEndTime = now;
        finalEth = address(this).balance;
        hasSentToUniswap = true;
        uint uniswapTokens = totalTokens.mulBP(uniswapTokenBP);
        uint uniswapEth = finalEth.mulBP(uniswapEthBP);
        uniswapRouter.addLiquidityETH.value(uniswapEth)(
            address(token),
            uniswapTokens,
            uniswapTokens,
            uniswapEth,
            address(0x000000000000000000000000000000000000dEaD),
            now
        );
    }

    function issueTokens() external whenPresaleFinished whenNotPaused {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        require(!hasIssuedTokens, "Has already issued tokens.");
        hasIssuedTokens = true;
        uint last = tokenPools.length.sub(1);
        for (uint i = 0; i < last; ++i) {
            token.transfer(
                tokenPools[i],
                totalTokens.mulBP(tokenPoolBPs[i])
            );
        }
        // in case rounding error, send all to final
        token.transfer(
            tokenPools[last],
            totalTokens.mulBP(tokenPoolBPs[last])
        );
    }

    function releaseEthToAddress(address payable receiver, uint amount) external onlyOwner whenNotPaused returns(uint) {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        receiver.transfer(amount);
    }

    function redeem() external whenPresaleFinished whenNotPaused {
        require(hasSentToUniswap, "Must have sent to Uniswap before any redeems.");
        uint claimable = redeemer.calculateReedemable(msg.sender, finalEndTime, totalTokens.mulBP(presaleTokenBP));
        redeemer.setClaimed(msg.sender, claimable);
        token.transfer(msg.sender, claimable);
    }

    function startRefund() external onlyOwner {
        _startRefund();
    }

    function claimRefund(address payable account) external whenPaused {
        require(isRefunding, "Refunds not active");
        uint refundAmt = getRefundableEth(account);
        require(refundAmt > 0, "Nothing to refund");
        refundedEth[account] = refundedEth[account].add(refundAmt);
        account.transfer(refundAmt);
    }

    function updateHardcap(uint valueWei) external onlyOwner {
        hardcap = valueWei;
    }

    function updateMaxBuy(uint valueWei) external onlyOwner {
        maxBuyPerAddress = valueWei;
    }

    function updateEthBP(uint _uniswapEthBP, uint _lidEthBP) external onlyOwner {
        uniswapEthBP = _uniswapEthBP;
        lidEthBP = _lidEthBP;
    }

    function deposit(address payable referrer) public payable nonReentrant whenNotPaused {
        require(timer.isStarted(), "Presale not yet started.");
        require(now >= access.getAccessTime(msg.sender, timer.startTime()), "Time must be at least access time.");
        require(msg.sender != referrer, "Sender cannot be referrer.");
        require(address(this).balance.sub(msg.value) <= hardcap, "Cannot deposit more than hardcap.");
        require(!hasSentToUniswap, "Presale Ended, Uniswap has been called.");
        uint endTime = timer.endTime();
        require(!(now > endTime && endTime != 0), "Presale Ended, time over limit.");
        require(
            redeemer.accountDeposits(msg.sender).add(msg.value) <= maxBuyPerAddress,
            "Deposit exceeds max buy per address."
        );
        bool _isRefunding = timer.updateRefunding();
        if(_isRefunding) {
            _startRefund();
            return;
        }
        uint depositEther = msg.value;
        uint excess = 0;

        //Refund eth in case final purchase needed to end sale without dust errors
        if (address(this).balance > hardcap) {
            excess = address(this).balance.sub(hardcap);
            depositEther = depositEther.sub(excess);
        }

        redeemer.setDeposit(msg.sender, depositEther);

        if (excess != 0) {
            msg.sender.transfer(excess);
        }
    }

    function getRefundableEth(address account) public view returns (uint) {
        if (!isRefunding) return 0;

        return redeemer.accountDeposits(account)
            .sub(refundedEth[account]);
    }

    function isPresaleEnded() public view returns (bool) {
        uint endTime =  timer.endTime();
        if (hasSentToUniswap) return true;
        return (
            (address(this).balance >= hardcap) ||
            (timer.isStarted() && (now > endTime && endTime != 0))
        );
    }

    function _startRefund() internal {
        //TODO: Automatically start refund after timer is passed for softcap reach
        pause();
        isRefunding = true;
    }

}
