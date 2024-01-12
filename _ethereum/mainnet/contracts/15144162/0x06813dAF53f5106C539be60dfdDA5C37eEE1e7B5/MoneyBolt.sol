// SPDX-License-Identifier: MIT

// LIBRARIES
pragma solidity ^0.8.14;

import "ERC20.sol";
import "ERC20Snapshot.sol";
import "Ownable.sol";
import "Pausable.sol";
import "SafeCast.sol";

// CREATE CONTRACT AND VARIABLES
contract MoneyBolt is ERC20, ERC20Snapshot, Ownable, Pausable {
    using SafeCast for uint256;
    using SafeCast for int256;
    bool is_taxed;
    uint256 tax_fee = 1;
    uint256 dividend = 100; // set dividend to 100 for int tax, set to 1000 for decimal tax (0.4 example)
    address wallet_fees = address(0x754a7fB1123d7aE650e1597Fe92Ae74C01862Ee5);
    address[] public excludedFromFees;

    constructor() ERC20("MoneyBolt", "BYT") {
        _mint(msg.sender, 1000000000 * 10**decimals());
        excludedFromFees.push(msg.sender);
    }

    // MODIFIED TRANSFER FUNCTIONS WITH INTERNAL FEES
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        is_taxed = is_in_excludedFromFees(owner);
        if (is_taxed) {
            uint256 perc = (amount * tax_fee) / dividend;
            amount = amount - perc;
            _transfer(owner, to, amount);
            _transfer(owner, wallet_fees, perc);
        } else {
            _transfer(owner, to, amount);
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        is_taxed = is_in_excludedFromFees(spender);
        if (is_taxed) {
            uint256 perc = (amount * tax_fee) / dividend;
            amount = amount - perc;
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
            _transfer(from, wallet_fees, perc);
        } else {
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
        }
        return true;
    }

    // ADD ADDRESS TO THE LIST 'excludedFromFees'
    function add_excludedFromFees(address privilege) public onlyOwner {
        //WARNING, only add function, can't remove
        excludedFromFees.push(privilege);
    }

    // REMOVE ADDRESS FROM THE LIST 'excludedFromFees'
    function remove_excludedFromFees(uint256 index) public onlyOwner {
        require(excludedFromFees.length > index, "Out of bounds");
        // move all elements to the left, starting from the `index + 1`
        for (uint256 i = index; i < excludedFromFees.length - 1; i++) {
            excludedFromFees[i] = excludedFromFees[i + 1];
        }
        excludedFromFees.pop(); // delete the last item
    }

    // CHECK IF AN ADDRESS IS IN THE 'exludedFromFees' LIST
    function is_in_excludedFromFees(address control)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < excludedFromFees.length; i++) {
            if (excludedFromFees[i] == control) {
                return false;
            }
        }
        return true;
    }

    //RETURN IN OUTPUT ALL THE LIST
    function list_excludedFromFees() public view returns (address[] memory) {
        return excludedFromFees;
    }

    // FUNCTION TO CHANGE THE WALLET ADDRESS THAT CONTAIN FEES
    function change_walletFees(address substitute) public onlyOwner {
        wallet_fees = substitute;
    }

    // FUNCTION TO VIEW THE ACTUAL FEES WALLET
    function view_walletFees() public view returns (address) {
        return (wallet_fees);
    }

    // FUNCTION TO MODIFY INTERNAL TAX
    function modify_tax(uint256 tax, uint256 _dividend) public onlyOwner {
        tax_fee = tax;
        dividend = _dividend;
    }

    // FUNCTION TO VIEW INTERNAL TAX
    function view_tax() public view returns (uint256, uint256) {
        return (tax_fee, dividend);
    }

    // ERC20 SNAPSHOT FUNCTION
    function snapshot() public onlyOwner {
        _snapshot();
    }

    // ERC20 PAUSE FUNCTION
    function pause() public onlyOwner {
        _pause();
    }

    // ERC20 UNPAUSE FUNCTION
    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Snapshot) whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
