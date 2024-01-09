// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./AggregateV3Interface.sol";


contract aKeeperPresale is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public aKEEPER;
    address public USDC;
    address public USDT;
    address public DAI;
    address public wBTC;
    address public gnosisSafe;
    mapping( address => uint ) public amountInfo;
    uint deadline;
    
    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal btcPriceFeed;

    event aKeeperRedeemed(address tokenOwner, uint amount);

    constructor(address _aKEEPER, address _USDC, address _USDT, address _DAI, address _wBTC, address _ethFeed, address _btcFeed, address _gnosisSafe, uint _deadline) {
        require( _aKEEPER != address(0) );
        require( _USDC != address(0) );
        require( _USDT != address(0) );
        require( _DAI != address(0) );
        require( _wBTC != address(0) );
        require( _ethFeed != address(0) );
        require( _btcFeed != address(0) );
        aKEEPER = IERC20(_aKEEPER);
        USDC = _USDC;
        USDT = _USDT;
        DAI = _DAI;
        wBTC = _wBTC;
        gnosisSafe = _gnosisSafe;
        deadline = _deadline;
        ethPriceFeed = AggregatorV3Interface( _ethFeed );
        btcPriceFeed = AggregatorV3Interface( _btcFeed );
    }

    function setDeadline(uint _deadline) external onlyOwner() {
        deadline = _deadline;
    }

    function ethAssetPrice() public view returns (int) {
        ( , int price, , , ) = ethPriceFeed.latestRoundData();
        return price;
    }

    function btcAssetPrice() public view returns (int) {
        ( , int price, , , ) = btcPriceFeed.latestRoundData();
        return price;
    }

    function maxAmount() internal pure returns (uint) {
        return 100000000000;
    }

    function getTokens(address principle, uint amount) external {
        require(block.timestamp < deadline, "Deadline has passed.");
        require(principle == USDC || principle == USDT || principle == DAI || principle == wBTC, "Token is not acceptable.");
        require(IERC20(principle).balanceOf(msg.sender) >= amount, "Not enough token amount.");
        // Get aKeeper amount. aKeeper is 9 decimals and 1 aKeeper = $100
        uint aKeeperAmount;
        if (principle == DAI) {
            aKeeperAmount = amount.div(1e11);
        }
        else if (principle == wBTC) {
            aKeeperAmount = amount.mul(uint(btcAssetPrice())).div(1e9);
        }
        else {
            aKeeperAmount = amount.mul(1e1);
        }

        require(maxAmount().sub(amountInfo[msg.sender]) >= aKeeperAmount, "You can only get a maximum of $10000 worth of tokens.");

        IERC20(principle).safeTransferFrom(msg.sender, gnosisSafe, amount);
        aKEEPER.transfer(msg.sender, aKeeperAmount);
        amountInfo[msg.sender] = amountInfo[msg.sender].add(aKeeperAmount);
        emit aKeeperRedeemed(msg.sender, aKeeperAmount);
    }

    function getTokensEth() external payable {
        require(block.timestamp < deadline, "Deadline has passed.");
        uint amount = msg.value;
        // Get aKeeper amount. aKeeper is 9 decimals and 1 aKeeper = $100
        uint aKeeperAmount = amount.mul(uint(ethAssetPrice())).div(1e19);
        require(maxAmount().sub(amountInfo[msg.sender]) >= aKeeperAmount, "You can only get a maximum of $10000 worth of tokens.");

        safeTransferETH(gnosisSafe, amount);
        aKEEPER.transfer(msg.sender, aKeeperAmount);
        amountInfo[msg.sender] = amountInfo[msg.sender].add(aKeeperAmount);
        emit aKeeperRedeemed(msg.sender, aKeeperAmount);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

    function withdraw() external onlyOwner() {
        uint256 amount = aKEEPER.balanceOf(address(this));
        aKEEPER.transfer(msg.sender, amount);
    }

    function withdrawEth() external onlyOwner() {
        safeTransferETH(gnosisSafe, address(this).balance);
    }
}
