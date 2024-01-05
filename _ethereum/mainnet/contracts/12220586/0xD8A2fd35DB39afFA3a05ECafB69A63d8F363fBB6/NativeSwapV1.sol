// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ITokenV1.sol";
import "./IAuctionV1.sol";

contract NativeSwapV1 {
    using SafeMath for uint256;

    event TokensSwapped(
        address indexed account,
        uint256 indexed stepsFromStart,
        uint256 userAmount,
        uint256 penaltyAmount
    );

    uint256 public start;
    uint256 public period;
    uint256 public stepTimestamp;
    IERC20 public swapToken;
    ITokenV1 public mainToken;
    IAuctionV1 public auction;

    mapping(address => uint256) public swapTokenBalanceOf;

    function init(
        uint256 _period,
        uint256 _stepTimestamp,
        address _swapToken,
        address _mainToken,
        address _auction
    ) external {
        period = _period;
        stepTimestamp = _stepTimestamp;
        swapToken = IERC20(_swapToken);
        mainToken = ITokenV1(_mainToken);
        auction = IAuctionV1(_auction);
        start = now;
    }

    function deposit(uint256 _amount) external {
        require(
            swapToken.transferFrom(msg.sender, address(this), _amount),
            'NativeSwap: transferFrom error'
        );
        swapTokenBalanceOf[msg.sender] = swapTokenBalanceOf[msg.sender].add(
            _amount
        );
    }

    function withdraw(uint256 _amount) external {
        require(_amount >= swapTokenBalanceOf[msg.sender], 'balance < amount');
        swapTokenBalanceOf[msg.sender] = swapTokenBalanceOf[msg.sender].sub(
            _amount
        );
        swapToken.transfer(msg.sender, _amount);
    }

    function swapNativeToken() external {
        uint256 stepsFromStart = calculateStepsFromStart();
        require(stepsFromStart <= period, 'swapNativeToken: swap is over');
        uint256 amount = swapTokenBalanceOf[msg.sender];
        uint256 deltaPenalty = calculateDeltaPenalty(amount);
        uint256 amountOut = amount.sub(deltaPenalty);
        require(amount > 0, 'swapNativeToken: amount == 0');
        swapTokenBalanceOf[msg.sender] = 0;
        mainToken.mint(address(auction), deltaPenalty);
        auction.callIncomeDailyTokensTrigger(deltaPenalty);
        mainToken.mint(msg.sender, amountOut);

        emit TokensSwapped(msg.sender, stepsFromStart, amount, deltaPenalty);
    }

    function calculateDeltaPenalty(uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 stepsFromStart = calculateStepsFromStart();
        if (stepsFromStart > period) return amount;
        return amount.mul(stepsFromStart).div(period);
    }

    function calculateStepsFromStart() public view returns (uint256) {
        return now.sub(start).div(stepTimestamp);
    }
}
