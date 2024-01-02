// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./IMapleProxyFactory.sol";

/// @title MapleLoanFactory deploys Loan instances.
interface IMapleLoanFactory is IMapleProxyFactory {

    /**
     *  @dev    Whether the proxy is a MapleLoan deployed by this factory or the old factory.
     *  @param  proxy_  The address of the proxy contract.
     *  @return isLoan_ Whether the proxy is a MapleLoan deployed by this factory.
     */
    function isLoan(address proxy_) external view returns (bool isLoan_);

    /**
     *  @dev    Returns the address of the old factory.
     *  @return oldFactory_ The address of the old factory.
     */
    function oldFactory() external view returns (address oldFactory_);

}
