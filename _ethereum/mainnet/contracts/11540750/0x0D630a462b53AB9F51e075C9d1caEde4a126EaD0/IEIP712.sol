pragma solidity ^0.7.3;

interface IEIP712 {

    /* ========== OPTIONAL VIEWS ========== */

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function nonces(address wallet) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

}
