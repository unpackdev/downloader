// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract WDoge is Initializable, ERC20Upgradeable, OwnableUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  /**
   * @param dogeLockTxId Dogecoin tx id of the lock tx that this mint corresponds to.
   */
  event Minted(bytes32 dogeLockTxId);

  /**
   * The total supply cannot exceed 10 million tokens.
   */
  error MintLimitExceeded();

  function initialize(address tokenAdmin) external initializer {
    // Contract initialization
    __ERC20_init("Wrapped Dogecoin", "WDOGE");
    __Ownable_init();

    // Must happen after initialization.
    _transferOwnership(tokenAdmin);
  }

  /**
   * @notice Allows the token owner to mint wDoges to process a dogecoin lock tx.
   * @param amount Quantity of tokens to mint.
   * @param dogeLockTxId Dogecoin tx id of the lock tx that this mint corresponds to.
   */
  function mint(uint256 amount, bytes32 dogeLockTxId) public onlyOwner {
    // We limit the total supply to 10 million tokens
    // 10M tokens = 10e7 tokens = 10e7 * (10 ** decimals) indivisible token units
    uint256 maxTotalSupply = 10**(7 + decimals());
    if (amount + totalSupply() > maxTotalSupply) revert MintLimitExceeded();
    _mint(owner(), amount);
    emit Minted(dogeLockTxId);
  }


  /**
   * @notice Allows the token owner to burn wDoges to process a dogecoin unlock tx.
   * @param amount Quantity of tokens to mint.
   */
  function burn(uint256 amount) public onlyOwner {
    _burn(owner(), amount);
  }

  /**
   * @dev Returns the number of decimals used to get its human representation.
   * Dogecoin has 8 decimals so that's what we use here too.
   */
  function decimals() public pure virtual override returns (uint8) {
    return 8;
  }

  function getVersion() external pure returns (uint256) {
    return 1;
  }
}
