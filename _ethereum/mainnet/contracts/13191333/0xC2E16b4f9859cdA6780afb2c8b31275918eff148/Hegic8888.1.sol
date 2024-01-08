// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

import "./Initializable.sol";

import "./Versioned.sol";
import "./Pausable.sol";
import "./HegicFacade.8888.sol";
import "./HegicOptionsManager.8888.sol";
import "./Adapter.sol";

//
//   ___ _ __ _ __ ___  _ __ ___
//  / _ \ '__| '__/ _ \| '__/ __|
// |  __/ |  | | | (_) | |  \__ \
//  \___|_|  |_|  \___/|_|  |___/
//
// Hegic8888AdapterV1_1  => Invalid data length received
// Hegic8888AdapterV1_2  => Expected only one currency
// Hegic8888AdapterV1_3  => Expected only one amount
// Hegic8888AdapterV1_4  => Not enough paid to purchase option

/// @title Hegic8888AdapterV1
/// @author Iulian Rotaru
/// @notice Adapter to purchase Hegic ETH or WBTC options
contract Hegic8888AdapterV1 is Versioned, Pausable, Adapter {
  //
  //      _        _
  //  ___| |_ __ _| |_ ___
  // / __| __/ _` | __/ _ \
  // \__ \ || (_| | ||  __/
  // |___/\__\__,_|\__\___|
  //

  HegicFacadeV8888 public facade;
  HegicOptionsManagerV8888 public optionsManager;

  //
  //  _       _                        _
  // (_)_ __ | |_ ___ _ __ _ __   __ _| |___
  // | | '_ \| __/ _ \ '__| '_ \ / _` | / __|
  // | | | | | ||  __/ |  | | | | (_| | \__ \
  // |_|_| |_|\__\___|_|  |_| |_|\__,_|_|___/
  //

  /// @dev Perform an option purchase
  /// @param caller Address purchasing the option
  /// @param currencies List of usable currencies
  /// @param amounts List of usable currencies amounts
  /// @param data Extra data usable by adapter
  /// @return _a A tuple containing used amounts and output data
  function purchase(
    address caller,
    address[] memory currencies,
    uint256[] memory amounts,
    bytes calldata data
  ) internal override returns (uint256[] memory, bytes memory) {
    require(data.length == 128, 'Hegic8888AdapterV1_1');
    require(currencies.length == 1, 'Hegic8888AdapterV1_2');
    require(amounts.length == 1, 'Hegic8888AdapterV1_3');
    uint256 _price;
    uint256 _tokenId;
    {
      address _pool;

      uint256[] memory _parameters = new uint256[](3);
      // uint256 _period;
      // uint256 _amount;
      // uint256 _strike;

      (_pool, _parameters[0], _parameters[1], _parameters[2]) = abi.decode(data, (address, uint256, uint256, uint256));

      (_price, , , ) = facade.getOptionPrice(_pool, _parameters[0], _parameters[1], _parameters[2], currencies);

      require(_price <= amounts[0], 'Hegic8888AdapterV1_4');

      IERC20(currencies[0]).approve(address(facade), _price);

      _tokenId = optionsManager.nextTokenId();
      facade.createOption(_pool, _parameters[0], _parameters[1], _parameters[2], currencies, _price);
      optionsManager.safeTransferFrom(address(this), caller, _tokenId);

      uint256 balance = IERC20(currencies[0]).balanceOf(address(this));

      if (balance > 0) {
        IERC20(currencies[0]).transfer(caller, balance);
      }
    }

    uint256[] memory usedAmount = new uint256[](1);
    usedAmount[0] = _price;

    return (usedAmount, abi.encode(_tokenId));
  }

  //
  //            _                        _
  //   _____  _| |_ ___ _ __ _ __   __ _| |___
  //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
  // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
  //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
  //

  // solhint-disable-next-line
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external returns (bytes4) {
    return Hegic8888AdapterV1.onERC721Received.selector;
  }

  /// @dev Retrieve adapter name
  /// @return Adapter name
  function name() external pure override returns (string memory) {
    return 'Hegic8888V1';
  }

  //
  //  _       _ _
  // (_)_ __ (_) |_
  // | | '_ \| | __|
  // | | | | | | |_
  // |_|_| |_|_|\__|
  //

  // solhint-disable-next-line
  function __Hegic8888AdapterV1__constructor(
    address _gateway,
    address _facade,
    address _optionsManager
  ) public initVersion(1) {
    facade = HegicFacadeV8888(_facade);
    optionsManager = HegicOptionsManagerV8888(_optionsManager);
    setGateway(_gateway);
  }
}
