// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IARVO.sol";

contract ArvoToken is ERC20, IARVO, Ownable {
    using SafeMath for uint256;

    address public terminal;

    /**
     * modifier to check the terminal smart contract address
     */
    modifier onlyTerminalContract() {
        require(
            terminal == _msgSender(),
            "ERC20: caller is not the terminal contract"
        );
        _;
    }

    /**
     * modifier to check the terminal smart contract address
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 sypply
    ) public ERC20(name, symbol) Ownable() {
        if (sypply > 0) {
            _mint(owner(), sypply * 10**uint256(decimals()));
        }
    }

    /**
     * this function will change the terminal contract incase of any emergency until the ownership transferred to the governance which is nodes smart contract
     */
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

    /** 
     * Creates `amount` tokens and assigns them to `Terminal Smart Contract`, increasing
     * the total supply.
     * This function will be used to mint only rewards per blocks with maximum supply of the governance decision.
     * default maximum supply is [20000 ARVO]
     */
    function mint(address _beneficiary, uint256 _amount)
        external
        override
        onlyTerminalContract
    {
        _mint(_beneficiary, _amount);
    }

    /**
     * Burn function will burn arvo when the stablecoin returns be used to buy Arvo from Uniswap and burn through this function
     */
    function burn(address _beneficiary, uint256 _amount)
        external
        override
        onlyTerminalContract
    {
        _burn(_beneficiary, _amount);
    }
}
