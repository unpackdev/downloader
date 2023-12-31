// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract Goaty is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;
    uint256 private _totalSupply;
    
    uint256 public sellTaxPercent = 5; // Initial value of 5%. This means a 5% tax on selling.
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Add a mapping to track if an address has bought
    mapping(address => bool) public hasBought;

    // Counter to keep track of the number of unique buyers
    uint256 public buyerCount = 0;

    
    address public owner;
    address public constant feeWallet =
        0x1e316b28Bd973B50A266e879D079F18331429227;
    address public constant marketingWallet =
        0x1e316b28Bd973B50A266e879D079F18331429227;
    address public constant liquidityWallet = 
        0x22291C80E9Cd65befcb26422d5076671263cC37b;
 
    address public immutable pair;
    address public immutable router;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public immutable WETH;

    bool private isSwapping;

    modifier onlyDeployer() {
        require(msg.sender == owner, "Only the owner can do that");
        _;
    }

   

    constructor() {
        owner = msg.sender;
        _name = "Goaty";
        _symbol = "GOATY";
        _totalSupply = 69_420_000_000_000 * (10 ** _decimals);
        router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap V2 router

        WETH = IDEXRouter(router).WETH();

        pair = IDEXFactory(IDEXRouter(router).factory()).createPair(
            address(this),
            WETH
        );

        isExcludedFromFees[owner] = true;
        isExcludedFromFees[marketingWallet] = true;
        isExcludedFromFees[liquidityWallet] = true;
  

        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable {}

    function name() public view override returns (string memory) {
        return _name;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply - _balances[DEAD];
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function rescueEth(uint256 amount) external onlyDeployer {
        (bool success, ) = address(owner).call{value: amount}("");
        success = true;
    }

    function setSellTaxPercent(uint256 newSellTax) external onlyDeployer {
    require(newSellTax <= 100, "Tax cannot be more than 100%");
    sellTaxPercent = newSellTax;
}

    function swapAllContractTokensForEth() internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 tokenAmount = _balances[address(this)];

        if (tokenAmount > 0) {
            _allowances[address(this)][router] += tokenAmount;
            // Swap all the GOATY balance to ETH
            IDEXRouter(router)
                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tokenAmount,
                    0,
                    path,
                    feeWallet,
                    block.timestamp
                );
        }
    }

    function rescueToken(address token, uint256 amount) external onlyDeployer {
        IERC20(token).transfer(owner, amount);
    }

    function allowance(
        address holder,
        address spender
    ) public view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        require(spender != address(0), "NO_ZERO");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        require(spender != address(0), "NO_ZERO");
        _allowances[msg.sender][spender] =
            allowance(msg.sender, spender) +
            addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        require(spender != address(0), "NO_ZERO");
        require(
            allowance(msg.sender, spender) >= subtractedValue,
            "INSUFF_ALLOWANCE"
        );
        _allowances[msg.sender][spender] =
            allowance(msg.sender, spender) -
            subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(
                _allowances[sender][msg.sender] >= amount,
                "INSUFF_ALLOWANCE"
            );
            _allowances[sender][msg.sender] -= amount;
            emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        }
        return _transferFrom(sender, recipient, amount);
    }

  function _transferFrom(
    address sender,
    address recipient,
    uint256 amount
) internal returns (bool) {
   
    // If it's a buy, check if should automatically blacklist the buyer
    if (sender == pair) {
        // Check if the buyer has bought before
        if(!hasBought[recipient]){
            hasBought[recipient] = true;
            buyerCount += 1;
        }
    }

    // If not tax-free
    if (!checkTaxFree(sender, recipient)) {
        // 20% tax on sells for the first 10 buyers
        if (hasBought[sender] && buyerCount <= 10 && recipient == pair) {
            _lowGasTransfer(sender, address(this), amount * 20 / 100);
            amount = (amount * 80) / 100;
        }
        // Default sell tax
        else if (recipient == pair) { // Additional condition to ensure it's a sell
            _lowGasTransfer(sender, address(this), amount * sellTaxPercent / 100);
            amount = (amount * (100 - sellTaxPercent)) / 100;
        }
    }

    if (!isSwapping && sender != pair) {
        isSwapping = true;
        swapAllContractTokensForEth();
        isSwapping = false;
    }

    return _lowGasTransfer(sender, recipient, amount);
}

    function checkTaxFree(
        address sender,
        address recipient
    ) internal view returns (bool) {
        if (isSwapping) return true;
        if (isExcludedFromFees[sender] || isExcludedFromFees[recipient])
            return true;
        if (sender == pair || recipient == pair) return false;
        return true;
    }

    function _lowGasTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "Can't use zero addresses here");
        require(
            amount <= _balances[sender],
            "Can't transfer more than you own"
        );
        if (amount == 0) return true;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function excludeFromFees(
        address excludedWallet,
        bool status
    ) external onlyDeployer {
        isExcludedFromFees[excludedWallet] = status;
    }

    function renounceOwnership() external onlyDeployer {
        owner = address(0);
    }
}