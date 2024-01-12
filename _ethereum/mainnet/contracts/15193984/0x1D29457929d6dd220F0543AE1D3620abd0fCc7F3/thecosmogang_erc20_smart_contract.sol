// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Ownable.sol";
import "./ERC20.sol";


contract Cosmog is ERC20, Ownable {
    uint public basis;

    constructor() ERC20("COSMOG", "CSMG")
    {
        basis = 10**uint(decimals());
        // Minting enough tokens for every holders (10k) staking
        // And earning 5 $COSMOG every day, for 1 year
        _mint(address(this), 10000 * 5 * 365 * basis);
    }


    // Function to alow another address to transfer illimited funds  on our behalf 
    // Out of the the Cosmo contract balance
    function setContractAllowance(address spender)
        external onlyOwner
    {
        // Need to encapsulate the contract in ERC20() so that it makes an EXTERNAL call
        // So that this ERC20 contract itself approve the spender, and not the msg.sender of this function
        ERC20(address(this)).approve(spender, 2**256-1);
    }

    // Function to alow another contract to transfer illimited funds  on our behalf 
    // Out of the msg.sender balance
    function setFullAllowance(address spender)
        external
    {
        approve(spender, 2**256-1);
    }

    function mint(uint256 amount)
        public payable onlyOwner
    {
        _mint(msg.sender, amount * basis);
    }

    function getTokens(address fromAddress, uint amount)
        public payable onlyOwner
    {
        transferFrom(fromAddress, msg.sender, amount * basis);
    }

    function sendTokens(address toAddress, uint amount)
        public payable onlyOwner
    {
        transferFrom(address(this), toAddress, amount * basis);
    }

    function getContractAddress()
        public view
        returns (address)
    {
        return address(this);
    }

    function getBalance()
        public view
        returns (uint256)
    {
        return address(this).balance;
    }
}