// SPDX-License-Identifier: MIT

import "./IKotoV3.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapv2Factory.sol";

pragma solidity 0.8.23;

interface IERC20Minimal {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract BondDepositoryV3 {
    IUniswapV2Factory public constant FACTORY = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public constant OWNER = 0x946eF43867225695E29241813A8F41519634B36b;
    address public constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public constant TIMELOCK_INTERVAL = 86400 * 3; // 3 day timelock
    uint256 public execution = type(uint256).max;
    ///@dev set timelock to max so that it can not be called
    address public koto;

    modifier onlyOwner() {
        if (msg.sender != OWNER) revert OnlyOwner();
        _;
    }

    constructor() {}

    ///@notice bond ETH held within the depository for Koto Tokens
    ///@param _value the ether value to send to the Koto Contract.
    function bond(uint256 _value) external onlyOwner {
        uint256 amountOut = IKotoV3(koto).bond{value: _value}();
        emit DepositoryBond(_value, amountOut);
    }

    ///@notice redeem Koto tokens held within the depository for ETH
    ///@param _amount the amount of Koto tokens to redeem
    function redeem(uint256 _amount) external onlyOwner {
        uint256 ethAmount = IKotoV3(koto).redeem(_amount);
        emit DepositoryRedeem(_amount, ethAmount);
    }

    ///@notice burn additional Koto tokens held within the depository without redeeming them
    ///@param _amount the amount of Koto tokens to burn.
    function burn(uint256 _amount) external onlyOwner {
        IKotoV3(koto).burn(_amount);
        emit DepositoryBurn(_amount);
    }

    ///@notice swap eth for koto or koto for eth
    ///@param _value the amount of either eth or koto to swap
    ///@param zeroForOne if you are swaping eth or koto
    ///@dev when zeroForOne is true koto is being swapped to eth
    function swap(uint256 _value, bool zeroForOne, uint256 _minAmount) external onlyOwner {
        if (zeroForOne) {
            address[] memory path = new address[](2);
            path[0] = koto;
            path[1] = WETH;
            IUniswapV2Router02(UNISWAP_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
                _value, _minAmount, path, address(this), block.timestamp
            );
            emit DepositorySell(_value);
        } else {
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = koto;
            IUniswapV2Router02(UNISWAP_ROUTER).swapExactETHForTokensSupportingFeeOnTransferTokens{value: _value}(
                _minAmount, path, address(this), block.timestamp
            );
            emit DepositoryBuy(_value);
        }
    }

    ///@notice send reward tokens to the Voter contract in order to being reward distribution.
    function reward(uint256 amount, address _to) external onlyOwner {
        if (msg.sender != OWNER) revert OnlyOwner();
        if (amount > IKotoV3(koto).allowance(address(this), _to)) {
            IKotoV3(koto).approve(_to, type(uint256).max);
        }
        assembly {
            let ptr := mload(0x40)
            ///@dev notifyRewardAmount function sig.
            mstore(ptr, 0x3c6b16ab00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 4), amount)
            let success := call(gas(), _to, 0, ptr, 36, 0, 0)
            if iszero(success) { revert(0, 0) }
        }
    }

    ///@notice set the koto contract address
    function set(address _koto) external onlyOwner {
        koto = _koto;
        IKotoV3(_koto).approve(_koto, type(uint256).max);
        IKotoV3(_koto).approve(UNISWAP_ROUTER, type(uint256).max);
        emit Set(_koto);
    }

    /// @notice create the markets for the eth and lp bonds
    /// @param ethBondAmount the amount of koto tokens to set aside for Eth bonds
    /// @param lpBondAmount the amount of koto tokens to set aside for LP Bonds
    function deposit(uint256 ethBondAmount, uint256 lpBondAmount) external onlyOwner {
        address _koto = koto;
        IKotoV3(_koto).create(ethBondAmount, lpBondAmount);
        emit DepositoryDeposit(_koto, ethBondAmount + lpBondAmount, ethBondAmount, lpBondAmount);
    }

    ///@notice begin timelock function if migrating liquidity is needed
    function start() external onlyOwner {
        execution = block.timestamp + TIMELOCK_INTERVAL;
        emit TimelockStart(block.timestamp, execution);
    }

    ///@notice in a emergency withdraw the liquidity pool tokens after the timelock has passed
    ///@param to the address to send the LP tokens to.
    function emergencyWithdraw(address to) external onlyOwner {
        if (block.timestamp < execution) revert Timelock();
        address _pair = FACTORY.getPair(koto, WETH);
        uint256 _balance = IERC20Minimal(_pair).balanceOf(address(this));
        IERC20Minimal(_pair).transfer(to, _balance);
        execution = type(uint256).max;
        emit LiquidityMigration(to, _balance);
    }

    event DepositoryBond(uint256 ethAmountIn, uint256 kotoAmountOut);
    event DepositoryBurn(uint256 kotoBurnAmount);
    event DepositoryBuy(uint256 ethAmountIn);
    event DepositoryDeposit(address indexed token, uint256 kotoIn, uint256 ethCapacity, uint256 lpCapacity);
    event DepositoryRedeem(uint256 kotoAmountIn, uint256 ethAmountOut);
    event DepositorySell(uint256 kotoAmountOut);
    event LiquidityMigration(address indexed receiver, uint256 amount);
    event Set(address indexed token);
    event TimelockStart(uint256 initializedTime, uint256 executionTime);

    error OnlyOwner();
    error Timelock();
    error TransferFailed();

    receive() external payable {}
}
