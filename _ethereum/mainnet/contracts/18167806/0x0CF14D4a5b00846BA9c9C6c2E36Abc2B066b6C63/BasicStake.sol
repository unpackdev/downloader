// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeERC20.sol";

import "./IBasicStake.sol";

contract BasicStake is IBasicStake {
    using SafeERC20 for IERC20;
    // ERC20 basic token contract being held
    IERC20 private immutable m_BaseCoin;

    mapping(address => recdBasicUnit) m_mpStake;

    constructor(address token) {
        require(token != address(0), "Zero address is not allowed");
        m_BaseCoin = IERC20(token);
    }

    function applyStake(
        address investor,
        uint256 nonce,
        uint256[] memory aryTime,
        uint256[] memory aryAmount
    ) external {
        require(
            msg.sender == address(m_BaseCoin),
            "caller should be BaseCoin contract"
        );
        require(m_mpStake[investor].nonce == nonce - 1, "wrong nonce");

        // current available elements for staking
        uint256 total = m_mpStake[investor].aryLKTime.length;
        uint256 occupied = total - m_mpStake[investor].offset;
        require(
            aryTime.length <= 10 - occupied,
            "exceed allowance staking elements"
        );

        // compare first aryTime element
        if (total != 0) {
            require(
                aryTime[0] > m_mpStake[investor].aryLKTime[total - 1],
                "aryTime elements should be in ascending order[S]"
            );
        }

        for (uint i = 0; i < aryTime.length; i++) {
            m_mpStake[investor].aryLKTime.push(aryTime[i]);
            m_mpStake[investor].aryAmount.push(aryAmount[i]);
        }

        m_mpStake[investor].nonce = nonce;
        emit evApplyStake(investor, nonce, aryTime, aryAmount);
    }

    function claimStake() public {
        uint256 total = 0;
        for (
            uint256 i = m_mpStake[msg.sender].offset;
            i < m_mpStake[msg.sender].aryLKTime.length;
            i++
        ) {
            if (block.timestamp > m_mpStake[msg.sender].aryLKTime[i]) {
                total += m_mpStake[msg.sender].aryAmount[i];
                m_mpStake[msg.sender].offset++;
            } else {
                break;
            }
        }
        m_BaseCoin.safeTransfer(msg.sender, total);
        emit evClaimStake(msg.sender, total);
    }

    function queryStake(
        address user
    ) external view returns (recdBasicUnit memory userStake) {
        return m_mpStake[user];
    }
}
