pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Counters.sol";
import "./AccessControl.sol";

contract SuperERC721 is ERC721, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory name, string memory symbol) ERC721 (name, symbol)  public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); 
    }

    function mint(address to, string memory tokenURI) public returns(uint256 tokenId) {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || 
            hasRole(MINTER_ROLE, msg.sender),
            "Not a minter role user");

        _tokenIds.increment();
        tokenId = _tokenIds.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function batchMint(address to, string[] memory tokensURI) public {
        for(uint256 i = 0; i < tokensURI.length; i++) {
            mint(to, tokensURI[i]);
        }
    }
}
