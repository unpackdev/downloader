//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract SQGToken is ERC20, Ownable {
    address public devAddress = 0x6f9F7a2dCa99FBaeC83332de3Be1A2173906B3cA;
    address public marketingAddress = 0x9Bd8D2B03123360fb30E70b4eA159F1251db8066;
    address public diamondHolderPoolAddress = 0x049860B04176594D72E7C8A4FCb449369e1d66b7;
    mapping(address => bool) private _noTax;
    
    uint256 public taxDiamondHolder = 40;
    uint256 public taxMarketing = 30;
    uint256 public taxBurn = 30;

    constructor() ERC20("SquidGame", "SQG") {
        _mint(msg.sender, 93000000000 ether);
        _mint(devAddress, 2000000000 ether);
        _mint(marketingAddress, 5000000000 ether);
        _noTax[msg.sender] = true;
        _noTax[devAddress] = true;
        _noTax[marketingAddress] = true;
        _noTax[diamondHolderPoolAddress] = true;
    }

    function _transferWithTax(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        // calculate tax amount
        uint256 transferAmount = amount;

        if (!_noTax[sender] && !_noTax[recipient]){
            uint256 taxDiamondHolderAmount = amount*taxDiamondHolder/1000;
            uint256 taxMarketingAmount = amount*taxMarketing/1000;
            uint256 taxBurnAmount = amount*taxBurn/1000;
            transferAmount = amount - taxDiamondHolderAmount - taxMarketingAmount - taxBurnAmount;

            // transfer tax
            _transfer(sender, diamondHolderPoolAddress, taxDiamondHolderAmount);
            _transfer(sender, marketingAddress, taxMarketingAmount);
            _burn(sender, taxBurnAmount);
        }

        // transfer token
        _transfer(sender, recipient, transferAmount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferWithTax(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transferWithTax(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function setDevAddress(address _devAddress) public onlyOwner {
        devAddress = _devAddress;
    }

    function setMarketingAddress(address _marketingAddress) public onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setDiamondHolderPoolAddress(address _diamondHolderPoolAddress) public onlyOwner {
        diamondHolderPoolAddress = _diamondHolderPoolAddress;
    }

    function setTaxDiamondHolder(uint256 _taxDiamondHolder) public onlyOwner {
        taxDiamondHolder = _taxDiamondHolder;
    }

    function setTaxMarketing(uint256 _taxMarketing) public onlyOwner {
        taxMarketing = _taxMarketing;
    }

    function setTaxBurn(uint256 _taxBurn) public onlyOwner {
        taxBurn = _taxBurn;
    }
}