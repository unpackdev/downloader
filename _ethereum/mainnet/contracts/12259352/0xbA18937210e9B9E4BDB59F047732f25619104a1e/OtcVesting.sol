//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./TokenTimelock.sol";

/*
    Simple OTC Escrow contract to transfer vested ROBOT in exchange for specified DAI amount
*/
contract OtcVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant robot = 0xfb5453340C03db5aDe474b27E68B6a9c6b2823Eb;
    address constant mfTreasury = 0x2150Cb38ee362bceAC3d4A2704A82eeeD02E93EC;

    event VestingDeployed(address vesting);

    address public beneficiary;
    uint256 public duration;
    uint256 public daiAmount;
    uint256 public robotAmount;

    constructor(
        address beneficiary_,
        uint256 duration_,
        uint256 daiAmount_,
        uint256 robotAmount_
    ) public {
        beneficiary = beneficiary_;
        duration = duration_;
        daiAmount = daiAmount_;
        robotAmount = robotAmount_;
    }

    modifier onlyApprovedParties() {
        require(msg.sender == mfTreasury || msg.sender == beneficiary);
        _;
    }

    /// @dev Atomically trade specified amonut of USDC for control over robot in vesting contract
    /// @dev Either counterparty may execute swap if sufficient token approval is given by recipient
    function swap() public onlyApprovedParties {
        // Transfer expected USDC from beneficiary
        IERC20(dai).safeTransferFrom(beneficiary, address(this), daiAmount);

        // Create Vesting contract
        TokenTimelock vesting = new TokenTimelock(
            IERC20(robot),
            beneficiary,
            now + duration
        );

        // Transfer robot to vesting contract
        IERC20(robot).transferFrom(mfTreasury, address(vesting), robotAmount);

        // Transfer DAI to MF Treasury
        IERC20(dai).transfer(mfTreasury, daiAmount);

        emit VestingDeployed(address(vesting));
    }

    /// @dev Return Robot to MF Treasury to revoke OTC deal
    function revoke() external {
        require(msg.sender == mfTreasury, "onlyMfTreasury");
        uint256 robotBalance = IERC20(robot).balanceOf(address(this));
        IERC20(robot).safeTransfer(mfTreasury, robotBalance);
    }

    function revokeDai() external onlyApprovedParties {
        uint256 daiBalance = IERC20(dai).balanceOf(address(this));
        IERC20(dai).safeTransfer(beneficiary, daiBalance);
    }
}
