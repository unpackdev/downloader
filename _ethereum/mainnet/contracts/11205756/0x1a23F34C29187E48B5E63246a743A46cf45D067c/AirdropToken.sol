// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.4;

import "./ERC20.sol";

import "./IJDFIStakingPool.sol";

contract AirdropToken is ERC20 {
  address private immutable _deployer;
  address private _jdfiStakingPool;

  constructor () ERC20('JusDeFi Airdrop', 'JDFI/A') {
    _deployer = msg.sender;
    _mint(msg.sender, 10020 ether);
  }

  /**
   * @notice set the JDFIStakingPool address once it is deployed
   * @param jdfiStakingPool JDFIStakingPool address
   */
  function setJDFIStakingPool (address jdfiStakingPool) external {
    require(msg.sender == _deployer, 'JusDeFi: sender must be deployer');
    require(_jdfiStakingPool == address(0), 'JusDeFi: JDFI Staking Pool contract has already been set');
    _jdfiStakingPool = jdfiStakingPool;
  }

  /**
   * @notice airdrop tokens to given accounts in given quantities
   * @dev _mint and _burn are used in place of _transfer due to gas considerations
   * @param accounts airdrop recipients
   * @param amounts airdrop quantities
   */
  function airdrop (address[] calldata accounts, uint[] calldata amounts) external {
    require(accounts.length == amounts.length, 'JusDeFi: array lengths do not match');

    uint length = accounts.length;
    uint initialSupply = totalSupply();

    for (uint i; i < length; i++) {
      _mint(accounts[i], amounts[i]);
    }

    _burn(msg.sender, totalSupply() - initialSupply);
  }

  /**
   * @notice exchange tokens for locked JDFI/S
   * @dev JDFI/S is locked in JDFIStakingPool _beforeTokenTransfer hook
   */
  function exchange () external {
    uint amount = balanceOf(msg.sender);
    _burn(msg.sender, amount);
    IJDFIStakingPool(_jdfiStakingPool).stake(amount);
    IJDFIStakingPool(_jdfiStakingPool).transfer(msg.sender, amount);
  }
}
