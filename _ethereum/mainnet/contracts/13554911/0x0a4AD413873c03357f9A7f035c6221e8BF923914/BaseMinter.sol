// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./IBridgeReserve.sol";
import "./IArtBridge.sol";
import "./BridgeContext.sol";

///
///
/// ██████╗  █████╗ ███████╗███████╗
/// ██╔══██╗██╔══██╗██╔════╝██╔════╝
/// ██████╔╝███████║███████╗█████╗
/// ██╔══██╗██╔══██║╚════██║██╔══╝
/// ██████╔╝██║  ██║███████║███████╗
/// ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
///
/// ███╗   ███╗██╗███╗   ██╗████████╗███████╗██████╗
/// ████╗ ████║██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
/// ██╔████╔██║██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
/// ██║╚██╔╝██║██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
/// ██║ ╚═╝ ██║██║██║ ╚████║   ██║   ███████╗██║  ██║
/// ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
///
/// @title Base Minter
/// @author artbridge.eth
/// @notice Provide project validated minting interface
contract BaseMinter is BridgeContext {
  IArtBridge public immutable bridge;
  IBridgeReserve public immutable reserve;

  /// @dev financial checks are not enforced, deferred to minter implementation
  /// @notice ensures attempted mint is for a valid project
  /// @param _id target bridge project id
  /// @param _amount number of tokens to mint
  modifier onlyValidMint(uint256 _id, uint256 _amount) {
    require(_id < bridge.nextProjectId(), "!registered");
    require(bridge.minters(address(this)), "!minter");
    require(reserve.projectToMinters(_id, address(this)), "!minter");
    BridgeBeams.ReserveParameters memory params = reserve.projectToParameters(
      _id
    );
    require(_amount <= params.maxMintPerInvocation, "exceed mint max");
    _;
  }

  /// @param _bridge art bridge deployment address
  /// @param _reserve bridge reserve deployment address
  constructor(address _bridge, address _reserve) {
    bridge = IArtBridge(_bridge);
    reserve = IBridgeReserve(_reserve);
  }

  /// @dev extensions of base minter can override mint for custom pricing
  /// @dev base minter provides single price validation
  /// @notice mints the requested amount of project tokens
  /// @param _id target bridge project id
  /// @param _amount number of tokens to mint
  /// @param _to address to mint tokens to
  function mint(
    uint256 _id,
    uint256 _amount,
    address _to
  ) external payable virtual onlyValidMint(_id, _amount) {
    require(
      _amount * bridge.projectToTokenPrice(_id) == msg.value,
      "invalid payment amount"
    );
    bridge.mint(_id, _amount, _to);
  }
}
