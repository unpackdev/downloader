// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./Ownable.sol";
import "./IOilerOptionBaseFactory.sol";
import "./IOilerOptionBase.sol";
import "./IOilerOptionsRouter.sol";

contract OilerRegistry is Ownable {
    uint256 public constant PUT = 1;
    uint256 public constant CALL = 0;

    /**
     * @dev Active options store, once the option expires the mapping keys are replaced.
     * option type => option contract.
     */
    mapping(bytes32 => address[2]) public activeOptions;

    /**
     * @dev Archived options store.
     * Once an option expires and is replaced it's pushed to an array under it's type key.
     * option type => option contracts.
     */
    mapping(bytes32 => address[]) public archivedOptions;

    /**
     * @dev Stores supported types of options.
     */
    bytes32[] public optionTypes; // Array of all option types ever registered

    /**
     * @dev Indicates who's the factory of specific option types.
     * option type => factory.
     */
    mapping(bytes32 => address) public factories;

    IOilerOptionsRouter public optionsRouter;

    constructor(address _owner) Ownable() {
        Ownable.transferOwnership(_owner);
    }

    function registerOption(address _optionAddress, string memory _optionType) external {
        require(address(optionsRouter) != address(0), "OilerRegistry.registerOption: router not set");
        bytes32 optionTypeHash = keccak256(abi.encodePacked(_optionType));
        // Check if caller is factory registered for current option.
        require(factories[optionTypeHash] == msg.sender, "OilerRegistry.registerOption: not a factory."); // Ensure that contract under address is an option.
        require(
            IOilerOptionBaseFactory(msg.sender).isClone(_optionAddress),
            "OilerRegistry.registerOption: invalid option contract."
        );
        uint256 optionDirection = IOilerOptionBase(_optionAddress).put() ? PUT : CALL;
        // Ensure option is not being registered again.
        require(
            _optionAddress != activeOptions[optionTypeHash][optionDirection],
            "OilerRegistry.registerOption: option already registered"
        );
        // Ensure currently set option is expired.
        if (activeOptions[optionTypeHash][optionDirection] != address(0)) {
            require(
                !IOilerOptionBase(activeOptions[optionTypeHash][optionDirection]).isActive(),
                "OilerRegistry.registerOption: option still active"
            );
        }
        archivedOptions[optionTypeHash].push(activeOptions[optionTypeHash][optionDirection]);
        activeOptions[optionTypeHash][optionDirection] = _optionAddress;
        optionsRouter.setUnlimitedApprovals(IOilerOptionBase(_optionAddress));
    }

    function setOptionsTypeFactory(string memory _optionType, address _factory) external onlyOwner {
        bytes32 optionTypeHash = keccak256(abi.encodePacked(_optionType));
        require(_factory != address(0), "Cannot set factory to 0x0");
        require(factories[optionTypeHash] != address(0), "OptionType wasn't yet registered");
        if (_factory != address(uint256(-1))) {
            // Send -1 if you want to remove the factory and disable this optionType
            require(
                optionTypeHash ==
                    keccak256(
                        abi.encodePacked(
                            IOilerOptionBase(IOilerOptionBaseFactory(_factory).optionLogicImplementation()).optionType()
                        )
                    ),
                "The factory is for different optionType"
            );
        }
        factories[optionTypeHash] = _factory;
    }

    function registerFactory(address factory) external onlyOwner {
        bytes32 optionTypeHash = keccak256(
            abi.encodePacked(
                IOilerOptionBase(IOilerOptionBaseFactory(factory).optionLogicImplementation()).optionType()
            )
        );
        require(factories[optionTypeHash] == address(0), "The factory for this OptionType was already registered");
        factories[optionTypeHash] = factory;
        optionTypes.push(optionTypeHash);
    }

    function setOptionsRouter(IOilerOptionsRouter _optionsRouter) external onlyOwner {
        optionsRouter = _optionsRouter;
    }

    function getOptionTypesLength() external view returns (uint256) {
        return optionTypes.length;
    }

    function getOptionTypeAt(uint256 _index) external view returns (bytes32) {
        return optionTypes[_index];
    }

    function getOptionTypeFactory(string memory _optionType) external view returns (address) {
        return factories[keccak256(abi.encodePacked(_optionType))];
    }

    function getAllArchivedOptionsOfType(bytes32 _optionType) external view returns (address[] memory) {
        return archivedOptions[_optionType];
    }

    function getAllArchivedOptionsOfType(string memory _optionType) external view returns (address[] memory) {
        return archivedOptions[keccak256(abi.encodePacked(_optionType))];
    }

    function checkActive(string memory _optionType) public view returns (bool, bool) {
        bytes32 id = keccak256(abi.encodePacked(_optionType));
        return checkActive(id);
    }

    function checkActive(bytes32 _optionType) public view returns (bool, bool) {
        return (
            activeOptions[_optionType][CALL] != address(0)
                ? IOilerOptionBase(activeOptions[_optionType][CALL]).isActive()
                : false,
            activeOptions[_optionType][PUT] != address(0)
                ? IOilerOptionBase(activeOptions[_optionType][PUT]).isActive()
                : false
        );
    }

    function getActiveOptions(bytes32 _optionType) public view returns (address[2] memory result) {
        (bool isCallActive, bool isPutActive) = checkActive(_optionType);

        if (isCallActive) {
            result[0] = activeOptions[_optionType][0];
        }

        if (isPutActive) {
            result[1] = activeOptions[_optionType][1];
        }
    }

    function getActiveOptions(string memory _optionType) public view returns (address[2] memory result) {
        return getActiveOptions(keccak256(abi.encodePacked(_optionType)));
    }

    function getArchivedOptions(bytes32 _optionType) public view returns (address[] memory result) {
        (bool isCallActive, bool isPutActive) = checkActive(_optionType);

        uint256 extraLength = 0;
        if (!isCallActive) {
            extraLength++;
        }
        if (!isPutActive) {
            extraLength++;
        }

        uint256 archivedLength = getArchivedOptionsLength(_optionType);

        result = new address[](archivedLength + extraLength);

        for (uint256 i = 0; i < archivedLength; i++) {
            result[i] = archivedOptions[_optionType][i];
        }

        uint256 cursor;
        if (!isCallActive) {
            result[archivedLength + cursor++] = activeOptions[_optionType][0];
        }

        if (!isPutActive) {
            result[archivedLength + cursor++] = activeOptions[_optionType][1];
        }

        return result;
    }

    function getArchivedOptions(string memory _optionType) public view returns (address[] memory result) {
        return getArchivedOptions(keccak256(abi.encodePacked(_optionType)));
    }

    function getArchivedOptionsLength(string memory _optionType) public view returns (uint256) {
        return archivedOptions[keccak256(abi.encodePacked(_optionType))].length;
    }

    function getArchivedOptionsLength(bytes32 _optionType) public view returns (uint256) {
        return archivedOptions[_optionType].length;
    }
}
