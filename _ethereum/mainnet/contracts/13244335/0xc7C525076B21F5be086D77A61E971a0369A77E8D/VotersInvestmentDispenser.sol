//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
This contract receives XRUNE tokens via the `deposit` method from the
`LpTokenVestingKeeper` contract and let's investors part of a given
snapshot (of the vXRUNE/Voters contract) claim their share of that XRUNE.
*/

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./IDAO.sol";
import "./IVoters.sol";

contract VotersInvestmentDispenser is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER");
    IERC20 public xruneToken;
    IDAO public dao;
    mapping(uint => uint) public snapshotAmounts;
    mapping(uint => uint) public claimedAmountsTotals;
    mapping(uint => mapping(address => uint)) public claimedAmounts;

    event Claim(uint snapshotId, address user, uint amount, address to);
    event Deposit(uint snapshotId, uint amount);

    constructor(address _xruneToken, address _dao) {
        require(_xruneToken != address(0), "token !zero");
        require(_dao != address(0), "dao !zero");
        xruneToken = IERC20(_xruneToken);
        dao = IDAO(_dao);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CLAIMER_ROLE, ADMIN_ROLE);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(CLAIMER_ROLE, msg.sender);
    }

    // Calculated based on % of total vote supply at snapshotId, multiplied by amount available, minus claimed
    function claimable(uint snapshotId, address user) public view returns (uint) {
        IVoters voters = IVoters(dao.voters());
        uint total = snapshotAmounts[snapshotId];
        uint totalSupply = voters.totalSupplyAt(snapshotId);
        uint balance = voters.balanceOfAt(user, snapshotId);
        require(totalSupply > 0, "totalSupply = 0");
        return ((total * balance) / totalSupply) - claimedAmounts[snapshotId][user];
    }

    function claimableMultiple(uint[] calldata snapshotIds, address user) public view returns (uint[] memory) {
        uint[] memory results = new uint[](snapshotIds.length);
        for (uint i = 0; i < snapshotIds.length; i++) {
            results[i] = claimable(snapshotIds[i], user);
        }
        return results;
    }

    function _claim(address user, uint snapshotId, address to) private {
        uint amount = claimable(snapshotId, user);
        if (amount > 0) {
            claimedAmounts[snapshotId][user] += amount;
            claimedAmountsTotals[snapshotId] += amount;
            xruneToken.safeTransfer(to, amount);
            emit Claim(snapshotId, user, amount, to);
        }
    }

    function claim(uint snapshotId) external {
        _claim(msg.sender, snapshotId, msg.sender);
    }

    function claimTo(uint snapshotId, address to) external {
        _claim(msg.sender, snapshotId, to);
    }

    function claimToFor(address user, uint snapshotId, address to) external onlyRole(CLAIMER_ROLE) {
        _claim(user, snapshotId, to);
    }

    function claimMultipleTo(uint[] calldata snapshotIds, address to) external {
        for (uint i = 0; i < snapshotIds.length; i++) {
            _claim(msg.sender, snapshotIds[i], to);
        }
    }

    // Used by LpTokenVestingKeeper
    function deposit(uint snapshotId, uint amount) external {
        xruneToken.safeTransferFrom(msg.sender, address(this), amount);
        snapshotAmounts[snapshotId] += amount;
        emit Deposit(snapshotId, amount);
    }

    // Allow DAO to get tokens out and migrate to a different contract
    function withdraw(address token, uint amount, address to) external {
        require(msg.sender == address(dao), "!dao");
        IERC20(token).safeTransfer(to, amount);
    }
}
