// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./IERC1155.sol";

//Exchange...selling tokens for ETH / USDT / BUSD
contract Exchange is Ownable, Pausable {
	uint256 public minAmount = 1 * (10**18); //1 token with 18 decimals
	uint256 public maxAmount = 1000 * (10**18); //1000 tokens with 18 decimals

	address public priceOracle; //the price oracle address

	IERC20 public theToken; //the token being sold

	IERC20 public usdToken; //the usd stablecoin (USDC, USDT etc...)

	uint256 public priceForTokenInWei; //price per token in WEI
	uint256 public priceForTokenInUSD; //price per token in USD

	constructor(IERC20 _theToken, IERC20 _usdToken) {
		theToken = _theToken;
		priceOracle = msg.sender;
		priceForTokenInWei = 1 ether;
		priceForTokenInUSD = 1 ether;
		usdToken = _usdToken;
	}

	// add funds to the smart contract (must have approval)
	function addFunds(uint256 _amount) external {
		theToken.transferFrom(msg.sender, address(this), _amount);
	}

	//buy tokens for Wei.  _amountTokens is with decimals
	function buyWithWei(uint256 _amountTokens) external payable whenNotPaused {
		require(_amountTokens >= minAmount, "below min");
		require(_amountTokens <= maxAmount, "above max");

		//you cannot buy more than the contract has
		uint256 balToken = theToken.balanceOf(address(this));
		require(_amountTokens <= balToken, "contract doesn't have enough balance");

		//how much would it pay for them
		uint256 requiredAmount = (priceForTokenInWei * _amountTokens) / (10**18);
		require(requiredAmount == msg.value, "you must send the exact ETH amount");

		//finally give the user the tokens
		theToken.transfer(msg.sender, _amountTokens);
	}

	//buy tokens for USD. _amountTokens is with decimals (must give allowance for USD Token)
	function buyWithUSD(uint256 _amountTokens) external whenNotPaused {
		require(_amountTokens >= minAmount, "below min");
		require(_amountTokens <= maxAmount, "above max");

		//you cannot buy more than the contract has
		uint256 balToken = theToken.balanceOf(address(this));
		require(_amountTokens <= balToken, "contract doesn't have enough balance");

		//how much would it pay for them
		uint256 usdRequiredAmount = (priceForTokenInUSD * _amountTokens) / (10**18);

		//transfer the usdtoken
		require(
			usdToken.transferFrom(msg.sender, address(this), usdRequiredAmount),
			"failed to transfer"
		);

		//finally give the user the tokens
		theToken.transfer(msg.sender, _amountTokens);
	}

	//sets the minimum tokens amount
	function setMinAmount(uint256 _newMinAmount) public onlyOwner {
		minAmount = _newMinAmount;
	}

	//sets the maximum tokens amount
	function setMaxAmount(uint256 _newMaxAmount) public onlyOwner {
		maxAmount = _newMaxAmount;
	}

	//sets the price oracle address
	function setPriceOracle(address _newAddress) public onlyOwner {
		priceOracle = _newAddress;
	}

	//sets the usd token
	function setUSDToken(IERC20 _newStablecoin) public onlyOwner {
		usdToken = _newStablecoin;
	}

	//sets the price of 1 token in WEI
	function setPriceForTokenInWei(uint256 _newPriceWei) external {
		require(msg.sender == priceOracle, "only oracle can update");
		priceForTokenInWei = _newPriceWei;
	}

	//sets the price of 1 token in USD (with decimals). eg: 1 SPI =  $200 => _newPriceUSD = 200*10**6 (USDC, USDT)
	function setPriceForTokenInUSD(uint256 _newPriceUSD) external {
		require(msg.sender == priceOracle, "only oracle can update");
		priceForTokenInUSD = _newPriceUSD;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	//owner can withdraw ETH
	function withdraw() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	// owner can withdraw tokens
	function withdrawTokens(IERC20 token, uint256 _amount) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		require(_amount <= balance, "not enough balance");
		token.transfer(msg.sender, _amount);
	}
}
