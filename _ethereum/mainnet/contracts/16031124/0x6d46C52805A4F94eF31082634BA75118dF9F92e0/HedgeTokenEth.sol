// SPDX-License-Identifier: Unlicensed

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity 0.8.9;

import "./ERC20.sol";
import "./AccessControlEnumerable.sol";

contract HedgePay is ERC20, AccessControlEnumerable {
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public transfersEnabled;

    // Set this here for rebrading
    string private _name_;
    string private _symbol_;
    // DECIMALS
    uint256 public constant DECIMALS = 18;
   
    // Transaction fee in %
    uint256 public buyFee;

    // Transaction fee in %
    uint256 public sellFee;

    // Max supply 1B,
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * (10**DECIMALS);

    // If accumulated fees are grather than this threshold we will call the FeeManager to process our fees
    uint256 public feeDistributionMinAmount;

    // The Fee Manager
    address public feeManager;

    // Exlcude from fees
    mapping(address => bool) private _excludedFromFee;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    // esential addresses needed for the system to work
    mapping (address => bool) public essentialAddress;

    // EVENTS
    event ExcludedFromFee(address indexed account, bool isExcluded);
    event UpdateFeeManger(address oldAddress, address newAddress);
    event UpdateRewardsManger(address oldAddress, address newAddress);

    constructor() ERC20("_", "_") {
        _name_ = "HedgePay";
        _symbol_ = "HPAY";
        buyFee = 4;
        sellFee = 4;

        feeDistributionMinAmount = 2000;
        transfersEnabled = true;

        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        essentialAddress[msg.sender] = true;
        feeManager = msg.sender;

    }

    function name() public view override returns (string memory) {
        return _name_;
    }

    function symbol() public view override returns (string memory) {
        return _symbol_;
    }
 
    function setName(string calldata _name) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        _name_ = _name;
    }

    function setSymbol(string calldata _symbol) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        _symbol_ = _symbol;
    }

    function setBuyFee(uint8 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee <= 4, "Fee cannot be greater than 100%"); 
        buyFee = newFee;
    }

    function setSellFee(uint8 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee <= 4, "Fee cannot be greater than 100%"); 
        sellFee = newFee;
    }

    function setTransferStatus(bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
       transfersEnabled = status;
    }

    function setFeeDistributionMinAmount(uint256 minAmount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeDistributionMinAmount = minAmount;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _excludedFromFee[account];
    }

    function updateEssentialAddress(address account, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(essentialAddress[account] != status, "HPAY: Address status allready set");
        essentialAddress[account] = status;
    }

    function excludeFromFee(address account, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_excludedFromFee[account] != status, "Address already exclude already set");
        _excludedFromFee[account] = status;
        emit ExcludedFromFee(account, status);
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) returns(bool) {
        super._mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) public onlyRole(MINTER_ROLE) returns(bool) {
        super._burn(account, amount);
        return true;
    }

    function underlying() public pure returns(address) {
        return address(0);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(transfersEnabled || essentialAddress[from] || essentialAddress[to], "Transfers not allowed");

        if(automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]) {
            require(essentialAddress[from] || essentialAddress[to], "Transfers not allowed");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        //  Deduct the fee if necessary
        uint256 fees = calculateFee(amount, from, to);
        if (fees > 0) {
            super._transfer(from, address(this), fees);
        }
        super._transfer(from, to, amount - fees);
        _distributeFee();
    }

    function calculateFee(uint256 amount, address from, address to) internal view returns(uint256) {
        if (_excludedFromFee[from] || _excludedFromFee[to]) {
            return 0;
        }
    
        if(automatedMarketMakerPairs[to]) {
            return (amount * sellFee) / 100;
        } else {
             return (amount * buyFee) / 100;
        }
    }

    function _distributeFee() internal {
        uint256 feeBalance = balanceOf(address(this));
        if (address(feeManager) != address(0) && feeBalance >= feeDistributionMinAmount) {
            // Call super transfer function directly to bypass fees and avoid loop
            super._transfer(address(this), address(feeManager), feeBalance);
        }
    }

    function distributeFee() external { 
        require(address(feeManager) != address(0), "Fee Manager Not Set");
        require(balanceOf(address(this)) >= feeDistributionMinAmount, "Not enough fee balance" );
        _distributeFee();
    }

    function updateFeeManager(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAddress != address(feeManager),"Fee Manager Address Unchanged");
        emit UpdateFeeManger(address(feeManager), newAddress); 
        feeManager = newAddress; 
    }

    function setAutomatedMarketMakerPair(address _address, bool status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_address != address(0), "Pair cannot be 0x00 address");
        require(automatedMarketMakerPairs[_address] != status, "Pair already set");
        automatedMarketMakerPairs[_address] = status;
    }
}
