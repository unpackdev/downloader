// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.4;

import "./Ownable.sol";

interface IHodler {
    function totalBonus() external view returns (uint256);
    function correctionAmount() external view returns (uint256);
}

interface IVester {
    function vestingBalance(address _account) external view returns (uint256);
    function totalGroove() external view returns (uint256);
    function vest(address account, uint256 amount) external;
}

/// @notice GRP vesting bonus claims contract - Where all unvested GRO are returned if user exits vesting contract early
contract GROHodler is Ownable {
    uint256 public constant DEFAULT_DECIMAL_FACTOR = 1E18;
    // The main vesting contract
    address public immutable vester;
    // Total amount of unvested GRO that has been tossed aside
    uint256 public totalBonus;
    // Estimation of total unvested GRO can become unreliable if there is a significant
    //  amount of users who have vesting periods that exceed their vesting end date.
    //  We use a manual correction variable to deal with this issue for now.
    uint256 public correctionAmount;
    // How long you have to wait between claims
    uint256 public claimDelay;
    // Contract that can help maintain the bonus contract by adjusting variables
    address public maintainer;
    
    // keep track of users last claim
    mapping(address => uint256) public userClaims;
    bool paused = true;

    event LogBonusAdded(uint256 amount);
    event LogBonusClaimed(address user, uint256 amount);
    event LogNewClaimDelay(uint256 delay);
    event LogNewCorrectionVariable(uint256 correction);
    event LogNewMaintainer(address newMaintainer);
    event LogNewStatus(bool status);

    constructor(address _vester, address oldHodler) {
        vester = _vester;
        // if we migrated to a new bonus contract, make sure to add the old bonus and correction
        if (oldHodler != address(0)) {
            totalBonus = IHodler(oldHodler).totalBonus();
            correctionAmount = IHodler(oldHodler).correctionAmount();
        }
    }

    /// @notice every time a users exits a vesting position, the penalty gets added to this contract
    /// @param amount user penealty amount
    function add(uint256 amount) external {
        require(msg.sender == vester);
        totalBonus += amount;
        emit LogBonusAdded(amount);
    }

    /// @notice Set a new maintainer
    /// @param newMaintainer address of new maintainer
    /// @dev Maintainer will mostly be used to be able to change the correctionValue
    ///  on short notice, as this can change on short notice depending on if users interact with
    ///  their position in the vesting contract
    function setMaintainer(address newMaintainer) external onlyOwner {
        maintainer = newMaintainer;
        emit LogNewMaintainer(newMaintainer);
    }

    /// @notice Start or stop the bonus contract
    /// @param pause Contract Pause state
    function setStatus(bool pause) external {
        require(msg.sender == maintainer || msg.sender == owner(), 'setCorrectionVariable: !authorized');
        paused = pause;
        emit LogNewStatus(pause);
    }

    /// @notice maintainer can correct total amount of vested GRO to adjust for drift of central curve vs user curves
    /// @param newCorrection a positive number to deduct from the unvested GRO to correct for central drift
    function setCorrectionVariable(uint256 newCorrection) external {
        require(msg.sender == maintainer || msg.sender == owner(), 'setCorrectionVariable: !authorized');
        require(newCorrection <= IVester(vester).totalGroove(), 'setCorrectionVariable: correctionAmount to large');
        correctionAmount = newCorrection;
        emit LogNewCorrectionVariable(newCorrection);
    }

    /// @notice after every bonus claim, a user has to wait some time before they can claim again
    /// @param delay time delay until next claim is possible
    function setClaimDelay(uint256 delay) external onlyOwner {
        claimDelay = delay;
        emit LogNewClaimDelay(delay);
    }

    /// @notice Get the pending bonus a user can claim
    function getPendingBonus() public view returns (uint256) {
        uint256 userGroove = IVester(vester).vestingBalance(msg.sender);
        // if the user doesnt have a vesting position, they cannot claim
        if (userGroove == 0) {
            return 0;
        }
        // if for some reason the user has a larger vesting position than the
        //  current vesting position - correctionAmount, then give them the whole bonus.
        // This should only happen if: theres only one vesting position, someone forgot to
        // update the correctionAmount;
        uint256 globalGroove = IVester(vester).totalGroove() - correctionAmount;
        if (userGroove >= globalGroove) {
            return totalBonus;
        }
        uint256 userAmount = userGroove * totalBonus / globalGroove;
        return userAmount; 
    }

    /// @notice User claims available bonus
    function claim() external returns (uint256) {
        // user cannot claim if they have claimed recently or the contract is paused
        if (userClaims[msg.sender] + claimDelay >= block.timestamp || paused) {
            return 0;
        }
        uint256 userAmount = getPendingBonus();
        if (userAmount > 0) {
            userClaims[msg.sender] = block.timestamp;
            totalBonus -= userAmount;
            IVester(vester).vest(msg.sender, userAmount);
            emit LogBonusClaimed(msg.sender, userAmount);
        }
        return userAmount;
    }

    function canClaim() external view returns (bool) {
        if (userClaims[msg.sender] + claimDelay >= block.timestamp || paused) {
            return false;
        }
        return true;
    }
}
