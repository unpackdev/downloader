// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./WETHBase.sol";
import "./IERC20.sol";
import "./Ownable.sol";

/**
 * @title WETHGatewayBase contract
 *
 * @author Aito
 * @notice Simple WETH gateway contract with basic functionality, must be inherited.
 */
contract WETHGatewayBase is Ownable, WETHBase {

    /**
     * @notice Constructor sets the immutable WETH address.
     *
     * @param weth The WETH address.
     */
    constructor(address weth) WETHBase(weth) {}

    /**
     * @dev Admin function authorizes an address through WETH approval.
     *
     * @param toAuthorize The address to approve with WETH.
     */
    function authorize(address toAuthorize) external onlyOwner {
        WETH.approve(toAuthorize, type(uint256).max);
    }

    /**
     * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     *
     * @param token token to transfer
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    /**
     * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computated contract address before deployment.
     *
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransfer(address to, uint256 amount) external onlyOwner {
        _safeTransferETH(to, amount);
    }
}
