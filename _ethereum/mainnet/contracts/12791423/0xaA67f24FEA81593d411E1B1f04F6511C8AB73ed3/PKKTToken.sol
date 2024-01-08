// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";

contract PKKTToken is ERC20, Ownable {

    /**
     * @dev A record status of minter.
     */
    mapping (address => bool) public minters;
    mapping (address => uint256) public mintingAllowance;
    
     /**
     * @dev maximum amount can be minted.
     */
    uint256 private immutable _cap;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event MintingAllowanceUpdated(address indexed account, uint256 oldAllowance, uint256 newAllowance);

    constructor(string memory tokenName, string memory symbol, uint256 cap_) public ERC20(tokenName, symbol) {
        minters[msg.sender] = true;
        _cap = cap_;
    }
    
    function cap() public view returns(uint256) {
        return _cap;
    }

    function isMinter(address _account) public view returns(bool) {
        return minters[_account];
    }

      /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint _amount) public onlyOwner {
        _burn(msg.sender, _amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address _account, uint256 _amount) public virtual onlyOwner {
        uint256 decreasedAllowance = 
        allowance(_account, msg.sender).sub(_amount, "ERC20: burn amount exceeds allowance");
        _approve(_account, msg.sender, decreasedAllowance);
        _burn(_account, _amount);
    }
    /// @notice Creates `_amount` token to `_to`. Must only be called by the minter .
    function mint(address _to, uint256 _amount) public virtual {
        require(minters[msg.sender], "must have minter role to mint");
        require(mintingAllowance[msg.sender] >= _amount, "mint amount exceeds allowance");
        require(totalSupply().add(_amount) <= _cap, "mint amount exceeds cap");
        mintingAllowance[msg.sender] = mintingAllowance[msg.sender].sub(_amount);
        _mint(_to, _amount);
    }
    /// @notice Add `_minter` . Must only be called by the owner .
    function addMinter(address _minter,uint256 _amount) public virtual onlyOwner {
        minters[_minter] = true;
        mintingAllowance[_minter] = _amount;
        emit MinterAdded(_minter);
    }

    /// @notice Remove `_minter` . Must only be called by the owner .
    function removeMinter(address _minter) public virtual onlyOwner {
        minters[_minter] = false;
        mintingAllowance[_minter] = 0;
        emit MinterRemoved(_minter);
    }

    /// @notice Increase minting allowance for minter` . Must only be called by the owner .
    function increaseMintingAllowance(address _minter, uint256 _addedValue) public virtual onlyOwner {
        uint256 currentMintingAllowance = mintingAllowance[_minter];
        mintingAllowance[_minter] = currentMintingAllowance.add(_addedValue);
        emit MintingAllowanceUpdated(_minter, currentMintingAllowance, currentMintingAllowance.add(_addedValue));
    }

    /// @notice Decrease minting allowance for minter` . Must only be called by the owner .
    function decreaseMintingAllowance(address _minter, uint256 _subtractedValue) public virtual onlyOwner {
        uint256 currentMintingAllowance = mintingAllowance[_minter];
        mintingAllowance[_minter] = currentMintingAllowance.sub(_subtractedValue,"decreased allowance below zero");
        emit MintingAllowanceUpdated(_minter, currentMintingAllowance, currentMintingAllowance.sub(_subtractedValue));
    }

}

