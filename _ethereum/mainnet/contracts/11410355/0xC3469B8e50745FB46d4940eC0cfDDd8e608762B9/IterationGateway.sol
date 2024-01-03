pragma solidity =0.6.8;

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

import "./TransferHelper.sol";
import "./ICoupons.sol";

import "./Refill.sol";
import "./Tickets.sol";

contract IterationGateway {
    using SafeMath for uint256;    
    
    event Sunk(uint256 amount, address indexed token, address indexed owner);    
    
    address public admin;
    address public weth;
    address public its;
    address payable public shareHolders;

    Refill refill;
    Tickets tickets;
    IUniswapV2Factory factory;
    IUniswapV2Router02 router;
    
    uint public minimumETHPair;
    uint256 public maxSink = 1000 ether;
    uint256 public minSink = 1000;
    
    //Do stuff when you receieve ETH in the SINK
    receive () external payable {}
    
    constructor(address _its, address _factory, address _router) public {
        admin = msg.sender;
        factory = IUniswapV2Factory(_factory);
        router = IUniswapV2Router02(_router);
        weth = router.WETH();
        refill = new Refill(_its, _router, weth);
        shareHolders = payable(address(refill));
        its = _its;
        minimumETHPair = 10 ether;
        tickets = new Tickets(0);
    }

    function setRouter(address _router) external {
        require(msg.sender == admin, "You're not the admin.");
        router = IUniswapV2Router02(_router);
    }

    function setMinimumEth(uint256 _amount) external {
        require(msg.sender == admin, "You're not the admin.");
        minimumETHPair = _amount;
    }
    function setRefillInverval(uint256 _interval) external {
        require(msg.sender == admin, "You're not the admin.");
        refill.setRefillInverval(_interval);
    }

    function setCallerRewardDivisor(uint256 _divisor) external {
        require(msg.sender == admin, "You're not the admin.");
        require(_divisor > 0);
        refill.setCallerRewardDivisor(_divisor);
    }
    
    function setItsBalance(uint256 _balance) external {
        require(msg.sender == admin, "You're not the admin.");        
        refill.setItsBalance(_balance);
    }

    function balanceOf(address _token) public view returns(uint) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    }

    function sinkToken(uint256 _amount, address _token) external {
        require(_amount > minSink, 'INSUFFICENT_INPUT_AMOUNT');
        require(_amount < maxSink, 'EXCECSIVE_INPUT_AMOUNT');
        require(_token != address(tickets), 'YOU WILL PLUG THE SINK');

        (, uint112 tokenWeth, ) = IUniswapV2Pair(factory.getPair(weth, _token)).getReserves();
        require(tokenWeth >= minimumETHPair, "INSUFFICENTLY_PAIRED_ETHER");

        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
        TransferHelper.safeApprove(_token, address(router), _amount);
        
        uint [] memory amounts = router.swapExactTokensForETH(
                                            _amount,
                                            1,
                                            getSalePath(_token),
                                            address(this),
                                            block.timestamp
                                        );

        (bool sent, ) = shareHolders.call.value(amounts[1] / 10)("");
        require(sent, "FAILED_ETH_ITS_DEPOSIT");
        router.swapExactETHForTokens.value(amounts[1].sub((amounts[1] / 5)))(
                                            1,
                                            getITSPath(),
                                            address(this),
                                            block.timestamp
                                        );
        (sent, ) = address(tickets).call.value(address(this).balance)("");
        require(sent, "FAILED_ETH_CPN_DEPOSIT");        
        uint256 actualAmounts = IERC20(its).balanceOf(address(this));
        uint256 reward = calculateCoupons(amounts[1], IERC20(its).balanceOf(address(tickets)) / 1 ether);
        TransferHelper.safeApprove(its, address(tickets), actualAmounts);
        tickets.fillPool(actualAmounts, its);
        tickets.mint(msg.sender, reward);
        emit Sunk(_amount, _token, msg.sender);
    }

    function getEstimatedETH(address _token, uint256 _amount) external view returns (uint256[] memory){
        return router.getAmountsOut(_amount, getSalePath(_token));
    }

    /* Coupon values will increase as more tokens are pooled.
     * The most expensive will be 1 Coupon == 2 ether.
     * With nothing in the pool, Coupons are worth 50 Coupons == 1 ether
     */
    function calculateCoupons(uint256 _ethAmount, uint256 _curve) public pure returns(uint256) {
        uint256 base = 100;
        _ethAmount = _ethAmount / 2;
        _curve = _curve >= base ? 99 : _curve; 
        base = _ethAmount.mul(base.sub(_curve));
        return base;
    }

    function percent(uint256 perc, uint256 whole) private pure returns(uint256) {
        uint256 a = (whole / 1000).mul(perc) ;
        return a;
    }

    function getSalePath(address _token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = weth;
        return path;
    }

    function getITSPath() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = its;
        return path;
    }
}
