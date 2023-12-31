// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

/*
 * Website: alacritylsd.com
 * X/Twitter: x.com/alacritylsd
 * Telegram: t.me/alacritylsd
 */

/*
 * Alacrity is a dynamic LSD liquidity and USDL trading platform.
 * We aim to unlock substantial returns for LSD holders, minimize liquidity costs,
 * and support LSD-related protocols. Our guide outlines ALSD's vision to revolutionize
 * the LSD and DeFi ecosystems through unique liquidity strategies and an innovative USDL
 * trading platform.
 */

contract ALSD is ERC20, ERC20Burnable, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 public constant MAX_SUPPLY = 10_000_000 * 10 ** 18;

    uint256 public sellFee = 20;
    address public feesWallet;
    uint256 public maxWallet;
    mapping(address => bool) private isExcludedFromFees;

    address public factoryAddress;
    bool public factoryAddressSet = false;

    modifier onlyFactory() {
        require(
            msg.sender == factoryAddress,
            "Only the Staking Pool Factory can call this function"
        );
        _;
    }

    function setFactoryAddress(address _factoryAddress) external onlyOwner {
        require(!factoryAddressSet, "Factory address has already been set");
        factoryAddress = _factoryAddress;
        factoryAddressSet = true;
    }

    constructor(
        address _feesWallet,
        address _treasuryWallet,
        address _airdropWallet,
        address _teamWallet
    ) ERC20("ALSD", "ALSD") {
        feesWallet = _feesWallet;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        automatedMarketMakerPairs[address(uniswapV2Pair)] = true;

        maxWallet = 2_000 * 1e18; // 2%

        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[_treasuryWallet] = true;
        isExcludedFromFees[_airdropWallet] = true;
        isExcludedFromFees[_teamWallet] = true;
        isExcludedFromFees[feesWallet] = true;
        isExcludedFromFees[address(_uniswapV2Router)] = true;
        isExcludedFromFees[address(uniswapV2Pair)] = true;

        _mint(owner(), 100_000 * 10 ** 18);
        _mint(_treasuryWallet, 800_000 * 10 ** 18);
        _mint(_airdropWallet, 1_100_000 * 10 ** 18);
        _mint(_teamWallet, 300_000 * 10 ** 18);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool isSelling = automatedMarketMakerPairs[to];

        bool takeFee = true;
        uint256 fees = 0;

        if (isExcludedFromFees[from]) {
            takeFee = false;
        }

        if (sellFee == 0) {
            takeFee = false;
        }

        if (!isExcludedFromFees[to]) {
            require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
        }

        if (isSelling && takeFee) {
            fees = (amount * (sellFee)) / 100;
            if (fees > 0) {
                super._transfer(from, feesWallet, fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function mintIncentiveLiquidity(
        uint256 amount
    ) external onlyFactory returns (bool) {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "Exceeded maximum supply"
        );
        _mint(factoryAddress, amount);
        return true;
    }

    function setFeesWallet(address _address) external onlyOwner {
        feesWallet = _address;
    }

    function updateSellFees(uint256 _fee) external onlyOwner {
        require(_fee <= 20, "Must keep sell fee at 20% or less");
        sellFee = _fee;
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 10) / 2500) / 1e18,
            "Cannot set maxWallet lower than 2.5%"
        );
        maxWallet = newNum * (10 ** 18);
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        automatedMarketMakerPairs[pair] = value;
    }
}
