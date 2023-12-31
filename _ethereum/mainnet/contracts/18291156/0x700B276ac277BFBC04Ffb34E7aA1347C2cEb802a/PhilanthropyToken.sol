// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Admin.sol";
import "./Security.sol";
import "./Utils.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract PhilanthropyToken is ERC20, Ownable {
    using Admin for *;
    using Security for *;
    using Utils for *;

    uint256 public constant MAX_TOTAL_SUPPLY = 500 * 10 ** 6 * 10 ** 18; // Maximum total supply of 500 million tokens
    uint256 public constant MARKET_CAP = 10 * 10 ** 6 * 10 ** 18; // Default market cap of 10 million tokens

    uint256 public INVESTOR_ALLOCATION = 4 * 10 ** 6 * 10 ** 18; // 4 million tokens for investors
    uint256 public constant GENERAL_PUBLIC_ALLOCATION = 5 * 10 ** 6 * 10 ** 18; // 5 million tokens for the general public
    uint256 public CHARITY_ALLOCATION = 4 * 10 ** 6 * 10 ** 18; // 4 million tokens for charities
    uint256 public constant PRESALE_ALLOCATION = 5 * 10 ** 6 * 10 ** 18; // 5 million tokens for the presale
    uint256 public PRESALE_TOTAL_SOLD = 0; // the presale

    uint256 public constant INVESTOR_LOCK_PERIOD = 730 days; // 2 years Lock-up period for investors
    uint256 public constant PRESALE_LOCK_PERIOD = 365 days; // 1 year Lock-up period for presale
    uint256 public TOTAL_INITIAL_RELEASED = 0;
    uint256 public TOTAL_INVESTOR_CLAIMED = 0;
    uint256 public constant PRESALE_PRICE = 50 * 10 ** 15; // $0.50 in wei
    uint256 public constant TRANSACTION_THRESHOLD = 1 * 10 ** 6 * 10 ** 18; // 1m Transaction threshold for requiring a secret code

    uint256 public constant MIN_BALANCE_TO_INCREASE_SUPPLY = 2 * 10 ** 18; // 2 is min balance

    uint256 public presaleStartTime;
    // Mapping to track buyer purchase timestamps
    mapping(address => uint256) public lastPurchaseTimestamp;
    string private secretCode;

    mapping(address => bool) private admins;

    /**
     * Only admin modifier
     */
    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner(), "Not an admin");
        _;
    }

    /**
     * constructor
     */
    constructor() ERC20("PhilanthropyToken", "PTPH") {
        // Mint the initial supply to the contract owner
        _mint(address(this), MARKET_CAP);
        presaleStartTime = block.timestamp;

        // Transfer ownership to the contract deployer!
        // transferOwnership(msg.sender);
    }

    // Function to add or remove admins
    function setAdmin(address _admin, bool _status) external onlyAdmin {
        admins[_admin] = _status;
    }

    /**
     * Function to increase the market cap
     * @param amount uint256
     */
    function mint(uint256 amount) external onlyAdmin {
        uint256 currentSupply = totalSupply();
        require(
            currentSupply + amount <= MAX_TOTAL_SUPPLY,
            "Exceeds maximum total supply"
        );
        _mint(address(this), amount);
    }

    /**
     * Function to allow users to buy presale tokens
     * @param amount uint256
     */
    function buyPresaleTokens(uint256 amount) external payable {
        require(amount > 0, "Invalid purchase amount");
        require(
            block.timestamp >= presaleStartTime,
            "Presale has not started yet"
        );
        require(
            block.timestamp <= presaleStartTime + 182.5 days,
            "Presale has ended"
        );

        uint256 totalPrice = amount * PRESALE_PRICE;
        require(msg.value >= totalPrice, "Insufficient funds sent");

        // Calculate and check remaining presale allocation
        uint256 remainingPresaleAllocation = PRESALE_TOTAL_SOLD;
        require(
            amount <= remainingPresaleAllocation,
            "Not enough tokens available for purchase"
        );

        // Transfer tokens to the buyer
        _transfer(address(this), msg.sender, amount);

        // Update the buyer's last purchase timestamp
        lastPurchaseTimestamp[msg.sender] = block.timestamp;

        // Refund any excess funds sent
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        PRESALE_TOTAL_SOLD += amount;
    }

    /**
     * Function to distribute CHARITY_ALLOCATION to multiple addresses
     * @param recipients string<addresses>
     * @param amounts uint256
     */
    function initialRelease(
        address[] memory recipients,
        uint256[] memory amounts
    ) external onlyAdmin {
        require(
            recipients.length == amounts.length,
            "Array lengths do not match"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            require(recipient != address(0), "Invalid recipient address");
            require(amount > 0, "Invalid amount");

            TOTAL_INITIAL_RELEASED += amount;
            require(
                TOTAL_INITIAL_RELEASED <= CHARITY_ALLOCATION,
                "Total distribution exceeds CHARITY_ALLOCATION"
            );

            // Transfer tokens to the recipient
            _transfer(address(this), recipient, amount);
        }
    }

    /**
     * Function to distribute INVESTOR_ALLOCATION to multiple investors
     * @param investors address
     * @param amounts uint256
     */
    function claimInvestorTokens(
        address[] memory investors,
        uint256[] memory amounts
    ) external onlyAdmin {
        require(
            investors.length == amounts.length,
            "Array lengths do not match"
        );

        require(
            block.timestamp >= presaleStartTime + INVESTOR_LOCK_PERIOD,
            "Lock-up period not over"
        );

        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            uint256 amount = amounts[i];

            require(investor != address(0), "Invalid investor address");
            require(amount > 0, "Invalid amount");

            TOTAL_INVESTOR_CLAIMED += amount;

            // Check if totalDistribution exceeds INVESTOR_ALLOCATION
            require(
                TOTAL_INVESTOR_CLAIMED <= INVESTOR_ALLOCATION,
                "Total distribution exceeds INVESTOR_ALLOCATION"
            );

            // Transfer tokens to the investor
            _transfer(address(this), investor, amount);
        }
    }

    // Function to set a secret code for transactions above the threshold
    function setSecretCode(string memory code) external onlyAdmin {
        secretCode = code;
    }

    /**
     * check secret code
     * @param code uint256
     */
    function checkSecretCode(string memory code) public view onlyOwner {
        require(
            keccak256(abi.encodePacked(code)) ==
                keccak256(abi.encodePacked(secretCode)),
            "Incorrect secret code"
        );
    }

    // Function to perform a transaction above the threshold with the correct secret code
    function transfer(
        address recipient,
        uint256 amount,
        string memory code
    ) external onlyAdmin {
        if (amount > TRANSACTION_THRESHOLD) {
            require(
                keccak256(abi.encodePacked(code)) ==
                    keccak256(abi.encodePacked(secretCode)),
                "Incorrect secret code"
            );
        }
        _transfer(address(this), recipient, amount);
    }

    function transferFrom(
        address recipient,
        uint256 amount,
        string memory code
    ) external {
        if (amount > TRANSACTION_THRESHOLD) {
            require(
                keccak256(abi.encodePacked(code)) ==
                    keccak256(abi.encodePacked(secretCode)),
                "Incorrect secret code"
            );
        }
        _transfer(msg.sender, recipient, amount);
    }

    /**
     * Function to automatically mint if the balance is below a certain threshold
     */
    function mintWhenNeedded() external onlyAdmin {
        uint256 currentBalance = balanceOf(address(this));
        if (currentBalance < MIN_BALANCE_TO_INCREASE_SUPPLY) {
            uint256 additionalSupply = MARKET_CAP;
            _mint(address(this), additionalSupply);
        }
    }

    // Custom burn function
    function burn(uint256 amount) public onlyAdmin {
        _burn(address(this), amount);
    }

    /**
     * Function to show available supply (minted balance) value
     * @return uint256
     */
    function getUnsudedSupplies() external view onlyAdmin returns (uint256) {
        return balanceOf(address(this));
    }

    /**
     * Function to show TOTAL_INITIAL_RELEASED value
     * @return uint256
     */
    function getTotalIInvestorAllocation()
        external
        view
        onlyAdmin
        returns (uint256)
    {
        return INVESTOR_ALLOCATION;
    }

    /**
     * Function to show TOTAL_INVESTOR_CLAIMED value
     * @return uint256
     */
    function getTotalInitialAllocation()
        external
        view
        onlyAdmin
        returns (uint256)
    {
        return CHARITY_ALLOCATION;
    }

    /**
     * Function to show TOTAL_INITIAL_RELEASED value
     * @return uint256
     */
    function getTotalInitialReleased()
        external
        view
        onlyAdmin
        returns (uint256)
    {
        return TOTAL_INITIAL_RELEASED;
    }

    /**
     * Function to show TOTAL_INVESTOR_CLAIMED value
     * @return uint256
     */
    function getTotalInvestorClaimed()
        external
        view
        onlyAdmin
        returns (uint256)
    {
        return TOTAL_INVESTOR_CLAIMED;
    }

    /**
     * Function to transfer tokens between TOTAL_INITIAL_RELEASED and TOTAL_INVESTOR_CLAIMED
     * @param amount uint256
     * @param fromInitialToInvestor boolean
     */
    function transferBetweenCategories(
        uint256 amount,
        bool fromInitialToInvestor
    ) external onlyAdmin {
        require(
            fromInitialToInvestor || TOTAL_INITIAL_RELEASED >= amount,
            "Insufficient tokens in INITIAL_RELEASED"
        );
        require(
            !fromInitialToInvestor || TOTAL_INVESTOR_CLAIMED >= amount,
            "Insufficient tokens in INVESTOR_CLAIMED"
        );

        if (fromInitialToInvestor) {
            CHARITY_ALLOCATION -= amount;
            INVESTOR_ALLOCATION += amount;
        } else {
            INVESTOR_ALLOCATION -= amount;
            CHARITY_ALLOCATION += amount;
        }

        _transfer(address(this), msg.sender, amount);
    }

    /**
     * Function to transfer tokens between TOTAL_INITIAL_RELEASED and TOTAL_INVESTOR_CLAIMED
     * @param amount uint256
     * @param fromInitialToInvestor boolean
     */
    function topupCategories(
        uint256 amount,
        bool fromInitialToInvestor
    ) external onlyAdmin {
        require(
            fromInitialToInvestor || CHARITY_ALLOCATION >= amount,
            "Insufficient tokens in INITIAL_RELEASED"
        );
        require(
            !fromInitialToInvestor || TOTAL_INVESTOR_CLAIMED >= amount,
            "Insufficient tokens in INVESTOR_CLAIMED"
        );

        if (fromInitialToInvestor) {
            CHARITY_ALLOCATION -= amount;
            INVESTOR_ALLOCATION += amount;
        } else {
            INVESTOR_ALLOCATION -= amount;
            CHARITY_ALLOCATION += amount;
        }

        // _transfer(address(this), msg.sender, amount);
    }

    // Function to perform a transaction above the threshold with an optional secret code
    function transferWithSecretCode(
        address recipient,
        uint256 amount,
        string memory code
    ) external {
        require(amount <= TRANSACTION_THRESHOLD, "Amount exceeds threshold");
        require(
            code.checkSecretCode(secretCode) || bytes(code).length == 0,
            "Incorrect secret code"
        );
        _transfer(msg.sender, recipient, amount);
    }

    /**
     * Function to top up CHARITY_ALLOCATION from the contract's available balance
     * @param amount uint256
     */
    function topUpCharityAllocation(uint256 amount) external onlyAdmin {
        uint256 availableBalance = balanceOf(address(this));
        require(amount <= availableBalance, "Exceeds available balance");
        CHARITY_ALLOCATION += amount;
        _transfer(address(this), address(this), amount);
    }

    /**
     * Function to top up INVESTOR_ALLOCATION from the contract's available balance
     * @param amount uint256
     */
    function topUpInvestorAllocation(uint256 amount) external onlyAdmin {
        uint256 availableBalance = balanceOf(address(this));
        require(amount <= availableBalance, "Exceeds available balance");
        INVESTOR_ALLOCATION += amount;
        _transfer(address(this), address(this), amount);
    }
}
