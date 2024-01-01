// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";

struct StakingContract {
    address contractAddress;
    uint8 percentage;
}
struct ProjectWallet {
    address wallet;
    uint8 percentage;
}

contract YieldMagnetFeeHandler is Ownable {
    using SafeERC20 for IERC20;

    address public immutable magnetTokenAddress;

    // Must add up to 100!
    uint8 public platformFeePercentage = 50;
    uint8 public stakingFeePercentage = 50;

    // The amount of WETH that must be in the contract before fees are distributed.
    uint256 public feeDistributionThreshold = 5000000 * 10 ** 18;

    StakingContract[] private _stakingContracts;
    ProjectWallet[] private _projectWallets;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address private immutable wethAddress;

    uint256 public lastStakingPayoutTime = block.timestamp;

    constructor(address magnetTokenAddress_, address stakingAddress_) Ownable(msg.sender) {
        magnetTokenAddress = magnetTokenAddress_;

        _stakingContracts.push(StakingContract(stakingAddress_, 100));
        _projectWallets.push(ProjectWallet(msg.sender, 100));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;

        wethAddress = _uniswapV2Router.WETH();
    }

    /// @notice Retrieves the Staking contract address and their percentages.
    function getStakingContracts()
        public
        view
        returns (StakingContract[] memory)
    {
        return _stakingContracts;
    }

    /// @notice Updates the Staking contract address and their percentages. All percentages must add up to 100. Previous addresses are deleted.
    /// @param stakingContracts_ array of staking contracts
    /// @param percentages_ array of percentage for each contracts
    function updateStakingContracts(
        address[] memory stakingContracts_,
        uint8[] memory percentages_
    ) public onlyOwner {
        require(
            stakingContracts_.length == percentages_.length,
            "YieldMagnetFeeHandler: No of address and No of Percentages doesn't match"
        );

        delete stakingContracts_;
        uint8 totalPercent = 0;

        // Insert the new staking contracts.
        for (uint256 i = 0; i < stakingContracts_.length; i++) {
            require(
                percentages_[i] >= 0 && percentages_[i] <= 100,
                "YieldMagnetFeeHandler: percentage should be between  0 to 100!"
            );
            _stakingContracts.push(
                StakingContract(stakingContracts_[i], percentages_[i])
            );
            totalPercent += percentages_[i];
        }
        require(totalPercent == 100, "Total Percentage should be 100.");
    }

    /// @notice Retrieves the project wallet addresses and their percentages.
    function getProjectWallets() public view returns (ProjectWallet[] memory) {
        return _projectWallets;
    }

    /// @notice Updates the project wallets and their percentages. Percentages must add up to 100.
    /// @param projectWallets_ array of project wallets address
    /// @param percentages_ array of percentage for each wallet
    function updateProjectWallets(
        address[] memory projectWallets_,
        uint8[] memory percentages_
    ) public onlyOwner {
        require(
            projectWallets_.length == percentages_.length,
            "Number of address and Number of Percentages doesn't match."
        );

        delete _projectWallets;
        uint8 totalPercent = 0;

        // Update the new project wallets.
        for (uint256 i = 0; i < projectWallets_.length; i++) {
            require(
                percentages_[i] >= 0 && percentages_[i] <= 100,
                "YieldMagnetFeeHandler: percentage should be between  0 to 100!"
            );
            _projectWallets.push(
                ProjectWallet(projectWallets_[i], percentages_[i])
            );
            totalPercent += percentages_[i];
        }
        require(totalPercent == 100, "Total Percentage should be 100.");
    }

    /// @notice Changes the fee split between staking contract and project wallets. The project wallet's fee will be 100 - stakingFeePercentage.
    /// @dev updates the platformFeePercentage and stakingFeePercentage.
    /// @param _stakingFeePercentage the percentage (0-100) that should go to staking fee. 
    function changeFeePercentages(
        uint8 _stakingFeePercentage
    ) public onlyOwner {
        require(
            _stakingFeePercentage >= 0 && _stakingFeePercentage <= 100,
            "YieldMagnetFeeHandler: percentage should be between  0 to 100!"
        );
        platformFeePercentage = 100 - _stakingFeePercentage;
        stakingFeePercentage = _stakingFeePercentage;
    }

    /// @notice Changes fee distribution threshold.
    /// @dev updates feeDistributionThreshold with new threshold.
    /// @param newFeeDistributionThreshold_ number of threshold and it should be without adding the decimals.
    function changeFeeDistributionThreshold(
        uint256 newFeeDistributionThreshold_
    ) public onlyOwner {
        feeDistributionThreshold = newFeeDistributionThreshold_ * 10 ** 18;
    }

    /// @notice collect the fees from the caller. Allowance and balance must be higher than feeAmount.
    /// @dev transfers the WETH from the caller to the contract.
    /// @param feeAmount amount of WETH to transfer.
    function collectFees(uint256 feeAmount) public {
        IERC20 wethContract = IERC20(wethAddress);
        wethContract.safeTransferFrom(msg.sender, address(this), feeAmount);

        if (wethContract.balanceOf(address(this)) >= feeDistributionThreshold) {
            releaseFees(wethContract.balanceOf(address(this)));
        }
    }

    /// @notice Distributes the fees to the project wallets and the staking contract.
    /// @param amountToRelease_ amount of WETH to distribute.
    function releaseFees(uint256 amountToRelease_) public onlyOwner {
        _releaseFees(amountToRelease_);
    }

    function _distributePlatformCut(uint256 platformCut) private {
        IERC20 wethContract = IERC20(wethAddress);
        for (uint i = 0; i < _projectWallets.length; i++) {
            ProjectWallet memory pw = _projectWallets[i];

            uint256 walletCut = (pw.percentage * platformCut) / 100;
            wethContract.safeTransfer(pw.wallet, walletCut);
        }
    }

    function _distributeStakingCut(uint256 stakersCut) private {
        IERC20 wethContract = IERC20(wethAddress);
        wethContract.approve(address(uniswapV2Router), stakersCut);

        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = magnetTokenAddress;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            stakersCut,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 magnetToPay = IERC20(magnetTokenAddress).balanceOf(
            address(this)
        );

        for (uint256 i = 0; i < _stakingContracts.length; i++) {
            StakingContract memory sc = _stakingContracts[i];

            uint256 stakerContractCut = (sc.percentage * magnetToPay) / 100;

            IERC20(magnetTokenAddress).transfer(sc.contractAddress, stakerContractCut);
        }
    }

    /// @notice Distributes the fees to the project wallets and the staking contract.
    /// @param amountToRelease_ amount of WETH to distribute
    function _releaseFees(uint256 amountToRelease_) private {
        IERC20 wethContract = IERC20(wethAddress);
        require(
            wethContract.balanceOf(address(this)) >= amountToRelease_,
            "Balance is not sufficient!"
        );


        uint256 platformCut = (platformFeePercentage * amountToRelease_) / 100;
        uint256 stakersCut = (stakingFeePercentage * amountToRelease_) / 100;

        _distributePlatformCut(platformCut);
        _distributeStakingCut(stakersCut);

        lastStakingPayoutTime = block.timestamp;
    }

    /// @notice Rescue any tokens that are stuck in the contract.
    function rescueStuckTokens(
        address tokenAddress_,
        uint256 amount_
    ) external onlyOwner {
        require(amount_ > 0, "YieldMagnet: amount can't be 0");
        IERC20 token = IERC20(tokenAddress_);
        token.safeTransfer(msg.sender, amount_);
    }
}