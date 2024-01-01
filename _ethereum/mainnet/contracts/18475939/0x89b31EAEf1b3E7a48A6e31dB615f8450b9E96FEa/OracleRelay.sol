//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
}

/**
 * @notice This contract is meant for relaying calls to the Oracle.
 * Example Oracle: BNB/USD on BSC at 0x0567f2323251f0aab15c8dfb1967e4e8a7d42aee.
 */
contract OracleRelay is Ownable {

    event OracleUpdated(address indexed oracle);

    address public oracle;
    
    constructor(address _oracle) {
        require(
            _oracle != address(0),
            "Oracle address cannot be zero"
        );
        oracle = _oracle;
    }

    function lastAnswer() external view returns (int256) {
        return IOracle(oracle).latestAnswer();
    }

    function setOracle(address _oracle) external onlyOwner {
        require(
            _oracle != address(0),
            "Oracle address cannot be zero"
        );
        oracle = _oracle;
        emit OracleUpdated(_oracle);
    }

    function getDecimals() external view returns (uint8) {
        return IOracle(oracle).decimals();
    }

    function getDescriptor() external view returns (string memory) {
        return IOracle(oracle).description();
    }
}