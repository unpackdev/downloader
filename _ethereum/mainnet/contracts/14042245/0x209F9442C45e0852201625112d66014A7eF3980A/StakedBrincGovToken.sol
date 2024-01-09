// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";

interface IBrincStaking {
  function totalRewards(address _user) external view returns (uint256);
}

contract StakedBrincGovToken is ERC20, ERC20Burnable, Ownable {
  using SafeMath for uint256;

  mapping(address => bool) public isMinter;
  IBrincStaking public staking;

  event Mint(address _to, uint256 amount);
  event Burn(address _from, uint256 amount);
  event StakingUpdated(address _staking);
  event SetMinter(address _minter, bool _isMinter);

  constructor() public ERC20("StakedBrincGovToken", "sgBRC") {
    isMinter[msg.sender] = true;
  }

  modifier onlyMinter {
    require(isMinter[msg.sender], "onlyMinter: only minter can call this operation");
    _;
  }

  /**
   * @dev mint will create specified number of tokens to specified address.
   * only a minter will be able to call this method.
   *
   * @param _to address to mint tokens to
   * @param _amount amount of tokens to mint
   * 
   */
  /// #if_succeeds {:msg "mint: The sender must be Minter"}
    /// isMinter[msg.sender] == true;
  /// #if_succeeds {:msg "mint: balance of receiving address is correct after mint"}
    /// this.balanceOf(_to) == old(this.balanceOf(_to) + _amount);
  function mint(address _to, uint256 _amount) public onlyMinter {
    _mint(_to, _amount);
    emit Mint(_to, _amount);
  }

  /**
   * @dev setStaking will set the address of the staking contract.
   * only the owner will be able to call this method.
   *
   * @param _staking address of the staking contract
   * 
   */
  /// #if_succeeds {:msg "setStaking: The sender must be owner"}
    /// old(msg.sender == this.owner());
  function setStaking(IBrincStaking _staking) public onlyOwner {
    staking = _staking;
    emit StakingUpdated(address(_staking));
  }

  /**
   * @dev setMinter will set and allow the specified address to mint sgBRC tokens.
   * only the owner will be able to call this method.
   * changing _isMinter to false will revoke minting privileges.
   *
   * @param _address address of minter
   * @param _isMinter bool access
   * 
   */
  /// #if_succeeds {:msg "setMinter: The sender must be owner"}
    /// old(msg.sender == this.owner());
  function setMinter(address _minter, bool _isMinter) public onlyOwner {
    require(_minter != address(0), "invalid minter address");
    isMinter[_minter] = _isMinter;
    emit SetMinter(_minter, _isMinter);
  }

  /**
   * @dev balanceOf is the override method that will show the number of staked tokens + totalrewards.
   * the new balanceOf will relect the total sgBRC balance, which will include any accured award that may not have been minted to gBRC yet.
   *
   * @return balanceOf(address)
   */
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(address(staking) != address(0x0), "staking contract not set");
    return super.balanceOf(owner).add(staking.totalRewards(owner));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256
  ) internal override {
    require(from == address(0x0) || to == address(0x0), "Transfer not allowed between accounts");
  }
}
