// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./ERC721.sol";
import "./Ownable.sol";


contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PunkBodiesV2 is ERC721, Ownable {
    address immutable proxyRegistryAddress;
    address public distributor;

    uint256 public min_id = 10000;
    uint256 public max_id = 25000;

    string baseURI_ = "https://punkbodiesv2.mypinata.cloud/ipfs/QmeDmZe5nqj34FKAKykckKCpjQLdRNQjrkop8XspzscVMs/";

    constructor(address _proxyRegistryAddress)  ERC721("PunkBodies V2", "PBV2") {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return  baseURI_;
    }


    function setDistributor(address _distributor) external {
        require(distributor == address(0), "PunkBodies: distributor already set");
        distributor = _distributor;
    }

    function setBaseUri(string calldata newURI) external onlyOwner {
        baseURI_ = newURI;
    }

    function mint(address to, uint256 tokenId) external {
        require(msg.sender == distributor, "PunkBodies: not authorized.");
        require(tokenId < max_id && tokenId >= min_id, "PunkBodies: outside of supply range");
        _mint(to, tokenId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function isApprovedForAll(address _owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, operator);
    }
}
