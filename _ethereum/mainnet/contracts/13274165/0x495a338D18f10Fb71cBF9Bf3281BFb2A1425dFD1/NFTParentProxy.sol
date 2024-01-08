// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// REMIX
// import "./ERC1967Proxy.sol";
// import "./Ownable.sol";

// TRUFFLE
import "./ERC1967Proxy.sol";
import "./Ownable.sol";

// NFTParentProxy SMART CONTRACT
contract NFTParentProxy is ERC1967Proxy, Ownable {
    /**
     * NFTParentProxy Constructor
     *
     * @param _logic - Implementation/Logic Contract Address
     */
    constructor(address _logic)
        public
        ERC1967Proxy(_logic, abi.encodeWithSignature("initialize()"))
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
