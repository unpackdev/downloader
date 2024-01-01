// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Permit.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ClonesUpgradeable.sol";
import "./sipERC20.sol";

contract OPPS is ERC721Permit, Ownable {
    mapping(uint256 => uint256) public nonces;
    mapping(bytes32 => bool) public nameTaken;
    address public immutable sipImplementation;
    bytes32 public immutable sipHash;

    function version() public pure returns (string memory) {
        return "1";
    }

    string private __baseURI;
    modifier onlySIP() {
        require(sipERC20(msg.sender).opps() == address(this), "!opps");
        bytes32 hash;
        assembly {
          hash := extcodehash(caller())
        }
        require(
            hash == sipHash,
            "!sip"
        );
        _;
    }

    function _deployClone(address asset) internal returns (address clone) {
        clone = ClonesUpgradeable.cloneDeterministic(
            sipImplementation,
            bytes32(uint256(uint160(asset)))
        );
    }
    function deployVault(address asset) public returns (address clone) {
        clone = _deployClone(asset);
        sipERC20(clone).initialize(asset);
    }

    function vaultFor(address asset) public view returns (address) {
      return ClonesUpgradeable.predictDeterministicAddress(sipImplementation, bytes32(uint256(uint160(asset))));
    }

    function registerName(bytes32 nameHash) public onlySIP {
        nameTaken[nameHash] = true;
    }

    constructor() ERC721Permit("OPPS", "OPPS", "1") Ownable() {
        setBaseURI(
            "ipfs://bafybeiezpbqq6favps74erwn35ircae2xqqdmczxjs7imosdkn6ahmuxme/"
        );
        sipImplementation = address(new sipERC20());
        bytes32 _sipHash;
        address clone = _deployClone(address(0x0));
        assembly {
          _sipHash := extcodehash(clone)
        }
        sipHash = _sipHash;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function _getAndIncrementNonce(
        uint256 _tokenId
    ) internal virtual override returns (uint256) {
        uint256 nonce = nonces[_tokenId];
        nonces[_tokenId]++;
        return nonce;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        __baseURI = _uri;
    }

    function mint(address _to, uint256 _tokenId) public onlyOwner {
        _mint(_to, _tokenId);
    }
}
