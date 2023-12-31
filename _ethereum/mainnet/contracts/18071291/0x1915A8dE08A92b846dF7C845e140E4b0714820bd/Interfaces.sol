// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

interface IERC20Like {

    function burn(address from, uint256 value) external;

    function mint(address to, uint256 value) external;

    function totalSupply() external view returns (uint256 totalSupply);

}

interface IGlobalsLike {

    function governor() external view returns (address governor);

    function isInstanceOf(bytes32 instanceKey, address instance) external view returns (bool isInstance);

    function isValidScheduledCall(
        address          caller,
        address          target,
        bytes32          functionId,
        bytes   calldata callData
    ) external view returns (bool isValidScheduledCall);

    function mapleTreasury() external view returns (address mapleTreasury);

    function unscheduleCall(address caller, bytes32 functionId, bytes calldata callData) external;

}

interface IMapleTokenInitializerLike {

    function initialize(address migrator, address treasury) external;

}

interface IMapleTokenLike is IERC20Like {

    function globals() external view returns (address globals);

}
