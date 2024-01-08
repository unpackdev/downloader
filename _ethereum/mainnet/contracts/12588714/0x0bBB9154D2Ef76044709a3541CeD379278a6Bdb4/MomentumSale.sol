// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./IMomentumSale.sol";
import "./IERC20.sol";
import "./IWhitelist.sol";
import "./AggregatorV3Interface.sol";

/**
 * Implementation of the {IGenesisSale} Interface.
 *
 * Used for the daily sale of EDGEX tokens.
 *
 * Token Price is stored as 8 precision variables.
 */

contract MomentumSale is ReentrancyGuard, Context, IMomentumSale {
    mapping(address => uint256) public totalPurchases;
    mapping(address => mapping(uint256 => Sale)) public sale;
    mapping(uint256 => SaleInfo) public info;
    mapping(uint256 => address) public oracle;

    address public admin;
    address public ethWallet;
    address public organisation;
    address public governor;
    address public whitelistOracle;

    uint256 public totalSaleContracts;
    uint256 public pricePerToken;
    address public ethPriceSource;
    address public edgexTokenContract;
    uint256 public lastCreated;
    uint256 public totalOracles = 15;

    /**
     * @dev stores the instance of every purchase.
     *
     * whenever an user purchases new EDGEX tokens we create a
     * new sale instance and stores it.
     */
    struct Sale {
        uint256 usdPurchase;
        uint256 pricePurchase;
        uint256 amountPurchased;
        uint256 timestamp;
        bool isAllocated;
        uint256 bonus;
        uint256 saleId;
    }

    /**
     * @dev stores the history of every sale instances.
     *
     * Every 24 hours, a new sale is created with a fixed amount
     * of tokens.
     */
    struct SaleInfo {
        uint256 start;
        uint256 end;
        uint256 allocated;
        uint256 totalPurchased;
        uint8 priceSource;
    }

    /**
     * @dev Emittee when the ownership of the contract changes.
     */
    event RevokeOwnership(address indexed _owner);

    /**
     * @dev Emitted when the governor role state changes.
     *
     * Based on the event we can predict the role of governor.
     */
    event UpdateGovernor(address indexed _governor);

    /**
     * @dev sets the initial params.
     *
     * {_ethWallet} - Address to which the funds are directed to.
     * {_organisation} - Address to which % of sale tokens are sent to.
     * {_governor} - Address to be configured in the server for off-chain settlement.
     * {_admin} - Owner of this contract.
     * {_ethPriceSource} - Chainlink ETH/USD price source.
     * {_whitelistOracle} - Oracle to fetch whitelisting info from.
     * {_edgexContract} - Address of the EDGEX token.
     * {_pricePerToken} - Price of Each EDGEX token (8 precision).
     */
    constructor(
        address _admin,
        address _organisation,
        address _ethWallet,
        address _governor,
        uint256 _pricePerToken,
        address _ethPriceSource,
        address _whitelistOracle,
        address _edgexTokenContract
    ) {
        admin = _admin;
        organisation = _organisation;
        ethWallet = _ethWallet;
        governor = _governor;
        pricePerToken = _pricePerToken;
        whitelistOracle = _whitelistOracle;
        ethPriceSource = _ethPriceSource;
        edgexTokenContract = _edgexTokenContract;
    }

    /**
     * @dev sanity checks the caller.
     * If the caller is not admin, the transaction is reverted.
     *
     * keeps the security of the platform and prevents bad actors
     * from executing sensitive functions / state changes.
     */
    modifier onlyAdmin() {
        require(_msgSender() == admin, "Error: caller not admin");
        _;
    }

    /**
     * @dev sanity checks the caller.
     * If the caller is not governor, the transaction is reverted.
     *
     * keeps the security of the platform and prevents bad actors
     * from executing sensitive functions / state changes.
     */
    modifier onlyGovernor() {
        require(_msgSender() == governor, "Error: caller not governor");
        _;
    }

    /**
     * @dev checks whether the address is a valid one.
     *
     * If it's a zero address returns an error.
     */
    modifier isZero(address _address) {
        require(_address != address(0), "Error: zero address");
        _;
    }

    /**
     * @dev checks whether the `_user` is whitelisted and verified his KYC.
     *
     * Requirements:
     * `_user` cannot be a zero address,
     *
     * Proxies calls to the whitelist contract address.
     */
    function isWhitelisted(address _user) public view virtual returns (bool) {
        bool status = IWhiteList(whitelistOracle).whitelisted(_user);
        return status;
    }

    /**
     * @dev allocates the `_allocated` amount of tokens for the current 24 hour sale.
     *
     * `_source` should be the specified as the external oracle source or the
     * internal fallback price.
     *
     * Requirements:
     * `caller` should be governor.
     */
    function createSaleContract(uint256 _allocated, uint8 _source)
        public
        virtual
        override
        onlyGovernor
        returns (bool)
    {
        uint256 cooldownPeriod = lastCreated + 24 hours;
        SaleInfo storage a = info[totalSaleContracts];
        require(
            block.timestamp >= cooldownPeriod
            || 
            a.allocated <= a.totalPurchased,
            "Error: sale cannot be created."
        );

        SaleInfo storage i = info[totalSaleContracts + 1];
        i.start = block.timestamp;
        i.end = block.timestamp + 24 hours;
        i.allocated = _allocated * 10**18;
        i.priceSource = _source;

        lastCreated = block.timestamp;
        totalSaleContracts += 1;
        return true;
    }

    /**
     * @dev increases the number of tokens allocated for each saleId.
     *
     * Requirements:
     * `_saleId` should have an active ongoing sale.
     * Allocated cannot be increased for ended sales.
     *
     * Requirements:
     * `caller` should be governor.
     */
    function increaseAllocation(uint256 _amount, uint256 _saleId)
        public
        virtual
        override
        onlyGovernor
        returns (bool)
    {
        SaleInfo storage i = info[_saleId];
        require(block.timestamp < i.end, "Error: sale already ended");

        uint256 amount = _amount * 10**18;
        i.allocated = i.allocated + amount;

        return true;
    }

    /**
     * @dev purchases edgex tokens by calling this function with ethers.
     *
     * Requirements:
     * `caller` should've to be whitelisted.
     * there should be an active sale ongoing.
     * allocated tokens should be available.
     */
    function purchaseWithEth()
        public
        payable
        virtual
        override
        nonReentrant
        returns (bool)
    {
        SaleInfo storage i = info[totalSaleContracts];

        require(i.totalPurchased <= i.allocated, "Error: sold out");
        require(block.timestamp < i.end, "Error: sale Ended");
        require(isWhitelisted(_msgSender()), "Error: address not verified");

        (uint256 _amountToken, uint256 _pricePurchase, uint256 _usdPurchase) =
            resolverEther(msg.value);

        Sale storage s = sale[_msgSender()][totalPurchases[_msgSender()] + 1];
        s.usdPurchase = _usdPurchase;
        s.amountPurchased = _amountToken;
        s.pricePurchase = _pricePurchase;
        s.timestamp = block.timestamp;
        s.saleId = totalSaleContracts;

        i.totalPurchased += _amountToken;
        totalPurchases[_msgSender()] += 1;

        payable(ethWallet).transfer(msg.value);
        return true;
    }

    /**
     * @dev allocated EDGEX tokens to users on behalf of them.
     * used for off-chain purchases.
     *
     * Requirements:
     * `_user` should be whitelisted for sale.
     * current sale should be live and not sold out.
     * `caller` should be governor.
     */
    function adminPurchase(
        address _user,
        uint256 _amountToken,
        uint256 _usdPurchase,
        uint256 _pricePurchase
    ) public virtual override onlyGovernor returns (bool) {
        SaleInfo storage i = info[totalSaleContracts];
        require(i.totalPurchased <= i.allocated, "Error: sold out");
        require(block.timestamp < i.end, "Error: purchase ended");

        Sale storage s = sale[_user][totalPurchases[_msgSender()] + 1];
        s.usdPurchase = _usdPurchase;
        s.amountPurchased = _amountToken;
        s.pricePurchase = _pricePurchase;
        s.timestamp = block.timestamp;
        s.saleId = totalSaleContracts;

        i.totalPurchased += _amountToken;
        totalPurchases[_user] += 1;

        return true;
    }

    /**
     * @dev returns the amount of EDGEX tokens for `_amountEther`
     * in the current sale scenario.
     *
     * Used for off-chain calculation of tokens for eq.ether value.
     */
    function resolverEther(uint256 _amountEther)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 ethPrice = uint256(fetchEthPrice());
        ethPrice = _amountEther * ethPrice;
        uint256 price = fetchTokenPrice();
        uint256 _tokenAmount = ethPrice / price;
        return (_tokenAmount, price, ethPrice);
    }

    /**
     * @dev returns the EDGEX token price.
     *
     * Based on the current business logic, EDGEX price can be an internal source
     * or from an external oracle.
     */
    function fetchTokenPrice() public view virtual override returns (uint256) {
        SaleInfo storage i = info[totalSaleContracts];
        if (i.priceSource == 0) {
            return pricePerToken;
        } else {
            return uint256(fetchEdgexPrice());
        }
    }

    /**
     * @dev fetches the price of Ethereum from chainlink oracle
     *
     * Real-time onchain price is fetched.
     */
    function fetchEthPrice() public view returns (int256) {
        (, int256 price, , , ) =
            AggregatorV3Interface(ethPriceSource).latestRoundData();
        return price;
    }

    /**
     * @dev fetches the price of EDGEX token from chainlink oracle
     *
     * Real-time onchain price is fetched.
     */
    function fetchEdgexPrice() public view returns (uint256) {
        uint256 totalPrice;
        uint256 validOracles;
        for (uint256 i = 0; i < totalOracles; i++) {
            if (oracle[i] != address(0)) {
                (, int256 price, , , ) =
                    AggregatorV3Interface(oracle[i]).latestRoundData();
                totalPrice += uint256(price);
                validOracles += 1;
            }
        }
        return totalPrice / validOracles;
    }

    function claim(uint256 _saleId)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        Sale storage s = sale[_msgSender()][_saleId];
        SaleInfo storage i = info[s.saleId];

        require(!s.isAllocated, "Error: account settlement completed");
        require(block.timestamp > i.end, "Error: sale not ended");

        uint256 _bonusTokens = resolveBonus(_saleId, _msgSender());
        s.bonus = _bonusTokens;
        s.isAllocated = true;

        uint256 totalTokens = s.amountPurchased + _bonusTokens;
        uint256 orgTokens = s.amountPurchased / 100;

        bool status = IERC20(edgexTokenContract).transfer(_msgSender(), totalTokens);
        bool status2 = IERC20(edgexTokenContract).transfer(organisation, orgTokens);

        return (status && status2);
    }

    /**
     * @dev calculates the bonus tokens for each purchase by an user.
     */
    function resolveBonus(uint256 _saleId, address _user)
        public
        view
        virtual
        override
        returns (uint256)
    {
        Sale storage s = sale[_user][_saleId];
        uint256 _bonusPercent = resolveBonusPercent(s.saleId);
        uint256 _bonusTokens = s.amountPurchased * _bonusPercent;
        _bonusTokens = _bonusTokens / 10 ** 6;
        return _bonusTokens;
    }

    /**
     * @dev maps the amount of sold tokens to the bonus percent.
     */
    function resolveBonusPercent(uint256 _saleId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        SaleInfo storage i = info[_saleId];
        uint256 sold = i.totalPurchased * 10**6;
        uint256 _salePercent = sold / i.allocated;

        if (_salePercent < 25 * 10 ** 4) {
            return 0;
        } else if (_salePercent >= 25 * 10 ** 4 && _salePercent < 50 * 10 ** 4) {
            return 10000;
        } else if (_salePercent >= 50 * 10 ** 4 && _salePercent < 75 * 10 ** 4) {
            return 20000;
        } else if (_salePercent >= 75 * 10 ** 4 && _salePercent < 100 * 10 ** 4) {
            return 30000;
        } else {
            return 50000;
        }
    }

    /**
     * @dev can change the Chainlink EDGEX Source.
     *
     * Requirements:
     * `_newSource` cannot be a zero address.
     * `_index` should be less than 15
     */
    function updateNewEdgexSource(address _newSource, uint8 index)
        public
        virtual
        override
        onlyAdmin
        isZero(_newSource)
        returns (bool)
    {
        oracle[index] = _newSource;
        return true;
    }

    /**
     * @dev transfer the control of genesis sale to another account.
     *
     * Onwers can add governors.
     *
     * Requirements:
     * `_newOwner` cannot be a zero address.
     *
     * CAUTION: EXECUTE THIS FUNCTION WITH CARE.
     */
    function revokeOwnership(address _newOwner)
        public
        virtual
        override
        onlyAdmin
        isZero(_newOwner)
        returns (bool)
    {
        admin = payable(_newOwner);
        emit RevokeOwnership(_newOwner);
        return true;
    }

    /**
     * @dev can change the Chainlink ETH Source.
     *
     * Requirements:
     * `_ethSource` cannot be a zero address.
     */
    function updateEthSource(address _newSource)
        public
        virtual
        override
        onlyAdmin
        isZero(_newSource)
        returns (bool)
    {
        ethPriceSource = _newSource;
        return true;
    }

    /**
     * @dev can change the contract address of EDGEX tokens.
     *
     * Requirements:
     * `_contract` cannot be a zero address.
     */

    function updateEdgexTokenContract(address _newSource)
        public
        virtual
        override
        onlyAdmin
        isZero(_newSource)
        returns (bool)
    {
        edgexTokenContract = _newSource;
        return true;
    }

    /**
     * @dev can allows admin to take out the unsold tokens from the smart contract.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_to` cannot be a zero address.
     * `_amount` should be less than the current EDGEX token balance.
     *
     * Prevents the tokens from getting locked within the smart contract.
     */
    function drain(address _to, uint256 _amount)
        public
        virtual
        onlyAdmin
        isZero(_to)
        returns (bool)
    {
        return IERC20(edgexTokenContract).transfer(_to, _amount);
    }

    /**
     * @dev add an account with governor level previlages.
     *
     * Requirements:
     * `caller` should have admin role.
     * `_newGovernor` should not be a zero wallet.
     */
    function updateGovernor(address _newGovernor)
        public
        virtual
        onlyGovernor
        isZero(_newGovernor)
        returns (bool)
    {
        governor = _newGovernor;
        emit UpdateGovernor(_newGovernor);
        return true;
    }
}
