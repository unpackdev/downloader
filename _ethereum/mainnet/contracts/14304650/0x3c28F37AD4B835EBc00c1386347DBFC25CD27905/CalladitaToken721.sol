// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./AccessControl.sol";

contract CalladitaToken721 is ERC721URIStorage, Ownable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721("Calladita Collection", "CLLDT") {
        //minter is owner (crowfunding contract)
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function awardNFT(address _to, string memory tokenURI) public returns (uint256)
    {   
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(_to, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {

        return super.supportsInterface(interfaceId);

    }

}