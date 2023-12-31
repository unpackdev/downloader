//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

/**
 * Introducing RobinHood and the $HOOD - the ultimate crypto adventure where generosity meets decentralization! 🏹💰
 * As transactions occur, our mischievous smart contract automatically snatches 10% from every sell. 5% will be redirected to the last lucky soul who bought before (min 0.1 ETH buy), 5% will be burned.
 * Consider it a modern-day twist on Robin Hood's "steal from the rich and give to the poor" mantra. 🎩💰
 * Learn more: https://robinhood.army
 * And join the world of decentralized generosity: https://t.me/RobinHood_ETH
 */
contract RobinHood is Ownable, ERC20 {
    uint256 public constant SUPPLY = 420690000000000 ether;
    uint256 public maxByWallet; 
    uint256 public robinHoodShare = 100;
    address public lastBuyer = address(0x000000000000000000000000000000000000dEaD); // will be changed after the first >= 0.1 eth buy
    bool public isTradingActive = false;

    IUniswapV2Router02 public immutable router;
    address public immutable weth;
    address public immutable pair;

    error NotTheOwner();
    error MaxByWalletReached();

    constructor(address _router) ERC20("RobinHood", "HOOD") {
        _mint(msg.sender, SUPPLY);
        maxByWallet = SUPPLY * 50 / 1000;

        // Create pair
        router = IUniswapV2Router02(_router);
        weth = router.WETH();
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), weth);
    }

    function _transfer(address from, address to, uint256 amount) internal override(ERC20)  {
        if (!isTradingActive) {
            if(from != owner() && to != owner()){
                revert NotTheOwner(); 
            }
            super._transfer(from, to, amount);    
        } else {
            if(from == pair) {
                if(super.balanceOf(to) + amount > maxByWallet){
                    revert MaxByWalletReached(); 
                }

                address[] memory path;
                path = new address[](2);
                path[0] = weth;
                path[1] = address(this);
                uint256[] memory amountsExpected = IUniswapV2Router02(router).getAmountsIn(amount, path);

                // Only a min buy of 0.1 ETH make you elligble to robinHood share on next sells
                if(amountsExpected[0] >= 0.1 ether){
                    lastBuyer = to;
                    robinHoodShare = 100;
                }
            } else if (to == pair) {
                // SELL
                uint256 amountToGive = amount * robinHoodShare / 1000 / 2;
                uint256 amountToBurn = amountToGive;
                robinHoodShare = robinHoodShare + 10;
                amount = amount - amountToGive - amountToBurn;

                super._transfer(from, lastBuyer, amountToGive);
                super._burn(from, amountToBurn);
            }

            super._transfer(from, to, amount);  
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function step1() external onlyOwner {
        isTradingActive = true;
    }

    function step2() external onlyOwner {
        maxByWallet = SUPPLY * 100 / 1000;
        _transferOwnership(address(0));
    }
}