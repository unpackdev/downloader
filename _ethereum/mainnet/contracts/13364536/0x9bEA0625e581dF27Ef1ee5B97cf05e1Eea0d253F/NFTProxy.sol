// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// REMIX
// import "./UpgradeableProxy.sol";
// import "./Ownable.sol";

// TRUFFLE
import "./UpgradeableProxy.sol";
import "./Ownable.sol";

// NFTProxy SMART CONTRACT
contract NFTProxy is UpgradeableProxy, Ownable {
    /**
     * NFTProxy Constructor
     *
     * @param _logic - Implementation/Logic Contract Address
     */
    constructor(address _logic)
        public
        UpgradeableProxy(_logic, abi.encodeWithSignature("initialize()"))
    {}

    /**
     * Get the current implementation contract address
     *
     */
    function implementation() external view returns (address) {
        return _implementation();
    }

    /**
     * Change the implementation contract address
     *
     * @param _logic - Implementation/Logic Contract Address
     */
    function upgradeTo(address _logic) public onlyOwner {
        _upgradeTo(_logic);
    }
}
