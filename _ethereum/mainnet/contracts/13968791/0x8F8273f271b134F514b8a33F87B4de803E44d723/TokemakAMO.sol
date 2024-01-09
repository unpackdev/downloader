// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ============================ TokemakAMO ============================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Jason Huan: https://github.com/jasonhuan

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian

import "./SafeMath.sol";
import "./IFrax.sol";
import "./IFraxAMOMinter.sol";
import "./ERC20.sol";
import "./Owned.sol";
import "./TransferHelper.sol";
import "./ILiquidityPool.sol";
import "./IRewards.sol";

contract TokemakAMO is Owned {
    using SafeMath for uint256;
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ========== STATE VARIABLES ========== */

    // Core
    IFrax private FRAX = IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IFraxAMOMinter private amo_minter;
    address public timelock_address;
    address public custodian_address;

    // Tokemak
    ILiquidityPool public tokemak_frax_pool = ILiquidityPool(0x94671A3ceE8C7A12Ea72602978D1Bb84E920eFB2);
    uint256 public frax_in_pool;
    IRewards public rewards_contract = IRewards(0x79dD22579112d8a5F7347c5ED7E609e60da713C5);

    // Price constants
    uint256 private constant PRICE_PRECISION = 1e6;

    /* ========== CONSTRUCTOR ========== */
    
    constructor (
        address _owner_address,
        address _amo_minter_address
    ) Owned(_owner_address) {
        FRAX = IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
        amo_minter = IFraxAMOMinter(_amo_minter_address);

        // Get the custodian and timelock addresses from the minter
        custodian_address = amo_minter.custodian_address();
        timelock_address = amo_minter.timelock_address();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner, "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelock_address || msg.sender == owner || msg.sender == custodian_address, "Not owner, tlck, or custd");
        _;
    }


    /* ========== VIEWS ========== */

    function showAllocations() public view returns (uint256[3] memory allocations) {
        // All numbers given are in FRAX unless otherwise stated
        allocations[0] = FRAX.balanceOf(address(this)); // Unallocated FRAX
    
        allocations[1] = frax_in_pool;

        allocations[2] = allocations[0].add(allocations[1]); // Total FRAX value
    }

    function dollarBalances() public view returns (uint256 frax_val_e18, uint256 collat_val_e18) {
        frax_val_e18 = showAllocations()[2];
        collat_val_e18 = (frax_val_e18).mul(FRAX.global_collateral_ratio()).div(PRICE_PRECISION);
    }

    // Backwards compatibility
    function mintedBalance() public view returns (int256) {
        return amo_minter.frax_mint_balances(address(this));
    }

    // Backwards compatibility
    function accumulatedProfit() public view returns (int256) {
        return int256(showAllocations()[2]) - mintedBalance();
    }

    // withdrawal period and amount info
    function withdrawalInfo() public view returns (uint256, uint256) {
        return tokemak_frax_pool.requestedWithdrawals(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /* ---------------------------------------------------- */
    /* ---------------------- Tokemak --------------------- */
    /* ---------------------------------------------------- */

    function depositFrax(uint256 _amount) external onlyByOwnGov {
        frax_in_pool += _amount; // as of Solidity 0.8, this is safemath (no overflow/underflow)
        FRAX.approve(address(tokemak_frax_pool), _amount);
        tokemak_frax_pool.deposit(_amount);
    }

    function requestWithdrawal(uint256 _amount) external onlyByOwnGov {
        tokemak_frax_pool.requestWithdrawal(_amount);
    }

    function withdrawFrax(uint256 _amount) external onlyByOwnGov {
        frax_in_pool -= _amount;
        tokemak_frax_pool.withdraw(_amount);
    }

    function claimRewards(uint256 _cycle, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external onlyByOwnGov {
        IRewards.Recipient memory recipient = IRewards.Recipient({
            chainId: 1,
            cycle: _cycle,
            wallet: address(this),
            amount: _amount
        });

        rewards_contract.claim(recipient, _v, _r, _s);
    }


    /* ========== Burns and givebacks ========== */

    // Burn unneeded or excess FRAX. Goes through the minter
    function burnFRAX(uint256 frax_amount) public onlyByOwnGovCust {
        FRAX.approve(address(amo_minter), frax_amount);
        amo_minter.burnFraxFromAMO(frax_amount);
    }

    /* ========== OWNER / GOVERNANCE FUNCTIONS ONLY ========== */
    // Only owner or timelock can call, to limit risk 


    function setAMOMinter(address _amo_minter_address) external onlyByOwnGov {
        amo_minter = IFraxAMOMinter(_amo_minter_address);

        // Get the custodian and timelock addresses from the minter
        custodian_address = amo_minter.custodian_address();
        timelock_address = amo_minter.timelock_address();

        // Make sure the new addresses are not address(0)
        require(custodian_address != address(0) && timelock_address != address(0), "Invalid custodian or timelock");
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyByOwnGov returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }

    /* ========== EVENTS ========== */

    event Recovered(address token, uint256 amount);
}