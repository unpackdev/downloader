pragma solidity ^0.8.18;

import "./Create2.sol";
import "./IERC6551Registry.sol";

/**
 * @title TBARegistry
 * @dev This contract implements the registry for Token Bound Accounts (TBA) as per the ERC-6551 standard.
 * It facilitates the creation and management of accounts bound to non-fungible tokens (NFTs),
 * enabling each NFT to operate as its own smart contract account.
 * 
 * The contract leverages the Ethereum Create2 opcode for deploying smart contracts at specified addresses,
 * allowing for predictable contract addresses and efficient user onboarding.
 * 
 * Each created account is registered within the contract, mapping the account address to its corresponding
 * NFT's contract address and token ID.
 *
 * The contract allows for the computation of account addresses prior to their actual creation,
 * aiding in the planning and management of TBAs.
 *
 * @author Logan Brutsche
 */
contract TBARegistry is IERC6551Registry {
    error InitializationFailed();

    struct TBA {
        address tokenContract;
        uint tokenId;
    }
    mapping (address => TBA) public registeredAccounts;

    /**
     * @dev Creates a new account with a bound non-fungible token using the provided parameters and returns the created account's address.
     * @param _implementation Address of the TBA account implementation.
     * @param _chainId Chain ID on which the account is created.
     * @param _tokenContract Address of the NFT contract.
     * @param _tokenId ID of the token to be bound to the new account.
     * @param _salt A value to modify the resulting address.
     * @param initData Initialization data to be called on the new account.
     * @return The address of the created account.
     */
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

    /**
     * @dev Computes and returns the address of the account with the provided parameters without actually creating the account.
     * @param _implementation Address of the TBA account implementation.
     * @param _chainId Chain ID for which to compute the account address.
     * @param _tokenContract Address of the token contract.
     * @param _tokenId ID of the token for which to compute the account address.
     * @param _salt A value to modify the resulting address.
     * @return The address of the computed account.
     */
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

    /**
     * @dev Generates the creation code for an account with the provided parameters.
     * @param _implementation Address of the TBA account implementation.
     * @param _chainId Chain ID on which the account is created.
     * @param _tokenContract Address of the token contract.
     * @param _tokenId ID of the token to be bound to the new account.
     * @param _salt A value to modify the resulting creation code.
     * @return The creation code for the account.
     */
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
