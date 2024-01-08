pragma solidity ^0.8.4;

import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router01.sol";

//
// Treasury contract for the BlackFriday $BFRY token project
//
//      << Because in the crypto space, black friday is everyday! >>
//
// Find out more on https://bfry.io
//


interface BFRY is IERC20 {
    function pauseFee (bool status) external;
}

contract BlackFridayTreasury is Context, Ownable {

    uint maxForLiquidity = 20000000 * 10**18;
    uint botTipPerc = 1;

    BFRY bfry;
    address bfryAddress;
    address public uniswapV2Pair;
    IUniswapV2Router01 public immutable uniswapV2Router;
    address payable private _mWallet;

    event LiquidityIncrease(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event Received(address, uint);

    constructor() {
        uniswapV2Router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    // increase the liquidity and pays the tip to the bot calling this function
    function addLiquidity() public payable {
        require(bfryAddress != address(0), "bfry address cannot be set to 0x00..00");
        uint balance = bfry.balanceOf(address(this));
        require(balance > maxForLiquidity, "Low balance");
        bfry.pauseFee(true);
        uint256 halfToLiquify = maxForLiquidity / 4;
        uint256 otherHalfToLiquify = maxForLiquidity / 4;
        uint256 portionForFees = maxForLiquidity - halfToLiquify - otherHalfToLiquify;
        uint256 initialBalance = address(this).balance;
        _swapTokensForEth(halfToLiquify);
        uint256 newBalance = address(this).balance - initialBalance;
        _addLiquidity(otherHalfToLiquify, newBalance);
        _sendFundsToWallets(portionForFees);
        bfry.pauseFee(false);
        emit LiquidityIncrease(halfToLiquify, newBalance, otherHalfToLiquify);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = bfryAddress;
        path[1] = uniswapV2Router.WETH();
        bfry.approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETH(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        bfry.approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            bfryAddress, tokenAmount, 0,  0, owner(), block.timestamp
        );
    }

    function _sendFundsToWallets(uint256 amount) private {
        _swapTokensForEth(amount);
        uint balance = address(this).balance;
        uint botTip = balance * botTipPerc / 100;
        // send tip to caller and funds to marketing wallet
        (payable(msg.sender)).transfer(botTip);
        _mWallet.transfer(address(this).balance);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setBFRYaddresses (address _newAdd, address _uniPool) public onlyOwner {
        bfry = BFRY(_newAdd);
        bfryAddress = _newAdd;
        uniswapV2Pair = _uniPool;
    }

    function setMarketingAddress (address payable _newAdd) public onlyOwner {
        _mWallet = _newAdd;
    }

    function setBotTipPerc (uint _perc) public onlyOwner {
        require(_perc < 100, "Cannot send 100% to bot");
        botTipPerc = _perc;
    }

    function setMAxForLiquidity (uint _newMax) public onlyOwner {
        maxForLiquidity = _newMax;
    }

}
