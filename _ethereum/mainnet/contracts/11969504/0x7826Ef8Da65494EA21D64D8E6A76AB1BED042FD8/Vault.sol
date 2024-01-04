// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Migratable.sol";

contract Vault is Migratable {

    event Claim(address indexed account, uint256 amount, uint256 deadline, uint256 nonce);

    string public constant name = 'MiningVault';

    address public tokenAddress;

    uint256 public chainId;

    mapping (bytes32 => bool) public usedHash;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    bytes32 public constant CLAIM_TYPEHASH = keccak256('Claim(address account,uint256 amount,uint256 deadline,uint256 nonce)');

    constructor (address tokenAddress_) {
        controller = msg.sender;
        tokenAddress = tokenAddress_;
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        chainId = _chainId;
    }

    function approveMigration() public override _controller_ _valid_ {
        require(migrationTimestamp != 0 && block.timestamp >= migrationTimestamp, 'Vault.approveMigration: migrationTimestamp not met yet');
        IERC20(tokenAddress).approve(migrationDestination, type(uint256).max);
        isMigrated = true;
        emit ApproveMigration(migrationTimestamp, address(this), migrationDestination);
    }

    function executeMigration(address source) public override _controller_ _valid_ {
        uint256 _migrationTimestamp = IVault(source).migrationTimestamp();
        address _migrationDestination = IVault(source).migrationDestination();
        require(_migrationTimestamp != 0 && block.timestamp >= _migrationTimestamp, 'Vault.executeMigration: migrationTimestamp not met yet');
        require(_migrationDestination == address(this), 'Vault.executeMigration: not destination address');
        IERC20(tokenAddress).transferFrom(source, address(this), IERC20(tokenAddress).balanceOf(source));
        emit ExecuteMigration(_migrationTimestamp, source, address(this));
    }

    function claim(address account, uint256 amount, uint256 deadline, uint256 nonce, uint8 v, bytes32 r, bytes32 s) public _valid_ {
        require(block.timestamp <= deadline, 'Vault.claim: signature expired');

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), chainId, address(this)));
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, account, amount, deadline, nonce));
        require(!usedHash[structHash], 'Vault.claim: replay');
        usedHash[structHash] = true;

        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == controller, 'Vault.claim: unauthorized');

        IERC20(tokenAddress).transfer(account, amount);

        emit Claim(account, amount, deadline, nonce);
    }

}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address account, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IVault {
    function migrationTimestamp() external view returns (uint256);
    function migrationDestination() external view returns (address);
}
