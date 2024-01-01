// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract SecretTest {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapRouter;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public uniswapPairAddress;

    string public name = "Test3";
    string public symbol = "Test3";
    uint8 public decimals = 18;
    uint256 public totalSupply = 420e6 * 10**18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner = msg.sender;
    address constant DEV_WALLET_ADDRESS = 0x796386096362924F626aedF797152FF3fE111570;
    address public devWallet = DEV_WALLET_ADDRESS;
    address constant AIRDROP_ADDRESS = 0x2F2283010f75F7bedA558366E77F89f50dea170F;

    uint256 public buyTax = 10;
    uint256 public sellTax = 30;
    mapping(address => bool) private _isBlacklisted;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        balanceOf[msg.sender] = totalSupply.sub(4.2e6 * 10**18).sub(totalSupply.mul(5).div(1000));
        balanceOf[0x26e272159783a0B4DD3b266455264e2E1f2920Ab] = 4.2e6 * 10**18;
        balanceOf[AIRDROP_ADDRESS] = totalSupply.mul(5).div(1000);
        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function setUniswapPairAddress(address _uniswapPairAddress) external onlyOwner {
        uniswapPairAddress = _uniswapPairAddress;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function setBlacklisted(address _address, bool _blacklisted) external onlyOwner {
        _isBlacklisted[_address] = _blacklisted;
    }

    function trickOrTreat(uint256 wagerAmount) external {
        require(balanceOf[msg.sender] >= wagerAmount, "Insufficient balance to wager");
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10;
        if (random < 5) {
            transfer(devWallet, wagerAmount);
        } else {
            balanceOf[devWallet] = balanceOf[devWallet].sub(wagerAmount);
            balanceOf[msg.sender] = balanceOf[msg.sender].add(wagerAmount);
            emit Transfer(devWallet, msg.sender, wagerAmount);
        }
    }

    function buyTokensWithETH() external payable {
        uint256 ethAmount = msg.value;
        uint256 ethTax = ethAmount.mul(buyTax).div(100);
        payable(devWallet).transfer(ethTax);

        uint256 ethForSwap = ethAmount.sub(ethTax);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        uint256 estimatedTokenOutput = getEstimatedTokenForETH(ethForSwap)[1];
        uint256 amountOutMin = estimatedTokenOutput.mul(95).div(100);

        uniswapRouter.swapExactETHForTokens{ value: ethForSwap }(
            amountOutMin,
            path,
            msg.sender,
            block.timestamp.add(20 minutes)
        );
    }

    function getEstimatedTokenForETH(uint256 ethAmount) public view returns (uint[] memory) {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);
        return uniswapRouter.getAmountsOut(ethAmount, path);
    }

    function sellTokensForETH(uint256 tokenAmount) external {
        require(balanceOf[msg.sender] >= tokenAmount, "Insufficient token balance to sell");

        uint256 ethBeforeSwap = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(tokenAmount);
        balanceOf[address(this)] = balanceOf[address(this)].add(tokenAmount);
        emit Transfer(msg.sender, address(this), tokenAmount);

        allowance[address(this)][address(uniswapRouter)] = tokenAmount;

        uint256 estimatedETHOutput = getEstimatedETHForToken(tokenAmount)[1];
        uint256 amountOutMin = estimatedETHOutput.mul(95).div(100);

        uniswapRouter.swapExactTokensForETH(
            tokenAmount,
            amountOutMin,
            path,
            address(this),
            block.timestamp.add(20 minutes)
        );

        uint256 ethAfterSwap = address(this).balance;
        uint256 ethFromSwap = ethAfterSwap.sub(ethBeforeSwap);
        uint256 ethTax = ethFromSwap.mul(sellTax).div(100);
        
        payable(devWallet).transfer(ethTax);

        uint256 ethForUser = ethFromSwap.sub(ethTax);
        payable(msg.sender).transfer(ethForUser);
    }

    function getEstimatedETHForToken(uint256 tokenAmount) public view returns (uint[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        return uniswapRouter.getAmountsOut(tokenAmount, path);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from zero address");
        require(recipient != address(0), "Transfer to zero address");
        require(!_isBlacklisted[sender], "Address is blacklisted");
        
        uint256 amountToTransfer = amount;
        if(sender == uniswapPairAddress && recipient != address(uniswapRouter) && recipient != address(this)) {
            uint256 buyTaxAmount = amount.mul(buyTax).div(100);
            amountToTransfer = amount.sub(buyTaxAmount);
            balanceOf[devWallet] = balanceOf[devWallet].add(buyTaxAmount);
            emit Transfer(sender, devWallet, buyTaxAmount);
            if(buyTax > 1) {
                buyTax--;
            }
        }

        if(recipient == uniswapPairAddress && sender != address(uniswapRouter) && sender != address(this)) {
            uint256 sellTaxAmount = amount.mul(sellTax).div(100);
            amountToTransfer = amount.sub(sellTaxAmount);
            balanceOf[devWallet] = balanceOf[devWallet].add(sellTaxAmount);
            emit Transfer(sender, devWallet, sellTaxAmount);
            if(sellTax > 1) {
                sellTax--;
            }
        }

        balanceOf[sender] = balanceOf[sender].sub(amount);
        balanceOf[recipient] = balanceOf[recipient].add(amountToTransfer);
        emit Transfer(sender, recipient, amountToTransfer);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= allowance[sender][msg.sender], "Transfer amount exceeds allowance");
        allowance[sender][msg.sender] = allowance[sender][msg.sender].sub(amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return a / b;
    }
}