pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./AccessControl.sol";

contract Cyberchads is ERC721, Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory name, string memory symbol, string memory baseURI) public ERC721(name, symbol) {
        _setBaseURI(baseURI);

        // Admin role for managing other roles.
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant the minter role to a specified account
        _setupRole(MINTER_ROLE, msg.sender);

        // Mint 5 special legendary Chads.
        mint(msg.sender);
        mint(msg.sender);
        mint(msg.sender);
        mint(msg.sender);
        mint(msg.sender);
    }

    function mint(address to) public returns (uint256) {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        uint256 newItemId = totalSupply();
        _safeMint(to, newItemId);

        return newItemId;
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function setBaseURI(string memory baseURI) onlyOwner public {
       _setBaseURI(baseURI);
    }

    /**
     * @dev Changes the token URI for a token. Might be useful if we want to each token's
     * metadata on IPFS.
     */
    function setTokenURI(uint256 tokenId, string memory tokenURI) onlyOwner public {
        _setTokenURI(tokenId, tokenURI);
    }
}
