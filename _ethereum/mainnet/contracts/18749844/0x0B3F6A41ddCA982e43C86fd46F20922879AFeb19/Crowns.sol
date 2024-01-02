// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./AggregatorV3Interface.sol";

contract Crowns is Initializable, ERC20Upgradeable {
    uint256 public totalStaked;
    uint256 public maxSupply;
    uint256 public tgeTimestamp;
    string public saleStage;
    bool public paused;

    address public maintenanceAdmin;
    address public financialAdmin;

    AggregatorV3Interface priceFeed;

    address public usdcAddress;
    IERC20 public usdc;

    address public usdtAddress;
    IERC20 public usdt;

    // Define a mapping for the each pool vesting schedules
    mapping(string => VestingSchedule) public poolVestingSchedules;

    // Define a mapping to store the price for each sale stage
    mapping(string => uint256) public stagePrices;

    mapping(address => VestingSchedule[]) public vestingSchedules;

    struct VestingSchedule {
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 totalAmount;
        uint256 releasedAmount;
        bool isActive;
        uint256 tgePercent;
        string pool;
    }

    // emitted when new user vesting schedule is created
    event NewVestingSchedule(
        address indexed user,
        uint256 amount,
        string stage,
        uint256 price,
        string currency
    );

    // emitted when user burn tokens
    // @param address The address of the user
    // @param amount The amount of tokens burned
    event TokensBurned(address indexed user, uint256 amount);

    // Pool supply limit reached
    // @param pool The identifier of the pool
    // @param available The amount of tokens available in the pool
    // @param requested The amount of tokens requested
    error PoolSupplyLimitReached(
        string pool,
        uint256 available,
        uint256 requested
    );

    // Max supply reached
    // @param available The amount of tokens available in the pool
    // @param requested The amount of tokens requested
    error MaxSupplyExceeded(uint256 available, uint256 requested);

    // Funds unavailable
    // @param available The amount of tokens available in the pool
    // @param required The amount of tokens required
    error InsufficientFunds(uint256 available, uint256 required);

    /**
     * @dev Initializes the token with specified name and symbol, and sets up initial parameters.
     * This function is called only once during deployment.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     */
    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        // Calls the initializer of the ERC-20 contract with the given name and symbol.
        __ERC20_init(name, symbol);

        // Sets the Chainlink price feed address for ETH/USD.
        priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );

        // Sets the maximum supply of the token.
        maxSupply = 1000000000 * 10 ** decimals();

        // Sets the initial sale stage to "seed" and pauses the contract.
        saleStage = "seed";
        paused = true;

        // Sets the addresses for USDC and USDT.
        usdcAddress = 0xEC7D792EE9953aea6803554293CAD681E5963f0F;
        usdc = IERC20(usdcAddress);

        usdtAddress = 0xEC7D792EE9953aea6803554293CAD681E5963f0F;
        usdt = IERC20(usdtAddress);

        // Initialize the prices for each sale stage.
        stagePrices["seed"] = 800; // Set the initial price in USD for the "seed" stage.
        stagePrices["private"] = 1200; // Set the initial price in USD for the "private" stage.
        stagePrices["public"] = 1800; // Set the initial price in USD for the "public" stage.

        maintenanceAdmin = msg.sender;
        financialAdmin = msg.sender;

        tgeTimestamp = block.timestamp + 69_420 * 365 days;

        // Set the vesting schedules for each pool
        poolVestingSchedules["seed"] = VestingSchedule(
            block.timestamp,
            5 minutes,
            10 minutes,
            // 2 * 30 days, // Cliff
            // 18 * 30 days, // Vesting duration
            120_000_000 * 10 ** 18,
            0,
            true,
            5,
            "seed"
        );
        poolVestingSchedules["private"] = VestingSchedule(
            block.timestamp,
            // 2 * 30 days, // Cliff
            // 12 * 30 days, // Vesting duration
            5 minutes,
            10 minutes,
            110_000_000 * 10 ** 18,
            0,
            false,
            5,
            "private"
        );
        poolVestingSchedules["public"] = VestingSchedule(
            block.timestamp,
            // 0, // Cliff
            // 6 * 30 days, // Vesting duration
            0,
            10 minutes,
            40_000_000 * 10 ** 18,
            0,
            false,
            15,
            "public"
        );
        poolVestingSchedules["team"] = VestingSchedule(
            block.timestamp,
            5 minutes,
            10 minutes,
            // 12 * 30 days, // Cliff
            // 36 * 30 days, // Vesting duration
            50_000_000 * 10 ** 18, // Total allocation
            0,
            false,
            0, // TGE percent
            "team"
        );
        poolVestingSchedules["ecosystem"] = VestingSchedule(
            block.timestamp,
            0,
            10 minutes,
            // 0, // Cliff
            // 72 * 30 days, // Vesting duration
            390_000_000 * 10 ** 18, // Total allocation
            0,
            false,
            0, // TGE percent
            "ecosystem"
        );
        poolVestingSchedules["marketing"] = VestingSchedule(
            block.timestamp,
            5 minutes,
            10 minutes,
            // 4 * 30 days, // Cliff
            // 48 * 30 days, // Vesting duration
            60_000_000 * 10 ** 18,
            0,
            false,
            0,
            "marketing"
        );
        poolVestingSchedules["airdrop"] = VestingSchedule(
            block.timestamp,
            0,
            10 minutes,
            // 0, // Cliff
            // 12 * 30 days, // Vesting duration
            60_000_000 * 10 ** 18,
            0,
            false,
            10,
            "airdrop"
        );
        poolVestingSchedules["liquidity"] = VestingSchedule(
            block.timestamp,
            0,
            10 minutes,
            // 0, // Cliff
            // 20 * 30 days, // Vesting duration
            120_000_000 * 10 ** 18,
            0,
            false,
            20,
            "liquidity"
        );
        poolVestingSchedules["ambassadors"] = VestingSchedule(
            block.timestamp,
            5 minutes,
            10 minutes,
            // 4 * 30 days, // Cliff
            // 36 * 30 days, // Vesting duration
            50_000_000 * 10 ** 18,
            0,
            false,
            0,
            "ambassadors"
        );
    }

    modifier onlyMaintenanceAdmin() {
        require(
            msg.sender == maintenanceAdmin,
            "Caller is not the maintenance admin"
        );
        _;
    }

    modifier onlyFinancialAdmin() {
        require(
            msg.sender == financialAdmin,
            "Caller is not the financial admin"
        );
        _;
    }

    function setMaintenanceAdmin(address newAdmin) public onlyMaintenanceAdmin {
        maintenanceAdmin = newAdmin;
    }

    function setFinancialAdmin(address newAdmin) public onlyFinancialAdmin {
        financialAdmin = newAdmin;
    }

    function setUSDT(address _usdtAddress) public onlyFinancialAdmin {
        usdtAddress = _usdtAddress;
        usdt = IERC20(usdtAddress);
    }

    function setUSDC(address _usdcAddress) public onlyFinancialAdmin {
        usdcAddress = _usdcAddress;
        usdc = IERC20(usdcAddress);
    }

    function setTGETimestamp(uint256 _tgeTimestamp) public onlyFinancialAdmin {
        tgeTimestamp = _tgeTimestamp;
    }

    // @dev Validates the amount of tokens to be minted.
    function validateAmount(uint256 amount, string memory pool) internal view {
        require(amount > 0, "Amount must be greater than 0");

        if (totalSupply() + amount > maxSupply) {
            revert MaxSupplyExceeded(maxSupply - totalSupply(), amount);
        }

        VestingSchedule storage poolVestingSchedule = poolVestingSchedules[
            pool
        ];

        require(poolVestingSchedule.totalAmount > 0, "Invalid pool");

        if (
            poolVestingSchedule.releasedAmount + amount >
            poolVestingSchedule.totalAmount
        ) {
            revert PoolSupplyLimitReached(
                pool,
                poolVestingSchedule.totalAmount -
                    poolVestingSchedule.releasedAmount,
                amount
            );
        }
    }

    /**
     * @dev Gets the latest price of ETH in USD from the Chainlink price feed.
     * @return The latest ETH price in USD.
     */
    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @dev Sets the price feed address for ETH/USD.
     * Only the admin can call this function.
     * @param _priceFeed The address of the price feed.
     */
    function setPriceFeed(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @dev Updates the current sale stage.
     * Only the admin can call this function.
     * @param stage The identifier of the new sale stage.
     */
    function updateStage(string memory stage) public onlyFinancialAdmin {
        saleStage = stage;
    }

    /**
     * @dev Updates the pause state of the contract.
     * Only the admin can call this function.
     * @param isPaused Boolean indicating whether the contract should be paused.
     */
    function updatePauseState(bool isPaused) public onlyMaintenanceAdmin {
        paused = isPaused;
    }

    /**
     * @dev Allows the admin to withdraw ETH from the contract.
     * Only the admin can call this function.
     * @param amount The amount of ETH to be withdrawn.
     */
    function withdrawETH(uint256 amount) external onlyFinancialAdmin {
        payable(financialAdmin).transfer(amount);
    }

    /**
     * @dev Allows the admin to withdraw ERC-20 tokens from the contract.
     * Only the admin can call this function.
     * @param tokenAddress The address of the ERC-20 token.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withdrawToken(
        address tokenAddress,
        uint256 amount
    ) external onlyFinancialAdmin {
        IERC20 token = IERC20(tokenAddress);

        token.transfer(financialAdmin, amount);
    }

    /**
     * @dev Creates a new vesting schedule for the specified address.
     * Ensures that the contract is not paused and the maximum supply is not exceeded.
     * Calculates the cost of the tokens in USD based on the current sale stage price and ETH exchange rate.
     * Checks if the sender has sent enough ETH to cover the cost.
     * Creates a new vesting schedule for the specified address.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to be minted.
     */
    function mint(address to, uint256 amount) external payable {
        // Requires that the contract is not paused.
        require(!paused, "The contract is paused!");

        // Validates the amount of tokens to be minted.
        validateAmount(amount, saleStage);

        // Gets the vesting schedule for the current sale stage.
        VestingSchedule storage poolVestingSchedule = poolVestingSchedules[
            saleStage
        ];

        poolVestingSchedule.releasedAmount += amount;

        // Calculates the cost of the tokens in USD based on the current ETH price.
        int256 ethPrice = getLatestPrice();
        require(ethPrice > 0, "Invalid ETH price");
        uint256 costInUSD = (stagePrices[saleStage] * amount) /
            uint256(ethPrice);

        // Checks if the sender has sent enough ETH to cover the cost.
        if (msg.value < costInUSD) {
            revert InsufficientFunds(msg.value, costInUSD);
        }

        if (block.timestamp < tgeTimestamp) {
            createVestingSchedule(
                to,
                amount,
                0,
                poolVestingSchedule.tgePercent,
                block.timestamp, // Start vesting from current timestamp
                poolVestingSchedule.cliff,
                poolVestingSchedule.duration,
                false
            );
        } else {
            uint256 initialRelease = (amount * poolVestingSchedule.tgePercent) /
                100; // % for immediate release

            if (initialRelease > 0) {
                _mint(to, initialRelease); // Mint % tokens immediately
            }

            createVestingSchedule(
                to,
                amount,
                initialRelease,
                poolVestingSchedule.tgePercent,
                block.timestamp,
                poolVestingSchedule.cliff,
                poolVestingSchedule.duration,
                true
            );
        }

        emit NewVestingSchedule(
            to,
            amount,
            saleStage,
            stagePrices[saleStage],
            "ETH"
        );
    }

    function createVestingSchedule(
        address beneficiary,
        uint256 amount,
        uint256 released,
        uint256 tgePercent,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration,
        bool isActive
    ) internal {
        VestingSchedule[] storage beneficiarySchedules = vestingSchedules[
            beneficiary
        ];
        uint256 index = beneficiarySchedules.length;

        beneficiarySchedules.push();

        VestingSchedule storage newVestingSchedule = beneficiarySchedules[
            index
        ];

        require(duration > 0, "Duration must be greater than 0");

        newVestingSchedule.tgePercent = tgePercent;
        newVestingSchedule.start = start;
        newVestingSchedule.cliff = cliffDuration;
        newVestingSchedule.duration = duration;
        newVestingSchedule.totalAmount = amount;
        newVestingSchedule.releasedAmount = released;
        newVestingSchedule.isActive = isActive;
    }

    function releaseVestedTokens(address beneficiary) public {
        uint256 totalUnreleased = 0;
        for (uint256 i = 0; i < vestingSchedules[beneficiary].length; i++) {
            VestingSchedule storage schedule = vestingSchedules[beneficiary][i];
            // If the vesting schedule is not active and TGE has occurred, update the start time
            if (!schedule.isActive && block.timestamp >= tgeTimestamp) {
                if (tgeTimestamp > schedule.start) {
                    schedule.start = tgeTimestamp;
                }
                schedule.isActive = true;

                // Claim initial % release after TGE if vesting schedule was purchased before TGE
                if (schedule.tgePercent > 0) {
                    uint256 initialRelease = (schedule.totalAmount *
                        schedule.tgePercent) / 100; // % of total amount
                    schedule.releasedAmount += initialRelease;
                    totalUnreleased += initialRelease;
                }
            }

            // If the vesting schedule is active, calculate the releasable amount
            if (schedule.isActive) {
                uint256 unreleased = calculableUnreleasedTokens(beneficiary, i);
                if (unreleased > 0) {
                    schedule.releasedAmount += unreleased;
                    totalUnreleased += unreleased;
                }
            }
        }

        require(totalUnreleased > 0, "No tokens are due");
        _mint(beneficiary, totalUnreleased);
    }

    function calculableUnreleasedTokens(
        address beneficiary,
        uint256 index
    ) internal view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[beneficiary][index];
        if (
            !schedule.isActive ||
            block.timestamp < schedule.start + schedule.cliff
        ) {
            return 0;
        }

        if (schedule.duration == 0) {
            return schedule.totalAmount - schedule.releasedAmount;
        }

        uint256 elapsedTime = block.timestamp - schedule.start;

        // Scale up the calculation to preserve precision.
        // For example, using a scale factor of 100.
        uint256 scaledTotalAmount = schedule.totalAmount * 100;

        // Calculate the vested portion.
        uint256 vestedPortion = ((100 - schedule.tgePercent) *
            scaledTotalAmount) / 100;

        // Calculate the vested amount.
        // First, do the multiplication to preserve precision, then divide.
        uint256 vestedAmount = (elapsedTime * vestedPortion) /
            schedule.duration;

        // Scale down the result to get the correct amount.
        vestedAmount = vestedAmount / 100;

        // Substract the amount already released, minus the initial release at TGE
        vestedAmount -=
            schedule.releasedAmount -
            ((schedule.totalAmount * schedule.tgePercent) / 100);

        if (vestedAmount > schedule.totalAmount - schedule.releasedAmount) {
            vestedAmount = schedule.totalAmount - schedule.releasedAmount;
        }

        return vestedAmount;
    }

    // View method to show if we can release tokens in front end
    function calculableReleaseAmount(
        address beneficiary
    ) public view returns (uint256) {
        uint256 totalReleasable = 0;
        for (uint256 i = 0; i < vestingSchedules[beneficiary].length; i++) {
            VestingSchedule storage schedule = vestingSchedules[beneficiary][i];
            uint256 releasableAmount = 0;

            // Handle initial release at TGE
            if (
                !schedule.isActive &&
                block.timestamp >= tgeTimestamp &&
                schedule.tgePercent > 0
            ) {
                releasableAmount +=
                    (schedule.totalAmount * schedule.tgePercent) /
                    100; // % of total amount
            }

            // Check if the schedule is active and calculate releasable vested tokens
            if (schedule.isActive) {
                releasableAmount += calculableUnreleasedTokens(beneficiary, i);
            }

            // Add to total releasable amount
            totalReleasable += releasableAmount;
        }
        return totalReleasable;
    }

    /**
     * @dev Sets the vesting schedule for a specific sale stage.
     * Only the admin can call this function.
     * @param currentSaleStage The identifier of the sale stage.
     * @param start The start time of the vesting schedule.
     * @param cliff The cliff period before vesting starts.
     * @param duration The total duration of the vesting schedule.
     * @param totalAmount The total amount of tokens to be vested for the sale stage.
     */
    function setStageVestingSchedule(
        string memory currentSaleStage,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 tgePercent,
        uint256 totalAmount
    ) external onlyMaintenanceAdmin {
        // Retrieves the vesting schedule for the specified sale stage.
        VestingSchedule storage vestingSchedule = poolVestingSchedules[
            currentSaleStage
        ];

        // Sets the parameters of the vesting schedule for the sale stage.
        vestingSchedule.start = start;
        vestingSchedule.cliff = cliff;
        vestingSchedule.duration = duration;
        vestingSchedule.totalAmount = totalAmount;
        vestingSchedule.tgePercent = tgePercent;
    }

    /**
     * @dev Mints tokens for a specified amount of USDC or USDT during the sale.
     * Calculates the amount of tokens based on the current sale stage price.
     * Transfers the specified stablecoin from the caller to the contract and mints the tokens for the specified address.
     * @param to The address to receive the minted tokens.
     * @param stablecoinAmount The amount of USDC or USDT to be used for minting.
     */
    function mintInStablecoin(
        address to,
        uint256 stablecoinAmount,
        string memory tokenName
    ) internal {
        // Requires that the contract is not paused.
        require(!paused, "The contract is paused!");

        // Calculate the amount of tokens to mint based on the stablecoin amount and price per token.
        uint256 tokenAmount = (stablecoinAmount / stagePrices[saleStage]) * 1e5; // * 1e18;

        // Validates the amount of tokens to be minted.
        validateAmount(tokenAmount, saleStage);

        // Determine the vesting schedule for the current sale stage.
        VestingSchedule storage poolVestingSchedule = poolVestingSchedules[
            saleStage
        ];

        if (block.timestamp < tgeTimestamp) {
            createVestingSchedule(
                to,
                tokenAmount,
                0,
                poolVestingSchedule.tgePercent,
                block.timestamp, // Start vesting from TGE date
                poolVestingSchedule.cliff,
                poolVestingSchedule.duration,
                false
            );
        } else {
            uint256 initialRelease = (tokenAmount *
                poolVestingSchedule.tgePercent) / 100; // % for immediate release

            if (initialRelease > 0) {
                _mint(to, initialRelease); // Mint % tokens immediately
            }

            createVestingSchedule(
                to,
                tokenAmount,
                initialRelease,
                poolVestingSchedule.tgePercent,
                block.timestamp,
                poolVestingSchedule.cliff,
                poolVestingSchedule.duration,
                true
            );
        }

        emit NewVestingSchedule(
            to,
            tokenAmount,
            saleStage,
            stagePrices[saleStage],
            tokenName
        );
    }

    /**
     * @dev Mints tokens for a specified amount of USDT during the sale.
     * Calculates the amount of tokens based on the current sale stage price.
     * Transfers the USDT from the caller to the contract and mints the tokens for the specified address.
     * @param to The address to receive the minted tokens.
     * @param usdtAmount The amount of USDT to be used for minting.
     */
    function mintInUSDT(address to, uint256 usdtAmount) external {
        // Transfers the USDT from the caller to the contract.
        usdt.transferFrom(msg.sender, address(this), usdtAmount);

        // Call the common minting function for stablecoins.
        mintInStablecoin(to, usdtAmount, "USDT");
    }

    /**
     * @dev Mints tokens for a specified amount of USDC during the sale.
     * Calculates the amount of tokens based on the current sale stage price.
     * Transfers the USDC from the caller to the contract and mints the tokens for the specified address.
     * @param to The address to receive the minted tokens.
     * @param usdcAmount The amount of USDC to be used for minting.
     */
    function mintInUSDC(address to, uint256 usdcAmount) external {
        // Transfers the USDC from the caller to the contract.
        usdc.transferFrom(msg.sender, address(this), usdcAmount);

        // Call the common minting function for stablecoins.
        mintInStablecoin(to, usdcAmount, "USDC");
    }

    /**
     * @dev Mints a specified amount of tokens for the admin.
     * Only the admin can call this function.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of tokens to be minted.
     */
    function mintForAdmin(
        address to,
        uint256 amount,
        string memory pool
    ) external onlyFinancialAdmin {
        // Validates the amount of tokens to be minted.
        validateAmount(amount, pool);

        // Update the total supply for the pool
        poolVestingSchedules[pool].releasedAmount += amount;

        // Mints the tokens and transfers them to the specified address.
        _mint(to, amount);

        emit NewVestingSchedule(to, amount, saleStage, 0, "admin");
    }

    /**
     * @dev Sets the vesting schedule for a staker.
     * Only the admin can call this function.
     * @param staker The address of the staker.
     * @param pool The identifier of the pool.
     * @param totalAmount The total amount of tokens to be vested.
     */
    function setVestingSchedule(
        address staker,
        uint256 totalAmount,
        string memory pool
    ) external onlyFinancialAdmin {
        // Validates the amount of tokens to be minted.
        validateAmount(totalAmount, pool);

        VestingSchedule storage poolVestingSchedule = poolVestingSchedules[
            pool
        ];

        poolVestingSchedule.releasedAmount += totalAmount;

        // Check if the staker is eligible for immediate release
        if (block.timestamp >= tgeTimestamp) {
            uint256 initialRelease = (totalAmount *
                poolVestingSchedule.tgePercent) / 100; // % for immediate release

            if (initialRelease > 0) {
                _mint(staker, initialRelease); // Mint % tokens immediately
            }

            createVestingSchedule(
                staker,
                totalAmount,
                initialRelease,
                poolVestingSchedule.tgePercent,
                block.timestamp,
                poolVestingSchedule.cliff,
                poolVestingSchedule.duration,
                true
            );
        } else {
            createVestingSchedule(
                staker,
                totalAmount,
                0,
                poolVestingSchedule.tgePercent,
                block.timestamp, // Start vesting from TGE date
                poolVestingSchedule.cliff,
                poolVestingSchedule.duration,
                false
            );
        }
    }

    /**
     * @dev Burns a specified amount of tokens owned by the given address.
     * Only the owner of the tokens can call this function.
     * @param amount The amount of tokens to be burned.
     */
    function burn(uint256 amount) external {
        // Calls the internal _burn function to burn the specified amount of tokens.
        _burn(msg.sender, amount);

        emit TokensBurned(msg.sender, amount);
    }
}
