// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./DataTypes.sol";
import "./Errors.sol";

/**
 * @title Aito Vault Contract
 * @author Aito
 *
 * @notice A contract that holds a staking auction won NFT's associated stkAAVE.
 */
contract Vault {
    using Address for address;

    address public immutable STAKING_AUCTION;

    constructor(address stakingAuction) {
        STAKING_AUCTION = stakingAuction;
    }

    modifier onlyStakingAuction() {
        require(msg.sender == STAKING_AUCTION, Errors.NOT_STAKING_AUCTION);
        _;
    }

    /**
     * @notice Executes the given low-level calls on given targets. Sender must be auction.
     *
     * @param targets The array of target addresses to call.
     * @param datas The array of abi encoded function data to call on each target.
     * @param callTypes The array of call types to execute, either regular call or delegateCall.
     */
    function execute(
        address[] calldata targets,
        bytes[] calldata datas,
        DataTypes.CallType[] calldata callTypes // The OpenZeppelin "Address" library handles reverting on failed calls.
    ) external onlyStakingAuction {
        require(
            targets.length == datas.length && datas.length == callTypes.length,
            Errors.VAULT_ARRAY_MISMATCH
        );

        for (uint256 i = 0; i < targets.length; i++) {
            if (callTypes[i] == DataTypes.CallType.Call) {
                targets[i].functionCall(datas[i]);
            } else if (callTypes[i] == DataTypes.CallType.DelegateCall) {
                targets[i].functionDelegateCall(datas[i]);
            } else {
                revert(Errors.INVALID_CALL_TYPE);
            }
        }
    }
}
