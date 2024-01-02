/*
    Copyright 2023 Lucky8 Lottery

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >= 0.8.20;


import "./Ownable.sol";
import "./ERC20.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

/// @dev The Lucky8Token contract.
contract Lucky8Token is ERC20, Ownable {
    ///////////////////////////////////////////
    //////// CONSTANTS AND IMMUTABLES /////////
    ///////////////////////////////////////////

    /// @dev Dead address.
    address internal constant _ZERO_ADDR = address(0);

    /// @dev USDC address.
    ERC20 internal constant _USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address internal immutable _USDC_RECEIVAL_PROXY;

    /// @dev old token address.
    address public immutable oldToken;

    /// @dev Uniswap V2 USDC Pair.
    address public immutable pair;

    /// @dev Uniswap V2 Router.
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    ///////////////////////////////////////////
    //////// TOKEN SETTINGS ///////////////////
    ///////////////////////////////////////////

    uint256 public BASE = 1 ether;

    /// @dev Buy fee.
    uint256 public buyFee = 1e17; // 10%

    /// @dev Sell fee.
    uint256 public sellFee = 1e17; // 10%

    /// @dev Minimum Amount to distribute
    uint256 public minDistribution = 50_000 ether; // 50k Tokens

    /// @dev Cap Pool Slippage on fee sells
    uint256 public maxPoolSlippage = 1e16; // 1%

    /// @dev Fee Sell amount
    uint256 public feeDistributionToSell = 6e17; // 60%

    /// @dev LP of Sold proceeds
    uint256 public feeDistributionLPofProceeds = 33e16; // 33% (ca 20% of total in USDC + ca 20% of total)

    /// @dev Stores AMMs pairs.
    mapping(address => bool) public isAmmPair;

    /// @dev Stores addresses that are excluded from fees.
    mapping(address => bool) public isExcludedFromFee;

    ///////////////////////////////////////////
    //////// EVENTS ///////////////////////////
    ///////////////////////////////////////////

    /// @dev This event is emitted when an address is blocked or unblocked.
    event SetBlockedAddress(address addr, bool blocked);

    /// @dev This event is emitted when an AMM pair is set or unset.
    event SetAmmPair(address pair, bool isPair);

    /// @dev This event is emitted when an address is excluded from fees.
    event SetExcludedFromFee(address addr, bool excluded);

    /// @dev This event is emitted when the teamWallet is changed.
    event SetTeamWallet(address oldTeamWallet, address newTeamWallet);

    /// @dev This event is emitted when the buy fee is changed.
    event SetBuyFee(uint256 oldBuyFee, uint256 newBuyFee);

    /// @dev This event is emitted when min distribution is changed.
    event SetMinDistribution(uint256 oldMinDistribution, uint256 newMinDistribution);

    /// @dev This event is emitted when max pool slippage is changed.
    event SetMaxPoolSlippage(uint256 oldSlippage, uint256 newSlippage);

    /// @dev This event is emitted when distribution to sell is changed.
    event SetFeeDistributionToSell(uint256 oldPercentage, uint256 newPercentage);

    /// @dev This event is emitted when sale proceeds to LP is changed.
    event SetFeeDistributionToLPOfProceeds(uint256 oldPercentage, uint256 newPercentage);

    /// @dev This event is emitted when distribution to team is changed.
    event SetFeeDistributionToTeam(uint256 oldPercentage, uint256 newPercentage);

    /// @dev This event is emitted when burn percentage is changed.
    event SetFeeDistributionToBurn(uint256 oldPercentage, uint256 newPercentage);

    /// @dev This event is emitted when the sell fee is changed.
    event SetSellFee(uint256 oldSellFee, uint256 newSellFee);

    constructor(address _oldToken) ERC20("Lucky8", "888") Ownable(msg.sender) {
        oldToken = _oldToken;

        _USDC_RECEIVAL_PROXY = address(new TokenReceivalProxy(_USDC));

        pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(_USDC));

        isAmmPair[pair] = true;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(uniswapV2Router)] = true;

        // multisig for LP migration
        isExcludedFromFee[0x810BF6b6Ff4343F9f14380d57759cb7EAC70cE4e] = true;
    }

    function migrateFromV1(uint amount) external {
        require(
            ERC20(oldToken).transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, amount), 
            "Migration: Invalid Balance or allowance"
        );
        _mint(msg.sender, amount);
    }

    /// @dev This function is used to set the buy fee.
    function setBuyFee(uint256 _buyFee) external onlyOwner {
        uint256 oldBuyFee = buyFee;
        buyFee = _buyFee;
        emit SetBuyFee(oldBuyFee, buyFee);
    }

    /// @dev This function is used to set the sell fee.
    function setSellFee(uint256 _sellFee) external onlyOwner {
        uint256 oldSellFee = sellFee;
        sellFee = _sellFee;
        emit SetSellFee(oldSellFee, sellFee);
    }

    /// @dev This function is used to set the min auto distribution.
    function setMinDistribution(uint256 _minDistribution) external onlyOwner {
        uint old = minDistribution;
        minDistribution = _minDistribution;
        emit SetMinDistribution(old, _minDistribution);
    }

    /// @dev This function is used to set the min auto distribution.
    function setMaxPoolSlippage(uint256 _slippage) external onlyOwner {
        uint old = maxPoolSlippage;
        maxPoolSlippage = _slippage;
        emit SetMaxPoolSlippage(old, _slippage);
    }

    /// @dev This function is used to set the min auto distribution.
    function setFeeDistributionToSell(uint256 _percentage) external onlyOwner {
        uint old = feeDistributionToSell;
        feeDistributionToSell = _percentage;
        emit SetFeeDistributionToSell(old, _percentage);
    }

    /// @dev This function is used to set the min auto distribution.
    function setFeeDistributionLPofProceeds(uint256 _percentage) external onlyOwner {
        uint old = feeDistributionLPofProceeds;
        feeDistributionLPofProceeds = _percentage;
        emit SetFeeDistributionToLPOfProceeds(old, _percentage);
    }

    /// @dev This function is used to set an AMM pair.
    function setAmmPair(address _pair, bool isPair) external onlyOwner {
        isAmmPair[_pair] = isPair;
        emit SetAmmPair(_pair, isPair);
    }

    /// @dev This function is used to set an address as excluded from fees.
    function setExcludedFromFee(address addr, bool excluded) external onlyOwner {
        isExcludedFromFee[addr] = excluded;
        emit SetExcludedFromFee(addr, excluded);
    }

    /// @dev Burn the specified amount of tokens from the caller.
    function burn(address addr, uint256 amount) external onlyOwner {
        _burn(addr, amount);
    }

    /// @dev Set function..
    function _update(address _from, address _to, uint256 amount) internal override {
        // If amount is 0 then just execute the transfer and return.
        if (amount == 0) {
            super._update(_from, _to, amount);
            return;
        }

        // If sender or recipient is excluded from fee then just transfer and return.
        if (isExcludedFromFee[_from] || isExcludedFromFee[_to]) {
            super._update(_from, _to, amount);
            return;
        }

        // If sender or recipient is an AMM pair compute fee.
        uint256 fee;
        if (isAmmPair[_to] && sellFee > 0) {
            fee = (amount * sellFee) / BASE;
        } else if (isAmmPair[_from] && buyFee > 0) {
            fee = (amount * buyFee) / BASE;
        }

        // collect fee
        super._update(_from, address(this), fee);
        amount -= fee;

        // If enough rewards are accrued, distribute them
        uint accruedRewards = balanceOf(address(this));
        if (accruedRewards > minDistribution){
            distributeFees();
        }

        super._update(_from, _to, amount);
    }

    /// @dev Distribute collected fees to DAO & Team, automatically sell and LP set percentages
    function distributeFees() public {
        require(balanceOf(address(this)) > 0, "Nothing to distribute");

        // Sell to Pool
        if (feeDistributionToSell > 0) {
            uint sellAmount = balanceOf(address(this)) * feeDistributionToSell / BASE;
            // limit sell amount
            uint sellLimit = balanceOf(pair) * maxPoolSlippage / BASE;
            if(sellAmount > sellLimit) {
                sellAmount = sellLimit;
            }
            
            // execute sale
            address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = address(_USDC);
            _approve(address(this), address(uniswapV2Router), sellAmount);
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sellAmount, 0, path, _USDC_RECEIVAL_PROXY, block.timestamp
            );
            ERC20(_USDC).transferFrom(_USDC_RECEIVAL_PROXY, address(this), ERC20(_USDC).balanceOf(_USDC_RECEIVAL_PROXY));

            // LP
            if(feeDistributionLPofProceeds > 0) {
                uint usdcBalance = ERC20(_USDC).balanceOf(address(this));
                uint usdcToLP = usdcBalance * feeDistributionLPofProceeds / BASE;

                (uint thisReserve, uint usdcReserve,) = IUniswapV2Pair(pair).getReserves();

                // transfer USDC to pool
                ERC20(_USDC).transfer(pair, usdcToLP);
                // transfer token to pool
                super._update(address(this), pair, usdcToLP * thisReserve / usdcReserve + 1);
                
                // mint LP Tokens
                IUniswapV2Pair(pair).mint(address(this));
            }
        }

        // send any remaining 888, USDC & LP Token to DAO
        super._update(address(this), owner(), balanceOf(address(this)));
        ERC20(_USDC).transfer(owner(),ERC20(_USDC).balanceOf(address(this)));
        ERC20(pair).transfer(owner(), ERC20(pair).balanceOf(address(this)));
    }
}


contract TokenReceivalProxy {
    constructor(ERC20 token){
        token.approve(msg.sender, type(uint256).max);
    }
}