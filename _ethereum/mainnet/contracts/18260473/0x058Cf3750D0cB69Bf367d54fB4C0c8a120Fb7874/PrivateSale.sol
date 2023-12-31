// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract PrivateSale {
    address public contributeCoin;
    mapping (address => uint256) public coinContributed;
    uint256 public totalCoinContributed;

    uint256 public maxPerWallet;

    uint256 public totalDepositCap;
	address public depositAddress;

    uint256 public startTimestamp;
    uint256 public endTimestamp;

    mapping(uint256 => bool) public depositAmountEnabled;

    address public owner;
    bool private initialized;

    event TransferOwnership(address _oldOwner, address _newOwner);
    event Deposit(address user, uint256 coin);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier underWay() {
        require(block.timestamp >= startTimestamp && startTimestamp > 0, "Private sale not started");
        require(block.timestamp <= endTimestamp, "Private sale ended");
        _;
    }

    modifier whenExpired() {
        require(block.timestamp > endTimestamp, "Private sale not ended");
        _;
    }

	modifier canDeposit() {
		require(depositAmountEnabled[msg.value], "Deposit amount is now allowed");
		_;
	}

    function initialize(address _coinToken) external {
        require (!initialized, "Already initialized");
        initialized = true;

        owner = msg.sender;
        emit TransferOwnership(address(0), owner);

        contributeCoin = _coinToken;

		totalDepositCap = 50 * (10 ** 18); // 50 ETH
        maxPerWallet = 1 * (10 ** 18); // 1 ETH
		depositAddress = 0x6264B1AE625b694C790628afC5472DE23940Abb2;

		startTimestamp = 1696420800; // October 4th , 12:00 UTC
		endTimestamp = 1697025600; // October 11th , 12:00 UTC

		depositAmountEnabled[25 * (10 ** 16)] = true; // 0.25 ETH
		depositAmountEnabled[50 * (10 ** 16)] = true; // 0.5 ETH
		depositAmountEnabled[100 * (10 ** 16)] = true; // 1 ETH
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Zero address");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit TransferOwnership(owner, address(0));
        owner = address(0);
    }

    function launchPrivateSale(uint256 secStart, uint256 _secDuration) external onlyOwner {
        startTimestamp = secStart;
        endTimestamp = secStart + _secDuration;
    }

    function launchPrivateSale(uint256 _secDuration) external onlyOwner underWay {
        endTimestamp = block.timestamp + _secDuration;
    }

    function updateMaxTokenPerWallet(uint256 _maxAmount) external onlyOwner {
        maxPerWallet = _maxAmount;
    }

    function setTotalCap(uint256 _totalAmount) external onlyOwner {
        totalDepositCap = _totalAmount;
    }

	function setDepositAddress(address newAddress) external onlyOwner {
		require(depositAddress != newAddress, "Already set");
        depositAddress = newAddress;
    }

	function updateDepositAmount(uint256 newAmount, bool set) external onlyOwner {
		require(depositAmountEnabled[newAmount] != set, "Already set");
        depositAmountEnabled[newAmount] = set;
    }

    function updateTokens(address _coinToken) external onlyOwner {
        require(totalCoinContributed == 0, "Unable to update token addresses");
        contributeCoin = _coinToken;
    }

    function innerDepositCoin(uint256 _coinAmount) internal returns (uint256) {
        uint256 cReceived;
		address _to = msg.sender;
        if (contributeCoin == address(0)) {
            cReceived = msg.value;
			payCoin(depositAddress, cReceived);
        } else {
            address feeRx = depositAddress;
            uint256 _oldCBalance = IToken(contributeCoin).balanceOf(feeRx);
            IToken(contributeCoin).transferFrom(_to, feeRx, _coinAmount);
            uint256 _newCBalance = IToken(contributeCoin).balanceOf(feeRx);

            cReceived = _newCBalance - _oldCBalance;
        }

        totalCoinContributed += cReceived;
		require(totalCoinContributed <= totalDepositCap, "Reached total cap");

        coinContributed[_to] += cReceived;
		require(coinContributed[_to] <= maxPerWallet, "Too much deposited");

        return cReceived;
    }

    function deposit(uint256 _coinAmount) external payable underWay canDeposit
    {
        uint256 coin = innerDepositCoin(_coinAmount);
        emit Deposit(msg.sender, coin);
    }

    function recoverCoin(address _to, uint256 _amount) external payable onlyOwner {
        if (_amount == 0) {
            if (contributeCoin == address(0)) {
                _amount = address(this).balance;
            } else {
                _amount = IToken(contributeCoin).balanceOf(address(this));
            }
        }

        payCoin(_to, _amount);
    }

    function payCoin(address _to, uint256 _amount) internal {
        if (contributeCoin == address(0)) {
            (bool success,) = payable(_to).call{value: _amount}("");
            require(success, "Failed to recover");
        } else {
            IToken(contributeCoin).transfer(_to, _amount);
        }
    }

    receive() external payable {}
}