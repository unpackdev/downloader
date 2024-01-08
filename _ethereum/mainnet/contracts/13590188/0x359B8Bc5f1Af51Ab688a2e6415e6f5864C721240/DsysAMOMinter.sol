// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./IDsysStablecoin.sol";
import "./IDsysShares.sol";
import "./IDsysPool.sol";
import "./IAMO.sol";
import "./SafeOwnable.sol";

contract DsysAMOMinter is SafeOwnable {
    // Core
    IDsysStablecoin public DSYS;
    IDsysShares public DSYSShares;
    ERC20 public collateral_token;
    IDsysPool public pool;
    address public timelock_address;
    address public custodian_address;

    // Collateral related
    address public collateral_address;
    uint256 public col_idx;

    // AMO addresses
    address[] public amos_array;
    mapping(address => bool) public amos; // Mapping is also used for faster verification

    // Price constants
    uint256 private constant PRICE_PRECISION = 1e6;

    // Max amount of collateral the contract can borrow from the DsysPool
    int256 public collat_borrow_cap = int256(10000000e6);

    // Max amount of Dsys and DsysShares this contract can mint
    int256 public dsys_mint_cap = int256(100000000e18);
    int256 public dsys_shares_mint_cap = int256(100000000e18);

    // Minimum collateral ratio needed for new DSYS minting
    uint256 public min_cr = 810000;

    // DSYS mint balances
    mapping(address => int256) public dsys_mint_balances; // Amount of DSYS the contract minted, by AMO
    int256 public dsys_mint_sum = 0; // Across all AMOs

    // DSYSShares mint balances
    mapping(address => int256) public dsys_shares_mint_balances; // Amount of DSYSShares the contract minted, by AMO
    int256 public dsys_shares_mint_sum = 0; // Across all AMOs

    // Collateral borrowed balances
    mapping(address => int256) public collat_borrowed_balances; // Amount of collateral the contract borrowed, by AMO
    int256 public collat_borrowed_sum = 0; // Across all AMOs

    // DSYS balance related
    uint256 public dsysDollarBalanceStored = 0;

    // Collateral balance related
    uint256 public missing_decimals;
    uint256 public collatDollarBalanceStored = 0;

    // AMO balance corrections
    mapping(address => int256[2]) public correction_offsets_amos;
    // [amo_address][0] = AMO's dsys_val_e18
    // [amo_address][1] = AMO's collat_val_e18

    constructor (
        address _owner_address,
        address _custodian_address,
        address _timelock_address,
        address _collateral_address,
        address _pool_address
    ) SafeOwnable (_owner_address) {
        custodian_address = _custodian_address;
        timelock_address = _timelock_address;

        // Pool related
        pool = IDsysPool(_pool_address);

        // Collateral related
        collateral_address = _collateral_address;
        col_idx = pool.collateralAddrToIdx(_collateral_address);
        collateral_token = ERC20(collateral_address);
        missing_decimals = uint(18) - collateral_token.decimals();
    }

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner(), "Not owner or timelock");
        _;
    }

    modifier validAMO(address amo_address) {
        require(amos[amo_address], "Invalid AMO");
        _;
    }

    function collatDollarBalance() external view returns (uint256) {
        (, uint256 collat_val_e18) = dollarBalances();
        return collat_val_e18;
    }

    function dollarBalances() public view returns (uint256 dsys_val_e18, uint256 collat_val_e18) {
        dsys_val_e18 = dsysDollarBalanceStored;
        collat_val_e18 = collatDollarBalanceStored;
    }

    function allAMOAddresses() external view returns (address[] memory) {
        return amos_array;
    }

    function allAMOsLength() external view returns (uint256) {
        return amos_array.length;
    }

    function dsysTrackedGlobal() external view returns (int256) {
        return int256(dsysDollarBalanceStored) - dsys_mint_sum - (collat_borrowed_sum * int256(10 ** missing_decimals));
    }

    function dsysTrackedAMO(address amo_address) external view returns (int256) {
        (uint256 dsys_val_e18, ) = IAMO(amo_address).dollarBalances();
        int256 dsys_val_e18_corrected = int256(dsys_val_e18) + correction_offsets_amos[amo_address][0];
        return dsys_val_e18_corrected - dsys_mint_balances[amo_address] - ((collat_borrowed_balances[amo_address]) * int256(10 ** missing_decimals));
    }

    // Callable by anyone willing to pay the gas
    function syncDollarBalances() public {
        uint256 total_dsys_value_d18 = 0;
        uint256 total_collateral_value_d18 = 0; 
        for (uint i = 0; i < amos_array.length; i++){ 
            // Exclude null addresses
            address amo_address = amos_array[i];
            if (amo_address != address(0)){
                (uint256 dsys_val_e18, uint256 collat_val_e18) = IAMO(amo_address).dollarBalances();
                total_dsys_value_d18 += uint256(int256(dsys_val_e18) + correction_offsets_amos[amo_address][0]);
                total_collateral_value_d18 += uint256(int256(collat_val_e18) + correction_offsets_amos[amo_address][1]);
            }
        }
        dsysDollarBalanceStored = total_dsys_value_d18;
        collatDollarBalanceStored = total_collateral_value_d18;
    }

    // Only owner or timelock can call, to limit risk 

    // ------------------------------------------------------------------
    // ------------------------------ DSYS ------------------------------
    // ------------------------------------------------------------------

    // This contract is essentially marked as a 'pool' so it can call OnlyPools functions like pool_mint and pool_burn_from
    // on the main DSYS contract
    function mintDsysForAMO(address destination_amo, uint256 frax_amount) external onlyByOwnGov validAMO(destination_amo) {
        int256 dsys_amt_i256 = int256(frax_amount);

        // Make sure you aren't minting more than the mint cap
        require((dsys_mint_sum + dsys_amt_i256) <= dsys_mint_cap, "Mint cap reached");
        dsys_mint_balances[destination_amo] += dsys_amt_i256;
        dsys_mint_sum += dsys_amt_i256;

        // Make sure the DSYS minting wouldn't push the CR down too much
        // This is also a sanity check for the int256 math
        uint256 current_collateral_E18 = DSYS.globalCollateralValue();
        uint256 cur_frax_supply = DSYS.totalSupply();
        uint256 new_frax_supply = cur_frax_supply + frax_amount;
        uint256 new_cr = (current_collateral_E18 * PRICE_PRECISION) / new_frax_supply;
        require(new_cr >= min_cr, "CR would be too low");

        // Mint the DSYS to the AMO
        DSYS.pool_mint(destination_amo, frax_amount);

        // Sync
        syncDollarBalances();
    }

    function burnDsysFromAMO(uint256 dsys_amount) external validAMO(msg.sender) {
        int256 dsys_amt_i256 = int256(dsys_amount);

        // Burn first
        DSYS.pool_burn_from(msg.sender, dsys_amount);

        // Then update the balances
        dsys_mint_balances[msg.sender] -= dsys_amt_i256;
        dsys_mint_sum -= dsys_amt_i256;

        // Sync
        syncDollarBalances();
    }

    // ------------------------------------------------------------------
    // ------------------------------- DSYSShares ------------------------------
    // ------------------------------------------------------------------
    function mintDsysSharesForAMO(address destination_amo, uint256 dsys_shares_amount) external onlyByOwnGov validAMO(destination_amo) {
        int256 dsys_shares_amt_i256 = int256(dsys_shares_amount);

        // Make sure you aren't minting more than the mint cap
        require((dsys_shares_mint_sum + dsys_shares_amt_i256) <= dsys_shares_mint_cap, "Mint cap reached");
        dsys_shares_mint_balances[destination_amo] += dsys_shares_amt_i256;
        dsys_shares_mint_sum += dsys_shares_amt_i256;

        // Mint the DSYSShares to the AMO
        DSYSShares.pool_mint(destination_amo, dsys_shares_amount);

        // Sync
        syncDollarBalances();
    }

    function burnDsysSharesFromAMO(uint256 dsys_shares_amount) external validAMO(msg.sender) {
        int256 dsys_shares_amt_i256 = int256(dsys_shares_amount);

        // Burn first
        DSYSShares.pool_burn_from(msg.sender, dsys_shares_amount);

        // Then update the balances
        dsys_shares_mint_balances[msg.sender] -= dsys_shares_amt_i256;
        dsys_shares_mint_sum -= dsys_shares_amt_i256;

        // Sync
        syncDollarBalances();
    }

    // ------------------------------------------------------------------
    // --------------------------- Collateral ---------------------------
    // ------------------------------------------------------------------

    function giveCollatToAMO(
        address destination_amo,
        uint256 collat_amount
    ) external onlyByOwnGov validAMO(destination_amo) {
        int256 collat_amount_i256 = int256(collat_amount);

        require((collat_borrowed_sum + collat_amount_i256) <= collat_borrow_cap, "Borrow cap");
        collat_borrowed_balances[destination_amo] += collat_amount_i256;
        collat_borrowed_sum += collat_amount_i256;

        // Borrow the collateral
        pool.amoMinterBorrow(collat_amount);

        // Give the collateral to the AMO
        SafeERC20.safeTransfer(IERC20(collateral_address), destination_amo, collat_amount);

        // Sync
        syncDollarBalances();
    }

    function receiveCollatFromAMO(uint256 usdc_amount) external validAMO(msg.sender) {
        int256 collat_amt_i256 = int256(usdc_amount);

        // Give back first
        SafeERC20.safeTransferFrom(IERC20(collateral_address), msg.sender, address(pool), usdc_amount);

        // Then update the balances
        collat_borrowed_balances[msg.sender] -= collat_amt_i256;
        collat_borrowed_sum -= collat_amt_i256;

        // Sync
        syncDollarBalances();
    }

    // Adds an AMO 
    function addAMO(address amo_address, bool sync_too) public onlyByOwnGov {
        require(amo_address != address(0), "Zero address detected");

        (uint256 dsys_val_e18, uint256 collat_val_e18) = IAMO(amo_address).dollarBalances();
        require(dsys_val_e18 >= 0 && collat_val_e18 >= 0, "Invalid AMO");

        require(amos[amo_address] == false, "Address already exists");
        amos[amo_address] = true; 
        amos_array.push(amo_address);

        // Mint balances
        dsys_mint_balances[amo_address] = 0;
        dsys_shares_mint_balances[amo_address] = 0;
        collat_borrowed_balances[amo_address] = 0;

        // Offsets
        correction_offsets_amos[amo_address][0] = 0;
        correction_offsets_amos[amo_address][1] = 0;

        if (sync_too) syncDollarBalances();

        emit AMOAdded(amo_address);
    }

    // Removes an AMO
    function removeAMO(address amo_address, bool sync_too) public onlyByOwnGov {
        require(amo_address != address(0), "Zero address detected");
        require(amos[amo_address] == true, "Address nonexistant");
        
        // Delete from the mapping
        delete amos[amo_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < amos_array.length; i++){ 
            if (amos_array[i] == amo_address) {
                amos_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        if (sync_too) syncDollarBalances();

        emit AMORemoved(amo_address);
    }

    function setTimelock(address new_timelock) external onlyByOwnGov {
        require(new_timelock != address(0), "Timelock address cannot be 0");
        timelock_address = new_timelock;
    }

    function setCustodian(address _custodian_address) external onlyByOwnGov {
        require(_custodian_address != address(0), "Custodian address cannot be 0");        
        custodian_address = _custodian_address;
    }

    function setFraxMintCap(uint256 _dsys_mint_cap) external onlyByOwnGov {
        dsys_mint_cap = int256(_dsys_mint_cap);
    }

    function setDsysSharesMintCap(uint256 _dsys_shares_mint_cap) external onlyByOwnGov {
        dsys_shares_mint_cap = int256(_dsys_shares_mint_cap);
    }

    function setCollatBorrowCap(uint256 _collat_borrow_cap) external onlyByOwnGov {
        collat_borrow_cap = int256(_collat_borrow_cap);
    }

    function setMinimumCollateralRatio(uint256 _min_cr) external onlyByOwnGov {
        min_cr = _min_cr;
    }

    function setAMOCorrectionOffsets(address amo_address, int256 dsys_e18_correction, int256 collat_e18_correction) external onlyByOwnGov {
        correction_offsets_amos[amo_address][0] = dsys_e18_correction;
        correction_offsets_amos[amo_address][1] = collat_e18_correction;

        syncDollarBalances();
    }

    function setFraxPool(address _pool_address) external onlyByOwnGov {
        pool = IDsysPool(_pool_address);

        // Make sure the collaterals match, or balances could get corrupted
        require(pool.collateralAddrToIdx(collateral_address) == col_idx, "col_idx mismatch");
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnGov {
        // Can only be triggered by owner or governance
        SafeERC20.safeTransfer(IERC20(tokenAddress), owner(), tokenAmount);
        
        emit Recovered(tokenAddress, tokenAmount);
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

    event AMOAdded(address amo_address);
    event AMORemoved(address amo_address);
    event Recovered(address token, uint256 amount);
}
