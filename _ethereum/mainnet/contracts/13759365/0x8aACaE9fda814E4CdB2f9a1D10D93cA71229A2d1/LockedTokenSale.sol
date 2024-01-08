// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./UniswapRouter.sol";
import "./ITokenVesting.sol";

contract LockedTokenSale is Ownable {

    ITokenVesting tokenVesting;
    IUniswapV2Router01 router;
    AggregatorInterface ref;
    address public token;

    uint constant plan1_price_limit = 97 * 1e16; // ie18
    uint constant plan2_price_limit = 87 * 1e16; // ie18

    mapping (uint => uint) lockedTokenPrice;

    uint public constant referral_ratio = 10000000; //1e8

    constructor(address _router, address _tokenVesting, address _ref, address _token) {
        router = IUniswapV2Router01(_router); // 0x9ac64cc6e4415144c455bd8e4837fea55603e5c3
        tokenVesting = ITokenVesting(_tokenVesting); // 0x63570e161Cb15Bb1A0a392c768D77096Bb6fF88C 0xDB83E3dDB0Fa0cA26e7D8730EE2EbBCB3438527E
        ref = AggregatorInterface(_ref); // 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526 bscTestnet
        token = _token; //0x5Ca372019D65f49cBe7cfaad0bAA451DF613ab96
        lockedTokenPrice[1] = plan1_price_limit;
        lockedTokenPrice[2] = plan2_price_limit;
        IERC20(token).approve(address(tokenVesting), 1e25);
    }

    function balanceOfToken() public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getUnlockedTokenPrice() public view returns (uint) {
        address pair = IUniswapV2Factory(router.factory()).getPair(token, router.WETH());
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        uint pancake_price;
        if( IUniswapV2Pair(pair).token0() == token ){
            pancake_price = reserve1 * (10 ** IERC20(token).decimals()) / reserve0;
        }
        else {
            pancake_price = reserve0 * (10 ** IERC20(token).decimals()) / reserve1;
        }
        return pancake_price;
    }

    function setLockedTokenPrice(uint plan, uint price) public onlyOwner{
        if(plan == 1)
            require(plan1_price_limit <= price, "Price should not below the limit");
        if(plan == 2)
            require(plan2_price_limit <= price, "Price should not below the limit");
        lockedTokenPrice[plan] = price;
    }

    function getLockedTokenPrice(uint plan) public view returns (uint){
        return lockedTokenPrice[plan] * 1e8 / ref.latestAnswer();
    }

    function buyLockedTokens(uint plan, uint amount, address referrer) public payable{

        require(amount > 0, "You should buy at least 1 locked token");

        uint price = getLockedTokenPrice(plan);
        
        uint amount_eth = amount * price;
        uint referral_value = amount_eth * referral_ratio / 1e8;

        require(amount_eth <= msg.value, 'EXCESSIVE_INPUT_AMOUNT');
        if(referrer != address(0x0) && referrer != msg.sender) {
            payable(referrer).transfer(referral_value);
        }
        
        require(amount <= IERC20(token).balanceOf(address(this)), "Insufficient fund");
        uint256 endEmission = block.timestamp + 60 * 60 * 24 * (plan == 1 ? 465 : 730);
        ITokenVesting.LockParams[] memory lockParams = new ITokenVesting.LockParams[](1);
        ITokenVesting.LockParams memory lockParam;
        lockParam.owner = payable(msg.sender);
        lockParam.amount = amount;
        lockParam.startEmission = 0;
        lockParam.endEmission = endEmission;
        lockParam.condition = address(0);
        lockParams[0] = lockParam;

        tokenVesting.lock(token, lockParams);

        if(amount_eth < msg.value) {
            payable(msg.sender).transfer(msg.value - amount_eth);
        }
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}

interface AggregatorInterface{
    function latestAnswer() external view returns (uint256);
}