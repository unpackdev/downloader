pragma solidity 0.6.6;

import "./IERC20.sol";
import "./IAllocationStrategy.sol";
import "./IStrategiesWhitelist.sol";

contract OTokenStorage {

    // DO NOT CHANGE this slot when upgrading contracts!!@!@!@
    bytes32 constant public otSlot = keccak256("OToken.storage.location");

    // O Token Storage ONLY APPEND TO THIS STRUCT WHEN UPGRADING CONTRACTS!@!@!@
    struct ots {
        IAllocationStrategy allocationStrategy;
        IERC20 underlying;
        uint256 fee;
        uint256 lastTotalUnderlying;
        string name;
        string symbol;
        uint8 decimals;
        mapping(address => mapping(address => uint256)) internalAllowances;
        mapping(address => uint256) internalBalanceOf;
        uint256 internalTotalSupply;
        bool initialised;
        address admin;
        address treasury;
        IStrategiesWhitelist strategiesWhitelist;
        // ONLY APPEND TO THIS STRUCT WHEN UPGRADING CONTRACTS!!@!@
    }

    function allocationStrategy() external view returns(address) {
        return address(lots().allocationStrategy);
    }

    function admin() external view returns(address) {
        return lots().admin;
    }

    function treasury() external view returns(address) {
        return lots().treasury;
    }

    function strategiesWhitelist() external view returns(address) {
        return address(lots().strategiesWhitelist);
    }

    function underlying() external view returns(address) {
        return address(lots().underlying);
    }

    function fee() external view returns(uint256) {
        return lots().fee;
    }

    function lastTotalUnderlying() external view returns(uint256) {
        return lots().lastTotalUnderlying;
    }

    function name() external view returns(string memory) {
        return lots().name;
    }

    function symbol() external view returns(string memory) {
        return lots().symbol;
    }

    function decimals() external view returns(uint8) {
        return lots().decimals;
    }

    function internalBalanceOf(address _who) external view returns(uint256) {
        return lots().internalBalanceOf[_who];
    }

    function internalTotalSupply() external view returns(uint256) {
        return lots().internalTotalSupply;
    }

    function lots() internal pure returns(ots storage s) {
        bytes32 loc = otSlot;
        assembly {
            s_slot := loc
        }
    }
}
