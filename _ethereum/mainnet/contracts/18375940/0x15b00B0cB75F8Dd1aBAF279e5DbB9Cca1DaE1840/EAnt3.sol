// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

contract EAnt3 is ERC20Upgradeable, OwnableUpgradeable {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _taxFee;
    address private _teamAddress;
    mapping(address => bool) private _isExcludedFromFee;

    function initialize(
        string memory _NAME,
        string memory _SYMBOL,
        uint8 _DECIMALS,
        uint256 totalSupply,
        uint256 taxFee
    ) public initializer {
        __Ownable_init();
        __ERC20_init(_NAME, _SYMBOL);
        _name = _NAME;
        _symbol = _SYMBOL;
        _decimals = _DECIMALS;
        totalSupply = totalSupply * 10 ** _decimals;
        _taxFee = taxFee;
        _teamAddress = 0x3ea2d29A2B41722979EdE1F01C5B9058005088AE;
        _isExcludedFromFee[owner()] = true;
        _mint(owner(), totalSupply);
    }

    receive() external payable {}

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function getTaxFee() public view returns (uint256) {
        return _taxFee;
    }

    function setTaxFee(uint256 _newTaxFee) external onlyOwner {
        _taxFee = _newTaxFee;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (_isExcludedFromFee[msg.sender] || _isExcludedFromFee[recipient]) {
            super.transfer(recipient, amount);
        } else {
            uint256 feeAmt = _calculateFeesAmt(amount);
            _transferFeesToTeam(feeAmt);
            uint256 newAmt = amount - feeAmt;
            super.transfer(recipient, newAmt);
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            super.transferFrom(from, to, amount);
        } else {
            uint256 feeAmt = _calculateFeesAmt(amount);
            _transferFromFeesToTeam(from, feeAmt);
            uint256 newAmt = amount - feeAmt;
            super.transferFrom(from, to, newAmt);
        }
        return true;
    }

    function _calculateFeesAmt(uint256 amount) private view returns (uint256) {
        uint256 feeAmt = (amount * _taxFee) / 100;
        return feeAmt;
    }

    function _transferFeesToTeam(uint256 amount) private {
        super.transfer(_teamAddress, amount);
    }

    function _transferFromFeesToTeam(address from, uint256 amount) private {
        super.transferFrom(from, _teamAddress, amount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function version() public pure returns (string memory) {
        return "1.0";
    }
}
