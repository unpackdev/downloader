// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract Vesting is Ownable {
    using SafeERC20 for ERC20;

    address public token; //= 0x8Ef9B898db563d3c6175c2CDdfCe5027C36380fc;
    uint256 private _start;
    address public constant founder =
        0x7FcFdd1ae31BAc46105D9538B81B82d7801C813C;
    address public constant marketing =
        0xD92B05c4Bff1Ca8F108751a4c070A38F726b6925;
    address public constant lp = 0x6f2b439E5944903fE5F53d377877CDbcc2A8056f;
    address public constant stable_reserves =
        0x14053EeDA9c20600E0Ff7795FcA20b18883B971E;
    address public constant bounties =
        0xF90e721813361fE5F1A9808c21f47bC3d8dF42c5;
    address public constant partnerships =
        0x29d3633e1E7eaEA4173e1796f3F86B4010dC8a72;
    address public constant rewards =
        0x232905756A628FE5a18f229Ed8Ba8c1F76a0b802;

    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public claimed;

    constructor(address _token) {
        _start = 1638316800;
        lastClaim[founder] = _start;
        lastClaim[marketing] = _start;
        lastClaim[stable_reserves] = _start;
        lastClaim[partnerships] = _start;
        // Turn back vesting time to allow initial vesting
        lastClaim[lp] = _start - 1;
        lastClaim[rewards] = _start - 1;
        lastClaim[bounties] = _start - 1;
        token = _token;
    }

    function stake(address _from) public {
        ERC20(token).safeTransferFrom(
            _from,
            address(this),
            75_000_000_000 * 1e18
        );
    }

    function claim() external returns (bool) {
        if (
            msg.sender == founder &&
            lastClaim[founder] + 365 days < block.timestamp &&
            claimed[founder] < 150_000_000 * 1e18
        ) {
            lastClaim[founder] = block.timestamp;
            claimed[founder] += 30_000_000 * 1e18;
            ERC20(token).safeTransfer(founder, 30_000_000 * 1e18);
            return true;
        }

        if (
            msg.sender == marketing &&
            lastClaim[marketing] + 30 days < block.timestamp &&
            claimed[marketing] < 150_000_000 * 1e18
        ) {
            lastClaim[marketing] = block.timestamp;
            claimed[marketing] += 2_500_000 * 1e18;
            ERC20(token).safeTransfer(marketing, 2_500_000 * 1e18);
            return true;
        }

        if (
            msg.sender == partnerships &&
            lastClaim[partnerships] + 30 days < block.timestamp &&
            claimed[partnerships] < 150_000_000 * 1e18
        ) {
            lastClaim[partnerships] = block.timestamp;
            if (claimed[partnerships] == 124_999_980 * 1e18) {
                uint256 finalClaim = 150_000_000 * 1e18 - claimed[partnerships];
                claimed[partnerships] += finalClaim;
                ERC20(token).safeTransfer(partnerships, finalClaim);
            } else {
                claimed[partnerships] += 4_166_666 * 1e18;
                ERC20(token).safeTransfer(partnerships, 4_166_666 * 1e18);
            }
            return true;
        }

        if (
            msg.sender == lp &&
            lastClaim[lp] + 30 days < block.timestamp &&
            claimed[lp] < 50_000_000 * 1e18
        ) {
            lastClaim[lp] = block.timestamp;
            // First vesting is instant
            if (claimed[lp] == 0) {
                claimed[lp] += 25_000_000 * 1e18;
                ERC20(token).safeTransfer(lp, 25_000_000 * 1e18);
            } else if (claimed[lp] + 2_083_334 * 1e18 > 50_000_000 * 1e18) {
                uint256 finalClaim = 50_000_000 * 1e18 - claimed[lp];
                claimed[lp] += finalClaim;
                ERC20(token).safeTransfer(lp, finalClaim);
            } else {
                claimed[lp] += 2_083_334 * 1e18;
                ERC20(token).safeTransfer(lp, 2_083_334 * 1e18);
            }
            return true;
        }

        if (
            msg.sender == stable_reserves &&
            lastClaim[stable_reserves] + 90 days < block.timestamp &&
            claimed[stable_reserves] < 50_000_000 * 1e18
        ) {
            lastClaim[stable_reserves] = block.timestamp;
            if (claimed[stable_reserves] == 41_666_660 * 1e18) {
                uint256 finalClaim = 50_000_000 *
                    1e18 -
                    claimed[stable_reserves];
                claimed[stable_reserves] += finalClaim;
                ERC20(token).safeTransfer(stable_reserves, finalClaim);
            } else {
                claimed[stable_reserves] += 4_166_666 * 1e18;
                ERC20(token).safeTransfer(stable_reserves, 4_166_666 * 1e18);
            }
            return true;
        }

        if (
            msg.sender == bounties &&
            lastClaim[bounties] + 90 days < block.timestamp &&
            claimed[bounties] < 50_000_000 * 1e18
        ) {
            lastClaim[bounties] = block.timestamp;
            // First vesting is instant
            if (claimed[bounties] == 0) {
                claimed[bounties] += 2_000_000 * 1e18;
                ERC20(token).safeTransfer(bounties, 2_000_000 * 1e18);
            } else {
                claimed[bounties] += 4_000_000 * 1e18;
                ERC20(token).safeTransfer(bounties, 4_000_000 * 1e18);
            }
            return true;
        }

        if (
            msg.sender == rewards &&
            lastClaim[rewards] + 30 days < block.timestamp &&
            claimed[rewards] < 150_000_000 * 1e18
        ) {
            lastClaim[rewards] = block.timestamp;
            // First vesting is instant
            if (claimed[rewards] == 0) {
                claimed[rewards] += 50_000_000 * 1e18;
                ERC20(token).safeTransfer(rewards, 50_000_000 * 1e18);
            } else if (
                claimed[rewards] + 5_555_556 * 1e18 > 150_000_000 * 1e18
            ) {
                uint256 finalClaim = 150_000_000 * 1e18 - claimed[rewards];
                claimed[rewards] += finalClaim;
                ERC20(token).safeTransfer(rewards, finalClaim);
            } else {
                claimed[rewards] += 5_555_556 * 1e18;
                ERC20(token).safeTransfer(rewards, 5_555_556 * 1e18);
            }
            return true;
        }

        return false;
    }
}
