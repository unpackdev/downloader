//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/*
This contract receives XRUNE tokens via the `deposit` method from the
`LpTokenVestingKeeper` contract and let's investors part of a given
snapshot (of the vXRUNE/Voters contract) claim their share of that XRUNE.
*/

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IDAO.sol";
import "./IVoters.sol";

contract VotersInvestmentDispenser {
    using SafeERC20 for IERC20;

    IERC20 public xruneToken;
    IDAO public dao;
    mapping(uint => uint) public snapshotAmounts;
    mapping(uint => uint) public claimedAmountsTotals;
    mapping(uint => mapping(address => uint)) public claimedAmounts;

    event Claim(uint snapshotId, address user, uint amount);
    event Deposit(uint snapshotId, uint amount);

    constructor(address _xruneToken, address _dao) {
        xruneToken = IERC20(_xruneToken);
        dao = IDAO(_dao);
    }

    // Calculated based on % of total vote supply at snapshotId, multiplied by amount available, minus claimed
    function claimable(uint snapshotId, address user) public view returns (uint) {
        IVoters voters = IVoters(dao.voters());
        uint total = snapshotAmounts[snapshotId];
        uint totalSupply = voters.totalSupplyAt(snapshotId);
        uint balance = voters.balanceOfAt(user, snapshotId);
        return ((total * balance) / totalSupply) - claimedAmounts[snapshotId][user];
    }

    function claim(uint snapshotId) public {
        uint amount = claimable(snapshotId, msg.sender);
        if (amount > 0) {
            claimedAmounts[snapshotId][msg.sender] += amount;
            claimedAmountsTotals[snapshotId] += amount;
            xruneToken.safeTransfer(msg.sender, amount);
            emit Claim(snapshotId, msg.sender, amount);
        }
    }

    // Used by LpTokenVestingKeeper
    function deposit(uint snapshotId, uint amount) public {
        xruneToken.safeTransferFrom(msg.sender, address(this), amount);
        snapshotAmounts[snapshotId] += amount;
        emit Deposit(snapshotId, amount);
    }

    // Allow DAO to get tokens out and migrate to a different contract
    function withdraw(address token, uint amount) public {
        require(msg.sender == address(dao), '!DAO');
        IERC20(token).safeTransfer(address(dao), amount);
    }
}
