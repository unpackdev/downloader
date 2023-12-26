// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./InfluenceRoles.sol";

/**
 * @dev ERC20 token
 */
contract SwayToken is Context, AccessControl, ERC20 {
  uint256 public constant INITIAL_SUPPLY = 97_500_000_000; // Without decimals
  uint256 public constant LAUNCH_SUPPLY = 32_500_000_000; // Without decimals
  uint64 public constant RECORDING_PERIOD = 1_000_000; // in seconds
  uint8 public constant DECIMALS = 6;

  bool public launched = false;
  mapping (uint256 => uint256) private _periodVolumes;

  event Launch(address indexed admin, uint256 indexed launchSupply);

  /**
    * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract and mints initial supply
    */
  constructor() ERC20("Standard Weighted Adalian Yield", "SWAY") {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(InfluenceRoles.TRANSFERRER_ROLE, _msgSender());

    uint256 initialSupply = INITIAL_SUPPLY * (10 ** uint256(DECIMALS));
    _mint(_msgSender(), initialSupply);
  }

  function currentPeriod() public view returns (uint256) {
    return block.timestamp / RECORDING_PERIOD;
  }

  /**
   * @dev Overrides the default # of decimals
   */
  function decimals() public pure override returns (uint8) {
    return DECIMALS;
  }

  /**
    * @dev Allows for unrestricted transfers and switches transfer volume recording
    */
  function launch() external {
    require(!launched, "SwayToken: token already launched");
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "SwayToken: must be admin to launch");

    uint256 launchSupply = LAUNCH_SUPPLY * (10 ** uint256(DECIMALS));
    _mint(_msgSender(), launchSupply);
    launched = true;

    emit Launch(_msgSender(), launchSupply);
  }

  /**
    * @dev Creates new tokens and transfers them. The caller must have the `GOVERNOR_ROLE`.
    * @param to The address to send new tokens to
    * @param amount The total number of new tokens to send (accounting for decimals)
    */
  function mint(address to, uint256 amount) public {
    require(hasRole(InfluenceRoles.GOVERNOR_ROLE, _msgSender()), "SwayToken: must have governor role to mint");
    _mint(to, amount);
  }

  /**
   * @dev Returns the volume for a given period only after the period has completed
   */
  function periodVolume(uint256 period) public view returns (uint256 volume) {
    require(period < currentPeriod(), "SwayToken: volume for period not yet final");
    return _periodVolumes[period];
  }

  /**
   * @dev After launch, records the transfer volumes for later use in calculating velocity
   * @param amount Amount of SWAY
   */
  function _afterTokenTransfer(address, address, uint256 amount) internal override {
    if (launched) {
      uint256 period = currentPeriod();
      _periodVolumes[period] += amount;
    }
  }

  /**
    * @dev Allows transfers only after launch OR from a caller with the TRANSFERRER_ROLE
    * @param from Address sending SWAY
    * @param to Address receiving SWAY
    * @param amount Amount of SWAY
    */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    super._beforeTokenTransfer(from, to, amount);
    require(launched || hasRole(InfluenceRoles.TRANSFERRER_ROLE, _msgSender()), "SwayToken: token transfer before launch");
  }
}
