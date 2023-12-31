// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


interface ITetherUSDTERC20 {

    function balanceOf(address who) external  returns (uint);

    function transfer(address to, uint value) external ;

    function allowance(address owner, address spender) external  returns (uint);

    function transferFrom(address from, address to, uint value) external;

    function approve(address spender, uint value) external;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}



interface IPancakeSwapRouter {

    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

}

contract IEO {

    //路由
    IPancakeSwapRouter public router;

    using SafeMath for uint;

    address  public admin;

    ITetherUSDTERC20 public USDT;

    IERC20 public ROBOT;

    //质押
    event Pledge(uint ,address, address, uint);
    //领取
    event CLaim(address,uint256);

    bool initialized;

    //全网限额(USDT)
    uint256 public  PLAT_TOTAL;
    //个人限额(ETH)
    uint256 public SINGLE_MAX;
    //单价 18wei
    uint256 public ROBOT_PRICE;

    //质押数量换算ROBOT
    mapping (address =>uint256) public   totalRobot;

    //已质押折合USDT总和
    mapping (address=>uint256) public totalUSDT;

    //全网已质押总和（USDT）
    uint256 public finish;

    //结束时间
    uint256 public endTime;



    modifier onlyAdmin {
        require(msg.sender == admin, "You Are not admin");
        _;
    }


    constructor(){

        admin = msg.sender;

        USDT = ITetherUSDTERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

        router=IPancakeSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        //全网限额（USDT）
        PLAT_TOTAL=3500000 * 10 **6;
        //个人限额（ETH）
        SINGLE_MAX=1*10**18;
        //18wei
        ROBOT_PRICE=500000000;

        endTime=1697299200;

    }

    //设置管理员
    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    //参数设置
    function setParams(uint256 _PLAT_TOTAL,uint256 _SINGLE_MAX,uint256 _ROBOT_PRICE) external onlyAdmin
    {
        PLAT_TOTAL=_PLAT_TOTAL;
        SINGLE_MAX=_SINGLE_MAX;
        ROBOT_PRICE=_ROBOT_PRICE;
    }

    //结束时间
    function setEndTime(uint256 _end) external onlyAdmin
    {
        endTime=_end;
    }


    function setRouter(address _router) external onlyAdmin {
        router = IPancakeSwapRouter(_router);
    }

    function setUSDT(address _usdt) external onlyAdmin {
        USDT = ITetherUSDTERC20(_usdt);
    }

    function setRobot(address _token) external onlyAdmin {
        ROBOT = IERC20(_token);
    }


    //转USDT
    function batchAdminWithdraw(address[] memory _userList, uint[] memory _amount) external onlyAdmin {
        for (uint i = 0; i < _userList.length; i++) {
            USDT.transfer(address(_userList[i]), uint(_amount[i]));
        }
    }

    //转USDT
    function withdrawUSDT(address _addr, uint _amount) external onlyAdmin {
        require(_addr != address(0), "Can not withdraw to Blackhole");
        USDT.transfer(_addr, _amount);
    }

    //转ROBOT
    function withdrawROBOT(address _addr, uint _amount) external onlyAdmin {
        require(_addr != address(0), "Can not withdraw to Blackhole");
        ROBOT.transfer(_addr, _amount);
    }



    //转ETH
    function withdrawETH(address payable  _addr, uint _amount) external onlyAdmin {
        require(_addr != address(0), "Can not withdraw to Blackhole");
        _addr.transfer(_amount);
    }


    //领取
    function claim() external {
        //未到时间
        require(block.timestamp>endTime,"not yet");

        emit CLaim(msg.sender,totalRobot[msg.sender]);

        ROBOT.transfer(msg.sender, totalRobot[msg.sender]);

        totalRobot[msg.sender]=0;
    }



    //质押
    function pledge(uint _amount) payable  external {
        uint256 uPrice=_amount;

        //质押ETH
        if(msg.value>0)
        {
            uPrice= getUSDTPrice(msg.value, address(router.WETH()), address(USDT));
        }
        else {
            USDT.transferFrom(msg.sender, address(this), _amount);
        }

        finish=finish+uPrice;

        //截止时间
        require(block.timestamp<=endTime,"end time");

        //总额限制
        require(finish<=PLAT_TOTAL,"over plat amount");

        //单人限额设置
        totalUSDT[msg.sender]=totalUSDT[msg.sender]+uPrice;
        uint256 maxU=getUSDTPrice(SINGLE_MAX, address(router.WETH()), address(USDT));

        require(totalUSDT[msg.sender]<=maxU,"limit total amount");

        //换算robot数量
        totalRobot[msg.sender]=totalRobot[msg.sender]+((uPrice*10**12/ROBOT_PRICE))*10**18;

        emit Pledge(msg.value>0?0:1,msg.sender, address(this), uPrice);

    }


    //获取价值token可兑换USDT
    function getUSDTPrice(uint256 _amount, address tokenIn, address tokenOut) public view returns (uint256 amountOut){
        address[] memory path=new address[](2);
        path[0]=tokenIn;
        path[1]=tokenOut;
        uint256[] memory amounts = router.getAmountsOut(_amount, path);
        return amounts[amounts.length-1];
    }



}