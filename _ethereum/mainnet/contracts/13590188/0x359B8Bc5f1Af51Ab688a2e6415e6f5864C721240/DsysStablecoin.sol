// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IChainlinkPriceConsumer.sol";
import "./IUniswapPairOracle.sol";
import "./IDsysPool.sol";

contract DsysStablecoin is ERC20, AccessControl {
    using SafeMath for uint256;

    // Track FRAX burned
    event DSYSBurned(address indexed from, address indexed to, uint256 amount);

    // Track FRAX minted
    event DSYSMinted(address indexed from, address indexed to, uint256 amount);

    enum PriceChoice { DSYS, DSYS_SHARE }
    IChainlinkPriceConsumer private eth_usd_pricer;
    uint8 private eth_usd_pricer_decimals;
    IUniswapPairOracle private dsys_eth_oracle;
    IUniswapPairOracle private dsys_share_eth_oracle;
    address public owner_address;
    address public creator_address;
    address public timelock_address; 
    address public controller_address; 
    address public dsys_share_address;
    address public dsys_eth_oracle_address;
    address public dsys_share_eth_oracle_address;
    address public weth_address;
    uint256 public constant genesis_supply = 2000000e18; // 2M FRAX (only for testing, genesis supply will be 5k on Mainnet). This is to help with establishing the Uniswap pools, as they need liquidity

    address[] public pools_array;
    mapping(address => bool) public pools; 

    uint256 private constant PRICE_PRECISION = 1e6;
    
    uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
    uint256 public redemption_fee; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public minting_fee; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public price_target; // The price of FRAX at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio

    bytes32 public constant COLLATERAL_RATIO_PAUSER = keccak256("COLLATERAL_RATIO_PAUSER");
    bool public collateral_ratio_paused = false;

    modifier onlyCollateralRatioPauser() {
        require(hasRole(COLLATERAL_RATIO_PAUSER, msg.sender));
        _;
    }

    modifier onlyPools() {
       require(pools[msg.sender] == true, "Only frax pools can call this function");
        _;
    } 
    
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address || msg.sender == controller_address, "You are not the owner, controller, or the governance timelock");
        _;
    }

    modifier onlyByOwnerGovernanceOrPool() {
        require(
            msg.sender == owner_address 
            || msg.sender == timelock_address 
            || pools[msg.sender] == true, 
            "You are not the owner, the governance timelock, or a pool");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _creator_address,
        address _timelock_address
    ) ERC20(_name, _symbol) {
        creator_address = _creator_address;
        timelock_address = _timelock_address;
        owner_address = _creator_address;
        _mint(creator_address, genesis_supply);
        grantRole(COLLATERAL_RATIO_PAUSER, creator_address);
        grantRole(COLLATERAL_RATIO_PAUSER, timelock_address);
        step = 2500; // 6 decimals of precision, equal to 0.25%
        global_collateral_ratio = 1000000; // Frax system starts off fully collateralized (6 decimals of precision)
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 1000000; // Collateral ratio will adjust according to the $1 price target at genesis
        price_band = 5000; // Collateral ratio will not adjust if between $0.995 and $1.005 at genesis
    }

    function oracle_price(PriceChoice choice) internal view returns (uint256) {
        // Get the ETH / USD price first, and cut it down to 1e6 precision
        uint256 price_vs_eth;

        if (choice == PriceChoice.DSYS) {
            price_vs_eth = uint256(dsys_eth_oracle.consult(weth_address, PRICE_PRECISION)); // How much DSYS if you put in PRICE_PRECISION WETH
        }
        else if (choice == PriceChoice.DSYS_SHARE) {
            price_vs_eth = uint256(dsys_share_eth_oracle.consult(weth_address, PRICE_PRECISION)); // How much DSYSShare if you put in PRICE_PRECISION WETH
        }
        else revert("INVALID PRICE CHOICE. Needs to be either 0 (DSYS) or 1 (DSYS_SHARE)");

        // Will be in 1e6 format
        return eth_usd_price().mul(PRICE_PRECISION).div(price_vs_eth);
    }

    // Returns X DSYS = 1 USD
    function dsys_price() public view returns (uint256) {
        return oracle_price(PriceChoice.DSYS);
    }

    // Returns X DSYShare = 1 USD
    function dsys_shares_price()  public view returns (uint256) {
        return oracle_price(PriceChoice.DSYS_SHARE);
    }

    function eth_usd_price() public view returns (uint256) {
        return uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
    }

    // Iterate through all frax pools and calculate all value of collateral in all pools globally 
    function globalCollateralValue() public view returns (uint256) {
        uint256 total_collateral_value_d18 = 0; 

        for (uint i = 0; i < pools_array.length; i++){ 
            // Exclude null addresses
            if (pools_array[i] != address(0)){
                total_collateral_value_d18 = total_collateral_value_d18.add(IDsysPool(pools_array[i]).collatDollarBalance());
            }

        }
        return total_collateral_value_d18;
    }

    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function dsys_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            oracle_price(PriceChoice.DSYS), // dsys_price()
            oracle_price(PriceChoice.DSYS_SHARE), // dsys_share_price()
            totalSupply(), // totalSupply()
            global_collateral_ratio, // global_collateral_ratio()
            globalCollateralValue(), // globalCollateralValue
            minting_fee, // minting_fee()
            redemption_fee, // redemption_fee()
            uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals) //eth_usd_price
        );
    }

    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
    uint256 public last_call_time; // Last time the refreshCollateralRatio function was called
    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        uint256 dsys_price_cur = dsys_price();
        require(block.timestamp - last_call_time >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setFraxStep()) 
        
        if (dsys_price_cur > price_target.add(price_band)) { //decrease collateral ratio
            if(global_collateral_ratio <= step){ //if within a step of 0, go to 0
                global_collateral_ratio = 0;
            } else {
                global_collateral_ratio = global_collateral_ratio.sub(step);
            }
        } else if (dsys_price_cur < price_target.sub(price_band)) { //increase collateral ratio
            if(global_collateral_ratio.add(step) >= 1000000){
                global_collateral_ratio = 1000000; // cap collateral ratio at 1.000000
            } else {
                global_collateral_ratio = global_collateral_ratio.add(step);
            }
        }

        last_call_time = block.timestamp; // Set the time of the last expansion
    }

    // Used by pools when user redeems
    function pool_burn_from(address b_address, uint256 b_amount) public onlyPools {
        super._burn(b_address, b_amount);
        emit DSYSBurned(b_address, msg.sender, b_amount);
    }

    // This function is what other frax pools will call to mint new FRAX 
    function pool_mint(address m_address, uint256 m_amount) public onlyPools {
        super._mint(m_address, m_amount);
        emit DSYSMinted(msg.sender, m_address, m_amount);
    }

    // Adds collateral addresses supported, such as tether and busd, must be ERC20 
    function addPool(address pool_address) public onlyByOwnerOrGovernance {
        require(pools[pool_address] == false, "address already exists");
        pools[pool_address] = true; 
        pools_array.push(pool_address);
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwnerOrGovernance {
        require(pools[pool_address] == true, "address doesn't exist already");
        
        // Delete from the mapping
        delete pools[pool_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < pools_array.length; i++){ 
            if (pools_array[i] == pool_address) {
                pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function setRedemptionFee(uint256 red_fee) public onlyByOwnerOrGovernance {
        redemption_fee = red_fee;
    }

    function setMintingFee(uint256 min_fee) public onlyByOwnerOrGovernance {
        minting_fee = min_fee;
    }  

    function setStep(uint256 _new_step) public onlyByOwnerOrGovernance {
        step = _new_step;
    }  

    function setPriceTarget (uint256 _new_price_target) public onlyByOwnerOrGovernance {
        price_target = _new_price_target;
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerOrGovernance {
    	refresh_cooldown = _new_cooldown;
    }

    function setDsysShareAddress(address _dsys_share_address) public onlyByOwnerOrGovernance {
        dsys_share_address = _dsys_share_address;
    }

    function setETHUSDOracle(address _eth_usd_consumer_address) public onlyByOwnerOrGovernance {
        eth_usd_pricer = IChainlinkPriceConsumer(_eth_usd_consumer_address);
        eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setController(address _controller_address) external onlyByOwnerOrGovernance {
        controller_address = _controller_address;
    }

    function setPriceBand(uint256 _price_band) external onlyByOwnerOrGovernance {
        price_band = _price_band;
    }

    // Sets the FRAX_ETH Uniswap oracle address 
    function setDsysEthOracle(address _dsys_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
        dsys_eth_oracle_address = _dsys_oracle_addr;
        dsys_eth_oracle = IUniswapPairOracle(_dsys_oracle_addr); 
        weth_address = _weth_address;
    }

    // Sets the FXS_ETH Uniswap oracle address 
    function setDsysShareEthOracle(address _dsys_share_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
        dsys_share_eth_oracle_address = _dsys_share_oracle_addr;
        dsys_share_eth_oracle = IUniswapPairOracle(_dsys_share_oracle_addr);
        weth_address = _weth_address;
    }

    function toggleCollateralRatio() public onlyCollateralRatioPauser {
        collateral_ratio_paused = !collateral_ratio_paused;
    }

}
