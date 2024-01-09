// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./ITaskTreasury.sol";
import "./IResolver.sol";
import "./IPokeMe.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

interface IDssVest {
    function vest(uint256 _id) external;

    function unpaid(uint256 _id) external view returns (uint256 amt);
}

interface IDaiJoin {
    function join(address usr, uint256 wad) external;
}

// solhint-disable max-line-length
// solhint-disable max-states-count
contract DssVestTopUp is Ownable {
    using SafeERC20 for IERC20;

    // solhint-disable var-name-mixedcase
    address public immutable POKE_ME;
    address public immutable GELATO;
    address public immutable DAI_JOIN;
    address public immutable VOW;

    // Max amount to deposit on Gelato per topup
    uint256 public maxDepositAmt;

    constructor(
        address _pokeMe,
        address _newOwner,
        address _daiJoin,
        address _vow,
        uint256 _maxDepositAmt
    ) {
        POKE_ME = _pokeMe;
        GELATO = IPokeMe(_pokeMe).gelato();
        DAI_JOIN = _daiJoin;
        VOW = _vow;
        maxDepositAmt = _maxDepositAmt;
        if (_newOwner != address(0)) transferOwnership(_newOwner);
    }

    /// @notice Called by Gelato to claim accrued tokens from DssVest.
    /// @param _id id of vesting contract
    /// @param _dssVest contract address of dssVest
    /// @param _paymentToken token to claim from vesting contract
    function topUp(
        uint256 _id,
        address _dssVest,
        address _paymentToken
    ) external {
        require(msg.sender == POKE_ME, "DssVestTopUp: topUp: Only PokeMe");
        // Withdraw vested tokens
        uint256 preBalance = IERC20(_paymentToken).balanceOf(address(this));

        IDssVest(_dssVest).vest(_id);

        // Send exec fee to Gelato
        (uint256 feeAmt, address feeToken) = IPokeMe(POKE_ME).getFeeDetails();

        require(
            feeToken == _paymentToken,
            "DssVestTopUp: topUp: Incorrect feeToken"
        );

        uint256 amt = IERC20(_paymentToken).balanceOf(address(this)) -
            preBalance -
            feeAmt;

        IERC20(_paymentToken).safeTransfer(GELATO, feeAmt);

        if (amt > maxDepositAmt) {
            IDaiJoin(DAI_JOIN).join(VOW, amt - maxDepositAmt);
            amt = maxDepositAmt;
        }

        // Deposit vested tokens - fee into TaskTreasury to pay for other execs
        address taskTreasury = getTaskTreasury();
        IERC20(_paymentToken).approve(taskTreasury, amt);

        ITaskTreasury(taskTreasury).depositFunds(owner(), _paymentToken, amt);
    }

    function updateMaxDepositAmount(uint256 _maxDepositAmount)
        external
        onlyOwner
    {
        require(
            _maxDepositAmount > 0,
            "DssVestTopUp: updateMaxDepositAmount: !Zero"
        );
        maxDepositAmt = _maxDepositAmount;
    }

    /// @notice Gelato calls to check if balance < threshold.
    /// @param _id id of vesting contract
    /// @param _dssVest contract address of dssVest
    /// @param _paymentToken token to claim from vesting contract
    /// @param _threshold balance which will trigger a topUp
    function checker(
        uint256 _id,
        address _dssVest,
        address _paymentToken,
        uint256 _threshold,
        uint256 _minWithdrawAmt
    ) external view returns (bool canExec, bytes memory execPayload) {
        uint256 balance = ITaskTreasury(getTaskTreasury()).userTokenBalance(
            owner(),
            _paymentToken
        );
        if (balance > _threshold) return (false, bytes("Balance > threshold"));

        uint256 claimableAmt = IDssVest(_dssVest).unpaid(_id);
        if (_minWithdrawAmt > claimableAmt)
            return (false, bytes("minWithdrawAmt > claimableAmt"));

        return (
            true,
            abi.encodeWithSelector(
                this.topUp.selector,
                _id,
                _dssVest,
                _paymentToken
            )
        );
    }

    /// @notice Returns Task Treasury address.
    function getTaskTreasury() public view returns (address) {
        return IPokeMe(POKE_ME).taskTreasury();
    }
}
