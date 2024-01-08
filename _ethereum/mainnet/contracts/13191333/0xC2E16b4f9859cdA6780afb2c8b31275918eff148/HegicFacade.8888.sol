// SPDX-License-Identifier: MIT
//  ______   ______     _____
// /\__  _\ /\  == \   /\  __-.
// \/_/\ \/ \ \  __<   \ \ \/\ \
//    \ \_\  \ \_____\  \ \____-
//     \/_/   \/_____/   \/____/
//
pragma solidity 0.8.6;

interface HegicFacadeV8888 {
  //
  //            _                        _
  //   _____  _| |_ ___ _ __ _ __   __ _| |___
  //  / _ \ \/ / __/ _ \ '__| '_ \ / _` | / __|
  // |  __/>  <| ||  __/ |  | | | | (_| | \__ \
  //  \___/_/\_\\__\___|_|  |_| |_|\__,_|_|___/
  //

  function getOptionPrice(
    address pool,
    uint256 period,
    uint256 amount,
    uint256 strike,
    address[] calldata swappath
  )
    external
    view
    returns (
      uint256 total,
      uint256 baseTotal,
      uint256 settlementFee,
      uint256 premium
    );

  function createOption(
    address pool,
    uint256 period,
    uint256 amount,
    uint256 strike,
    address[] calldata swappath,
    uint256 acceptablePrice
  ) external;
}
