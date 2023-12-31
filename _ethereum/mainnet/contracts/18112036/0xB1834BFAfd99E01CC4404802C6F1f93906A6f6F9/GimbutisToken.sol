// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC20BurnableUpgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapRouterV2.sol";
import "./IUniswapV2Pair.sol";
import "./IAggregatorV3.sol";

interface IBadERC20 {
    function transferFrom(address _from, address _to, uint _value) external;
    function transfer(address _to, uint _value) external;
}

contract GimbutisToken is OwnableUpgradeable, ERC20BurnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public adminAddress;
    address public aswmAddress;
    address public routerAddress;
    address public factoryAddress;
    address public usdcAddress;
    address public oracleAddress;

    uint256 public transferFee;
    uint256 public deliveryFee;
    uint256 public rollOverFee;
    uint256 public rollOverEpochDuration;
    // how many tokens = 1 silver
    uint256 public silverRatio;
    uint256 public minReserveAmount;
    uint256 public minBuyAmount;

    string public streemURL;

    bool public toggleStatus;

    mapping(address => uint256) public reserves;

    address public usdtAddress; // added 2023-06-19

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event SetAdminAddress(address indexed _address);
    event SetAswmAddress(address indexed _address);
    event SetrouterAddress(address indexed _address);
    event SetfactoryAddress(address indexed _address);
    event SetUsdcAddress(address indexed _address);
    event SetOracleAddress(address indexed _address);
    event SetTransferFee(uint256 indexed _fee);
    event SetDeliveryFee(uint256 indexed _fee);
    event SetRollOverFee(uint256 indexed _fee);
    event SetRollOverEpochDuration(uint256 indexed _duration);
    event SetSilverRatio(uint256 indexed _silverRatio);
    event SetMinReserveAmount(uint256 indexed _minReserveAmount);
    event SetMinBuyAmount(uint256 indexed _minBuyAmount);
    event SetStreemURL(string indexed _url);
    event SetToggleStatus(bool indexed _status);
    event SetUsdtAddress(address indexed _address); // added 2023-06-19

    function initialize(
        address _aswmAddress,
        address _routerAddress,
        address _factoryAddress,
        address _usdcAddress,
        address _oracleAddress,
        uint256 _transferFee,
        uint256 _deliveryFee,
        uint256 _rollOverFee,
        uint256 _rollOverEpochDuration,
        uint256 _silverRatio,
        uint256 _minReserveAmount,
        uint256 _minBuyAmount,
        string calldata _streemURL,
        bool _toggleStatus
    ) external initializer {
        adminAddress = msg.sender;
        routerAddress = _routerAddress;
        factoryAddress = _factoryAddress;
        usdcAddress = _usdcAddress;
        aswmAddress = _aswmAddress;
        oracleAddress = _oracleAddress;

        transferFee = _transferFee;
        deliveryFee = _deliveryFee;
        rollOverFee = _rollOverFee;
        rollOverEpochDuration = _rollOverEpochDuration;
        silverRatio = _silverRatio;
        minReserveAmount = _minReserveAmount;
        minBuyAmount = _minBuyAmount;

        streemURL = _streemURL;

        toggleStatus = _toggleStatus;

        __Ownable_init();
        __ERC20_init("GimbutisToken", "GXAG");
        emit Initialized(msg.sender, block.number);
    }

    modifier onlyActive() {
        require(toggleStatus, "GXAG: contract is not available right now ");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress || msg.sender == owner(), "GXAG: only admin");
        _;
    }

    modifier onlyASWM() {
        require(msg.sender == aswmAddress, "GXAG: only aswm");
        _;
    }

    function setAdminAddress(address _address) external onlyAdmin {
        adminAddress = _address;

        emit SetAdminAddress(_address);
    }

    function setAswmAddress(address _address) external onlyAdmin {
        aswmAddress = _address;

        emit SetAswmAddress(_address);
    }

    function setRouterAddress(address _address) external onlyAdmin {
        routerAddress = _address;

        emit SetrouterAddress(_address);
    }

    function setFactoryAddress(address _address) external onlyAdmin {
        factoryAddress = _address;

        emit SetfactoryAddress(_address);
    }

    function setUsdcAddress(address _address) external onlyAdmin {
        usdcAddress = _address;

        emit SetUsdcAddress(_address);
    }

    function setUsdtAddress(address _address) external onlyAdmin {
        usdtAddress = _address;

        emit SetUsdtAddress(_address);
    }

    function setOracleAddress(address _address) external onlyAdmin {
        oracleAddress = _address;

        emit SetOracleAddress(_address);
    }

    function setTransferFee(uint256 _fee) external onlyAdmin {
        transferFee = _fee;

        emit SetTransferFee(_fee);
    }

    function setDeliveryFee(uint256 _fee) external onlyAdmin {
        deliveryFee = _fee;

        emit SetDeliveryFee(_fee);
    }

    function setRollOverFee(uint256 _fee) external onlyAdmin {
        rollOverFee = _fee;

        emit SetRollOverFee(_fee);
    }

    function setRollOverEpochDuration(uint256 _duration) external onlyAdmin {
        rollOverEpochDuration = _duration;

        emit SetRollOverEpochDuration(_duration);
    }

    function setStreemURL(string calldata _streemURL) external onlyAdmin {
        streemURL = _streemURL;

        emit SetStreemURL(_streemURL);
    }

    function setToggleStatus(bool _status) external onlyAdmin {
        toggleStatus = _status;

        emit SetToggleStatus(_status);
    }

    function setSilverRatio(uint256 _silverRatio) external onlyAdmin {
        silverRatio = _silverRatio;
		require( _silverRatio >= 100, "GXAG: SiverRatio less than 100" );
        emit SetSilverRatio(_silverRatio);
    }

    function setMinReserveAmount(uint256 _minReserveAmount) external onlyAdmin {
        minReserveAmount = _minReserveAmount;

        emit SetMinReserveAmount(_minReserveAmount);
    }

    function setMinBuyAmount(uint256 _minBuyAmount) external onlyAdmin {
        minBuyAmount = _minBuyAmount;

        emit SetMinBuyAmount(_minBuyAmount);
    }

    /**
     * @notice Functon to add commodities
     * @param _amount amount of commodities
     */
    function addCommodities(uint256 _amount) external onlyAdmin {
        _mint(address(this), _amount * 1e18);
    }

    /**
     * @notice Functon to buy tokens
     * @param token ERC20 contract address
     * @param amount amount of tokens
     */ //XXX, uint256 expectedGXAG
    function buy(address token, uint256 amount) external onlyActive {
    	require(token != address(this), "GXAG: Buy GXAG for GXAG is prohibited");
    	require(amount > 0, "GXAG: buy amount is null");
        uint256 _userBalance = IERC20Upgradeable(token).balanceOf(msg.sender);
        require(_userBalance >= amount, "GXAG: Invalid user balance for buy");

        if (token == usdcAddress || token == usdtAddress) {
            _buyTokenWithUsd(token, msg.sender, amount);
        } else {
            address _pairAddress = IUniswapV2Factory(factoryAddress).getPair(token, usdcAddress);
            require(_pairAddress != address(0), "GXAG: USDC pair with this token not exist");

            _buyToken(msg.sender, token, amount, _pairAddress);
        }
    }

    /**
     * @notice Functon to add reserve
     * @param _holder holder address
     * @param _amount amount of reserve
     */
    function addReserve(address _holder, uint256 _amount) external onlyASWM {
        require(reserves[_holder] == 0, "GXAG: already have redeem with this address");
        require(
            super.balanceOf(_holder) >= _amount && minReserveAmount < _amount,
            "GXAG: Invalid amount for redeem"
        );

        reserves[_holder] = _amount;
        _transfer(_holder, address(this), _amount);
    }

    /**
     * @notice Functon to release reserve
     * @param _holder holder address
     */
    function releaseReserve(address _holder) external onlyASWM {
        require(reserves[_holder] != 0, "GXAG: Redeem is null");

        _burn(address(this), reserves[_holder]);
        delete reserves[_holder];
    }

    /**
     * @notice Functon to cancel reserve
     * @param _holder holder address
     */
    function cancelReserve(address _holder) external onlyASWM {
        require(reserves[_holder] != 0, "GXAG: Redeem is null");

        uint256 amount = reserves[_holder];
        uint256 fee = (amount * deliveryFee) / 10000;
        _transfer(address(this), _holder, amount - fee);
        delete reserves[_holder];
    }

    function mint(address account, uint256 amount) external onlyAdmin {
        _mint(account, amount);
    }

    /**
     * @notice Functon to get erc20 token price in usdc
     * @param token ERC20 contract address
     */
    function getErc20UsdcPrice(address token) external view returns (uint256) {
        address _pairAddress = IUniswapV2Factory(factoryAddress).getPair(token, usdcAddress);
        require(_pairAddress != address(0), "GXAG: USDC pair with this token not exist");
        return _getERC20Price(_pairAddress, token, 10 ** IERC20MetadataUpgradeable(token).decimals());
    }

    /**
     * @notice Functon to transfer tokens
     * @param to receiver address
     * @param amount amount
     */
    function transfer(address to, uint256 amount) public override onlyActive returns (bool) {
        address from = _msgSender();
        if( transferFee != 0 && from.code.length==0 && from != adminAddress && from != owner() ) {
        	uint256 fee = (amount * transferFee) / 10000;
        	_transfer( from, address(this), fee );
        	amount -= fee;
        }
        _transfer( from, to, amount );
        return true;
    }

    /**
     * @notice Functon to transfer tokens
     * @param from sender address
     * @param to receiver address
     * @param amount amount
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyActive returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        if( transferFee != 0 && from.code.length==0 && from != adminAddress && from != owner() ) {
        	uint256 fee = (amount * transferFee) / 10000;
        	_transfer(from, address(this), fee);
        	amount -= fee;
        }        
        _transfer( from, to, amount );
        return true;
    }

    /**
     * Returns the latest price GimbutisToken for buying
     */
    function getTokenPrice() public view returns (uint256 price) {
    	IAggregatorV3 aggregator = IAggregatorV3(oracleAddress);
        (, int256 _price, , , ) = aggregator.latestRoundData(); //an ounce of silver with decimals
        require( _price > 0, "GXAG: Aggregator price less or equal 0" );
        price = uint256(_price) * (10 ** (18-aggregator.decimals())) * silverRatio / 100;
    }

    /**
     * @notice Functon to buy gxag tokens with usdc/usdt
     * @param usdToken USDC/USDT contract address
     * @param buyer sender address
     * @param amount amount
     */
    function _buyTokenWithUsd(address usdToken, address buyer, uint256 amount) private {
        // Note: amount in USD, 6 decimals
        uint256 _gxagAmount = (amount * 1e30) / getTokenPrice();

        require(_gxagAmount >= minBuyAmount, "GXAG: Too small amount to buy minimum GXAG");
        require(
            super.balanceOf(address(this)) >= _gxagAmount,
            "GXAG: Not enough GXAG on balance"
        );
        if(usdToken == usdcAddress) {
            IERC20Upgradeable(usdToken).safeTransferFrom(buyer, address(this), amount);
        } else {
            IBadERC20(usdToken).transferFrom(buyer, address(this), amount);
        }
        _transfer(address(this), buyer, _gxagAmount);
    }

    /**
     * @notice Functon to buy gxag tokens with ERC20
     * @param amount sender address
     * @param _token ERC20 contract address
     * @param amount amount
     * @param _pairAddress pair address
     */
    function _buyToken(
        address _sender,
        address _token,
        uint256 amount,
        address _pairAddress
    ) private {
        uint256 _gxagUsdPrice = getTokenPrice(); // 18 decimals
        uint256 _erc20UsdPrice = _getERC20Price(_pairAddress, _token, amount);
        uint256 _gxagAmount = (_erc20UsdPrice * 1e18) / _gxagUsdPrice;

        require(_gxagAmount >= minBuyAmount, "GXAG: Too small GXAG amount for buy");
        require(
            super.balanceOf(address(this)) >= _gxagAmount,
            "GXAG: Not enough GXAG tokens on contract balance"
        );

        IERC20Upgradeable(_token).safeTransferFrom(_sender, address(this), amount);

        IERC20Upgradeable(_token).approve(routerAddress, amount);   // safeApprove

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = usdcAddress;

        IUniswapRouterV2(routerAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,                // amountIn
            _erc20UsdPrice / 1e12,  // amountOutMin
            path,
            address(this),
            block.timestamp + 100
        );

        _transfer(address(this), _sender, _gxagAmount);
    }

    /**
     * @notice Returns the latest price ERC20Token
     * @param _pairAddress pair address
     * @param _token token address
     * @param amount amount
     */
    function _getERC20Price(
        address _pairAddress,
        address _token,
        uint amount
    ) private view returns (uint256) {
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(_pairAddress).getReserves();
        uint256 usdcDecimalsPlus = 10 ** (18 - IERC20MetadataUpgradeable(usdcAddress).decimals());
        uint256 erc20DecimalsPlus = 10 ** (18 - IERC20MetadataUpgradeable(_token).decimals());
        if (IUniswapV2Pair(_pairAddress).token0() == usdcAddress) {
            return (amount * reserve0 * usdcDecimalsPlus) / (reserve1 * erc20DecimalsPlus);
        } else {
            return (amount * reserve1 * usdcDecimalsPlus) / (reserve0 * erc20DecimalsPlus);
        }
    }

    /**
     * @notice Functon to sell Gimbutis tokens
     * @param token USDC/USDT contract address
     * @param _gxagAmount amount of GAXG tokens
     */
    function sell(uint256 _gxagAmount, address token) external onlyActive {
        require( super.balanceOf(msg.sender) >= _gxagAmount, "GXAG: Too small user balance" );
        require(token == usdcAddress || token == usdtAddress, "GXAG: Sell for USDC or USDT only");        

    	IAggregatorV3 aggregator = IAggregatorV3(oracleAddress);
        (, int256 _price, , , ) = aggregator.latestRoundData();
        require( _price > 0, "GXAG: Aggregator price less or equal 0" ); 
    	uint256 _usdAmount = _gxagAmount * uint256(_price) / 10 ** (aggregator.decimals() + 12);
        require( IERC20Upgradeable(token).balanceOf(address(this)) >= _usdAmount, 
            "GXAG: Too small contract balance for sell");

		if(token == usdcAddress) {
		    IERC20Upgradeable(token).transfer(msg.sender, _usdAmount);
		} else {
            IBadERC20(token).transfer(msg.sender, _usdAmount);
        }
		_transfer(msg.sender, address(this), _gxagAmount);
    }

    
    /**
     * @notice Functon to claim tokens from contract to admin account
     * @param token ERC20 contract address
     * @param amount of tokens
     */
    function claim(address token, uint256 amount) external onlyAdmin {
        require( IERC20Upgradeable(token).balanceOf(address(this)) >= amount, 
	            "GXAG: Too small contract balance to claim");
        if(token == usdtAddress) {
            IBadERC20(token).transfer(msg.sender, amount);
        } else {
	    	IERC20Upgradeable(token).transfer(msg.sender, amount);
        }
    }
}
