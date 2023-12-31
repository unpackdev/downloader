// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./WrappedRebaseToken.sol";
import "./IERC20.sol";
import "./IWrappedRebaseTokenFactory.sol";
import "./IERC4626.sol";
import "./SafeERC20.sol";

/**
 * @title WrappedRebaseTokenFactory
 * @notice Factory contract for deploying ERC4624 tokens that are resistant to inflation attacks
 * @dev Depositing 1 ether of the underlying asset should sufficently raise the cost of an inflation attack to make it infeasible
 */
contract WrappedRebaseTokenFactory is IWrappedRebaseTokenFactory {
    using SafeERC20 for IERC20;

    constructor() {}

    /**
     * @notice Deploys a new WrappedRebaseToken contract
     * @param asset The rebase token that this contract wraps around, will be passed into the WrappedRebaseToken constructor
     * @param name The name of the Wrapped Rebase Token; will be passed into the WrappedRebaseToken constructor
     * @param symbol The symbol of the Wrapped Rebase Token; will be passed into the WrappedRebaseToken constructor
     * @return newWrappedRebaseTokenContract The address of the newly deployed WrappedRebaseToken contract
     */
    function deploy(IERC20 asset, string memory name, string memory symbol)
        external
        returns (IERC4626 newWrappedRebaseTokenContract)
    {
        asset.safeTransferFrom(msg.sender, address(this), 1 ether);
        newWrappedRebaseTokenContract = IERC4626(address(new WrappedRebaseToken(asset, name, symbol)));
        asset.safeIncreaseAllowance(address(newWrappedRebaseTokenContract), 1 ether);
        newWrappedRebaseTokenContract.deposit(1 ether, address(newWrappedRebaseTokenContract)); // pre-seed deploy amount to protect against inflation attacks
        emit newWrappedRebaseTokenContractDeployed(msg.sender, address(newWrappedRebaseTokenContract));
    }
}
