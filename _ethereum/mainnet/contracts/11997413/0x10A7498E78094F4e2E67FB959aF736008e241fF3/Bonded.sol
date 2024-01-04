pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";

contract Bonded is OwnableUpgradeSafe {
    using SafeMath for uint256;

    uint256 public TGE;
    uint256 public constant month = 30 days;
    uint256 constant decimals = 18;
    uint256 constant decMul = uint256(10)**decimals;

    address public advisorsAddress;
    address public foundationAddress;
    address public ecosystemAddress;
    address public reserveAddress;
    address public marketingAddress;
    address public employeesAddress;

    uint256 public constant SEED_POOL = 5000000 * decMul;
    uint256 public constant ADVISORS_POOL = 480000 * decMul;
    uint256 public constant FOUNDATION_POOL = 1200000 * decMul;
    uint256 public constant ECOSYSTEM_POOL = 1200000 * decMul;
    uint256 public constant RESERVE_POOL = 600000 * decMul;
    uint256 public constant MARKETING_POOL = 480000 * decMul;
    uint256 public constant EMPLOYEES_POOL = 840000 * decMul;

    uint256 public currentSeedPool;
    uint256 public currentAdvisorsPool;
    uint256 public currentFoundationPool;
    uint256 public currentEcosystemPool;
    uint256 public currentReservePool;
    uint256 public currentMarketingPool;
    uint256 public currentEmployeesPool;

    ERC20BurnableUpgradeSafe public token;

    mapping(address => uint256) public seedWhitelist;

    modifier requireSetTGE() {
        require(TGE > 0, "TGE must be set");
        _;
    }

    constructor(
        address _advisorsAddress,
        address _foundationAddress,
        address _ecosystemAddress,
        address _reserveAddress,
        address _marketingAddress,
        address _employeesAddress,
        uint256 _currentSeedPool,
        uint256 _currentAdvisorsPool,
        uint256 _currentFoundationPool,
        uint256 _currentEcosystemPool,
        uint256 _currentReservePool,
        uint256 _currentMarketingPool,
        uint256 _currentEmployeesPool
    ) public {
        __Ownable_init_unchained();

        advisorsAddress = _advisorsAddress;
        foundationAddress = _foundationAddress;
        ecosystemAddress = _ecosystemAddress;
        reserveAddress = _reserveAddress;
        marketingAddress = _marketingAddress;
        employeesAddress = _employeesAddress;

        currentSeedPool = _currentSeedPool;
        currentAdvisorsPool = _currentAdvisorsPool;
        currentFoundationPool = _currentFoundationPool;
        currentEcosystemPool = _currentEcosystemPool;
        currentReservePool = _currentReservePool;
        currentMarketingPool = _currentMarketingPool;
        currentEmployeesPool = _currentEmployeesPool;
    }

    /**
     * @dev Sets the AddXyz ERC-20 token contract address
     */
    function setTokenContract(address _tokenAddress) public onlyOwner {
        require(true == isContract(_tokenAddress), "require contract");
        token = ERC20BurnableUpgradeSafe(_tokenAddress);
    }

    /**
     * @dev Sets the current TGE from where the vesting period will be counted. Can be used only if TGE is zero.
     */
    function setTGE(uint256 _date) public onlyOwner {
        require(TGE == 0, "TGE has already been set");
        TGE = _date;
    }

    /**
     * @dev Sets each address from `addresses` as the key and each balance
     * from `balances` to the privateWhitelist. Can be used only by an owner.
     */
    function addToWhitelist(
        address[] memory addresses,
        uint256[] memory balances
    ) public onlyOwner {
        require(addresses.length == balances.length, "Invalid request length");
        for (uint256 i = 0; i < addresses.length; i++) {
            seedWhitelist[addresses[i]] = balances[i];
        }
    }

    /**
     * @dev claim seed tokens from the contract balance.
     * `amount` means how many tokens must be claimed.
     * Can be used only by an owner or by any whitelisted person
     */

    function claimSeedTokens(uint256 amount) public requireSetTGE() {
        require(
            seedWhitelist[msg.sender] > 0 || msg.sender == owner(),
            "Sender is not whitelisted"
        );
        require(
            seedWhitelist[msg.sender] >= amount || msg.sender == owner(),
            "Exceeded token amount"
        );
        require(currentSeedPool >= amount, "Exceeded seedpool");
        require(amount > 0, "Amount should be more than 0");

        currentSeedPool = currentSeedPool.sub(amount);

        // Bridge fees are not taken off for contract owner
        if (msg.sender == owner()) {
            token.transfer(msg.sender, amount);
            return;
        }

        seedWhitelist[msg.sender] = seedWhitelist[msg.sender].sub(amount);

        uint256 amountToBurn = calculateFee(amount);

        if (amountToBurn > 0) {
            token.burn(amountToBurn);
        }

        token.transfer(msg.sender, amount.sub(amountToBurn));
    }

    /**
     * @dev claim advisors tokens from the contract balance.
     * Can be used only by an owner or from advisorsAddress.
     * Tokens will be send to sender address.
     */
    function claimAdvisorsTokens() public requireSetTGE() {
        require(
            msg.sender == advisorsAddress || msg.sender == owner(),
            "Unauthorised sender"
        );
        require(currentAdvisorsPool > 0, "nothing to claim");

        uint256 amount = 0;
        uint256 periodsPass = now.sub(TGE).div(6 * month);
        require(periodsPass >= 1, "Vesting period");

        uint256 amountToClaim = ADVISORS_POOL.div(4);
        for (uint256 i = 1; i <= periodsPass; i++) {
            if (
                currentAdvisorsPool <= ADVISORS_POOL.sub(amountToClaim.mul(i))
            ) {
                continue;
            }
            currentAdvisorsPool = currentAdvisorsPool.sub(amountToClaim);
            amount = amount.add(amountToClaim);
        }

        // 25% each 6 months
        require(amount > 0, "nothing to claim");

        uint256 amountToBurn = calculateFee(amount);

        if (amountToBurn > 0) {
            token.burn(amountToBurn);
        }

        token.transfer(advisorsAddress, amount.sub(amountToBurn));
    }

    /**
     * @dev claim foundation tokens from the contract balance.
     * Can be used only by an owner or from foundationAddress.
     * Tokens will be send to foundationAddress.
     */

    function claimFoundationTokens() public requireSetTGE() {
        require(
            msg.sender == foundationAddress || msg.sender == owner(),
            "Unauthorised sender"
        );
        require(currentFoundationPool > 0, "nothing to claim");

        // 1 year of vesting period
        require(now >= TGE + 12 * month, "Vesting period");

        // Get the total months passed after the vesting period of 1 year
        uint256 monthPassed = (now.sub(TGE)).div(month).sub(12).add(1);

        // Avoid overflow when releasing 10% each month
        // If more than 10 months passed without token claim then 100% tokens can be claimed at once.
        if (monthPassed > 10) {
            monthPassed = 10;
        }

        uint256 amount =
            currentFoundationPool.sub(
                FOUNDATION_POOL.sub(
                    FOUNDATION_POOL.mul(monthPassed * 10).div(100)
                )
            );
        require(amount > 0, "nothing to claim");

        currentFoundationPool = currentFoundationPool.sub(amount);

        //18 month of vesting period, no need to check fee
        token.transfer(foundationAddress, amount);
    }

    /**
     * @dev claim ecosystem tokens from the contract balance.
     * Can be used only by an owner or from ecosystemAddress.
     * Tokens will be send to ecosystemAddress.
     */
    function claimEcosystemTokens() public requireSetTGE() {
        require(
            msg.sender == ecosystemAddress || msg.sender == owner(),
            "Unauthorised sender"
        );

        //6 months of vesting period
        require(now >= TGE + 6 * month, "Vesting period");

        uint256 monthPassed = now.sub(TGE).div(month).sub(5);

        // Avoid overflow when releasing 5% each month
        if (monthPassed > 20) {
            monthPassed = 20;
        }

        uint256 amount =
            currentEcosystemPool.sub(
                ECOSYSTEM_POOL.sub(ECOSYSTEM_POOL.mul(monthPassed * 5).div(100))
            );
        require(amount > 0, "nothing to claim");

        currentEcosystemPool = currentEcosystemPool.sub(amount);

        uint256 amountToBurn = calculateFee(amount);

        if (amountToBurn > 0) {
            token.burn(amountToBurn);
        }

        token.transfer(ecosystemAddress, amount.sub(amountToBurn));
    }

    /**
     * @dev claim reserve tokens from the contract balance.
     * Can be used only by an owner or from reserveAddress.
     * Tokens will be send to reserveAddress.
     */
    function claimReserveTokens() public requireSetTGE() {
        require(
            msg.sender == reserveAddress || msg.sender == owner(),
            "Unauthorised sender"
        );

        //6 months of vesting period
        require(now >= TGE + 6 * month, "Vesting period");

        uint256 monthPassed = now.sub(TGE).div(month).sub(5);

        // Avoid overflow when releasing 5% each month
        if (monthPassed > 20) {
            monthPassed = 20;
        }

        uint256 amount =
            currentReservePool.sub(
                RESERVE_POOL.sub((RESERVE_POOL.mul(monthPassed * 5)).div(100))
            );

        currentReservePool = currentReservePool.sub(amount);
        require(amount > 0, "nothing to claim");

        uint256 amountToBurn = calculateFee(amount);

        if (amountToBurn > 0) {
            token.burn(amountToBurn);
        }

        token.transfer(reserveAddress, amount.sub(amountToBurn));
    }

    /**
     * @dev claim marketing tokens from the contract balance.
     * Can be used only by an owner or from marketingAddress.
     * Tokens will be send to marketingAddress.
     */
    function claimMarketingTokens() public requireSetTGE() {
        require(
            msg.sender == marketingAddress || msg.sender == owner(),
            "Unauthorised sender"
        );

        // no vesting period
        uint256 monthPassed = (now.sub(TGE)).div(month).add(1);

        // Avoid overflow when releasing 10% each month
        if (monthPassed > 10) {
            monthPassed = 10;
        }

        uint256 amount =
            currentMarketingPool.sub(
                MARKETING_POOL.sub(
                    MARKETING_POOL.mul(monthPassed * 10).div(100)
                )
            );
        require(amount > 0, "nothing to claim");

        currentMarketingPool = currentMarketingPool.sub(amount);

        uint256 amountToBurn = calculateFee(amount);

        if (amountToBurn > 0) {
            token.burn(amountToBurn);
        }

        token.transfer(marketingAddress, amount.sub(amountToBurn));
    }

    /**
     * @dev claim employee tokens from the contract balance.
     * Can be used only by an owner or from employeesAddress
     */
    function claimEmployeeTokens() public requireSetTGE() {
        require(
            msg.sender == employeesAddress || msg.sender == owner(),
            "Unauthorised sender"
        );

        // 1 year of vesting period
        require(now >= TGE + 12 * month, "Vesting period");

        // Get the total months passed after the vesting period of 1.5 years
        uint256 monthPassed = (now.sub(TGE)).div(month).sub(12).add(1);

        // Avoid overflow when releasing 10% each month
        // If more than 10 months passed without token claim then 100% tokens can be claimed at once.
        if (monthPassed > 10) {
            monthPassed = 10;
        }

        uint256 amount =
            currentEmployeesPool.sub(
                EMPLOYEES_POOL.sub(
                    EMPLOYEES_POOL.mul(monthPassed * 10).div(100)
                )
            );
        require(amount > 0, "nothing to claim");

        currentEmployeesPool = currentEmployeesPool.sub(amount);

        //18 month of vesting period, no need to check fee
        token.transfer(employeesAddress, amount);
    }

    /**
     * @dev getCurrentFee calculate current fee according to TGE and returns it.
     * NOTE: divide result by 10000 to calculate current percent.
     */
    function getCurrentFee() public returns (uint256) {
        if (now >= TGE + 9 * month) {
            return 0;
        }
        if (now >= TGE + 8 * month) {
            return 923;
        }
        if (now >= TGE + 7 * month) {
            return 1153;
        }
        if (now >= TGE + 6 * month) {
            return 1442;
        }
        if (now >= TGE + 5 * month) {
            return 1802;
        }
        if (now >= TGE + 4 * month) {
            return 2253;
        }
        if (now >= TGE + 3 * month) {
            return 2816;
        }
        if (now >= TGE + 2 * month) {
            return 3520;
        }
        if (now >= TGE + 1 * month) {
            return 4400;
        }

        return 5500;
    }

    function calculateFee(uint256 amount) public returns (uint256) {
        return amount.mul(getCurrentFee()).div(10000);
    }

    function isContract(address addr) private returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
