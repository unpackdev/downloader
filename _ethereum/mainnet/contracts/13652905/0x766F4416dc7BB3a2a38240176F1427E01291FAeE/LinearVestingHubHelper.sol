// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ILinearVestingHub.sol";
import "./SVesting.sol";
import "./VestingFormulaFunctions.sol";

contract LinearVestingHubHelper {
    // solhint-disable-next-line var-name-mixedcase
    ILinearVestingHub public immutable LINEAR_VESTING_HUB;

    constructor(ILinearVestingHub linearVestingHub_) {
        LINEAR_VESTING_HUB = linearVestingHub_;
    }

    function isLinearVestingHubHealthy() external view returns (bool) {
        return
            LINEAR_VESTING_HUB.TOKEN().balanceOf(address(LINEAR_VESTING_HUB)) ==
            calcTotalBalance();
    }

    function getVestingsPaginated(
        address receiver_,
        uint256 startVestingId_,
        uint256 pageSize_
    ) external view returns (Vesting[] memory vestings) {
        uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
            receiver_
        );
        uint256 endVestingId = nextVestingId > startVestingId_ + pageSize_
            ? startVestingId_ + pageSize_
            : nextVestingId;
        vestings = new Vesting[](endVestingId - startVestingId_);

        uint8 j = 0;
        for (uint256 i = startVestingId_; i < endVestingId; i++) {
            vestings[j] = LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, i);
            j++;
        }
    }

    function getMaxWithdrawByVesting(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return
                vesting.receiver != address(0)
                    ? _getTknMaxWithdraw(
                        vesting.tokenBalance,
                        vesting.withdrawnTokens,
                        vesting.startTime,
                        vesting.cliffDuration,
                        vesting.duration
                    )
                    : 0;
        } catch {
            return 0;
        }
    }

    function getMaxWithdrawByReceiver(address receiver_)
        public
        view
        returns (uint256 maxWithdraw)
    {
        uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
            receiver_
        );

        for (uint256 i = 0; i < nextVestingId; i++)
            maxWithdraw += getMaxWithdrawByVesting(receiver_, i);
    }

    function getVestedTkn(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return
                vesting.receiver != address(0)
                    ? _getVestedTkns(
                        vesting.tokenBalance,
                        vesting.withdrawnTokens,
                        vesting.startTime,
                        vesting.duration
                    )
                    : 0;
        } catch {
            return 0;
        }
    }

    function getUnvestedTkn(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return
                vesting.receiver != address(0)
                    ? vesting.tokenBalance -
                        _getTknMaxWithdraw(
                            vesting.tokenBalance,
                            vesting.withdrawnTokens,
                            vesting.startTime,
                            vesting.cliffDuration,
                            vesting.duration
                        )
                    : 0;
        } catch {
            return 0;
        }
    }

    function calcTotalVestedTokens()
        public
        view
        returns (uint256 totalVestedTkn)
    {
        address[] memory receivers = LINEAR_VESTING_HUB.receivers();

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
                receivers[i]
            );
            for (uint256 j = 0; j < nextVestingId; j++)
                totalVestedTkn += getVestedTkn(receivers[i], j);
        }
    }

    function calcTotalUnvestedTokens()
        public
        view
        returns (uint256 totalUnvestedTkn)
    {
        address[] memory receivers = LINEAR_VESTING_HUB.receivers();

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
                receivers[i]
            );
            for (uint256 j = 0; j < nextVestingId; j++)
                totalUnvestedTkn += getUnvestedTkn(receivers[i], j);
        }
    }

    function getVestingBalance(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return vesting.receiver != address(0) ? vesting.tokenBalance : 0;
        } catch {
            return 0;
        }
    }

    function calcTotalBalance() public view returns (uint256 totalBalance) {
        address[] memory receivers = LINEAR_VESTING_HUB.receivers();

        for (uint256 i = 0; i < receivers.length; i++) {
            uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
                receivers[i]
            );
            for (uint256 j = 0; j < nextVestingId; j++)
                totalBalance += getVestingBalance(receivers[i], j);
        }
    }
}
