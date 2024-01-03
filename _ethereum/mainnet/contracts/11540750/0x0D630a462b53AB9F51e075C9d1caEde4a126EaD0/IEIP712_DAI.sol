pragma solidity ^0.7.3;

interface IEIP712_DAI {

    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;

}
