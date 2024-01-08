//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./ERC2981ContractWideRoyalties.sol";

contract Eva is ERC721URIStorage, ERC2981ContractWideRoyalties, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981ContractWideRoyalties, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    constructor() ERC721("Eva", "EVA") {
        //console.logBytes4(type(ERC721URIStorage).interfaceId);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoyalties(0xf8b32D30aC6Ab3030595432533D7836FD76B078d, 1000); //to hex6c, 10% royalties
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmQjuJ1jzz5BNPMfz5TQSg7h6CmyYLV28aNLKqfw9UwD3J";
    }

    modifier onlyMinter {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _;
    }

    function mint(string memory tokenURI) onlyMinter public returns (uint256) {
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        _tokenIds.increment();

        return newTokenId;
    }
}
