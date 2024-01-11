// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IEMEFactory.sol";
import "./IEMERouter.sol";

contract KNToken is ERC20, Ownable {
    using SafeMath for uint256;

    bool private inSwapAndLiquify;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) public pairs;
    bool public swapAndLiquifyEnabled = true;

    uint256 public tradeFeePercent = 1e6 / 100; //1%
    uint256 public numTokensSell = 10**18;
    uint256 public execCond = 0.5 ether;
    address payable public vault;
    IEMERouter public uniswapV2Router;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event AddPair(address pair);
    event DelPair(address pair);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _maxSupply,
        address payable _vault,
        IEMERouter _uniswapV2Router
    ) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        _mint(_vault, _maxSupply);
        uniswapV2Router = _uniswapV2Router;
        vault = _vault;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function setVault(address payable _vault) external onlyOwner {
        vault = _vault;
    }

    function setExecCond(uint256 _cond) external onlyOwner {
        execCond = _cond;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setNumTokensSell(uint256 _numTokensSell) external onlyOwner {
        numTokensSell = _numTokensSell;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setTradeFeePercent(uint256 _percent) external onlyOwner {
        tradeFeePercent = _percent;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (
            (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) &&
            (pairs[from] || pairs[to])
        ) {
            amount = calculateFee(from, to, amount);
        }
        super._transfer(from, to, amount);

        uint256 balance = balanceOf(address(this));
        if (
            swapAndLiquifyEnabled &&
            !pairs[from] &&
            !pairs[to] &&
            balance >= numTokensSell
        ) {
            swapTokensForEth(balance);

            if (address(this).balance >= execCond) {
                vault.transfer(execCond.mul(90).div(100));
                swapTokensForKNT(execCond.mul(10).div(100));
            }
        }
    }

    function execManually() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            vault.transfer(balance.mul(90).div(100));
            swapTokensForKNT(balance.mul(10).div(100));
        }
    }

    function calculateFee(
        address from,
        address to,
        uint256 amount
    ) private returns (uint256) {
        uint256 tradeFee = amount.mul(tradeFeePercent).div(1e6);
        if (tradeFee > 0) {
            amount = amount.sub(tradeFee);
            super._transfer(from, address(this), tradeFee);
        }
        return amount;
    }

    function expectPair(
        IEMEFactory _factory,
        address _tokenA,
        address _tokenB
    ) public pure returns (address pair) {
        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            _factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            _factory.INIT_CODE_PAIR_HASH()
                        )
                    )
                )
            )
        );
    }

    function addPairByFactory(IEMEFactory _factory, address _token)
        external
        onlyOwner
    {
        address pair = expectPair(_factory, address(this), _token);
        pairs[pair] = true;
        emit AddPair(pair);
    }

    function addPair(address _pair) external onlyOwner {
        pairs[_pair] = true;
        emit AddPair(_pair);
    }

    function delPair(address _pair) external onlyOwner {
        delete pairs[_pair];
        emit DelPair(_pair);
    }

    function swapTokensForEth(uint256 tokenAmount)
        private
        lockTheSwap
    {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForKNT(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: tokenAmount
        }(0, path, address(0xdead), block.timestamp);
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
}
