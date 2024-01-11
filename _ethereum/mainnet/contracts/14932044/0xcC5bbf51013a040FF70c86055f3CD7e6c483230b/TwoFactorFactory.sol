// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./Ownable.sol";

contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

interface ITwoFactor {
    function init(address _sender, address _backupWallet, bytes32 _encryptedPassword) external;
}

contract TwoFactorFactory is CloneFactory, Ownable {
    
    address public firstChildAddress;
    bool private isCreationEnabled = true;
    mapping(address => address) public eoaToVaultMap;
    event TwoFactorCreated(address newTwoFactor);
 
    constructor(address _firstChildAddress) {
        require(_firstChildAddress!= address(0), "Address can not be zero");
        firstChildAddress = _firstChildAddress;
    }
    
    function createTwoFactor(address _backupWallet, bytes32 _encryptedPassword) external {
        require(isCreationEnabled == true, "Creating TwoFactor vaults has been disabled for now");
        require(
            eoaToVaultMap[msg.sender] == address(0),
            "Vault already exists for user"
        );
        address clone = createClone(firstChildAddress);
        ITwoFactor(clone).init(msg.sender, _backupWallet, _encryptedPassword);
        eoaToVaultMap[msg.sender] = clone;
        emit TwoFactorCreated(clone);
    }

    function pauseTwoFactorProduction() external onlyOwner{
        require(isCreationEnabled == true, "TwoFactor production is already paused");
        isCreationEnabled = false;
    }

    function resumeTwoFactorProduction() external onlyOwner{
        require(isCreationEnabled == false, "TwoFactor production already going on");
        isCreationEnabled = true;
    }
}
