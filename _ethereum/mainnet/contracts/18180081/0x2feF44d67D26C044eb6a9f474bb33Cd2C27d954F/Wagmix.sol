/**                                                                         
                                                                                
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%             %%%%%%%%%%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%%%%%     %%%%%%%%%%%     %%%%%%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%(    %%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%     %%%%%%%%%%%%%%%     
      %%%%%%%%%%%%    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    %%%%%%%%%%%%     
      %%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%     
      %%%%%%%%%%  %%%% %%              %%%%            %%  %%%%  %%%%%%%%%%     
      %%%%%%%%%%  %%%%%   %%%%             %%%%  %%%%    %%%%%%  %%%%%%%%%%     
      %%%%%%%%%%  %%%%%%#    ,%%%%%%%%%%%%%%%%%%%       %%%%%%%  %%%%%%%%%%     
      %%%%%%%%%%  %%%%%%%%     %%.%%%%%%%%%%%%%       %%%%%%%%%  %%%%%%%%%%     
      %%%%%%%%%%  %%%%%%%%%    %%  %%%%%%%%%%        %%%%%%%%%%  %%%%%%%%%%     
      %%%%%%%%%%  %%%%%%%%%%%%%%%   .%%%%%%%      %%%%%%%%%%%%%  %%%%%%%%%%     
      %%%%%%%%%%  %%%%%%%%%%%%%%%     %%%%%  %%%%%%%%%%%%%%%%%%  %%%%%%%%%%     
      %%%%%%%%%%  %%%%%%%%%%%%%%%      (%%%%   %%%%%%%%%%%%%%%%  %%%%%%%%%%     
      %%%%%%%%%%  %%%%%%%%%%%%%%%.     .%      %%%%%%%%%%%%%%%%  %%%%%%%%%%     
      %%%%%%%%%%%  (%%%%%%%%%%%%%%%     %    #%%%%%%%%%%%%%%%#  %%%%%%%%%%%     
      %%%%%%%%%%%%    %%%%%%%%%%%%%%    %   %%%%%%%%%%%%%%%    %%%%%%%%%%%%     
      %%%%%%%%%%%%%%%     %%%%%%%%%%%%  %  %%%%%%%%%%%%     %%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%    #%%%%%%%% %/%%%%%%%%%    ,%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%%%%%     %%%%%%%%%%%     %%%%%%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%            .%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
                                                                                
      // Wagmix Coin            - https://coin.wagmix.io
      // Wagmix Exchange        - https://wagmix.io
      // Wagmix Twitter         - https://twitter.com/WagmixGlobal
      // Wagmix Community       - https://t.me/WagmixCommunity
      // Wagmix Channel         - https://t.me/WagmixGlobal
      // Wagmix Exchange        - https://t.me/WagmixExchange
      // Wagmix Support         - https://support.wagmix.io
      // Wagmix Support Bot     - https://t.me/WagmixGlobalSupportBot
      // Wagmix Proposal Bot    - https://t.me/WagmixGlobalProposalsBot
      // Wagmix Market Data     - https://t.me/WagmixMarketData
      // Wagmix Market Data Bot - https://t.me/WagixGlobalMarketBot

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;
pragma experimental ABIEncoderV2;

abstract contract Ownable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    // Function to transfer ownership to a new address
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
    // Function to renounce ownership
    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
    }
}

// SafeERC20 library ensures safe ERC20 token transfers
library SafeERC20 {
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: INTERNAL TRANSFER_FAILED');
    }
}

// ERC20 token interface
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
}

// Uniswap V2 Factory interface
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Uniswap V2 Router interface
interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;

    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

/**
 * @title Wagmix (WGX) Token Contract
 * @dev This contract implements the Wagmix token (WGX) with ownership control, fees, and automatic liquidity generation.
 * It also provides functions to manage various parameters and control the token distribution.
 */
 
