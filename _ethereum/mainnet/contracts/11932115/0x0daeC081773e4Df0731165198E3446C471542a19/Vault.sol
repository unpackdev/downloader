// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./Operator.sol";
import "./SafeMath.sol";
import "./StakingTimelock.sol";
import "./IVaultBoardroom.sol";
import "./console.sol";

/**
 * A vault is a contract that handles only the bonding & unbonding of tokens;
 * Rewards are handled by the boardroom contracts.
 */
contract Vault is AccessControl, StakingTimelock, Operator {
    using SafeMath for uint256;

    bytes32 public constant BOARDROOM_ROLE = keccak256('BOARDROOM_ROLE');

    /**
     * Data structures.
     */
    struct BondingDetail {
        uint256 firstBondedOn;
        uint256 latestBondedOn;
        uint256 previousBondedOn;
    }

    /**
     * State variables.
     */

    // The staked token.
    IERC20 public token;
    IVaultBoardroom public expansionBoardroom;
    IVaultBoardroom public contractionBoardroom;

    uint256 internal _totalSupply;
    bool public enableDeposits = true;
    uint256 internal _totalBondedSupply;

    mapping(address => uint256) internal _balances;

    /**
     * Modifier.
     */

    modifier stakerExists(address who) {
        require(balanceOf(who) > 0, 'Boardroom: The director does not exist');
        _;
    }

    /**
     * Events.
     */

    event Bonded(address indexed user, uint256 amount);
    event Unbonded(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * Constructor.
     */
    constructor(IERC20 token_, uint256 duration_) StakingTimelock(duration_) {
        token = token_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BOARDROOM_ROLE, _msgSender());
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setBoardrooms(
        IVaultBoardroom expansionBoardroom_,
        IVaultBoardroom contractionBoardroom_
    ) public {
        expansionBoardroom = expansionBoardroom_;
        contractionBoardroom = contractionBoardroom_;
    }

    function balanceOf(address who) public view returns (uint256) {
        return _balances[who];
    }

    function totalBondedSupply() public view returns (uint256) {
        return _totalBondedSupply;
    }

    function balanceWithoutBonded(address who) public view returns (uint256) {
        uint256 unbondingAmount = getStakedAmount(msg.sender);
        return _balances[who].sub(unbondingAmount);
    }

    function toggleDeposits(bool val) external onlyOwner {
        enableDeposits = val;
    }

    function bond(uint256 amount) external virtual {
        _bond(msg.sender, amount);
    }

    function bondFor(address who, uint256 amount) external virtual {
        require(
            hasRole(BOARDROOM_ROLE, _msgSender()),
            'Vault: must have boardroom role to bond for someone else'
        );

        _bond(who, amount);
    }

    function unbond(uint256 amount) external virtual {
        _unbond(msg.sender, amount);
    }

    function withdraw() external virtual {
        _withdraw(msg.sender);
    }

    function _updateRewards(address who) private {
        if (address(expansionBoardroom) != address(0))
            expansionBoardroom.updateReward(who);

        if (address(contractionBoardroom) != address(0))
            contractionBoardroom.updateReward(who);
    }

    function _bond(address who, uint256 amount) private {
        require(amount > 0, 'Boardroom: cannot bond 0');
        require(enableDeposits, 'Boardroom: deposits are disabled');

        console.log('vault bonding for %s', who);
        console.log('vault bonding amount %s', amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[who] = _balances[who].add(amount);
        _totalBondedSupply = _totalBondedSupply.add(amount);

        // NOTE: has to be pre-approved.
        token.transferFrom(who, address(this), amount);

        _updateRewards(who);

        emit Bonded(who, amount);
    }

    function _unbond(address who, uint256 amount) private stakerExists(who) {
        require(amount > 0, 'Boardroom: cannot unbond 0');

        uint256 directorShare = _balances[who];

        require(
            directorShare >= amount,
            'Boardroom: unbond request greater than staked amount'
        );

        _updateStakerDetails(who, amount);
        _updateRewards(who);

        _totalBondedSupply = _totalBondedSupply.sub(amount);

        emit Unbonded(who, amount);
    }

    function _withdraw(address who)
        private
        stakerExists(who)
        checkLockDurationFor(who)
    {
        uint256 directorShare = _balances[who];
        uint256 unbondingAmount = getStakedAmount(who);

        require(
            directorShare >= unbondingAmount,
            'Boardroom: withdraw request greater than unbonded amount'
        );

        // Reset the bonding timestamp, as we are withdrawing the entire amount.
        _totalSupply = _totalSupply.sub(unbondingAmount);
        _balances[who] = directorShare.sub(unbondingAmount);
        token.transfer(who, unbondingAmount);

        _updateStakerDetails(who, 0);
        _updateRewards(who);

        emit Withdrawn(who, unbondingAmount);
    }
}
