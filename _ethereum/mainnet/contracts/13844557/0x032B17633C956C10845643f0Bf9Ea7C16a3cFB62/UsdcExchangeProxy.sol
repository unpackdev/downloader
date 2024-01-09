/*

  Copyright 2021 dYdX Trading Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./I_ExchangeProxy.sol";

/**
 * @title UsdcExchangeProxy
 * @author dYdX
 *
 * @notice Contract for interacting with exchanges.
 */
contract UsdcExchangeProxy is I_ExchangeProxy {
  using SafeERC20 for IERC20;

  // ============ State Variables ============

  IERC20 immutable USDC_ADDRESS;

  // ============ Constructor ============

  constructor(
    IERC20 usdcAddress
  ) {
    USDC_ADDRESS = usdcAddress;
  }

  // ============ State-Changing Functions ============

  /**
    * @notice Make a call to an exchange via proxy.
    *
    * @param  proxyExchangeData  Bytes data for the trade, specific to the exchange proxy implementation.
    */
  function proxyExchange(
    bytes calldata proxyExchangeData
  )
    external
    override
    payable
  {
    (
      IERC20 tokenFrom,
      address allowanceTarget,
      uint256 minUsdcAmount,
      address exchange,
      bytes memory exchangeData
    ) = abi.decode(proxyExchangeData, (IERC20, address, uint256, address, bytes));

    // Set allowance (if non-zero addresses provided).
    if (
      tokenFrom != IERC20(address(0)) &&
      allowanceTarget != address(0)
    ) {
      // safeApprove requires unsetting the allowance first.
      tokenFrom.safeApprove(allowanceTarget, 0);
      tokenFrom.safeApprove(allowanceTarget, type(uint256).max);
    }

    // Call exchange with data to execute swap.
    (bool success, bytes memory returndata) = exchange.call{ value: msg.value }(
      exchangeData
    );
    require(success, string(returndata));

    // Verify minUsdcAmount.
    uint256 usdcBalance = USDC_ADDRESS.balanceOf(address(this));
    require(usdcBalance >= minUsdcAmount, 'Received USDC is less than minUsdcAmount');

    // Transfer all USDC balance back to msg.sender.
    USDC_ADDRESS.safeTransfer(
      msg.sender,
      usdcBalance
    );
  }
}
