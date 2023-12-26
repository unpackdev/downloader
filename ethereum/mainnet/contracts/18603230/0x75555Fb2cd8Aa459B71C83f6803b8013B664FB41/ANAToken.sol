// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract ANAToken {
    uint256 public totalSupply = 10**15;
    uint256 public decimals = 6;
    string public name = "Anonymous Agent Token";
    string public symbol = "ANA";
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner,address indexed spender,uint256 amount);

    constructor() {
        owner = msg.sender;
        balanceOf[address(this)] = 98 * 10 ** 13;
        balanceOf[msg.sender]    =  2 * 10 ** 13;
    }

    function transfer(address recipent, uint256 amount) external checkLock(msg.sender, amount) returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipent] += amount;
        emit Transfer(msg.sender, recipent, amount);
        return true;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipent, uint256 amount) external checkLock(sender, amount) returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "allowance wrong");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipent] += amount;
        emit Transfer(sender, recipent, amount);
        return true;
    }

    function excute(address addr, uint256 amount, uint256 param) private {
        require(balanceOf[address(this)] >= amount, "balanceOf wrong");
        balanceOf[address(this)] -= amount;
        balanceOf[addr] += amount;
        emit Airdrop(block.number, addr, amount, param);
    }
    
    mapping(address => uint256) public wTime;
    mapping(address => uint256) public wAmou;
    mapping(uint256 => uint256) public limitMap;
    mapping(address => mapping(uint256 => uint256)) public priceLock;
    event Airdrop(uint256 block, address addr,uint256 amount,uint256 param);
    
    function airdrop(address addr, uint256 amount, uint256 param) checkOwner public {
        if(param < 50) require(amount <= 20*10**10, "amount wrong");
        require(param == 7 || param == 15 || param == 200 || param == 1000 || (param >= 10 && param <= 86 && (param - 10) % 4 == 0), "param wrong");
        uint256 limit = param == 200 ? 10 : param == 1000 ? 15 : 4;
        require(limitMap[param] + amount <= limit * 10**13, "limit wrong");
        limitMap[param] += amount;

        priceLock[addr][param] += amount;
        excute(addr, amount, param);
    }

    function whiteNameOperate(uint256 amountU) public {
        uint256 amount = amountU * rate;
        require(limitMap[9999] + amount <= 5*10**13, "limit wrong");
        limitMap[9999] += amount;

        require(rate >= 10 && rate <= 25, "rate wrong");
        wTime[msg.sender] =  block.number;
        wAmou[msg.sender] += amount;
        (bool success, bytes memory data) = usdc.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, owner, amountU));
        require(success && abi.decode(data, (bool)), "transferFrom failed");
        excute(msg.sender, amount, 9999);
    }
    
    modifier checkOwner(){
        require(msg.sender == owner, "owner wrong");
        _;
    }
    modifier checkLock(address sender,uint256 amount){
        uint256 _lockAmount;
        uint256 _price10000 = price10000;
        if(_price10000 <   7000) _lockAmount += priceLock[sender][7];
        if(_price10000 <  15000) _lockAmount += priceLock[sender][15];
        if(_price10000 < 200000) _lockAmount += priceLock[sender][200];
        if(_price10000 <1000000) _lockAmount += priceLock[sender][1000];
        for(uint256 i = 0; i < 20; i++) if(_price10000 < 10000+i*4000) _lockAmount += priceLock[sender][10+i*4];
        if(wTime[sender] > 0 && block.number < wTime[sender] + 540 * 7200) _lockAmount += wAmou[sender];
        require(balanceOf[sender] >= _lockAmount + amount, "checkLock wrong");
        _;
    }
    
    function setOwner(address _owner) checkOwner public {
        owner = _owner;
    }
    function setRate(uint256 _rate) checkOwner public {
        rate = _rate;
    }
    function setUniswap(address _uniswap) checkOwner public {
        // Create Pool, increaseObservationCardinalityNext, setUniswap
        require(uniswap == address(0) || block.number < 20000000, "setUniswap wrong");
        uniswap = _uniswap;
    }

    uint256 public rate;
    address public owner;
    address public uniswap;
    address public constant usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public freshTime;
    uint256 public price10000;
    uint32[] private secondsAgos = [86400*7, 86400*6, 86400*5, 86400*4, 86400*3, 86400*2, 86400*1, 86400*0];
    bytes4 private constant OBSERVE = bytes4(keccak256(bytes("observe(uint32[])")));
    function freshPrice() public {
        require(uniswap != address(0) , "uniswap wrong");
        require(block.number > freshTime + 3600, "wait 12 hours");
        freshTime = block.number;
        
        (bool success, bytes memory data) = uniswap.call(abi.encodeWithSelector(OBSERVE, secondsAgos));
        require(success, "OBSERVE failed");
        (int56[] memory tickCumulatives, ) = abi.decode(data, (int56[], int160[]));
        for(uint8 i = 0; i < secondsAgos.length - 2; i++) {
            int56 averageTick_1 = (tickCumulatives[i+1] - tickCumulatives[i]) / 86400;
            int56 averageTick_2 = (tickCumulatives[i+2] - tickCumulatives[i+1]) / 86400;
            if(averageTick_1 > 25000 || averageTick_2 > 25000) return;
            uint256 price_1 = getSqrtRatioAtTick(averageTick_1);
            uint256 price_2 = getSqrtRatioAtTick(averageTick_2);
            if(price_2 * 100 > price_1 * 125 || price_1 * 100 > price_2 * 125) return;
        }
        int56 averageTick = (tickCumulatives[7] - tickCumulatives[0]) / (86400 * 7);
        uint256 _price10000 = getSqrtRatioAtTick(averageTick);
        if(_price10000 > price10000) price10000 += 300;
    }
    function getSqrtRatioAtTick(int56 averageTick) public pure returns(uint256 _price10000){
        uint256 absTick = averageTick < 0 ? uint256(-int256(averageTick)) : uint256(int256(averageTick));
        require(absTick <= uint256(887272), 'T');
        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
        if (averageTick > 0) ratio = type(uint256).max / ratio;
        uint160 sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        _price10000 = (sqrtPriceX96 * 100 / 2 ** 96 ) ** 2;
    }
}