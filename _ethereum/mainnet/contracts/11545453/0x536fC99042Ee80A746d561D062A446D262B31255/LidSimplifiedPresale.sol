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

contract LidSimplifiedPresale is
    Initializable,
    Ownable,
    ReentrancyGuard,
    Pausable
{
    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public maxBuyPerAddress;

    uint256 public uniswapEthBP;
    address[] public ethPools;
    uint256[] public ethPoolBPs;

    uint256 public uniswapTokenBP;
    uint256 public presaleTokenBP;
    address[] public tokenPools;
    uint256[] public tokenPoolBPs;

    uint256 public hardcap;
    uint256 public totalTokens;

    bool public hasSentToUniswap;
    bool public hasIssuedTokens;
    bool public hasIssuedEths;

    uint256 public finalEndTime;
    uint256 public finalEth;

    IERC20 private token;
    IUniswapV2Router01 private uniswapRouter;
    LidSimplifiedPresaleTimer private timer;
    LidSimplifiedPresaleRedeemer private redeemer;
    LidSimplifiedPresaleAccess private access;

    mapping(address => uint256) public earnedReferrals;

    mapping(address => uint256) public referralCounts;

    mapping(address => uint256) public refundedEth;

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
        uint256 _maxBuyPerAddress,
        uint256 _hardcap,
        address owner,
        LidSimplifiedPresaleTimer _timer,
        LidSimplifiedPresaleRedeemer _redeemer,
        LidSimplifiedPresaleAccess _access,
        IERC20 _token,
        IUniswapV2Router01 _uniswapRouter
    ) external initializer {
        Ownable.initialize(msg.sender);
        Pausable.initialize(msg.sender);
        ReentrancyGuard.initialize();

        token = _token;
        timer = _timer;
        redeemer = _redeemer;
        access = _access;
        uniswapRouter = _uniswapRouter;

        hardcap = _hardcap;
        maxBuyPerAddress = _maxBuyPerAddress;

        totalTokens = token.totalSupply();
        token.approve(address(uniswapRouter), token.totalSupply());

        //Due to issue in oz testing suite, the msg.sender might not be owner
        _transferOwnership(owner);
    }

    function deposit() external payable whenNotPaused {
        deposit(address(0x0));
    }

    function setEthPools(
        uint256 _uniswapEthBP,
        address[] calldata _ethPools,
        uint256[] calldata _ethPoolBPs
    ) external onlyOwner whenNotPaused {
        require(
            _ethPools.length == _ethPoolBPs.length,
            "Must have exactly one tokenPool addresses for each BP."
        );
        delete ethPools;
        delete ethPoolBPs;
        uniswapEthBP = _uniswapEthBP;
        for (uint256 i = 0; i < _ethPools.length; ++i) {
            ethPools.push(_ethPools[i]);
        }

        uint256 totalEthPoolBPs = uniswapEthBP;
        for (uint256 i = 0; i < _ethPoolBPs.length; ++i) {
            ethPoolBPs.push(_ethPoolBPs[i]);
            totalEthPoolBPs = totalEthPoolBPs.add(_ethPoolBPs[i]);
        }
        require(
            totalEthPoolBPs == 10000,
            "Must allocate exactly 100% (10000 BP) of eths to pools"
        );
    }

    function setTokenPools(
        uint256 _uniswapTokenBP,
        uint256 _presaleTokenBP,
        address[] calldata _tokenPools,
        uint256[] calldata _tokenPoolBPs
    ) external onlyOwner whenNotPaused {
        require(
            _tokenPools.length == _tokenPoolBPs.length,
            "Must have exactly one tokenPool addresses for each BP."
        );
        delete tokenPools;
        delete tokenPoolBPs;
        uniswapTokenBP = _uniswapTokenBP;
        presaleTokenBP = _presaleTokenBP;
        for (uint256 i = 0; i < _tokenPools.length; ++i) {
            tokenPools.push(_tokenPools[i]);
        }
        uint256 totalTokenPoolBPs = uniswapTokenBP.add(presaleTokenBP);
        for (uint256 i = 0; i < _tokenPoolBPs.length; ++i) {
            tokenPoolBPs.push(_tokenPoolBPs[i]);
            totalTokenPoolBPs = totalTokenPoolBPs.add(_tokenPoolBPs[i]);
        }
        require(
            totalTokenPoolBPs == 10000,
            "Must allocate exactly 100% (10000 BP) of tokens to pools"
        );
    }

    function sendToUniswap()
        external
        whenPresaleFinished
        nonReentrant
        whenNotPaused
    {
        require(
            msg.sender == tx.origin,
            "Sender must be origin - no contract calls."
        );
        require(tokenPools.length > 0, "Must have set token pools");
        require(!hasSentToUniswap, "Has already sent to Uniswap.");
        finalEndTime = now;
        finalEth = address(this).balance;
        hasSentToUniswap = true;
        uint256 uniswapTokens = totalTokens.mulBP(uniswapTokenBP);
        uint256 uniswapEth = finalEth.mulBP(uniswapEthBP);
        uniswapRouter.addLiquidityETH.value(uniswapEth)(
            address(token),
            uniswapTokens,
            uniswapTokens,
            uniswapEth,
            address(0x000000000000000000000000000000000000dEaD),
            now
        );
    }

    function issueEths() external whenPresaleFinished whenNotPaused {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        require(!hasIssuedEths, "Has already issued eths.");
        hasIssuedEths = true;
        uint256 last = ethPools.length.sub(1);
        for (uint256 i = 0; i < last; ++i) {
            address payable poolAddress = address(uint160(ethPools[i]));
            poolAddress.transfer(finalEth.mulBP(ethPoolBPs[i]));
        }

        // in case rounding error, send all to final
        address payable poolAddress = address(uint160(ethPools[last]));
        poolAddress.transfer(finalEth.mulBP(ethPoolBPs[last]));
    }

    function issueTokens() external whenPresaleFinished whenNotPaused {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        require(!hasIssuedTokens, "Has already issued tokens.");
        hasIssuedTokens = true;
        uint256 last = tokenPools.length.sub(1);
        for (uint256 i = 0; i < last; ++i) {
            token.transfer(tokenPools[i], totalTokens.mulBP(tokenPoolBPs[i]));
        }
        // in case rounding error, send all to final
        token.transfer(tokenPools[last], totalTokens.mulBP(tokenPoolBPs[last]));
    }

    function releaseEthToAddress(address payable receiver, uint256 amount)
        external
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        require(hasSentToUniswap, "Has not yet sent to Uniswap.");
        receiver.transfer(amount);
    }

    function recoverTokens(address _receiver) external onlyOwner {
        require(isRefunding, "Refunds not active");
        token.transfer(_receiver, token.balanceOf(address(this)));
    }

    function redeem() external whenPresaleFinished whenNotPaused {
        require(
            hasSentToUniswap,
            "Must have sent to Uniswap before any redeems."
        );
        uint256 claimable = redeemer.calculateReedemable(
            msg.sender,
            finalEndTime,
            totalTokens.mulBP(presaleTokenBP)
        );
        redeemer.setClaimed(msg.sender, claimable);
        token.transfer(msg.sender, claimable);
    }

    function startRefund() external onlyOwner {
        _startRefund();
    }

    function claimRefund(address payable account) external whenPaused {
        require(isRefunding, "Refunds not active");
        uint256 refundAmt = getRefundableEth(account);
        require(refundAmt > 0, "Nothing to refund");
        refundedEth[account] = refundedEth[account].add(refundAmt);
        account.transfer(refundAmt);
    }

    function updateHardcap(uint256 valueWei) external onlyOwner {
        hardcap = valueWei;
    }

    function updateMaxBuy(uint256 valueWei) external onlyOwner {
        maxBuyPerAddress = valueWei;
    }

    function deposit(address payable referrer)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        require(timer.isStarted(), "Presale not yet started.");
        require(
            now >= access.getAccessTime(msg.sender, timer.startTime()),
            "Time must be at least access time."
        );
        require(msg.sender != referrer, "Sender cannot be referrer.");
        require(
            address(this).balance.sub(msg.value) <= hardcap,
            "Cannot deposit more than hardcap."
        );
        require(!hasSentToUniswap, "Presale Ended, Uniswap has been called.");
        uint256 endTime = timer.endTime();
        require(
            !(now > endTime && endTime != 0),
            "Presale Ended, time over limit."
        );
        require(
            redeemer.accountDeposits(msg.sender).add(msg.value) <=
                maxBuyPerAddress,
            "Deposit exceeds max buy per address."
        );
        bool _isRefunding = timer.updateRefunding();
        if (_isRefunding) {
            _startRefund();
            return;
        }
        uint256 depositEther = msg.value;
        uint256 excess = 0;

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

    function getRefundableEth(address account) public view returns (uint256) {
        if (!isRefunding) return 0;

        return redeemer.accountDeposits(account).sub(refundedEth[account]);
    }

    function isPresaleEnded() public view returns (bool) {
        uint256 endTime = timer.endTime();
        if (hasSentToUniswap) return true;
        return ((address(this).balance >= hardcap) ||
            (timer.isStarted() && (now > endTime && endTime != 0)));
    }

    function _startRefund() internal {
        //TODO: Automatically start refund after timer is passed for softcap reach
        pause();
        isRefunding = true;
    }
}
