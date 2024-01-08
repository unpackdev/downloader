// SPDX-License-Identifier: NO-LICENSE

pragma solidity ^0.8.4;

import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./IGenesisSale.sol";
import "./IERC20.sol";
import "./IWhitelist.sol";
import "./AggregatorV3Interface.sol";

/**
 * Implementation of the {IGenesisSale} Interface.
 *
 * Used for the sale of EDGEX tokens at a constant price
 * with a lock tenure of 365 days.
 *
 * 2 Level Governance Model with admin and governor previlages.
 *
 * Token Price is stored as 8 precision variables.
 */

contract GenesisSale is ReentrancyGuard, Context, IGenesisSale {
    mapping(address => uint256) public allocated;
    mapping(address => uint256) public purchases;
    mapping(address => mapping(uint256 => Purchase)) public purchase;
    mapping(uint8 => uint256) public poolCap;
    mapping(uint8 => uint256) public poolSold;
    mapping(uint8 => uint256) public poolLock;
    mapping(address => uint256) public balanceOf;

    address public organisation;
    address payable public ethWallet;
    address public governor;
    address public admin;

    address public edgexContract;
    address public ethPriceSource;
    address public whitelistOracle;

    uint256 public presalePrice;

    uint256 public maxCap;
    uint256 public minCap;

    /**
     * @dev stores the sale history as individual structs.
     *
     * Mapped to an account with individual identifier.
     */
    struct Purchase {
        uint256 time;
        uint256 amount;
        uint256 price;
        uint256 lock;
        uint8 method;
        bool isSettled;
    }

    /**
     * @dev Emitted when there is a purchase of EDGEX tokens.
     *
     * Can be used for storing off-chain history events.
     */
    event PurchaseEvent(address indexed to, uint256 amount);

    /**
     * @dev Emitted when the governor role state changes.
     *
     * Based on the event we can predict the role of governor.
     */
    event UpdateGovernor(address indexed _governor);

    /**
     * @dev Emittee when the ownership of the contract changes.
     */
    event RevokeOwnership(address indexed _newOwner);

    /**
     * @dev Emitted when the pool parameters changes.
     */
    event PoolCapChange(uint256 newCap, uint8 poolId);

    /**
     * @dev Emitted when the pool lock duration changes.
     */
    event PoolLockChange(uint256 lockTime, uint8 poolId);

    /**
     * @dev sets the initial params.
     *
     * {_ethWallet} - Address to which the funds are directed to.
     * {_organisation} - Address to which % of sale tokens are sent to.
     * {_governor} - Address to be configured in the server for off-chain settlement.
     * {_admin} - Owner of this contract.
     * {_ethSource} - Chainlink ETH/USD price source.
     * {_whitelistOracle} - Oracle to fetch whitelisting info from.
     * {_edgexContract} - Address of the EDGEX token.
     * {_presalePrice} - Price of Each EDGEX token (8 precision).
     */
    constructor(
        address _ethWallet,
        address _organisation,
        address _governor,
        address _admin,
        address _ethSource,
        address _whitelistOracle,
        address _edgexContract,
        uint256 _presalePrice
    ) {
        organisation = _organisation;
        ethWallet = payable(_ethWallet);
        governor = _governor;
        whitelistOracle = _whitelistOracle;
        admin = _admin;
        edgexContract = _edgexContract;
        ethPriceSource = _ethSource;
        presalePrice = _presalePrice;
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
        require(_msgSender() == governor, "Error: caller not Governor");
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
        require(_user != address(0), "Error: zero address cannot buy");
        return IWhiteList(whitelistOracle).whitelisted(_user);
    }

    /**
     * @dev sends in `eth` in the transaction as `value`
     *
     * The function calculates the price of the ETH send
     * in value to equivalent amount in USD using chainlink
     * oracle and transfer the equivalent amount of tokens back to the user.
     *
     * Requirements:
     * `_reciever` address has to be whitelisted.
     */
    function buyEdgex(address _reciever, uint8 poolId)
        public
        payable
        virtual
        override
        nonReentrant
        returns (bool)
    {
        uint256 tokens = calculate(msg.value);

        require(tokens >= minCap, "Error: amount less than minimum");
        require(tokens <= maxCap, "Error: amount greater than maximum");

        require(poolCap[poolId] >= poolSold[poolId] + tokens, "Error: pool cap reached");
        require(    
            isWhitelisted(_reciever),
            "Error: account not elligible to puchase"
        );

        purchases[_reciever] += 1;
        balanceOf[_reciever] += tokens;

        Purchase storage p = purchase[_reciever][purchases[_reciever]];
        p.time = block.timestamp;
        p.lock = poolLock[poolId];
        p.method = 1;
        p.price = presalePrice;
        p.amount = tokens;

        poolSold[poolId] += tokens;

        ethWallet.transfer(msg.value);
    
        emit PurchaseEvent(_reciever, tokens);
        return true;
    }

    /**
     * @dev returns the amount of EDGEX tokens
     * for the input eth value.
     *
     * EDGEX tokens are returned in 18-decimal precision.
     */

    function calculate(uint256 _amount) private view returns (uint256) {
        require(_amount > 0, "Error: amount should not be zero");
        uint256 value = uint256(fetchEthPrice());
        value = _amount * value;
        uint256 tokens = value / presalePrice;
        return tokens;
    }

    function allocate(
        uint256 _tokens,
        address _user,
        uint8 _method,
        uint8 _poolId
    ) public virtual override onlyGovernor nonReentrant returns (bool) {
        require(_tokens >= minCap, "Error: amount less than minimum");
        require(_tokens <= maxCap, "Error: amount greater than maximum");

        require(
            isWhitelisted(_user),
            "Error: account not elligible to puchase"
        );

        require(
            poolCap[_poolId] >= poolSold[_poolId] + _tokens, 
            "Error: pool cap reached"
        );

        purchases[_user] += 1;
        balanceOf[_user] += _tokens;

        Purchase storage p = purchase[_user][purchases[_user]];
        p.time = block.timestamp;
        p.lock = poolLock[_poolId];
        p.method = _method;
        p.price = presalePrice;
        p.amount = _tokens;

        poolSold[_poolId] += _tokens;

        emit PurchaseEvent(_user, _tokens);
        return true;
    }

    /**
     * @dev transfers the edgex tokens to the user's wallet after the
     * 365-day lock time.
     *
     * Requirements:
     * `caller` shoul have a valid token balance > 0;
     */
    function claim(uint256 _purchaseId)
        public
        virtual
        override
        nonReentrant
        returns (bool)
    {
        Purchase storage p = purchase[_msgSender()][_purchaseId];
        uint256 lockedTill = p.lock;
        uint256 orgAmount = p.amount / 100;
        balanceOf[_msgSender()] -= p.amount;

        require(!p.isSettled, "Error: amount already claimed");
        require(block.timestamp >= lockedTill, "Error: lock time till not yet reached");

        p.isSettled = true;
        bool status = IERC20(edgexContract).transfer(_msgSender(), p.amount);
        bool status2 = IERC20(edgexContract).transfer(organisation, orgAmount);

        return (status && status2);
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
     * @dev fetches the price of Ethereum from chainlink oracle
     *
     * Real-time onchain price is fetched.
     */

    function fetchEthPrice() public view virtual returns (int256) {
        (, int256 price, , , ) =
            AggregatorV3Interface(ethPriceSource).latestRoundData();
        return price;
    }

    /**
     * @dev can change the minimum and maximum purchase value of edgex tokens
     * per transaction.
     *
     * Requirements:
     * `_maxCap` can never be zero.
     *
     * `caller` should have governor role.
     */
    function updateCap(uint256 _minCap, uint256 _maxCap)
        public
        virtual
        override
        onlyGovernor
        returns (bool)
    {
        // solhint-ig
        require(_maxCap > 0, "Error: maximum amount cannot be zero");
        maxCap = _maxCap;
        minCap = _minCap;
        return false;
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
        override
        onlyGovernor
        isZero(_newGovernor)
        returns (bool)
    {
        governor = _newGovernor;

        emit UpdateGovernor(_newGovernor);
        return true;
    }

    /**
     * @dev can change the contract address of EDGEX tokens.
     *
     * Requirements:
     * `_contract` cannot be a zero address.
     */
    function updateContract(address _contract)
        public
        virtual
        override
        onlyAdmin
        isZero(_contract)
        returns (bool)
    {
        edgexContract = _contract;
        return true;
    }

    /**
     * @dev can change the Chainlink ETH Source.
     *
     * Requirements:
     * `_ethSource` cannot be a zero address.
     */
    function updateEthSource(address _ethSource)
        public
        virtual
        override
        onlyAdmin
        isZero(_ethSource)
        returns (bool)
    {
        ethPriceSource = _ethSource;
        return true;
    }

    /**
     * @dev can change the address to which all paybale ethers are sent to.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_newEthSource` cannot be a zero address.
     */
    function updateEthWallet(address _newEthWallet)
        public
        virtual
        override
        onlyAdmin
        isZero(_newEthWallet)
        returns (bool)
    {
        ethWallet = payable(_newEthWallet);
        return true;
    }

    /**
     * @dev can change the address to which a part of sold tokens are paid to.
     *
     * Requirements:
     * `_caller` should be admin.
     * `_newOrgWallet` cannot be a zero address.
     */
    function updateOrgWallet(address _newOrgWallet)
        public
        virtual
        override
        onlyAdmin
        isZero(_newOrgWallet)
        returns (bool)
    {
        organisation = _newOrgWallet;
        return true;
    }

    /**
     * @dev can update the locktime for each poolId in number of days.
     *
     * Requirements:
     * `caller` should be admin.
     * `poolId` should be a valid one
     */
    function updatePoolLock(uint8 poolId, uint256 lockDays)
       public
       virtual
       override
       onlyAdmin
       returns (bool)
    {
       require(lockDays > 0, "Error: lock days cannot be zero");
       poolLock[poolId] = lockDays * 1 days;

       emit PoolLockChange(lockDays, poolId);
       return true;
    }

    /**
     * @dev can update the cap for each poolId in number of edgex tokens.
     *
     * Requirements:
     * `caller` should be admin.
     * `poolId` should be a valid one
     */
    function updatePoolCap(uint8 poolId, uint256 _poolCap)
        public 
        virtual 
        override
        onlyAdmin
        returns (bool) 
    {
        require(_poolCap > 0, "Error: cap cannot be zero");
        poolCap[poolId] = _poolCap;

        emit PoolCapChange(_poolCap, poolId);
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
        override
        onlyAdmin
        isZero(_to)
        returns (bool)
    {
        return IERC20(edgexContract).transfer(_to, _amount);
    }
}
