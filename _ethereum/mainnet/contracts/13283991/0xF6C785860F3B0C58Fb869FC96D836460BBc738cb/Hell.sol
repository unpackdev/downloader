// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;
import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract Hell is Initializable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    address public _hellVaultAddress;
    uint public _burnFee;
    uint public _burntTokens;
    mapping(address => bool) public _excludedFromBurnFees;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
    function initialize(string memory name, string memory symbol) initializer public {
        __ERC20_init(name, symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        _hellVaultAddress = msg.sender;
        _excludedFromBurnFees[msg.sender] = true;
        _mint(msg.sender, 566 * 10 ** decimals());
        _burnFee = 5;
        _burntTokens = 0;
    }
    ////////////////////////////////////////////////////////////////////
    // Public Functions                                             ////
    ////////////////////////////////////////////////////////////////////
    function transfer(address recipient, uint amount) public override returns (bool) {
        (uint recipientReceives, ) =  _burnFees(msg.sender, recipient, amount);
        // Proceed with the transfer.
        return super.transfer(recipient, recipientReceives);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        (uint recipientReceives, ) =  _burnFees(sender, recipient, amount);
        return super.transferFrom(sender, recipient, recipientReceives);
    }

    function calculateBurnFees(address sender, address recipient, uint amount) public view returns (uint) {
        // If msg.sender or Recipient are Excluded from fees.
        if (_excludedFromBurnFees[sender] || _excludedFromBurnFees[recipient]) {
            return 0;
        } else {
            return uint(_burnFee) * (amount / 100);
        }
    }
    ////////////////////////////////////////////////////////////////////
    // Internal                                                     ////
    ////////////////////////////////////////////////////////////////////
    function _burnFees(address sender, address recipient, uint amount) internal returns (uint recipientReceives, uint amountBurned) {
        require(recipient != address(0), "Cannot transfer to the zero address");
        require(balanceOf(sender) >= amount, "Not enough balance");
        amountBurned = calculateBurnFees(sender, recipient, amount);
        if (amountBurned > 0) {
            // Subtract Burn fees
            amount -= amountBurned;
            _burntTokens += amountBurned;
            // Burn Fees
            _burn(msg.sender, amountBurned);
        }
        return (amount, amountBurned);
    }
    ////////////////////////////////////////////////////////////////////
    // Only Owner                                                   ////
    ////////////////////////////////////////////////////////////////////
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _setHellVaultAddress(address newHellVaultAddress) external onlyOwner {
        require(newHellVaultAddress != address (0), "The Hell Vault address cannot be the zero address");
        _hellVaultAddress = newHellVaultAddress;
        emit HellVaultAddressUpdated(newHellVaultAddress);
    }

    function _setExcludedFromBurnList(address excludedAddress, bool isExcluded) external onlyOwner {
        require(excludedAddress != address(0), "Cannot exclude the zero address");
        _excludedFromBurnFees[excludedAddress] = isExcluded;
        emit ExcludedFromBurnList(excludedAddress, isExcluded);
    }
    ////////////////////////////////////////////////////////////////////
    // Hell Vault Only                                              ////
    ////////////////////////////////////////////////////////////////////
    modifier onlyHellVault {
        require(msg.sender == _hellVaultAddress, "Only the Hell Vault might trigger this function");
        _;
    }

    function mintVaultRewards(uint amount) external onlyHellVault {
        require(amount > 0, "The amount cannot be 0");
        _mint(_hellVaultAddress, amount);
        emit HellVaultMint(amount);
    }
    ////////////////////////////////////////////////////////////////////
    // Events                                                       ////
    ////////////////////////////////////////////////////////////////////
    event HellVaultMint(uint amount);
    event HellVaultAddressUpdated(address newHellVaultAddress);
    event ExcludedFromBurnList(address excludedAddress, bool isExcluded);

}
