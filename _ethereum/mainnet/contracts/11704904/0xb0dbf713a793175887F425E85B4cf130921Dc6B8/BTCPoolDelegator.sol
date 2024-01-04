// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

contract BTCPoolDelegator {
    address[] public _coins;
    uint256[] public _balances;
    uint256 public fee;
    uint256 public admin_fee;
    uint256 constant max_admin_fee = 5 * 10**9;
    address public owner;
    address token;

    uint256 constant A_PRECISION = 100;
    uint256 public initial_A;
    uint256 public future_A;
    uint256 public initial_A_time;
    uint256 public future_A_time;

    uint256 public admin_actions_deadline;
    uint256 public transfer_ownership_deadline;

    uint256 public future_fee;
    uint256 public future_admin_fee;
    address public future_owner;

    uint256 kill_deadline;
    uint256 constant kill_deadline_dt = 2 * 30 * 86400;
    bool is_killed;

    constructor(
        address _owner,
        address[3] memory coins_,
        address _lp_token,
        uint256 _A,
        uint256 _init_fee,
        uint256 _admin_fee
    ) public {
        for (uint256 i = 0; i < 3; i++) {
            require(coins_[i] != address(0));
            _balances.push(0);
            _coins.push(coins_[i]);
        }

        initial_A = _A * A_PRECISION;
        future_A = _A * A_PRECISION;
        fee = _init_fee;
        admin_fee = _admin_fee;
        owner = _owner;
        kill_deadline = block.timestamp + kill_deadline_dt;
        is_killed = false;
        token = _lp_token;
    }

    // receive() external payable {}

    function balances(int128 i) public view returns (uint256) {
        return _balances[uint256(i)];
    }

    function coins(int128 i) public view returns (address) {
        return _coins[uint256(i)];
    }

    fallback() external payable {
        address _target = 0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0x0, calldatasize())
            let _retval := delegatecall(
                gas(),
                _target,
                ptr,
                calldatasize(),
                0,
                0
            )
            returndatacopy(ptr, 0, returndatasize())

            switch _retval
                case 0 {
                    revert(ptr, returndatasize())
                }
                default {
                    return(ptr, returndatasize())
                }
        }
    }
}