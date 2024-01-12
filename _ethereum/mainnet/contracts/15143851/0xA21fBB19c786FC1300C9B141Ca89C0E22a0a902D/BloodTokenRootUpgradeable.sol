pragma solidity 0.6.6;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PausableUpgradeable.sol";
import "./IMintableERC20.sol";
import "./AccessControlMixinUpgradeable.sol";
import "./NativeMetaTransactionUpgradeable.sol";
import "./ContextMixinUpgradeable.sol";


contract BloodTokenRootUpgradeable is ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, AccessControlMixinUpgradeable, NativeMetaTransactionUpgradeable, ContextMixinUpgradeable, IMintableERC20 {

    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    uint256 public transferTax;
    address public taxWallet;
    mapping(address => bool) public exemptedFromTaxSenders;
    mapping(address => bool) public exemptedFromTaxRecipients;

    function __BloodTokenRoot_init(
        string memory name_,
        string memory symbol_
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Pausable_init();
        _setupContractId("BloodTokenRootUpgradeable");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());
        _initializeEIP712(name_);
    }

    function mint(address user, uint256 amount) external override only(PREDICATE_ROLE) {
        _mint(user, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20Upgradeable, IERC20Upgradeable) returns (bool) {
        uint256 amountAfterTax = _calculateTransferAmountAndProcessTax(sender, recipient, amount);
        return ERC20Upgradeable.transferFrom(sender, recipient, amountAfterTax);
    }

    function transfer(address recipient, uint256 amount) public override(ERC20Upgradeable, IERC20Upgradeable) returns (bool) {
        uint256 amountAfterTax = _calculateTransferAmountAndProcessTax(_msgSender(), recipient, amount);
        return ERC20Upgradeable.transfer(recipient, amountAfterTax);
    }

    function setTransferTax(uint256 newTransferTax_) external only(DEFAULT_ADMIN_ROLE) {
        require(newTransferTax_ <= 100, "Tax too high");
        transferTax = newTransferTax_;
    }

    function setTaxWallet(address newTaxWallet_) external only(DEFAULT_ADMIN_ROLE) {
        taxWallet = newTaxWallet_;
    }

    function setExemptedFromTaxSenders(
        address[] calldata addresses_,
        bool[] calldata exemptions_
    ) external only(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses_.length; ++i) {
            exemptedFromTaxSenders[addresses_[i]] = exemptions_[i];
        }
    }

    function setExemptedFromTaxRecipients(
        address[] calldata addresses_,
        bool[] calldata exemptions_
    ) external only(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses_.length; ++i) {
            exemptedFromTaxRecipients[addresses_[i]] = exemptions_[i];
        }
    }

    function pause() public only(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public only(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20PausableUpgradeable, ERC20Upgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _msgSender() internal override view returns (address payable sender) {
        return ContextMixinUpgradeable.msgSender();
    }

    function _calculateTransferAmountAndProcessTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if (exemptedFromTaxSenders[sender] || exemptedFromTaxRecipients[recipient] || transferTax == 0) {
            return amount;
        }
        uint256 taxAmount = amount * transferTax / 100;
        ERC20Upgradeable._transfer(sender, taxWallet, taxAmount);
        return amount - taxAmount;
    }
}
