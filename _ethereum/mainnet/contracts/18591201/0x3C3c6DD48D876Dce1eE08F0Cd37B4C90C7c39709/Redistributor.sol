// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./IRevenueDistributionToken.sol";


contract Redistributor is Ownable {
    uint public distributionThreshold;
    uint public liquidityShare;
    uint public crocShare;
    uint public vestingPeriod;
    uint public distributionTime;

    address public croc;
    address public crocVault;
    address public lpVault;

    IUniswapV2Router02 public uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    event Distribution(uint ethForCroc, uint ethForLiq);

    constructor(
        uint _liquidityShare,
        uint _crocShare,
        address _crocVault,
        address _croc,
        address _lpVault,
        uint _vestingPeriod,
        uint _threshold
    ) {
        liquidityShare = _liquidityShare;
        crocShare = _crocShare;
        crocVault = _crocVault;
        lpVault = _lpVault;
        croc = _croc;
        vestingPeriod = _vestingPeriod;
        distributionTime = block.timestamp;
        distributionThreshold = _threshold;
    }

    // Handle receiving ETH

    receive() external payable { _onETHReceived(); }
    fallback() external payable { _onETHReceived(); }

    function _onETHReceived() internal {
        if (
            msg.sender != address(uniswapRouter) &&
            address(this).balance >= distributionThreshold &&
            block.timestamp >= distributionTime
        ) {
            _triggerDistribution();
        }
    }

    function _triggerDistribution() internal {
        uint totalAccumulated = address(this).balance;
        uint ethForCrocVault = (totalAccumulated * crocShare) / 100;
        uint ethForLPVault = totalAccumulated - ethForCrocVault;

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = croc;

        // Buy CROC
        uniswapRouter.swapExactETHForTokens{value: ethForCrocVault}(
            0, 
            path,
            address(this),
            block.timestamp
        );

        // Deposit to CrocVault
        IERC20(croc).transfer(crocVault, IERC20(croc).balanceOf(address(this)));
        IRevenueDistributionToken(crocVault).updateVestingSchedule(vestingPeriod);

        // Buy more CROC
        uniswapRouter.swapExactETHForTokens{value: ethForLPVault / 2}(
            0,
            path,
            address(this),
            block.timestamp
        );

        // Approve
        if (IERC20(croc).allowance(address(this), address(uniswapRouter)) < type(uint256).max) {
            IERC20(croc).approve(address(uniswapRouter), type(uint256).max);
        }

        // Add liquidity
        uniswapRouter.addLiquidityETH{value: ethForLPVault / 2}(
            croc,
            IERC20(croc).balanceOf(address(this)),
            0,
            0,
            lpVault,
            block.timestamp
        );

        IRevenueDistributionToken(lpVault).updateVestingSchedule(vestingPeriod);

        distributionTime = block.timestamp + 6 hours;

        emit Distribution(ethForCrocVault, ethForLPVault);
    }

    // Admin functions

    function editDistributionThreshold(uint _newThreshold) external onlyOwner {
        distributionThreshold = _newThreshold;
    }

    function acceptVaultOwnership(address _vault) external onlyOwner {
        IRevenueDistributionToken(_vault).acceptOwnership();
    }

    function setVaultPendingOwner(address _vault, address _newOwner) external onlyOwner {
        IRevenueDistributionToken(_vault).setPendingOwner(_newOwner);
    }

    function editShares(uint _crocShare, uint _liquidityShare) external onlyOwner {
        crocShare = _crocShare;
        liquidityShare = _liquidityShare;
    }

    function editVesting(uint _vestingPeriod) external onlyOwner {
        vestingPeriod = _vestingPeriod;
    }

    function emergencyWithdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function emergencyWithdrawToken(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}
