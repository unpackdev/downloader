// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20Taxable.sol";
import "./BlackList.sol";
import "./Pausable.sol";
import "./Initializable.sol";
import "./Ownable.sol";

contract TaxableToken is Initializable, ERC20Taxable, Pausable, Ownable, BlackList {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        uint256 _maxSupply,
        uint256 _taxFeePerMille,
        address _taxAddress
    ) external initializer {
        _transferOwnership(_owner);
        ERC20.init(
            _name,
            _symbol,
            _decimals,
            _maxSupply == type(uint256).max ? type(uint256).max : _maxSupply * 10 ** _decimals
        );
        ERC20Taxable.init(_taxFeePerMille, _taxAddress);
        _mint(_owner, _initialSupply * 10 ** _decimals);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function blockAccount(address _account) public onlyOwner {
        _blockAccount(_account);
    }

    function unblockAccount(address _account) public onlyOwner {
        _unblockAccount(_account);
    }

    function setTaxRate(uint256 _newTaxFee) public onlyOwner {
        _setTaxRate(_newTaxFee);
    }

    function setTaxAddress(address _newTaxAddress) public onlyOwner {
        _setTaxAddress(_newTaxAddress);
    }

    function setExclusionFromTaxFee(address _account, bool _status) public onlyOwner {
        _setExclusionFromTaxFee(_account, _status);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        require(!isAccountBlocked(to), "BlackList: Recipient account is blocked");
        require(!isAccountBlocked(from), "BlackList: Sender account is blocked");

        super._beforeTokenTransfer(from, to, amount);
    }
}
