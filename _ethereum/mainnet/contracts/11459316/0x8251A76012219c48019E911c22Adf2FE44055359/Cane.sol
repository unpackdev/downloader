pragma solidity ^0.6.12;

import "./ERC20.sol";

// File: contracts/Cane.sol
contract Cane is ERC20 {

    address minter;
    uint256 tradingStartTimestamp;
    uint256 public constant maxSupply = 12500 * 1e18;

    modifier onlyMinter {
        require(msg.sender == minter, 'Only minter can call this function.');
        _;
    }

    modifier limitEarlyBuy (uint256 _amount) {
        require(tradingStartTimestamp <= block.timestamp ||
            _amount <= (5 * 1e18), "ERC20: early buys limited"
        );
        _;
    }

    constructor(address _minter, uint256 _tradingStartTimestamp) public ERC20('Hurricane Finance', 'HCANE') {
        tradingStartTimestamp = _tradingStartTimestamp;
        minter = _minter;
    }

    function mint(address account, uint256 amount) external onlyMinter {
        require(_totalSupply.add(amount) <= maxSupply, "ERC20: max supply exceeded");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override limitEarlyBuy (amount) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override limitEarlyBuy (amount) returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}
