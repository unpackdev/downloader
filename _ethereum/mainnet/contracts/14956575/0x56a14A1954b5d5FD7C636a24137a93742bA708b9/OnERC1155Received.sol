pragma solidity 0.7.5;

import "./AugustusStorage.sol";
import "./IRouter.sol";

contract OnERC1155Received is AugustusStorage, IRouter {
    constructor() public {}

    function initialize(bytes calldata data) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function getKey() external pure override returns (bytes32) {
        return keccak256(abi.encodePacked("onERC1155Received", "1.0.0"));
    }

    bytes4 constant ERC1155_RECEIVED = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    bytes4 constant ERC1155_BATCH_RECEIVED =
        bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4) {
        return ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4) {
        return ERC1155_BATCH_RECEIVED;
    }
}
