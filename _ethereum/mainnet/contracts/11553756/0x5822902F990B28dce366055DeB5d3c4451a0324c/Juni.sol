pragma solidity ^0.5.0;

import "./ERC20Capped.sol";
import "./ERC20Detailed.sol";
import "./Pausable.sol";
import "./Ownable.sol";


contract Juni is ERC20Capped, ERC20Detailed, Pausable, Ownable {

	string public _name = "Juni";
	string public _symbol = "JUNI";
	uint8 public _decimals = 18;
	uint256 private _initialSupply = 1192258185; // 1,192,258,185 all tokens will be minted at genesis

    uint256 _cap = 1192258185 * (10 ** uint256(_decimals)); // hard cap of 1,192,258,185

    event Checkpoint(uint256 data);

	constructor() ERC20Capped(_cap) ERC20Detailed(_name, _symbol, _decimals) public {
		_mint(msg.sender, _initialSupply * (10 ** uint256(decimals())));
	}

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }	

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function checkpoint(uint256 checkpointData) public {
        emit Checkpoint(checkpointData);
    }

}


