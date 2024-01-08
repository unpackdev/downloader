pragma solidity 0.6.12;

import "./AccessControl.sol";
import "./ERC721.sol";
import "./IMintableCollection.sol";

contract UnicStakingERC721 is AccessControl, ERC721, IMintableCollection {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) public ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function burn(uint256 tokenId) public override virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "UnicStakingERC721: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function setBaseURI(string memory baseURI) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "UnicStakingERC721: must have admin role to change baseUri"
        );
        _setBaseURI(baseURI);
    }

    function mint(address to, uint256 tokenId) public override virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "UnicStakingERC721: must have minter role to mint"
        );

        _mint(to, tokenId);
    }
}
