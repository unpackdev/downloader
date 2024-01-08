pragma solidity 0.5.16;

contract IDefiPassport {
    function mint(
        address _to,
        address _passportSkin,
        uint256 _skinTokenId
    )
        external
        returns (uint256);
}
