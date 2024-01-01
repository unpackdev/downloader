pragma solidity ^0.8.18;

import "./Create2.sol";
import "./IERC6551Registry.sol";

contract TGARegistry is IERC6551Registry {
    error InitializationFailed();

    struct TBA {
        address tokenContract;
        uint tokenId;
    }
    mapping (address => TBA) public registeredAccounts;

    function createAccount(
        address _implementation,
        uint256 _chainId,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _salt,
        bytes calldata initData
    ) external returns (address) {
        bytes memory code = _creationCode(_implementation, _chainId, _tokenContract, _tokenId, _salt);

        address _account = Create2.computeAddress(
            bytes32(_salt),
            keccak256(code)
        );

        if (_account.code.length != 0) return _account;

        _account = Create2.deploy(0, bytes32(_salt), code);

        registeredAccounts[_account].tokenContract = _tokenContract;
        registeredAccounts[_account].tokenId = _tokenId;

        if (initData.length != 0) {
            (bool success, ) = _account.call(initData);
            if (!success) revert InitializationFailed();
        }

        emit AccountCreated(
            _account,
            _implementation,
            _chainId,
            _tokenContract,
            _tokenId,
            _salt
        );

        return _account;
    }

    function account(
        address _implementation,
        uint256 _chainId,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _salt
    ) external view returns (address) {
        bytes32 bytecodeHash = keccak256(
            _creationCode(_implementation, _chainId, _tokenContract, _tokenId, _salt)
        );

        return Create2.computeAddress(bytes32(_salt), bytecodeHash);
    }

    function _creationCode(
        address _implementation,
        uint256 _chainId,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _salt
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                _implementation,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(_salt, _chainId, _tokenContract, _tokenId)
            );
    }
}
