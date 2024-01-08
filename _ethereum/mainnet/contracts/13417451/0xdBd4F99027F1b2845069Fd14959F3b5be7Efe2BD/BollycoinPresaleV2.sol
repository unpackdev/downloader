// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Context.sol";
import "./IBollycoinPriceFeed.sol";
import "./ReentrancyGuard.sol";

/**
 * @title - Bollycoin Presale Contract V2
 * @author - Nodeberry Pvt Ltd
 */

contract BollycoinPresaleV2 is Context, ReentrancyGuard {
    /**
     * @dev `_usdt` represents the USDT smart contract address.
     * @dev `_usdc` represents the USDC smart contract address.
     * @dev `_busd` represents the BUSD smart contract address.
     * @dev `_bollycoin` represents Bollycoin token contract address.
     * @dev `_settlementWallet` represents the wallet address to which tokens are sent during purchase.
     * @dev `_admin` is the account that controls the sale.
     */
    address private _usdt;
    address private _usdc;
    address private _busd;
    address private _wbtc;
    address private _bollycoin;
    address private _admin;
    address private _oracle;
    address private _settlementWallet;
    
    uint256 public bollycoinPrice = 0.1 * 10**18; // 0.1 USD
    
    /**
     * @dev checks if `caller` is `_admin`
     * reverts if the `caller` is not the `_admin` account.
     */
    modifier onlyAdmin() {
        require(_admin == msgSender(), "Error: caller not admin");
        _;
    }

    /**
     * @dev - Purchase event is emitted whenever a successful purchase is made.
     */
    event Purchase(
        address indexed buyer,
        string uid,
        uint256 amount,
        uint256 valueInPurchaseCurrency,
        bytes32 currency
    );

    constructor(
        address _usdtAddress,
        address _usdcAddress,
        address _busdAddress,
        address _wbtcAddress,
        address _bollyAddress,
        address _oracleAddress,
        address _settlementAddress
        
    ) {
        _usdt = _usdtAddress;
        _usdc = _usdcAddress;
        _busd = _busdAddress;
        _bollycoin = _bollyAddress;
        _oracle = _oracleAddress;
         _wbtc = _wbtcAddress;
        _admin = _settlementAddress;
        _settlementWallet = _settlementAddress;
    }

    /**
     * @dev used to purchase bollycoin using USDT. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithUSDT(uint256 _amount, string memory uid)
        public
        nonReentrant
        virtual
        returns (bool)
    {
        uint256 balance = IERC20(_usdt).balanceOf(msgSender());
        uint256 allowance = IERC20(_usdt).allowance(msgSender(), address(this));

        uint256 usdValue = (bollycoinPrice) * _amount;

        uint256 totalCostInUSDT = usdValue / 10**12;
         
        
        require(balance >= totalCostInUSDT, "Error: insufficient USDT Balance");
        require(
            allowance >= totalCostInUSDT,
            "Error: allowance less than spending"
        );

        IERC20(_usdt).transferFrom(
            msgSender(),
            _settlementWallet,
            totalCostInUSDT
        );
        
        IERC20(_bollycoin).transfer(msgSender(), _amount * 10**18);
        
        emit Purchase(
            msgSender(),
            uid,
            _amount,
            usdValue,
            bytes32("USDT")
        );
        
        return true;
    }

    /**
     * @dev used to purchase bollycoin using USDC. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithUSDC(uint256 _amount, string memory uid)
        public
        nonReentrant
        virtual
        returns (bool)
    {
        uint256 balance = IERC20(_usdc).balanceOf(msgSender());
        uint256 allowance = IERC20(_usdc).allowance(msgSender(), address(this));

        uint256 usdValue = (bollycoinPrice) * _amount;

        uint256 totalCostInUSDC = usdValue / 10**12;
         
        require(balance >= totalCostInUSDC, "Error: insufficient USDC Balance");
        
        require(
            allowance >= totalCostInUSDC,
            "Error: allowance less than spending"
        );

        IERC20(_usdc).transferFrom(
            msgSender(),
            _settlementWallet,
            totalCostInUSDC
        );
        IERC20(_bollycoin).transfer(msgSender(), _amount * 10**18);
        
        emit Purchase(msgSender(), uid, _amount, usdValue, bytes32("USDC"));
        
        return true;
    }

    /**
     * @dev used to purchase bollycoin using BUSD. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithBUSD(uint256 _amount, string memory uid)
        public
        nonReentrant
        virtual
        returns (bool)
    {
        uint256 balance = IERC20(_busd).balanceOf(msgSender());
        uint256 allowance = IERC20(_busd).allowance(msgSender(), address(this));

        uint256 totalCostInBUSD = (bollycoinPrice) * _amount;
        require(balance >= totalCostInBUSD, "Error: insufficient BUSD Balance");
        require(
            allowance >= totalCostInBUSD,
            "Error: allowance less than spending"
        );

        IERC20(_busd).transferFrom(
            msgSender(),
            _settlementWallet,
            totalCostInBUSD
        );
        IERC20(_bollycoin).transfer(msgSender(), _amount * 10**18);
        emit Purchase(
            msgSender(),
            uid,
            _amount,
            totalCostInBUSD,
            bytes32("BUSD")
        );
        return true;
    }


    /**
     * @dev used to purchase bollycoin using wBTC. Tokens are sent to the buyer.
     * @param _amount - The number of bollycoin tokens to purchase
     */
    function purchaseWithWBTC(uint256 _amount, string memory uid)
        public
        nonReentrant
        virtual
        returns (bool)
    {
        uint256 balance = IERC20(_wbtc).balanceOf(msgSender());
        uint256 allowance = IERC20(_wbtc).allowance(msgSender(), address(this));
        
        uint256 wbtcCmp = IBollycoinPriceFeed(_oracle).getLatestBTCPrice();
       
        uint256 totalCostInWBTC = (bollycoinPrice) * _amount *10**18 / wbtcCmp / 10**10;
        
        require(balance >= totalCostInWBTC, "Error: insufficient WBTC Balance");
        require(
            allowance >= totalCostInWBTC,
            "Error: allowance less than spending"
        );

        IERC20(_wbtc).transferFrom(
            msgSender(),
            _settlementWallet,
            totalCostInWBTC
        );
        
        IERC20(_bollycoin).transfer(msgSender(), _amount * 10**18);
        
        emit Purchase(
            msgSender(),
            uid,
            _amount,
            totalCostInWBTC,
            bytes32("wBTC")
        );
        return true;
    }
 
   
    
    /**
     * @dev used to purchase bollycoin using ETH. ETH is sent to the buyer.
      */
    function purchaseWithETH(string memory uid)
        public
        payable
        nonReentrant
        virtual
        returns (bool)
    {
        uint256 ethCmp = IBollycoinPriceFeed(_oracle).getLatestETHPrice();
         uint256 bollyToTransfer = _msgValue() * ethCmp / bollycoinPrice;
        
        (bool sent, bytes memory data) = _settlementWallet.call{value: _msgValue()}("");
        require(sent, "Failed to send ETH"); 		
        IERC20(_bollycoin).transfer(msgSender(), bollyToTransfer);
        emit Purchase(
            msgSender(),
            uid,
            bollyToTransfer,
            _msgValue(),
            bytes32("ETH")
        );
        return true;
    }
    /**
     * @dev returns the USDT token address used for purchase.
     */
    function usdt() public view returns (address) {
        return _usdt;
    }

    /**
     * @dev returns the USDC token address used for purchase.
     */
    function usdc() public view returns (address) {
        return _usdc;
    }
    
    /**
     * @dev returns the Oracle address.
     */
    function oracle() public view returns (address) {
        return _oracle;
    }

    /**
     * @dev returns the busd smart contract used for purchase.
     */
    function busd() public view returns (address) {
        return _busd;
    }

    /**
     * @dev returns the bollycoin smart contract used for purchase.
     */
    function bolly() public view returns (address) {
        return _bollycoin;
    }

    /**
     * @dev returns the wBTC token address used for purchase.
     */
     
    function wBTC() public view returns (address) {
        return _wbtc;
    }

    /**
     * @dev returns the admin account used for purchase.
     */
    function admin() public view returns (address) {
        return _admin;
    }

    /**
     * @dev returns the settlement address used for purchase.
     */
    function settlementAddress() public view returns (address) {
        return _settlementWallet;
    }

    /**
     * @dev transfers ownership to a different account.
     *
     * Requirements:
     * `newAdmin` cannot be a zero address.
     * `caller` should be current admin.
     */
    function transferControl(address newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0), "Error: owner cannot be zero");
        _admin = newAdmin;
    }
    
    
     /**
     * @dev updates the oracle address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateOracle(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _oracle = newAddress;
    }

    /**
     * @dev updates the usdt sc address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateUsdt(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _usdt = newAddress;
    }

    /**
     * @dev updates the usdc sc address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateUsdc(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _usdc = newAddress;
    }

    /**
     * @dev updates the bollycoin token address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateBolly(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _bollycoin = newAddress;
    }
    
     /**
     * @dev updates the wBTC token address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateWBTC(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _wbtc = newAddress;
    }

    /**
     * @dev updates the busd sc address.
     *
     * Requirements:
     * `newAddress` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateBusd(address newAddress) public virtual onlyAdmin {
        require(newAddress != address(0), "Error: address cannot be zero");
        _busd = newAddress;
    }

    /**
     * @dev updates the bollycoin token price.
     *
     * Requirements:
     * `newPrice` cannot be zero.
     * `caller` should be current admin.
     */
    function updateBollycoinPrice(uint256 newPrice) public virtual onlyAdmin {
        require(newPrice > 0, "Error: price cannot be zero");
        bollycoinPrice = newPrice;
    }

    /**
     * @dev updates the settlement wallet address
     *
     * Requirements:
     * `settlementWallet` cannot be a zero address.
     * `caller` should be current admin.
     */
    function updateSettlementWallet(address newAddress)
        public
        virtual
        onlyAdmin
    {
        require(newAddress != address(0), "Error: not a valid address");
        _settlementWallet = newAddress;
    }

    /**
     * @dev withdraw bollycoin from SC to any EOA.
     *
     * `caller` should be admin account.
     * `to` cannot be zero address.
     */
    function withdrawBolly(address to, uint256 amount)
        public
        virtual
        onlyAdmin
        returns (bool)
    {
        require(to != address(0), "Error: cannot send to zero address");
        IERC20(_bollycoin).transfer(to, amount);
        return true;
    }
}
