// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Initializable.sol";
import "./LSRModelBase.sol";

/**
 * @title dForce's Liquid Stability Reserve
 * @author dForce
 */
contract LSR is Initializable, LSRModelBase {
    /**
     * @notice Only for the implementation contract, as for the proxy pattern,
     *            should call `initialize()` separately.
     * @param _msdController MsdController address.
     * @param _msd Msd address.
     * @param _mpr MSD peg reserve address.
     * @param _strategy Strategy address.
     */
    constructor(
        IMSDController _msdController,
        address _msd,
        address _mpr,
        address _strategy
    ) public {
        initialize(_msdController, _msd, _mpr, _strategy);
    }

    /**
     * @notice Initialize peg stability data.
     * @param _msdController MsdController address.
     * @param _msd MSD address.
     * @param _mpr MSD peg reserve address.
     * @param _strategy Strategy address..
     */
    function initialize(
        IMSDController _msdController,
        address _msd,
        address _mpr,
        address _strategy
    ) public initializer {
        __Ownable_init();

        LSRMinter._initialize(_msdController, _msd);
        LSRModelBase._initialize(_msd, _mpr, _strategy);
    }
}
