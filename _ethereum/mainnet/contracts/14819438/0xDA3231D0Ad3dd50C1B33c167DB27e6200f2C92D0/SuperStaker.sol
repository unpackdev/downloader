// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ILendingPool.sol";
import "./IFlashLoanReceiver.sol";
import "./IStETH.sol";
import "./IWETH9.sol";

contract SuperStaker is Ownable, Pausable, ReentrancyGuard, IFlashLoanReceiver {
    using SafeMath for uint256;
    using SafeERC20 for IStETH;

    IStETH public steth;
    IWETH9 public weth;
    address public referral;
    ILendingPool public pool;

    event SuperStaked(uint256 stethShares);

    constructor(address payable _weth, address _steth, address _pool, address _referral) {
        steth = IStETH(_steth);
        weth = IWETH9(_weth);
        referral = _referral;
        pool = ILendingPool(_pool);
        steth.approve(_pool, 2**256 - 1);
    }

    // @dev SuperStakes native ETH sent to the function
    function stake(uint256 factor) payable external nonReentrant {
        require(msg.value != 0, "0eth");
        _stake(msg.value.mul(factor).div(100));      
    }

    // @dev sender already has stETH and want to superStake
    function superStake(uint256 shares, uint256 factor) external nonReentrant {
        // @dev tranfer stETH to this contract (temporaily) - must get approval first:
        steth.safeTransferFrom(msg.sender, address(this), shares);
        _stake(shares.mul(factor).div(100));   
    }

    function _stake(uint256 loanAmt) internal {
        address[] memory assets = new address[](1);
        assets[0] = address(weth);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = loanAmt;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 2; // variable debt taken by msg.sender
        pool.flashLoan(address(this), assets, amounts, modes, msg.sender, abi.encode(msg.sender), uint16(0));
    }

    function executeOperation(address[] calldata assets, uint256[] calldata amounts, uint256[] calldata premiums, address initiator, bytes calldata params) external override returns (bool) {
        require(msg.sender == address(pool), '!sender');
        (address sender) = abi.decode(params, (address));
        weth.withdraw(amounts[0]);
        // @dev stake inital msg.value + flash loan proceeds via Lido:
        steth.submit{value: address(this).balance}(referral);
        emit SuperStaked( steth.balanceOf(address(this)) );
        // @dev deposit resulting stETH as collateral in Aave:
        pool.deposit(address(steth), steth.balanceOf(address(this)), sender, 0);       
        return true;
    }

    receive() external payable {}
    fallback() external payable {}
}