// SPDX-License-Identifier: Unlicense

pragma solidity >=0.6.0 <0.8.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./ERC20MintSnapshot.sol";

contract FeeAccrual {
    using SafeMath for uint256;
    using SafeERC20 for ERC20MintSnapshot;

    Fees[] internal accruedFees;

    struct Fees {
        uint32 blockNumber;
        uint224 amount;
        mapping(address => bool) claimed;
    }

    // Token to pay out fees in and query about proportions
    ERC20MintSnapshot internal immutable PRISM;
    // Address to signify snapshotted total mint amount
    address private constant TOTAL_MINT = address(0);

    event CrossChainFeesClaimed(address indexed beneficiary, uint256 amount);

    constructor(ERC20MintSnapshot prism) internal {
        PRISM = prism;
    }

    function totalAvailableRedemption() external view returns (uint256 total) {
        for (uint256 i = 0; i < accruedFees.length; i++)
            total = total.add(availableRedemption(i));
    }

    function availableRedemption(uint256 num) public view returns (uint256) {
        Fees memory fees = accruedFees[num];

        if (accruedFees[num].claimed[msg.sender]) return 0;

        uint256 userMints =
            uint256(PRISM.getPriorMints(msg.sender, fees.blockNumber));
        uint256 totalMints =
            uint256(PRISM.getPriorMints(TOTAL_MINT, fees.blockNumber));
        uint256 amount = uint256(fees.amount);

        return amount.mul(userMints).div(totalMints);
    }

    function redeemAll() external {
        uint256 availableFees = 0;
        for (uint256 i = 0; i < accruedFees.length; i++) {
            uint256 available = availableRedemption(i);
            if (available > 0) {
                availableFees = availableFees.add(available);
                accruedFees[i].claimed[msg.sender] = true;
            }
        }
        require(availableFees > 0, "FeeAccrual::redeem: No fees are claimable");

        PRISM.safeTransfer(msg.sender, availableFees);

        emit CrossChainFeesClaimed(msg.sender, availableFees);
    }

    function redeem(uint256 num) external {
        uint256 availableFees = availableRedemption(num);

        require(
            availableFees != 0,
            "FeeAccrual::redeem: No fees are claimable"
        );

        accruedFees[num].claimed[msg.sender] = true;
        PRISM.safeTransfer(msg.sender, availableFees);

        emit CrossChainFeesClaimed(msg.sender, availableFees);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }
}
