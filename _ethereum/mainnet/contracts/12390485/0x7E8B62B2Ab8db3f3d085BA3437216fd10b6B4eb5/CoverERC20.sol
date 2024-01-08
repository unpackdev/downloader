// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./ERC20Permit.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./ICoverERC20.sol";

/**
 * @title CoverERC20 implements {ERC20} standards with expended features for COVER
 * @author crypto-pumpkin
 *
 * COVER's covToken Features:
 *  - Has mint and burn by owner (Cover contract) only feature.
 *  - No limit on the totalSupply.
 *  - Should only be created from Cover contract. See {Cover}
 *
 * Symbol example:
 *  C_FUT0_Yearn_0_DAI_12_31_20
 *  C_3Crv_Yearn_0_DAI_12_31_20
 *  C_yCRV_Yearn_0_DAI_12_31_20
 *  NC_Yearn_0_DAI_12_31_20
 */
contract CoverERC20 is ICoverERC20, ERC20Permit, Ownable {

  /// @notice Initialize, called once
  function initialize (string calldata _name, string calldata _symbol, uint8 _decimals) external initializer {
    initializeOwner();
    initializeERC20(_name, _symbol, _decimals);
    initializeERC20Permit(_name);
  }

  /// @notice COVER specific function
  function mint(address _account, uint256 _amount) external override onlyOwner returns (bool) {
    _mint(_account, _amount);
    return true;
  }

  /// @notice COVER specific function
  function burnByCover(address _account, uint256 _amount) external override onlyOwner returns (bool) {
    _burn(_account, _amount);
    return true;
  }

  // to support permit
  function getChainId() external view returns (uint256 chainId) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }
  }
}
