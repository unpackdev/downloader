/*

#####################################
Token generated with ❤️ on 20lab.app
#####################################

*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable2Step.sol";

contract CoinFans is ERC20, ERC20Burnable, Ownable2Step {
    
    address public coinfansAddress;
    uint16 public coinfansFee;

    address public marketingAddress;
    uint16 public marketingFee;

    mapping (address => bool) public isExcludedFromFees;

    uint16 public totalFee;
 
    event coinfansAddressUpdated(address coinfansAddress);
    event coinfansFeeUpdated(uint16 coinfansFee);

    event marketingAddressUpdated(address marketingAddress);
    event marketingFeeUpdated(uint16 marketingFee);

    event ExcludeFromFees(address indexed account, bool isExcluded);
 
    constructor()
        ERC20(unicode"CoinFans", unicode"CFAN") 
    {
        address supplyRecipient = 0xBb7e43f4311E613F820Ff7d0BFEA615CF710d910;
        
        coinfansAddressSetup(0xCDD3870bf3550a2B8F11bEc899bFA4bF2b396cF1);
        coinfansFeeSetup(200);

        marketingAddressSetup(0xd0CFd8E1a4639A84fD6912Bc8Ac1011999CaC89F);
        marketingFeeSetup(300);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _mint(supplyRecipient, 1000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xBb7e43f4311E613F820Ff7d0BFEA615CF710d910);
    }
    
    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function _sendInTokens(address from, address to, uint256 amount) private {
        super._transfer(from, to, amount);
    }

    function coinfansAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesClassic: Wallet tax recipient cannot be a 0x0 address");
        coinfansAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit coinfansAddressUpdated(_newAddress);
    }

    function coinfansFeeSetup(uint16 _newFee) public onlyOwner {
        totalFee = totalFee - coinfansFee + _newFee;
        require(totalFee <= 2500, "TaxesClassic: Cannot exceed max total fee of 25%");

        coinfansFee = _newFee;
            
        emit coinfansFeeUpdated(_newFee);
    }

    function marketingAddressSetup(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "TaxesClassic: Wallet tax recipient cannot be a 0x0 address");
        marketingAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit marketingAddressUpdated(_newAddress);
    }

    function marketingFeeSetup(uint16 _newFee) public onlyOwner {
        totalFee = totalFee - marketingFee + _newFee;
        require(totalFee <= 2500, "TaxesClassic: Cannot exceed max total fee of 25%");

        marketingFee = _newFee;
            
        emit marketingFeeUpdated(_newFee);
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
        
        emit ExcludeFromFees(account, isExcluded);
    }

    function _takeFees(address from, uint256 amount) private returns (uint256) {
        
        uint256 coinfansTokens = amount * coinfansFee / 10000;
        if (coinfansTokens > 0) _sendInTokens(from, coinfansAddress, coinfansTokens);

        uint256 marketingTokens = amount * marketingFee / 10000;
        if (marketingTokens > 0) _sendInTokens(from, marketingAddress, marketingTokens);

        return amount - coinfansTokens - marketingTokens;
    }
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount > 0 && !isExcludedFromFees[from] && !isExcludedFromFees[to])
            amount = _takeFees(from, amount);
        
        super._transfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}
