// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./ITaxController.sol";
import "./IAnyswapV4Token.sol";

/**
 * @title  ARTHShares.
 * @author MahaDAO.
 */
interface IARTHX is IERC20, IAnyswapV4Token {
    function addToTaxWhiteList(address entity) external;

    function addToTaxWhiteListMultiple(address[] memory entity) external;

    function removeFromTaxWhitelist(address entity) external;

    function setArthController(address _controller) external;

    function setTaxPercent(uint256 percent) external;

    function setTaxController(ITaxController controller) external;

    function setARTHAddress(address arthContractAddress) external;

    function poolMint(address account, uint256 amount) external;

    function poolBurnFrom(address account, uint256 amount) external;

    function getTaxAmount(uint256 amount) external view returns (uint256);

    function isTxWhiteListedForTax(address sender, address receiver)
        external
        view
        returns (bool);
}
