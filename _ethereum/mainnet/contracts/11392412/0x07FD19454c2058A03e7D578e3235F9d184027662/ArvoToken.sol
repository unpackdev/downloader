// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ITerminal.sol";
import "./IARVO.sol";

contract ArvoToken is ERC20, IARVO, Ownable {
    using SafeMath for uint256;

    address public terminal;

    modifier onlyTerminalContract() {
        require(
            terminal == _msgSender(),
            "ERC20: caller is not the terminal contract"
        );
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 sypply
    ) public ERC20("Arvo", "ARVO") Ownable() {
        if (sypply > 0) {
            _mint(owner(), sypply * 10**uint256(decimals()));
        }
    }

    function changeTerminalContract(address _terminalContract)
        public
        onlyOwner
    {
        require(
            _terminalContract != address(0),
            "ERC20: caller from the zero address"
        );
        terminal = _terminalContract;
    }

    function mint(address _beneficiary, uint256 _amount)
        external
        override
        onlyTerminalContract
    {
        _mint(_beneficiary, _amount);
    }

    function burn(address _beneficiary, uint256 _amount)
        external
        override
        onlyTerminalContract
    {
        _burn(_beneficiary, _amount);
    }
}
