// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./ISyntheticToken.sol";
import "./IERC20.sol";

import "./Adminable.sol";
import "./Amount.sol";
import "./Decimal.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./IMozartCoreV1.sol";

import "./MozartSavingsStorage.sol";

/**
 * @title MozartSavingsV1
 * @author Kerman Kohli
 * @notice This contract is relatively simple in where you deposit a specific token and then
 *         users who deposit their tokens earn more of it as more of it gets minted directly to
 *         this contract. Balances are stored as "principal" amounts and the actual amount
 *         can be retreived through simply multiplying by the exchangeRate() stored.
 */
contract MozartSavingsV1 is Adminable, MozartSavingsStorage, IERC20 {

    /* ========== Libraries ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Amount for Amount.Principal;

    /* ========== Events ========== */

    event IndexUpdated(uint256 updateTime, uint256 newIndex);

    event SavingsRateUpdated(uint256 newRate);

    event ArcFeeUpdated(uint256 feeUpdated);

    event Paused(bool newStatus);

    /* ========== Constants ========== */

    uint256 constant BASE = 10**18;

    /* ========== Modifier ========== */

    modifier isActive() {
        require(
            paused == false,
            "D2Savings: contract is paused"
        );
        _;
    }

    /* ========== Constructor ========== */

    function init(
        string memory name,
        string memory symbol,
        address _syntheticAddress,
        Decimal.D256 memory _fee
    )
        public
        onlyAdmin
    {
        _name = name;
        _symbol = symbol;

        synthetic = ISyntheticToken(_syntheticAddress);

        paused = true;

        savingsIndex = BASE;
        indexLastUpdate = currentTimestamp();

        setArcFee(_fee);
    }

    /* ========== Public View Functions ========== */

    function name()
        external
        view
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        external
        view
        returns (string memory)
    {
        return _symbol;
    }

    function decimals()
        external
        pure
        returns (uint8)
    {
        return 18;
    }

    function currentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    function balanceOf(
        address user
    )
        public
        view
        returns (uint256)
    {
        return _balances[user];
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function currentSavingsIndex()
        public
        view
        returns (uint256)
    {
        // Check the time since the last update, multiply to get interest generated
        uint256 totalInterestAccumulated = savingsRate.mul(currentTimestamp().sub(indexLastUpdate));

        // Set the new index based on how much accrued
        return savingsIndex.add(totalInterestAccumulated);
    }

    /* ========== Admin Functions ========== */

    function setSavingsRate(
        uint256 rate
    )
        public
        onlyAdmin
    {
        savingsRate = rate;

        emit SavingsRateUpdated(rate);
    }

    function setArcFee(
        Decimal.D256 memory _fee
    )
        public
        onlyAdmin
    {
        arcFee = _fee;

        emit ArcFeeUpdated(_fee.value);
    }

    function setPaused(
        bool status
    )
        public
        onlyAdmin
    {
        paused = status;

        emit Paused(status);
    }

    /* ========== Public Functions ========== */

    /**
     * @dev Stake your synthetic tokens to earn interest.
     *
     * @notice Can only be called if contracts not paused.
     *
     * @param amount The actual number of tokens you'd like to stake (not principal amount)
     */
    function stake(
        uint256 amount
    )
        public
        isActive
        returns (uint256)
    {
        // CHECKS:
        // 1. Update the index to make sure we use the correct
        //    values for calculations when withdrawing
        // 2. Calculate the principal amount given a deposit amount

        // EFFECTS:
        // 1. Set the user's balance to the new calculated amount

        // INTERACTIONS:
        // 1. Transfer the synthetic tokens to the contract
        // 2. Increase the total supplied amount

        // Update the index first
        uint256 latestIndex = updateIndex();

        // Calculate your stake amount given the current index
        Amount.Principal memory depositPrincipalAmount = Amount.calculatePrincipal(
            amount,
            latestIndex,
            true
        );

        // Increase the totalSupplied amount
        totalSupplied = totalSupplied.add(amount);

        // Mints the receipt token
        _mint(
            msg.sender,
            depositPrincipalAmount.value
        );

        // Transfer the synth
        IERC20(address(synthetic)).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        return latestIndex;
    }

    /**
     * @dev Unstake your synthetic tokens and stop earning interest on them.
     *
     * @notice Can only be called if contracts not paused.
     *
     * @param amount The interested adjusted amount of tokens you'd like to unstake
     */
    function unstake(
        uint256 amount
    )
        public
        isActive
        returns (uint256)
    {
        // CHECKS:
        // 1. Update the index to make sure we can use the correct
        //    values for calculations when withdrawing
        // 2. Calculate the principal amount that needs to be withdrawn

        // EFFECTS:
        // 1. Update the user's balance
        // 2. Decrease the total supplied amount

        // INTERACTIONS
        // 1. Transfer the tokens back to the user

        // Update the index first
        uint256 latestIndex = updateIndex();

        // Calculate the withdraw amount given the index
        Amount.Principal memory withdrawPrinicipalAmount = Amount.calculatePrincipal(
            amount,
            latestIndex,
            true
        );

        // Get the user's existing balance
        uint256 existingPrincipalBalance = _balances[msg.sender];

        // Ensure that the user's existing balance is greater than the withdraw amount
        require(
            existingPrincipalBalance >= withdrawPrinicipalAmount.value,
            "unstake(): cannot withdraw more than you are allowed"
        );

        // Decrease the totalSupplied amount
        totalSupplied = totalSupplied.sub(amount);

        // Burns the receipt token
        _burn(
            msg.sender,
            withdrawPrinicipalAmount.value
        );

        // Transfer the synth
        IERC20(address(synthetic)).transfer(
            msg.sender,
            amount
        );

        return latestIndex;
    }

    /**
     * @dev Unstake all your synthetic tokens and stop earning interest on them.
     *
     * @notice Can only be called if contracts not paused.
     *
     */
    function unstakeAll()
        public
        isActive
        returns (uint256)
    {
        // Get the user's principal balance
        uint256 principalBalance = balanceOf(msg.sender);

        // Get the interest adjusted amount by multiplying by the current index
        uint256 userBalance = principalBalance.mul(currentSavingsIndex()).div(BASE);

        // Call the unstake function with the final balance
        return unstake(userBalance);
    }

    /**
     * @dev Accumulates interest for all capital. Can be called by anyone.
     *
     * @notice Can only be called if contracts not paused.
     *
     */
    function updateIndex()
        public
        isActive
        returns (uint256)
    {
        // CHECKS:
        // 1. If there has been no time since the last update OR no savings rate set, return
        // 2. Calculate the interest accumulated since the last time the index was updated

        // EFFECTS:
        // 1. Update the new savings index by adding the amount of interest accumualted
        // 2. Update the total supplied amount of the contracts to indicate how much money it holds
        // 3. Update the index last update timestamp

        // INTERACTIONS:
        // 1. Mint the amount of interest accrued

        // If there have been no updates then return
        if (currentTimestamp() == indexLastUpdate) {
            return savingsIndex;
        }

        if (savingsRate == 0) {
            indexLastUpdate = currentTimestamp();
            emit IndexUpdated(indexLastUpdate, savingsIndex);
            return savingsIndex;
        }

        // Set the new index based on how much accrued
        uint256 newSavingsIndex = currentSavingsIndex();
        savingsIndex = newSavingsIndex;

        uint256 existingSupply = totalSupplied;
        totalSupplied = totalSupplied.mul(newSavingsIndex).div(BASE);

        // With the difference between the new amount being borrowed and the existing amount
        // we can figure out how much interest is owed to the system as a whole and therefore
        // calculate how much of the synth to mint
        uint256 interestAccrued = totalSupplied.sub(existingSupply);

        // Set the last time the index was updated to now
        indexLastUpdate = currentTimestamp();

        synthetic.mint(
            address(this),
            interestAccrued
        );

        emit IndexUpdated(
            indexLastUpdate,
            newSavingsIndex
        );

        return newSavingsIndex;
    }

    /* ========== Token Functions ========== */

    function transfer(
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    )
        public
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount)
        );

        return true;
    }

    /* ========== Internal Functions ========== */

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
    {
        require(
            sender != address(0),
            "ERC20: transfer from the zero address"
        );

        require(
            recipient != address(0),
            "ERC20: transfer to the zero address"
        );

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        internal
    {
        require(
            owner != address(0),
            "ERC20: approve from the zero address"
        );

        require(
            spender != address(0),
            "ERC20: approve to the zero address"
        );

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(
        address account,
        uint256 amount
    )
        internal
    {
        require(
            account != address(0),
            "ERC20: mint to the zero address"
        );

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(
        address account,
        uint256 amount
    )
        internal
    {
        require(
            account != address(0),
            "ERC20: burn from the zero address"
        );

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

}
