// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./IERC721.sol";

interface BaseRegistrar is IERC721 {
    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;
}

contract ENSHuntingGame is Ownable {
    BaseRegistrar public registrar;
    string[] public domains;

    constructor(address _registrar, string[] memory _domains) {
        registrar = BaseRegistrar(_registrar);
        domains = _domains;
    }

    function claimAll() external onlyOwner {
        for (uint256 i = 0; i < domains.length; i++) {
            _claim(domains[i]);
        }
    }

    function claim(uint256 domainIndex) external onlyOwner {
        require(domainIndex < domains.length, "Domain index out of bounds");
        _claim(domains[domainIndex]);
    }

    function _claim(string memory domain) internal {
        uint256 tokenId = getTokenId(domain);
        address tokenOwner = registrar.ownerOf(tokenId);

        registrar.reclaim(tokenId, _msgSender());
        registrar.safeTransferFrom(tokenOwner, _msgSender(), tokenId);
    }

    function getTokenId(string memory domain) public pure returns (uint256) {
        return uint256(keccak256(bytes(domain)));
    }
}
