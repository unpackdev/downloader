//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

library TransferHelper {
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}

contract IDO {

    uint public totalSupply;
    uint public amountRound1;
    uint public amountRound2;
    uint public priceRound1;
    uint public priceRound2;
    uint public totalRaised;
    uint public soldAmount;
    address private owner;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant TOKEN = 0x028C4cd9606E3963a17eCdF6765b27a32D31A8aB;
    address public constant RECIPIENT = 0x4807416E8925d8772EC714e74df03E071c099feB;
    
    address[] public holders;
    uint public holdersNum;
    mapping (address => bool) public isHolderExist;
    mapping (address => uint) public amountOf;

    bool public isEnds;
    uint public maxToken;

    constructor() {
        owner = msg.sender;
        totalSupply = 15_000_000 * 1e18;
        maxToken = 10000 * 1e18;
        amountRound1 = totalSupply * 30 / 100;
        amountRound2 = totalSupply * 70 / 100;
        priceRound1 = 5 * 1e4;
        priceRound2 = 1e5;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setMaxToken(uint _maxToken) external onlyOwner {
        maxToken = _maxToken;
    }

    function setRoundAmount(uint _amountRound1, uint _amountRound2) external onlyOwner {
        amountRound1 = _amountRound1;
        amountRound2 = _amountRound2;
    }

    function setPrice(uint _priceRound1, uint _priceRound2) external onlyOwner {
        priceRound1 = _priceRound1;
        priceRound2 = _priceRound2;
    }
   
    function endsSale(bool flag) external onlyOwner{
        isEnds = flag;
    }

    function buy(uint usdtAmount) external {
        require(!isEnds, 'presale ends');
        TransferHelper.safeTransferFrom(USDT, msg.sender, RECIPIENT, usdtAmount);

        uint price = priceRound1;
        if (soldAmount > amountRound1) {
            price = priceRound2;
        }
        uint desiredAmount = usdtAmount * 1e6 / price;
        amountOf[msg.sender] += desiredAmount;
        require(amountOf[msg.sender] <= maxToken, "max token");
    
        if (!isHolderExist[msg.sender]) {
            holders.push(msg.sender);
            isHolderExist[msg.sender] = true;
            holdersNum++;
        }
        totalRaised += usdtAmount;
        soldAmount += desiredAmount;
        require(soldAmount <= totalSupply, "sold out");
        if (soldAmount >= totalSupply) {
            isEnds = true;
        }
	}

    function claimToken() external {
        require(isEnds, 'presale not ends');
        uint amount = amountOf[msg.sender];
        require(amount > 0, "insufficent balance");
        amountOf[msg.sender] = 0;
        IERC20(TOKEN).transfer(msg.sender, amount);
    }

    function rescureToken(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}