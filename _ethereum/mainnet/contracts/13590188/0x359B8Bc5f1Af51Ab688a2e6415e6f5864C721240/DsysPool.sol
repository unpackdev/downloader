// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./IDsysStablecoin.sol";
import "./IDsysAMOMinter.sol";
import "./IDsysShares.sol";
import "./SafeOwnable.sol";

contract DsysPool is SafeOwnable {
    using SafeMath for uint256;

    event MRBRToggled(uint256 col_idx, uint8 tog_idx);
    event AMOMinterAdded(address amo_minter_addr);
    event AMOMinterRemoved(address amo_minter_addr);
    event CollateralToggled(uint256 col_idx, bool new_state);
    event CollateralPriceSet(uint256 col_idx, uint256 new_price);
    event PoolCeilingSet(uint256 col_idx, uint256 new_ceiling);
    event FeesSet(uint256 col_idx, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee);
    event PoolParametersSet(uint256 new_bonus_rate, uint256 new_redemption_delay);
    event PriceThresholdsSet(uint256 new_bonus_rate, uint256 new_redemption_delay);
    event BbkRctPerHourSet(uint256 bbkMaxColE18OutPerHour, uint256 rctMaxFxsOutPerHour);
    event CustodianSet(address new_custodian);
    event TimelockSet(address new_timelock);

    // Core
    address public timelock_address;
    address public custodian_address; // Custodian is an EOA (or msig) with pausing privileges only, in case of an emergency
    IDsysStablecoin private DSYS;
    IDsysShares private DSYSShares;
    mapping(address => bool) public amo_minter_addresses; // minter address -> is it enabled

    // Collateral
    address[] public collateral_addresses;
    string[] public collateral_symbols;
    uint256[] public missing_decimals; // Number of decimals needed to get to E18. collateral index -> missing_decimals
    uint256[] public pool_ceilings; // Total across all collaterals. Accounts for missing_decimals
    uint256[] public collateral_prices; // Stores price of the collateral, if price is paused
    mapping(address => uint256) public collateralAddrToIdx; // collateral addr -> collateral index
    mapping(address => bool) public enabled_collaterals; // collateral address -> is it enabled
    
    // Redeem related
    mapping (address => uint256) public redeem_dsys_shares_balances;
    mapping (address => mapping(uint256 => uint256)) public redeem_collateral_balances; // Address -> collateral index -> balance
    uint256[] public unclaimed_pool_collateral; // collateral index -> balance
    uint256 public unclaimed_pool_dsys_shares;
    mapping (address => uint256) public last_redeemed; // Collateral independent
    uint256 public redemption_delay = 2; // Number of blocks to wait before being able to collectRedemption()
    uint256 public redeem_price_threshold = 990000; // $0.99
    uint256 public mint_price_threshold = 1010000; // $1.01
    
    // Buyback related
    mapping(uint256 => uint256) public bbkHourlyCum; // Epoch hour ->  Collat out in that hour (E18)
    uint256 public bbkMaxColE18OutPerHour = 1000e18;

    // Recollat related
    mapping(uint256 => uint256) public rctHourlyCum; // Epoch hour ->  FXS out in that hour
    uint256 public rctMaxFxsOutPerHour = 1000e18;

    // Fees and rates
    // getters are in collateral_information()
    uint256[] private minting_fee;
    uint256[] private redemption_fee;
    uint256[] private buyback_fee;
    uint256[] private recollat_fee;
    uint256 public bonus_rate; // Bonus rate on FXS minted during recollateralize(); 6 decimals of precision, set to 0.75% on genesis
    
    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;

    // Pause variables
    // getters are in collateral_information()
    bool[] private mintPaused; // Collateral-specific
    bool[] private redeemPaused; // Collateral-specific
    bool[] private recollateralizePaused; // Collateral-specific
    bool[] private buyBackPaused; // Collateral-specific

    modifier onlyByOwnGov() {
        require(msg.sender == timelock_address || msg.sender == owner(), "Not owner or timelock");
        _;
    }

    modifier onlyByOwnGovCust() {
        require(msg.sender == timelock_address || msg.sender == owner() || msg.sender == custodian_address, "Not owner, tlck, or custd");
        _;
    }

    modifier onlyAMOMinters() {
        require(amo_minter_addresses[msg.sender], "Not an AMO Minter");
        _;
    }

    modifier collateralEnabled(uint256 col_idx) {
        require(enabled_collaterals[collateral_addresses[col_idx]], "Collateral disabled");
        _;
    }

    constructor (
        address _pool_manager_address,
        address _custodian_address,
        address _timelock_address,
        address[] memory _collateral_addresses,
        uint256[] memory _pool_ceilings,
        uint256[] memory _initial_fees
    ) SafeOwnable(_pool_manager_address){
        // Core
        timelock_address = _timelock_address;
        custodian_address = _custodian_address;

        // Fill collateral info
        collateral_addresses = _collateral_addresses;
        for (uint256 i = 0; i < _collateral_addresses.length; i++){ 
            // For fast collateral address -> collateral idx lookups later
            collateralAddrToIdx[_collateral_addresses[i]] = i;

            // Set all of the collaterals initially to disabled
            enabled_collaterals[_collateral_addresses[i]] = false;

            // Add in the missing decimals
            missing_decimals.push(uint256(18).sub(ERC20(_collateral_addresses[i]).decimals()));

            // Add in the collateral symbols
            collateral_symbols.push(ERC20(_collateral_addresses[i]).symbol());

            // Initialize unclaimed pool collateral
            unclaimed_pool_collateral.push(0);

            // Initialize paused prices to $1 as a backup
            collateral_prices.push(PRICE_PRECISION);

            // Handle the fees
            minting_fee.push(_initial_fees[0]);
            redemption_fee.push(_initial_fees[1]);
            buyback_fee.push(_initial_fees[2]);
            recollat_fee.push(_initial_fees[3]);

            // Handle the pauses
            mintPaused.push(false);
            redeemPaused.push(false);
            recollateralizePaused.push(false);
            buyBackPaused.push(false);
        }

        // Pool ceiling
        pool_ceilings = _pool_ceilings;
    }

    struct CollateralInformation {
        uint256 index;
        string symbol;
        address col_addr;
        bool is_enabled;
        uint256 missing_decs;
        uint256 price;
        uint256 pool_ceiling;
        bool mint_paused;
        bool redeem_paused;
        bool recollat_paused;
        bool buyback_paused;
        uint256 minting_fee;
        uint256 redemption_fee;
        uint256 buyback_fee;
        uint256 recollat_fee;
    }

    // Helpful for UIs
    function collateral_information(address collat_address) external view returns (CollateralInformation memory return_data){
        require(enabled_collaterals[collat_address], "Invalid collateral");

        // Get the index
        uint256 idx = collateralAddrToIdx[collat_address];
        
        return_data = CollateralInformation(
            idx, // [0]
            collateral_symbols[idx], // [1]
            collat_address, // [2]
            enabled_collaterals[collat_address], // [3]
            missing_decimals[idx], // [4]
            collateral_prices[idx], // [5]
            pool_ceilings[idx], // [6]
            mintPaused[idx], // [7]
            redeemPaused[idx], // [8]
            recollateralizePaused[idx], // [9]
            buyBackPaused[idx], // [10]
            minting_fee[idx], // [11]
            redemption_fee[idx], // [12]
            buyback_fee[idx], // [13]
            recollat_fee[idx] // [14]
        );
    }

    function allCollaterals() external view returns (address[] memory) {
        return collateral_addresses;
    }

    function getDsysPrice() public view returns (uint256) {
        return DSYS.dsys_price();
    }

    function getDsysSharesPrice() public view returns (uint256) {
        return DSYS.dsys_shares_price();
    }

    // Returns the FRAX value in collateral tokens
    function getDSYSInCollateral(uint256 col_idx, uint256 dsys_amount) public view returns (uint256) {
        return dsys_amount.mul(PRICE_PRECISION).div(10 ** missing_decimals[col_idx]).div(collateral_prices[col_idx]);
    }

    // Used by some functions.
    function freeCollatBalance(uint256 col_idx) public view returns (uint256) {
        return IERC20(collateral_addresses[col_idx]).balanceOf(address(this)).sub(unclaimed_pool_collateral[col_idx]);
    }

    // Returns dollar value of collateral held in this Frax pool, in E18
    function collatDollarBalance() external view returns (uint256 balance_tally) {
        balance_tally = 0;

        // Test 1
        for (uint256 i = 0; i < collateral_addresses.length; i++){ 
            balance_tally += freeCollatBalance(i).mul(10 ** missing_decimals[i]).mul(collateral_prices[i]).div(PRICE_PRECISION);
        }

    }

    function comboCalcBbkRct(uint256 cur, uint256 max, uint256 theo) internal pure returns (uint256) {
        if (cur >= max) {
            // If the hourly limit has already been reached, return 0;
            return 0;
        }
        else {
            // Get the available amount
            uint256 available = max.sub(cur);

            if (theo >= available) {
                // If the the theoretical is more than the available, return the available
                return available;
            }
            else {
                // Otherwise, return the theoretical amount
                return theo;
            }
        } 
    }

    // Returns the current epoch hour
    function curEpochHr() public view returns (uint256) {
        return (block.timestamp / 3600); // Truncation desired
    }

    // Returns the value of excess collateral (in E18) held globally, compared to what is needed to maintain the global collateral ratio
    // Also has throttling to avoid dumps during large price movements
    function buybackAvailableCollat() public view returns (uint256) {
        uint256 total_supply = DSYS.totalSupply();
        uint256 global_collateral_ratio = DSYS.global_collateral_ratio();
        uint256 global_collat_value = DSYS.globalCollateralValue();

        if (global_collateral_ratio > PRICE_PRECISION) global_collateral_ratio = PRICE_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(PRICE_PRECISION); // Calculates collateral needed to back each 1 FRAX with $1 of collateral at current collat ratio
        
        if (global_collat_value > required_collat_dollar_value_d18) {
            // Get the theoretical buyback amount
            uint256 theoretical_bbk_amt = global_collat_value.sub(required_collat_dollar_value_d18);

            // See how much has collateral has been issued this hour
            uint256 current_hr_bbk = bbkHourlyCum[curEpochHr()];

            // Account for the throttling
            return comboCalcBbkRct(current_hr_bbk, bbkMaxColE18OutPerHour, theoretical_bbk_amt);
        }
        else return 0;
    }

    // Returns the missing amount of collateral (in E18) needed to maintain the collateral ratio
    function recollatTheoColAvailableE18() public view returns (uint256) {
        uint256 frax_total_supply = DSYS.totalSupply();
        uint256 effective_collateral_ratio = DSYS.globalCollateralValue().mul(PRICE_PRECISION).div(frax_total_supply); // Returns it in 1e6
        
        uint256 desired_collat_e24 = (DSYS.global_collateral_ratio()).mul(frax_total_supply);
        uint256 effective_collat_e24 = effective_collateral_ratio.mul(frax_total_supply);

        // Return 0 if already overcollateralized
        // Otherwise, return the deficiency
        if (effective_collat_e24 >= desired_collat_e24) return 0;
        else {
            return (desired_collat_e24.sub(effective_collat_e24)).div(PRICE_PRECISION);
        }
    }

    // Returns the value of FXS available to be used for recollats
    // Also has throttling to avoid dumps during large price movements
    function recollatAvailableFxs() public view returns (uint256) {
        uint256 fxs_price = getDsysSharesPrice();

        // Get the amount of collateral theoretically available
        uint256 recollat_theo_available_e18 = recollatTheoColAvailableE18();

        // Get the amount of FXS theoretically outputtable
        uint256 fxs_theo_out = recollat_theo_available_e18.mul(PRICE_PRECISION).div(fxs_price);

        // See how much FXS has been issued this hour
        uint256 current_hr_rct = rctHourlyCum[curEpochHr()];

        // Account for the throttling
        return comboCalcBbkRct(current_hr_rct, rctMaxFxsOutPerHour, fxs_theo_out);
    }

    function mintFrax(
        uint256 col_idx, 
        uint256 frax_amt,
        uint256 frax_out_min,
        bool one_to_one_override
    ) external collateralEnabled(col_idx) returns (
        uint256 total_frax_mint, 
        uint256 collat_needed, 
        uint256 fxs_needed
    ) {
        require(mintPaused[col_idx] == false, "Minting is paused");

        // Prevent unneccessary mints
        require(getDsysPrice() >= mint_price_threshold, "Frax price too low");

        uint256 global_collateral_ratio = DSYS.global_collateral_ratio();

        if (one_to_one_override || global_collateral_ratio >= PRICE_PRECISION) { 
            // 1-to-1, overcollateralized, or user selects override
            collat_needed = getDSYSInCollateral(col_idx, frax_amt);
            fxs_needed = 0;
        } else if (global_collateral_ratio == 0) { 
            // Algorithmic
            collat_needed = 0;
            fxs_needed = frax_amt.mul(PRICE_PRECISION).div(getDsysSharesPrice());
        } else { 
            // Fractional
            uint256 frax_for_collat = frax_amt.mul(global_collateral_ratio).div(PRICE_PRECISION);
            uint256 frax_for_fxs = frax_amt.sub(frax_for_collat);
            collat_needed = getDSYSInCollateral(col_idx, frax_for_collat);
            fxs_needed = frax_for_fxs.mul(PRICE_PRECISION).div(getDsysSharesPrice());
        }

        // Subtract the minting fee
        total_frax_mint = (frax_amt.mul(PRICE_PRECISION.sub(minting_fee[col_idx]))).div(PRICE_PRECISION);

        // Checks
        require((frax_out_min <= total_frax_mint), "FRAX slippage");
        require(freeCollatBalance(col_idx).add(collat_needed) <= pool_ceilings[col_idx], "Pool ceiling");

        // Take the FXS and collateral first
        DSYSShares.pool_burn_from(msg.sender, fxs_needed);
        SafeERC20.safeTransferFrom(IERC20(collateral_addresses[col_idx]), msg.sender, address(this), collat_needed);

        // Mint the FRAX
        DSYS.pool_mint(msg.sender, total_frax_mint);
    }

    function redeemFrax(
        uint256 col_idx, 
        uint256 frax_amount, 
        uint256 fxs_out_min, 
        uint256 col_out_min
    ) external collateralEnabled(col_idx) returns (
        uint256 collat_out, 
        uint256 fxs_out
    ) {
        require(redeemPaused[col_idx] == false, "Redeeming is paused");

        // Prevent unneccessary redemptions that could adversely affect the FXS price
        require(getDsysPrice() <= redeem_price_threshold, "Frax price too high");

        uint256 global_collateral_ratio = DSYS.global_collateral_ratio();
        uint256 frax_after_fee = (frax_amount.mul(PRICE_PRECISION.sub(redemption_fee[col_idx]))).div(PRICE_PRECISION);

        // Assumes $1 FRAX in all cases
        if(global_collateral_ratio >= PRICE_PRECISION) { 
            // 1-to-1 or overcollateralized
            collat_out = frax_after_fee
                            .mul(collateral_prices[col_idx])
                            .div(10 ** (6 + missing_decimals[col_idx])); // PRICE_PRECISION + missing decimals
            fxs_out = 0;
        } else if (global_collateral_ratio == 0) { 
            // Algorithmic
            fxs_out = frax_after_fee
                            .mul(PRICE_PRECISION)
                            .div(getDsysSharesPrice());
            collat_out = 0;
        } else { 
            // Fractional
            collat_out = frax_after_fee
                            .mul(global_collateral_ratio)
                            .mul(collateral_prices[col_idx])
                            .div(10 ** (12 + missing_decimals[col_idx])); // PRICE_PRECISION ^2 + missing decimals
            fxs_out = frax_after_fee
                            .mul(PRICE_PRECISION.sub(global_collateral_ratio))
                            .div(getDsysSharesPrice()); // PRICE_PRECISIONS CANCEL OUT
        }

        // Checks
        require(collat_out <= (ERC20(collateral_addresses[col_idx])).balanceOf(address(this)).sub(unclaimed_pool_collateral[col_idx]), "Insufficient pool collateral");
        require(collat_out >= col_out_min, "Collateral slippage");
        require(fxs_out >= fxs_out_min, "FXS slippage");

        // Account for the redeem delay
        redeem_collateral_balances[msg.sender][col_idx] = redeem_collateral_balances[msg.sender][col_idx].add(collat_out);
        unclaimed_pool_collateral[col_idx] = unclaimed_pool_collateral[col_idx].add(collat_out);

        redeem_dsys_shares_balances[msg.sender] = redeem_dsys_shares_balances[msg.sender].add(fxs_out);
        unclaimed_pool_dsys_shares = unclaimed_pool_dsys_shares.add(fxs_out);

        last_redeemed[msg.sender] = block.number;

        DSYS.pool_burn_from(msg.sender, frax_amount);
        DSYSShares.pool_mint(address(this), fxs_out);
    }

    // After a redemption happens, transfer the newly minted FXS and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out FRAX/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption(uint256 col_idx) external returns (uint256 fxs_amount, uint256 collateral_amount) {
        require(redeemPaused[col_idx] == false, "Redeeming is paused");
        require((last_redeemed[msg.sender].add(redemption_delay)) <= block.number, "Too soon");
        bool sendDSYSShares = false;
        bool sendCollateral = false;

        // Use Checks-Effects-Interactions pattern
        if(redeem_dsys_shares_balances[msg.sender] > 0){
            fxs_amount = redeem_dsys_shares_balances[msg.sender];
            redeem_dsys_shares_balances[msg.sender] = 0;
            unclaimed_pool_dsys_shares = unclaimed_pool_dsys_shares.sub(fxs_amount);
            sendDSYSShares = true;
        }
        
        if(redeem_collateral_balances[msg.sender][col_idx] > 0){
            collateral_amount = redeem_collateral_balances[msg.sender][col_idx];
            redeem_collateral_balances[msg.sender][col_idx] = 0;
            unclaimed_pool_collateral[col_idx] = unclaimed_pool_collateral[col_idx].sub(collateral_amount);
            sendCollateral = true;
        }

        // Send out the tokens
        if(sendDSYSShares){
            SafeERC20.safeTransfer(IERC20(address(DSYSShares)), msg.sender, fxs_amount);
        }
        if(sendCollateral){
            SafeERC20.safeTransfer(IERC20(collateral_addresses[col_idx]), msg.sender, collateral_amount);
        }
    }

    // Function can be called by an FXS holder to have the protocol buy back FXS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackFxs(uint256 col_idx, uint256 fxs_amount, uint256 col_out_min) external collateralEnabled(col_idx) returns (uint256 col_out) {
        require(buyBackPaused[col_idx] == false, "Buyback is paused");
        uint256 fxs_price = getDsysSharesPrice();
        uint256 available_excess_collat_dv = buybackAvailableCollat();

        // If the total collateral value is higher than the amount required at the current collateral ratio then buy back up to the possible FXS with the desired collateral
        require(available_excess_collat_dv > 0, "Insuf Collat Avail For BBK");

        // Make sure not to take more than is available
        uint256 fxs_dollar_value_d18 = fxs_amount.mul(fxs_price).div(PRICE_PRECISION);
        require(fxs_dollar_value_d18 <= available_excess_collat_dv, "Insuf Collat Avail For BBK");

        // Get the equivalent amount of collateral based on the market value of FXS provided 
        uint256 collateral_equivalent_d18 = fxs_dollar_value_d18.mul(PRICE_PRECISION).div(collateral_prices[col_idx]);
        col_out = collateral_equivalent_d18.div(10 ** missing_decimals[col_idx]); // In its natural decimals()

        // Subtract the buyback fee
        col_out = (col_out.mul(PRICE_PRECISION.sub(buyback_fee[col_idx]))).div(PRICE_PRECISION);

        // Check for slippage
        require(col_out >= col_out_min, "Collateral slippage");

        // Take in and burn the FXS, then send out the collateral
        DSYSShares.pool_burn_from(msg.sender, fxs_amount);
        SafeERC20.safeTransfer(IERC20(collateral_addresses[col_idx]), msg.sender, col_out);

        // Increment the outbound collateral, in E18, for that hour
        // Used for buyback throttling
        bbkHourlyCum[curEpochHr()] += collateral_equivalent_d18;
    }

    // When the protocol is recollateralizing, we need to give a discount of FXS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get FXS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of FXS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra FXS value from the bonus rate as an arb opportunity
    function recollateralize(uint256 col_idx, uint256 collateral_amount, uint256 fxs_out_min) external collateralEnabled(col_idx) returns (uint256 fxs_out) {
        require(recollateralizePaused[col_idx] == false, "Recollat is paused");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals[col_idx]);
        uint256 fxs_price = getDsysSharesPrice();

        // Get the amount of FXS actually available (accounts for throttling)
        uint256 fxs_actually_available = recollatAvailableFxs();

        // Calculated the attempted amount of FXS
        fxs_out = collateral_amount_d18.mul(PRICE_PRECISION.add(bonus_rate).sub(recollat_fee[col_idx])).div(fxs_price);

        // Make sure there is FXS available
        require(fxs_out <= fxs_actually_available, "Insuf FXS Avail For RCT");

        // Check slippage
        require(fxs_out >= fxs_out_min, "FXS slippage");

        // Don't take in more collateral than the pool ceiling for this token allows
        require(freeCollatBalance(col_idx).add(collateral_amount) <= pool_ceilings[col_idx], "Pool ceiling");

        // Take in the collateral and pay out the FXS
        SafeERC20.safeTransferFrom(IERC20(collateral_addresses[col_idx]), msg.sender, address(this), collateral_amount);
        DSYSShares.pool_mint(msg.sender, fxs_out);

        // Increment the outbound FXS, in E18
        // Used for recollat throttling
        rctHourlyCum[curEpochHr()] += fxs_out;
    }

    // Bypasses the gassy mint->redeem cycle for AMOs to borrow collateral
    function amoMinterBorrow(uint256 collateral_amount) external onlyAMOMinters {
        // Checks the col_idx of the minter as an additional safety check
        uint256 minter_col_idx = IDsysAMOMinter(msg.sender).col_idx();

        // Transfer
        SafeERC20.safeTransfer(IERC20(collateral_addresses[minter_col_idx]), msg.sender, collateral_amount);
    }

    function toggleMRBR(uint256 col_idx, uint8 tog_idx) external onlyByOwnGovCust {
        if (tog_idx == 0) mintPaused[col_idx] = !mintPaused[col_idx];
        else if (tog_idx == 1) redeemPaused[col_idx] = !redeemPaused[col_idx];
        else if (tog_idx == 2) buyBackPaused[col_idx] = !buyBackPaused[col_idx];
        else if (tog_idx == 3) recollateralizePaused[col_idx] = !recollateralizePaused[col_idx];

        emit MRBRToggled(col_idx, tog_idx);
    }

    // Add an AMO Minter
    function addAMOMinter(address amo_minter_addr) external onlyByOwnGov {
        require(amo_minter_addr != address(0), "Zero address detected");

        // Make sure the AMO Minter has collatDollarBalance()
        uint256 collat_val_e18 = IDsysAMOMinter(amo_minter_addr).collatDollarBalance();
        require(collat_val_e18 >= 0, "Invalid AMO");

        amo_minter_addresses[amo_minter_addr] = true;

        emit AMOMinterAdded(amo_minter_addr);
    }

    // Remove an AMO Minter 
    function removeAMOMinter(address amo_minter_addr) external onlyByOwnGov {
        amo_minter_addresses[amo_minter_addr] = false;
        
        emit AMOMinterRemoved(amo_minter_addr);
    }

    function setCollateralPrice(uint256 col_idx, uint256 _new_price) external onlyByOwnGov {
        collateral_prices[col_idx] = _new_price;

        emit CollateralPriceSet(col_idx, _new_price);
    }

    // Could also be called toggleCollateral
    function toggleCollateral(uint256 col_idx) external onlyByOwnGov {
        address col_address = collateral_addresses[col_idx];
        enabled_collaterals[col_address] = !enabled_collaterals[col_address];

        emit CollateralToggled(col_idx, enabled_collaterals[col_address]);
    }

    function setPoolCeiling(uint256 col_idx, uint256 new_ceiling) external onlyByOwnGov {
        pool_ceilings[col_idx] = new_ceiling;

        emit PoolCeilingSet(col_idx, new_ceiling);
    }

    function setFees(uint256 col_idx, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external onlyByOwnGov {
        minting_fee[col_idx] = new_mint_fee;
        redemption_fee[col_idx] = new_redeem_fee;
        buyback_fee[col_idx] = new_buyback_fee;
        recollat_fee[col_idx] = new_recollat_fee;

        emit FeesSet(col_idx, new_mint_fee, new_redeem_fee, new_buyback_fee, new_recollat_fee);
    }

    function setPoolParameters(uint256 new_bonus_rate, uint256 new_redemption_delay) external onlyByOwnGov {
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay;
        emit PoolParametersSet(new_bonus_rate, new_redemption_delay);
    }

    function setPriceThresholds(uint256 new_mint_price_threshold, uint256 new_redeem_price_threshold) external onlyByOwnGov {
        mint_price_threshold = new_mint_price_threshold;
        redeem_price_threshold = new_redeem_price_threshold;
        emit PriceThresholdsSet(new_mint_price_threshold, new_redeem_price_threshold);
    }

    function setBbkRctPerHour(uint256 _bbkMaxColE18OutPerHour, uint256 _rctMaxFxsOutPerHour) external onlyByOwnGov {
        bbkMaxColE18OutPerHour = _bbkMaxColE18OutPerHour;
        rctMaxFxsOutPerHour = _rctMaxFxsOutPerHour;
        emit BbkRctPerHourSet(_bbkMaxColE18OutPerHour, _rctMaxFxsOutPerHour);
    }

    function setCustodian(address new_custodian) external onlyByOwnGov {
        custodian_address = new_custodian;

        emit CustodianSet(new_custodian);
    }

    function setTimelock(address new_timelock) external onlyByOwnGov {
        timelock_address = new_timelock;

        emit TimelockSet(new_timelock);
    }

}
