// SPDX-License-Identifier: MIT
//
// FWB Network
// website.: www.fwb.network

//             @@@@@@@@@@@@
//          @@@@@        @@@@@
//        @@@@              @@@@
//       @@@                  @@@
//      @@                      @@
//     @@@    @@@@@     @@@@     @@
//     @@    @@@@@@    @@@@@@    @@
//    @@@      @@        @@      @@@
//     @@                        @@
//     @@@   @@@          @@@    @@
//      @@     @@@@    @@@@     @@
//       @@@     @@@@@@@@     @@@
//        @@@@              @@@@
//          @@@@@        @@@@@
//             @@@@@@@@@@@@

pragma solidity 0.8.21;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./EnumerableSet.sol";
import "./Address.sol";
import "./Multicall.sol";

interface IStaking {
    function injectRewardsWithTime(
        uint256 amount,
        uint256 rewardsSeconds
    ) external;
}

contract StakingVault is AccessControl, Pausable, Multicall {
    using Address for address payable;
    using SafeERC20 for IERC20;

    bytes32 public constant CALLER_ROLE = keccak256("CALLER_ROLE");

    uint256 public stakingRoundDuration = 1 weeks;
    uint256 public lastStakingRound;
    IStaking public staking;

    uint256 public currentRewards;
    uint256 public totalRewards;

    IERC20 public FWB;

    constructor() {
        lastStakingRound = block.timestamp;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(CALLER_ROLE, _msgSender());
        _pause();
    }

    function startRound(
        uint256 amount,
        bool checkTime
    ) external onlyRole(CALLER_ROLE) whenNotPaused {
        require(
            address(staking) != address(0),
            "StakingVault: Staking contract not set"
        );
        if (checkTime) {
            require(
                block.timestamp > lastStakingRound + stakingRoundDuration,
                "StakingVault: Need to wait longer"
            );
        }
        require(
            FWB.balanceOf(address(this)) > amount,
            "StakingVault: Not enough FWB balance"
        );
        _startStakingRound(amount);
    }

    function _startStakingRound(uint256 amount) internal {
        totalRewards += amount;
        lastStakingRound = block.timestamp;
        FWB.forceApprove(address(staking), amount);
        staking.injectRewardsWithTime(amount, stakingRoundDuration);
    }

    function setStakingRoundDuration(
        uint256 _stakingRoundDuration
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingRoundDuration = _stakingRoundDuration;
    }

    function setStaking(
        IStaking _staking
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        staking = _staking;
    }

    function setToken(IERC20 _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FWB = _token;
    }

    function rescueETH(
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(to).sendValue(amount);
    }

    function rescueTokens(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.safeTransfer(to, amount);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function sendCustomTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data
    ) public payable onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes memory) {
        bytes32 txHash = keccak256(abi.encode(target, value, signature, data));
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }
        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(success, "Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data);

        return returnData;
    }

    receive() external payable {}

    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint value,
        string signature,
        bytes data
    );
}
