pragma solidity ^0.8.22;

interface IWagmeToken {

    error IdempotencyKeyAlreadyExist(bytes32 idempotencyKey);

    function mint(address account, uint256 amount) external;

    function mint(bytes32 idempotencyKey, address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function burn(bytes32 idempotencyKey, address account, uint256 amount) external;
}