contract Wagmix is Ownable {
    // Token metadata    
    string private constant _name = unicode"Wagmix";
    string private constant _symbol = unicode"WGX";
    uint256 private constant _totalSupply = 120_000_000 * 1e18;
    uint256 private constant _maxSupply = 120_000_000 * 1e18;

    // Transaction limits and fees
    uint256 public maxTransactionAmount = 1_200_000 * 1e18;
    uint256 public maxWallet = (_totalSupply * 2) / 100;
    uint256 public swapTokensAtAmount = (_totalSupply * 2) / 10000;

    // Address for various purposes
    address private revAddress = 0xB6577370052B015e0494030A18F3B8Fe31b9a1F3;
    address private treasuryAddress = 0xC66D9606B7C9eC8199BD285343B502CF291F9e89;
    address private teamAddress = 0xAe78Db306479f8289E52c53b4Bc1F9d6A7842942;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Fee multipliers and distribution percentages
    uint256 private multiplier = 20;

    uint8 public buyTotalFees = 50;
    uint8 public sellTotalFees = 50;

    uint8 public revFee = 40;
    uint8 public treasuryFee = 30;
    uint8 public teamFee = 30;

    // Flags for contract state
    bool private swapping;
    bool public limitsInEffect = true;
    bool private launched;

    // Token balances and allowances
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    // Events
    event SwapAndLiquify(uint256 tokensSwapped, uint256 teamETH, uint256 revETH, uint256 TreasuryETH);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Uniswap Router instance
    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;

    constructor() {
        // Create the Uniswap pair for WGX and WETH        
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WETH);
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        // Exclude key addresses from fees
        setExcludedFromFees(owner(), true);
        setExcludedFromFees(address(this), true);
        setExcludedFromFees(address(0xdead), true);
        setExcludedFromFees(teamAddress, true);
        setExcludedFromFees(revAddress, true);
        setExcludedFromFees(treasuryAddress, true);

        // Exclude key addresses from max transaction amount
        setExcludedFromMaxTransaction(owner(), true);
        setExcludedFromMaxTransaction(address(uniswapV2Router), true);
        setExcludedFromMaxTransaction(address(this), true);
        setExcludedFromMaxTransaction(address(0xdead), true);
        setExcludedFromMaxTransaction(address(uniswapV2Pair), true);
        setExcludedFromMaxTransaction(teamAddress, true);
        setExcludedFromMaxTransaction(revAddress, true);
        setExcludedFromMaxTransaction(treasuryAddress, true);

        // Calculate the token amounts for distribution
        uint256 totalTokens = _totalSupply;
        uint256 tokensToTreasury = (totalTokens * 20) / 100;
        uint256 tokensToTeam = (totalTokens * 10) / 100;
        uint256 tokensToDeployer = totalTokens - tokensToTreasury - tokensToTeam;

        // Allocate tokens to addresses
        _balances[msg.sender] = tokensToDeployer;
        emit Transfer(address(0), msg.sender, tokensToDeployer);
        _balances[treasuryAddress] = tokensToTreasury;
        emit Transfer(address(0), treasuryAddress, tokensToTreasury);
        _balances[teamAddress] = tokensToTeam;
        emit Transfer(address(0), teamAddress, tokensToTeam);

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    // Fallback function to receive ETH
    receive() external payable {}

    // Getters for token metadata
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    // Get the balance of a specific address
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Get the allowance for a spender on behalf of an owner
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approve a spender to spend a specific amount on behalf of the owner
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Internal function to set allowance
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Transfer tokens to a recipient
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // Transfer tokens from sender to recipient
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    // Internal function for token transfer
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Ensure trading is enabled
        if (!launched && (from != owner() && from != address(this) && to != owner())) {
            revert("Trading not enabled");
        }

        // Apply transaction limits and fees
        if (limitsInEffect) {
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTx");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                } else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTx");
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;

        if (canSwap && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        // Handle fee calculations
        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        uint256 fees = 0;
        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 1000;
            } else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 1000;
            }

            if (fees > 0) {
                unchecked {
                    amount = amount - fees;
                    _balances[from] -= fees;
                    _balances[address(this)] += fees;
                }
                emit Transfer(from, address(this), fees);
            }
        }
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    // Function to remove transaction limits
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    // Function to set distribution fees
    function setDistributionFees(uint8 _RevFee, uint8 _TreasuryFee, uint8 _teamFee) external onlyOwner {
        revFee = _RevFee;
        treasuryFee = _TreasuryFee;
        teamFee = _teamFee;
        require((revFee + treasuryFee + teamFee) == 100, "Distribution must total 100%");
    }

    // Function to set transaction fees
    function setFees(uint8 _buyTotalFees, uint8 _sellTotalFees) external onlyOwner {
        require(_buyTotalFees <= 50, "Buy fees must be less than or equal to 5%");
        require(_sellTotalFees <= 50, "Sell fees must be less than or equal to 5%");
        buyTotalFees = _buyTotalFees;
        sellTotalFees = _sellTotalFees;
    }

    // Function to exclude an address from fees
    function setExcludedFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    // Function to exclude an address from max transaction amount
    function setExcludedFromMaxTransaction(address account, bool excluded) public onlyOwner {
        _isExcludedMaxTransactionAmount[account] = excluded;
    }

    // Function to open trading
    function openTrade() external onlyOwner {
        require(!launched, "Already launched");
        launched = true;
    }

    // Function to start the liquidity generation
    function startingWagmix() external payable onlyOwner {
        require(!launched, "Already launched");
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            _balances[address(this)],
            0,
            0,
            teamAddress,
            block.timestamp
        );
    }

    // Function to set automated market maker pair
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed");
        automatedMarketMakerPairs[pair] = value;
    }

    // Function to set swap amount
    function setSwapAtAmount(uint256 newSwapAmount) external onlyOwner {
        require(newSwapAmount >= (totalSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% of the supply");
        require(newSwapAmount <= (totalSupply() * 5) / 1000, "Swap amount cannot be higher than 0.5% of the supply");
        swapTokensAtAmount = newSwapAmount;
    }

    // Function to set maximum transaction amount
    function setMaxTxnAmount(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx >= ((totalSupply() * 1) / 1000) / 1e18, "Cannot set max transaction lower than 0.1%");
        maxTransactionAmount = newMaxTx * (10**18);
    }

    // Function to set maximum wallet amount
    function setMaxWalletAmount(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= ((totalSupply() * 1) / 1000) / 1e18, "Cannot set max wallet lower than 0.1%");
        maxWallet = newMaxWallet * (10**18);
    }

    // Function to update the reward address
    function updateRevAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero");
        revAddress = newAddress;
    }

    // Function to update the treasury address
    function updateTreasuryAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero");
        treasuryAddress = newAddress;
    }

    // Function to update the team address
    function updateTeamAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Address cannot be zero");
        teamAddress = newAddress;
    }

    // Function to check if an address is excluded from fees
    function excludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    // Function to withdraw stuck tokens from the contract
    function withdrawStuckToken(address token, address to) external onlyOwner {
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        SafeERC20.safeTransfer(token, to, _contractBalance); // Use safeTransfer
    }

    // Function to withdraw stuck ETH from the contract
    function withdrawStuckETH(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");

        (bool success, ) = addr.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    // Function to update the fee multiplier
    function updateFeeMultiplier(uint256 newMultiplier) external onlyOwner {
        require(newMultiplier > 0, "Multiplier must be greater than zero");
        multiplier = newMultiplier; // Update the multiplier
    }

    // Private function to perform the swap
    function swapBack() private {
        uint256 swapThreshold = swapTokensAtAmount * multiplier;
        bool success;

        if (balanceOf(address(this)) > swapTokensAtAmount * multiplier) {
            swapThreshold = swapTokensAtAmount * multiplier;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(swapThreshold, 0, path, address(this), block.timestamp);

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            uint256 ethForRev = (ethBalance * revFee) / 100;
            uint256 ethForTeam = (ethBalance * teamFee) / 100;
            uint256 ethForTreasury = ethBalance - ethForRev - ethForTeam;

            (success, ) = address(teamAddress).call{value: ethForTeam}("");
            (success, ) = address(treasuryAddress).call{value: ethForTreasury}("");
            (success, ) = address(revAddress).call{value: ethForRev}("");

            emit SwapAndLiquify(swapThreshold, ethForTeam, ethForRev, ethForTreasury);
        }
    }
}