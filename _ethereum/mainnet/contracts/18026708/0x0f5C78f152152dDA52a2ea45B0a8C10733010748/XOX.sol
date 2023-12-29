// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./XOXTokenBase.sol";
import "./Address.sol";

contract XOX is XOXTokenBase {
    using Address for address;

    uint256 public constant amount_team_allocation = 12_600_000 ether;
    uint256 public constant amount_company_reserve = 9_720_000 ether;
    uint256 public constant amount_strategic_partnerships = 9_000_000 ether;
    uint256 public constant amount_ecosystem_growth = 12_600_000 ether;
    uint256 public constant amount_community_rewards = 1_800_000 ether;
    uint256 public constant amount_lp_farming = 18_000_000 ether;
    uint256 public constant amount_cex_listing = 18_000_000 ether;
    uint256 public constant amount_seed_sale = 2_880_000 ether;
    uint256 public constant amount_pre_sale = 72_000_000 ether;
    uint256 public constant amount_public_sale_liquidity_pools_address =
        23_400_000 ether;

    constructor(
        address timelockAdmin_,
        address timelockSystem_,
        address feeWallet_,
        address uniswapV2Router_,
        address[] memory path_,
        uint256 timeStartTrade_
    )
        XOXTokenBase(
            "XOX Labs",
            "XOX",
            18,
            timelockSystem_,
            feeWallet_,
            uniswapV2Router_,
            path_,
            timeStartTrade_
        )
    {
        require(
            timelockAdmin_.isContract(),
            "ERC20: timelock is smartcontract"
        );
        _transferOwnership(timelockAdmin_);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function changeTaxFee(uint256 taxFee_) external onlyOwner {
        _changeTaxFee(taxFee_);
    }

    function changeFeeWallet(address feeWallet) external onlyOwner {
        _changeFeeWallet(feeWallet);
    }

    function changeSwapPath(address[] memory path_) external onlyOwner {
        _changeSwapPath(path_);
    }

    function setSwapAndLiquifyEnabled(
        bool swapAndLiquifyEnabled_
    ) external onlyOwner {
        _setSwapAndLiquifyEnabled(swapAndLiquifyEnabled_);
    }

    function setupTokenAllocation(
        address[10] memory allocations
    ) external onlyOwner {
        _mintTokenAllocation(allocations[0], amount_team_allocation); // Team allocation
        _mintTokenAllocation(allocations[1], amount_company_reserve); // Company Reserve
        _mintTokenAllocation(allocations[2], amount_strategic_partnerships); // Strategic Partnerships
        _mintTokenAllocation(allocations[3], amount_ecosystem_growth); // Ecosystem Growth
        _mintTokenAllocation(allocations[4], amount_community_rewards); // Community Rewards
        _mintTokenAllocation(allocations[5], amount_lp_farming); // LP Farming
        _mintTokenAllocation(allocations[6], amount_cex_listing); // CEX Listing
        _mintTokenAllocation(allocations[7], amount_seed_sale); //  Seed Sale - Partner Sale
        _mintTokenAllocation(allocations[8], amount_pre_sale); // Pre Sale
        _mintTokenAllocation(
            allocations[9],
            amount_public_sale_liquidity_pools_address
        ); // Owner
    }

    function _mintTokenAllocation(
        address allocation_,
        uint256 amount_
    ) private {
        require(
            allocation_.isContract(),
            "ERC20: allocation is a smartcontract"
        );
        _mint(allocation_, amount_);
    }
}
