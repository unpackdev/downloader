// SPDX-License-Identifier: MIT

/* Borrowed heavily from Synthetix

* MIT License
* ===========
*
* Copyright (c) 2021 Synthetix
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
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

import "./IBankNodeManager.sol";

import "./BankNodeRewardSystem.sol";

contract BankNodeLendingRewards is Initializable, BankNodeRewardSystem {
    using SafeERC20 for IERC20;

    function initialize(
        uint256 _defaultRewardsDuration,
        address _rewardsToken,
        address _bankNodeManager,
        address distributorAdmin,
        address managerAdmin
    ) external initializer {
        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        rewardsToken = IERC20(_rewardsToken);
        bankNodeManager = IBankNodeManager(_bankNodeManager);
        defaultRewardsDuration = _defaultRewardsDuration;

        _setupRole(REWARDS_DISTRIBUTOR_ROLE, _bankNodeManager);
        _setupRole(REWARDS_DISTRIBUTOR_ROLE, distributorAdmin);
        _setupRole(REWARDS_DISTRIBUTOR_ADMIN_ROLE, distributorAdmin);
        _setRoleAdmin(REWARDS_DISTRIBUTOR_ROLE, REWARDS_DISTRIBUTOR_ADMIN_ROLE);

        _setupRole(REWARDS_MANAGER, _bankNodeManager);
        _setupRole(REWARDS_MANAGER, managerAdmin);
        _setupRole(REWARDS_MANAGER_ROLE_ADMIN, managerAdmin);
        _setRoleAdmin(REWARDS_MANAGER, REWARDS_MANAGER_ROLE_ADMIN);
    }

    function _bnplTokensStakedToBankNode(uint32 bankNodeId) internal view returns (uint256) {
        return
            rewardsToken.balanceOf(
                _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(bankNodeId))
            );
    }

    function getBNPLTokenDistribution(uint256 amount) external view returns (uint256[] memory) {
        uint32 nodeCount = bankNodeManager.bankNodeCount();
        uint256[] memory bnplTokensPerNode = new uint256[](nodeCount);
        uint32 i = 0;
        uint256 amt = 0;
        uint256 total = 0;
        while (i < nodeCount) {
            amt = rewardsToken.balanceOf(
                _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(i + 1))
            );
            bnplTokensPerNode[i] = amt;
            total += amt;
            i += 1;
        }
        i = 0;
        while (i < nodeCount) {
            bnplTokensPerNode[i] = (bnplTokensPerNode[i] * amount) / total;
            i += 1;
        }
        return bnplTokensPerNode;
    }

    function distributeBNPLTokensToBankNodes(uint256 amount)
        external
        onlyRole(REWARDS_DISTRIBUTOR_ROLE)
        returns (uint256)
    {
        require(amount > 0, "cannot send 0");
        rewardsToken.safeTransferFrom(msg.sender, address(this), amount);
        uint32 nodeCount = bankNodeManager.bankNodeCount();
        uint256[] memory bnplTokensPerNode = new uint256[](nodeCount);
        uint32 i = 0;
        uint256 amt = 0;
        uint256 total = 0;
        while (i < nodeCount) {
            if (getPoolLiquidityTokensStakedInRewards(i + 1) != 0) {
                amt = rewardsToken.balanceOf(
                    _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(i + 1))
                );
                bnplTokensPerNode[i] = amt;
                total += amt;
            }
            i += 1;
        }
        i = 0;
        while (i < nodeCount) {
            amt = (bnplTokensPerNode[i] * amount) / total;
            if (amt != 0) {
                _notifyRewardAmount(i + 1, amt);
            }
            i += 1;
        }
        return total;
    }

    function distributeBNPLTokensToBankNodes2(uint256 amount)
        external
        onlyRole(REWARDS_DISTRIBUTOR_ROLE)
        returns (uint256)
    {
        uint32 nodeCount = bankNodeManager.bankNodeCount();
        uint32 i = 0;
        uint256 amt = 0;
        uint256 total = 0;
        while (i < nodeCount) {
            total += rewardsToken.balanceOf(
                _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(i + 1))
            );
            i += 1;
        }
        i = 0;
        while (i < nodeCount) {
            amt =
                (rewardsToken.balanceOf(
                    _ensureContractAddressNot0(bankNodeManager.getBankNodeStakingPoolContract(i + 1))
                ) * amount) /
                total;
            if (amt != 0) {
                _notifyRewardAmount(i + 1, amt);
            }
            i += 1;
        }
        return total;
    }
}
