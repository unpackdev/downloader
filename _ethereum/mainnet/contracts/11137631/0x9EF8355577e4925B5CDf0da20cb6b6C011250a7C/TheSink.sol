pragma solidity =0.6.6;

import "./UniswapV2Library.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

import "./TransferHelper.sol";
import "./ICoupons.sol";
import "./IDEE.sol";

contract TheSink {
    using SafeMath for uint256;    
    bool public couponsSet;
    address public admin;
    address public weth;
    address payable public coupon;
    address payable public shareHolders;

    uint256 public maxSink = 1000 ether;
    uint256 public minSink = 1000;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    
    event Sunk(uint256 amount, address indexed token, address indexed owner);
    //Setting anythting in here could cause the contract to become unusable.
    //An internal call in swapExactTokensForETH does not forward gas
    receive () external payable {}
    
    constructor(address _factory, address _router, address payable _shareHolders) public {
        admin = msg.sender;
        factory = IUniswapV2Factory(_factory);
        router = IUniswapV2Router02(_router);
        weth = router.WETH();
        shareHolders = _shareHolders;
    }

    function setCoupon(address payable _coupon) external {
        require(msg.sender == this.admin(), "You're not the admin.");
        require(coupon == address(0), 'It can only be set once.');
        coupon = _coupon;
    }

    function setRouter(address _router) external {
        require(msg.sender == this.admin(), "You're not the admin.");
        router = IUniswapV2Router02(_router);
    }

    function balanceOf(address _token) public view returns(uint) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    }

    /*
     * This functiton will take the _amount sent from _token
       Sell 40% for ETH and of which 75% is sent to Coupons to seed the next round.
       Ramainder (10% of whole) sent to shareHolders
       50% is sent to Coupons to be put into The Pool
       Remaining 10% is left in the contract never to be moved.
     */
    function sinkToken(uint256 _amount, address _token) external {
        require(_amount > minSink, 'INSUFFICENT_INPUT_AMOUNT');
        require(_amount < maxSink, 'EXCECSIVE_INPUT_AMOUNT');
        require(_token != coupon, 'YOU WILL PLUG THE SINK');

        (, uint112 tokenWeth, ) = IUniswapV2Pair(factory.getPair(weth, _token)).getReserves();
        require(tokenWeth >= 10 ether, "INSUFFICENTLY_PAIRED_ETHER");

        ICoupons _coupon = ICoupons(coupon);
        uint256 toSwap = percent(400, _amount);

        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _amount);
        TransferHelper.safeApprove(_token, address(router), toSwap);
        
        uint [] memory amounts = router.swapExactTokensForETH(
                                            toSwap,
                                            getEstimatedETH(_token, toSwap)[1],
                                            getSalePath(_token),
                                            address(this),
                                            block.timestamp
                                        );
        uint256 dump = percent(500, _amount);
        IDEE(shareHolders).addPendingETHRewards.value(amounts[1] / 4)();
        (bool sent, ) = coupon.call.value(address(this).balance)("");
        require(sent, "FAILED_ETH_CPN_DEPOSIT");

        TransferHelper.safeApprove(_token, coupon, dump);
        _coupon.fillPool(dump, _token);
        _coupon.mint(msg.sender, calculateCoupons(amounts[1], _coupon.poolSize()));
        emit Sunk(_amount, _token, msg.sender);
    }
    /* Coupon values will increase as more tokens are pooled.
     * The most expensive will be 1 Coupon == 2 ether.
     * With nothing in the pool, Coupons are worth 50 Coupons == 1 ether
     */
    function calculateCoupons(uint256 _ethAmount, uint256 _curve) public pure returns(uint256) {
        uint256 base = 100;
        if(_curve >= 100)
            _curve = 99;
        base = _ethAmount.mul(base.sub(_curve));
        return base;
    }

    function getEstimatedETH(address _token, uint256 _amount) public view returns (uint256[] memory){
        return router.getAmountsOut(_amount, getSalePath(_token));
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

    function getCouponPath() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = coupon;        
        return path;
    }    

}
