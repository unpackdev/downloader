// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interface for the ERC20 standard, including transferFrom and transfer functions.
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// Contract BridgeZUSDC facilitates the bridging of USDC tokens, allowing for deposits and releases of funds.
contract BridgeZUSDC {
    // State variables
    address public owner;            // Address of the contract owner
    address public withdrawer;       // Address allowed to withdraw USDC from the contract
    address public usdcAddress;      // Address of the USDC token contract
    address public feeWallet;        // Address where fees are collected
    uint256 public fee;              // Fee charged for depositing USDC
    bool public paused;              // Boolean indicating whether the contract is paused

    // Events for logging actions
    event ReceivedUSDC(address from, uint256 amount, string depositInfo);
    event ReleaseUSDC(address from, uint256 amount, string withdrawInfo);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event WithdrawerChanged(address newWithdrawer);
    event USDCAddressChanged(address newUsdcAddress);
    event FeeWalletChanged(address newFeeWallet);
    event FeeChanged(uint256 newFee);

    // Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "Not owner");
        _;
    }

    modifier onlyOwnerOrWithdrawer() {
        require(msg.sender == owner || msg.sender == withdrawer, "Only the owner or withdrawer can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    // Constructor to initialize the contract with USDC token address, fee wallet, and fee amount.
    constructor(address _usdcAddress, address _feeWallet, uint256 _fee) {
        require(_usdcAddress != address(0), "USDC address cannot be the zero address");
        require(_feeWallet != address(0), "Fee wallet cannot be the zero address");
        require(_fee > 0, "Fee must be greater than 0");
        
        owner = msg.sender;
        usdcAddress = _usdcAddress;
        feeWallet = _feeWallet;
        fee = _fee;
    }

    // Functions
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setWithdrawer(address _withdrawer) external onlyOwner {
        require(_withdrawer != address(0), "Withdrawer cannot be the zero address");
        withdrawer = _withdrawer;
        emit WithdrawerChanged(_withdrawer);
    }

    function setUSDCAddress(address _usdcAddress) external onlyOwner {
        require(_usdcAddress != address(0), "USDC address cannot be the zero address");
        usdcAddress = _usdcAddress;
        emit USDCAddressChanged(_usdcAddress);
    }

    function setFeeWallet(address _feeWallet) external onlyOwner {
        require(_feeWallet != address(0), "Fee wallet cannot be the zero address");
        feeWallet = _feeWallet;
        emit FeeWalletChanged(_feeWallet);
    }

    function setFee(uint256 _fee) external onlyOwner {
        require(_fee > 0, "Fee must be greater than 0");
        fee = _fee;
        emit FeeChanged(_fee);
    }

    function depositUSDC(uint256 amount, string memory depositInfo) external whenNotPaused {
        require(amount > fee, "Amount must be greater than fee");
        IERC20(usdcAddress).transferFrom(msg.sender, feeWallet, fee);
        IERC20(usdcAddress).transferFrom(msg.sender, address(this), amount - fee);
        emit ReceivedUSDC(msg.sender, amount, depositInfo);
    }

    function releaseUSDC(address to, uint256 amount, string memory withdrawInfo) external onlyOwnerOrWithdrawer whenNotPaused {
        require(to != address(0), "Recipient cannot be the zero address");
        require(amount > 0, "Amount must be greater than 0");
        IERC20(usdcAddress).transfer(to, amount);
        emit ReleaseUSDC(msg.sender, amount, withdrawInfo);
    }

    function pause() public onlyOwnerOrWithdrawer {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // Function to prevent accidental Ether transfers to the contract
    receive() external payable {
        revert("This contract does not accept ETH");
    }
}