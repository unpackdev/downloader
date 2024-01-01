// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./Clones.sol";
import "./Initializable.sol";

import "./IConfig.sol";
import "./IInitializableNFT.sol";

error SupplyTooBig();

contract Factory is Initializable, Ownable {
    using Clones for address;

    address public config;
    address public nft;

    uint256 public maxSupply;

    event NewNFTCollection(
        address indexed creator,
        uint256 indexed nonce,
        address instance,
        uint256 totalSupply,
        string name
    );

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function initialize(
        address _config,
        address _nft,
        uint256 _maxSupply
    ) external initializer onlyOwner {
        config = _config;
        nft = _nft;
        maxSupply = _maxSupply;
    }

    function setNFT(address _nft) external onlyOwner {
        nft = _nft;
    }

    function deploy(
        address creator,
        uint256 nonce,
        uint256 totalSupply,
        string calldata name
    ) external {
        if (totalSupply > maxSupply) revert SupplyTooBig();
        address instance = nft.cloneDeterministic(_getSalt(creator, nonce));
        IInitializableNFT(instance).initialize(
            config,
            creator,
            totalSupply,
            name
        );
        emit NewNFTCollection(creator, nonce, instance, totalSupply, name);
    }

    function getFutureAddress(
        address creator,
        uint256 nonce
    ) external view returns (address) {
        return nft.predictDeterministicAddress(_getSalt(creator, nonce));
    }

    function _getSalt(
        address creator,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(creator, nonce));
    }
}
