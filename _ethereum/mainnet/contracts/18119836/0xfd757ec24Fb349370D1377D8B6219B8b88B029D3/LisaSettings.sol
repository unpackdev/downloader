//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Ownable.sol";
import "./Address.sol";
import "./ILisaSettings.sol";

contract LisaSettings is Ownable, ILisaSettings {
    address public protocolArtTreasuryAddress;
    uint256 public protocolATFeeBps;
    uint256 public protocolBTFeeBps;
    uint256 public buyoutDurationSeconds;
    address public trustedForwarder;

    using Address for address;
    mapping(bytes32 => address) private _logicContracts;

    constructor(
        uint256 atFeeBps,
        uint256 btFeeBps,
        address artTreasuryAddress,
        uint256 buyoutDurationSec
    ) Ownable() {
        require(atFeeBps < 100 * 100);
        require(btFeeBps < 100 * 100);
        require(
            address(artTreasuryAddress) != address(0),
            "wallet address should not be 0"
        );
        protocolATFeeBps = atFeeBps;
        protocolBTFeeBps = btFeeBps;
        protocolArtTreasuryAddress = artTreasuryAddress;
        buyoutDurationSeconds = buyoutDurationSec;
    }

    function protocolAdmin() external view override returns (address) {
        return owner();
    }

    function updatePlatformAdmin(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        transferOwnership(newOwner);
    }

    function updateFeeWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0));
        protocolArtTreasuryAddress = newWallet;
    }

    function updateATFeeBps(uint256 atFeeBps) external onlyOwner {
        require(atFeeBps < 100 * 100);
        protocolATFeeBps = atFeeBps;
    }

    function updateBTFeeBps(uint256 btFeeBps) external onlyOwner {
        require(btFeeBps < 100 * 100);
        protocolBTFeeBps = btFeeBps;
    }

    function updateBuyoutDurationSeconds(
        uint256 newDuration
    ) external onlyOwner {
        require(newDuration > 0);
        buyoutDurationSeconds = newDuration;
    }

    function updateTrustedForwarder(address forwarder) external onlyOwner {
        require(
            forwarder != address(0),
            "LisaSettings: forwarder cannot be zero"
        );
        trustedForwarder = forwarder;
    }

    function getLogic(bytes32 contractId) external view returns (address) {
        return _logicContracts[contractId];
    }

    function setLogic(
        bytes32 contractId,
        address contractAddress
    ) external onlyOwner {
        require(
            Address.isContract(contractAddress),
            "LisaSettings: contractAddress should be a contract"
        );
        _logicContracts[contractId] = contractAddress;
    }
}
