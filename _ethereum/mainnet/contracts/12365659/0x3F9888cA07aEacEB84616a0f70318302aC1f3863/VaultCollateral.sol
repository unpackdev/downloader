// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
  ___                      _   _
 | _ )_  _ _ _  _ _ _  _  | | | |
 | _ \ || | ' \| ' \ || | |_| |_|
 |___/\_,_|_||_|_||_\_, | (_) (_)
                    |__/

*
* MIT License
* ===========
*
* Copyright (c) 2020 BunnyFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./PausableUpgradeable.sol";
import "./WhitelistUpgradeable.sol";
import "./SafeToken.sol";
import "./PoolConstant.sol";

import "./PriceCalculatorETH.sol";
import "./ZapETH.sol";


contract VaultCollateral is PausableUpgradeable, WhitelistUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMath for uint;
    using SafeToken for address;

    /* ========== CONSTANTS ============= */

    PoolConstant.PoolTypes public constant poolType = PoolConstant.PoolTypes.Collateral;

    PriceCalculatorETH public constant priceCalculator = PriceCalculatorETH(0xB73106688fdfee99578731aDb18c9689462B415a);
    ZapETH public constant zap = ZapETH(0x421a8dfd8683400Ee6AFE8EDEbdbe6E76A61f278);

    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant SNOOPY = 0x13174B00Fe4AF831BC6a321712dC186D53c8cB3A;

    uint public constant WITHDRAWAL_FEE_PERIOD = 3 days;
    uint public constant WITHDRAWAL_FEE_UNIT = 10000;
    uint public constant WITHDRAWAL_FEE = 50;

    /* ========== STATE VARIABLES ========== */

    address public stakingToken;
    address public pairToken;

    uint public collateralValueMin;

    mapping(address => uint) private _available;
    mapping(address => uint) private _collateral;
    mapping(address => uint) private _realizedProfit;
    mapping(address => uint) private _depositedAt;

    /* ========== EVENTS ========== */

    event CollateralAdded(address indexed user, uint amount);
    event CollateralRemoved(address indexed user, uint amount, uint profitInETH);
    event CollateralUnlocked(address indexed user, uint amount, uint profitInETH, uint lossInETH);
    event Recovered(address token, uint amount);

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize(address _token) external initializer {
        require(_token != address(0), "VaultCollateral: invalid token");
        __PausableUpgradeable_init();
        __WhitelistUpgradeable_init();
        __ReentrancyGuard_init();

        stakingToken = _token;
        collateralValueMin = 100e18;

        _token.safeApprove(address(zap), uint(- 1));
        if (keccak256(abi.encodePacked(IUniswapV2Pair(_token).symbol())) == keccak256("UNI-V2")) {
            address token0 = IUniswapV2Pair(_token).token0();
            address token1 = IUniswapV2Pair(_token).token1();
            pairToken = token0 == WETH ? token1 : token0;
            pairToken.safeApprove(address(zap), uint(- 1));
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    function balance() public view returns (uint) {
        return stakingToken == WETH ? address(this).balance : IERC20(stakingToken).balanceOf(address(this));
    }

    function availableOf(address account) public view returns (uint) {
        return _available[account];
    }

    function collateralOf(address account) public view returns (uint) {
        return _collateral[account];
    }

    function collateralInUSD(address account) public view returns (uint valueInUSD) {
        (, valueInUSD) = priceCalculator.valueOfAsset(stakingToken, _collateral[account]);
    }

    function realizedInETH(address account) public view returns (uint) {
        return _realizedProfit[account];
    }

    function depositedAt(address account) external view returns (uint) {
        return _depositedAt[account];
    }

    function withdrawalFee(address account, uint amount) public view returns (uint) {
        if (_depositedAt[account] + WITHDRAWAL_FEE_PERIOD < block.timestamp) {
            return 0;
        }
        return amount.mul(WITHDRAWAL_FEE).div(WITHDRAWAL_FEE_UNIT);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function bridgeETH(uint amount) external onlyWhitelisted {
        SafeToken.safeTransferETH(SNOOPY, amount);
    }

    function setCollateralValueMin(uint newValue) external onlyOwner {
        require(newValue > 0, "CVaultETHLP: minimum value must not be zero");
        collateralValueMin = newValue;
    }

    function unlockCollateral(address account, uint profitInETH, uint lossInETH) external onlyWhitelisted {
        (, uint lossInUSD) = priceCalculator.valueOfAsset(WETH, lossInETH);
        (, uint tokenInUSD) = priceCalculator.valueOfAsset(stakingToken, 1e18);

        uint available = _collateral[account].sub(withdrawalFee(account, _collateral[account]));
        uint lossInCollateral = lossInUSD.mul(1e18).div(tokenInUSD);
        if (lossInCollateral > 0) {
            available = available > lossInCollateral ? available.sub(lossInCollateral) : 0;
        }

        if (profitInETH > 0) {
            _realizedProfit[account] = _realizedProfit[account].add(profitInETH);
        }

        _available[account] = _available[account].add(available);
        uint repayment = _collateral[account].sub(available);

        delete _collateral[account];
        delete _depositedAt[account];

        if (repayment > 0) {
            uint _beforeETH = address(this).balance;
            if (stakingToken != WETH) {
                zap.zapOut(stakingToken, repayment);
                if (pairToken != address(0)) {
                    zap.zapOut(pairToken, IERC20(pairToken).balanceOf(address(this)));
                }
            } else {
                _beforeETH = _beforeETH.sub(repayment);
            }

            SafeToken.safeTransferETH(SNOOPY, address(this).balance.sub(_beforeETH));
        }
        emit CollateralUnlocked(account, available, profitInETH, lossInETH);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addCollateral(uint amount) public notPaused nonReentrant {
        require(stakingToken != WETH, 'VaultCollateral: invalid asset');

        uint _before = balance();
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        amount = balance().sub(_before);

        (, uint valueInUSD) = priceCalculator.valueOfAsset(stakingToken, amount);
        require(valueInUSD >= collateralValueMin, "VaultCollateral: collateral value limit");

        _collateral[msg.sender] = _collateral[msg.sender].add(amount);
        _depositedAt[msg.sender] = block.timestamp;
        emit CollateralAdded(msg.sender, amount);
    }

    function addCollateralETH() public payable notPaused nonReentrant {
        require(stakingToken == WETH, 'VaultCollateral: invalid asset');

        uint amount = msg.value;
        (, uint valueInUSD) = priceCalculator.valueOfAsset(stakingToken, amount);
        require(valueInUSD >= collateralValueMin, "VaultCollateral: collateral value limit");

        _collateral[msg.sender] = _collateral[msg.sender].add(amount);
        _depositedAt[msg.sender] = block.timestamp;
        emit CollateralAdded(msg.sender, amount);
    }

    function removeCollateral() external {
        uint available = _available[msg.sender];
        uint profitInETH = _realizedProfit[msg.sender];
        delete _available[msg.sender];
        delete _realizedProfit[msg.sender];

        if (available > 0) {
            if (stakingToken == WETH) {
                SafeToken.safeTransferETH(msg.sender, available);
            } else {
                stakingToken.safeTransfer(msg.sender, available);
            }
        }

        if (profitInETH > 0) {
            SafeToken.safeTransferETH(msg.sender, profitInETH);
        }
        emit CollateralRemoved(msg.sender, available, profitInETH);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address tokenAddress, uint tokenAmount) external onlyOwner {
        require(tokenAddress != address(0) && tokenAddress != stakingToken, "VaultCollateral: cannot recover token");

        tokenAddress.safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /// dev: TODO Will be removed after beta test (beta test only)
    function recoverForBetaTest(address tokenAddress, uint tokenAmount) external onlyOwner {
        tokenAddress.safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}
