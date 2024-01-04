pragma solidity >=0.6.0 <0.7.0;


library TokenAccessRoles {
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 private constant TRANSFERER_ROLE = keccak256("TRANSFERER_ROLE");
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function minter() public pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function burner() public pure returns (bytes32) {
        return BURNER_ROLE;
    }

    function transferer() public pure returns (bytes32) {
        return TRANSFERER_ROLE;
    }

    function admin() public pure returns (bytes32) {
        return ADMIN_ROLE;
    }
}
