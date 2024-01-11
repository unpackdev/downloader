// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Pausable.sol";
import "./Registry.sol";

contract MainchainGatewayStorage is Pausable {
    event TokenDeposited(
        uint256 indexed _depositId,
        address indexed _owner,
        string _sidechainOwner,
        address indexed _tokenAddress,
        string _sidechainAddress,
        uint256 _tokenNumber // ERC-20 amount or ERC721 tokenId
    );

    event TokenWithdrew(
        uint256 indexed _withdrawId,
        address indexed _owner,
        address indexed _tokenAddress,
        uint256 _tokenNumber
    );

    struct DepositEntry {
        string owner;
        address tokenAddress;
        string sidechainAddress;
        uint256 tokenNumber;
    }

    struct WithdrawalEntry {
        address owner;
        address tokenAddress;
        uint256 tokenNumber;
    }

    Registry public registry;

    uint256 public depositCount;
    DepositEntry[] public deposits;
    mapping(uint256 => WithdrawalEntry) public withdrawals;

  function updateRegistry(address _registry) external onlyOwner {
    registry = Registry(_registry);
  }
}
