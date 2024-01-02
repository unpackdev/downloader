// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IMOPNGovernance.sol";
import "./IMOPN.sol";
import "./IERC6551Registry.sol";
import "./IMOPNERC6551Account.sol";
import "./Multicall.sol";

contract MOPNERC6551AccountHelper is Multicall {
    IMOPNGovernance immutable governance;

    constructor(address governance_) {
        governance = IMOPNGovernance(governance_);
    }

    function createAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt,
        bytes calldata initData
    ) external returns (address) {
        return
            IERC6551Registry(governance.ERC6551Registry()).createAccount(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt,
                initData
            );
    }

    function computeAccount(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) public view returns (address) {
        return
            IERC6551Registry(governance.ERC6551Registry()).account(
                implementation,
                chainId,
                tokenContract,
                tokenId,
                salt
            );
    }

    function checkAccountExist(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        uint256 salt
    ) external view returns (bool exist, address _account) {
        _account = computeAccount(
            implementation,
            chainId,
            tokenContract,
            tokenId,
            salt
        );
        if (_account.code.length != 0) return (true, _account);
        return (false, _account);
    }

    /// @dev executes a low-level call against an account if the caller is authorized to make calls
    function executeProxy(
        address account,
        address to,
        uint256 value,
        bytes calldata data,
        uint256 operation
    ) public payable returns (bytes memory) {
        return
            IMOPNERC6551Account(payable(account)).executeProxy(
                to,
                value,
                data,
                operation,
                msg.sender
            );
    }
}
