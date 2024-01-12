/* SPDX-License-Identifier: UNLICENSED
 * Smart Contract Ownership ID: 19 5 8 18 15 20 19   4 5 8 3 20 9 20 19
 */
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./MerkleProof.sol";
import "./AccessControl.sol";

contract RugOrDiamond is ERC721A, AccessControl {
    
    uint32 public maxSupply = 2000;
    string private baseURI = "ipfs://QmfJcdYvcVcFjaR8wCfeLXzd8FUYEQnXdcfVRCcmRWgAWd/";
    bytes32 private _merkleRootWhitelisted = 0x561eb31651fd28bf5aac4d648d5aa2a5348e4985d979c2a2ce0ef6dcb9850d9b;
    mapping(address => bool) public whitelistClaimed;

    bool public presale = false;
    bool public publicsale = false;
    bool public paused = true;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant DEVELOPER = keccak256("DEVELOPER");

    event NewrugOrDiamondNFTMinted(uint256);

    constructor() ERC721A("Rug or Diamond", "ROD") {
        _grantRole(DEFAULT_ADMIN_ROLE, 0x8b73ABfcD04338E0064D7fD09A98C4fE299531e9);
        _grantRole(ADMIN, 0x8b73ABfcD04338E0064D7fD09A98C4fE299531e9);
        _grantRole(DEVELOPER, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || 
        super.supportsInterface(interfaceId) ||
        interfaceId == 0x01ffc9a7 ||
        interfaceId == 0x80ac58cd ||
        interfaceId == 0x5b5e139f;
    }

    function mint(uint256 quantity, bytes32[] calldata _merkleProof) external {
        require(!paused, "The contract is paused.");
        require(presale || publicsale, "Sale has not started yet.");
        require(quantity == 1, "No more than one NFT.");
        require(totalSupply() + quantity <= maxSupply, "The total supply limit has been reached.");
        if(presale) {
            require(balanceOf(msg.sender) == 0, "You have already mintend an NFT.");
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, _merkleRootWhitelisted, leaf), "You are not Whitelisted.");
            whitelistClaimed[msg.sender] = true;
        } else if(publicsale) {
            if(whitelistClaimed[msg.sender])
                require(balanceOf(msg.sender) == 1, "You have already mintend two NFTs.");
            else
                require(balanceOf(msg.sender) == 0, "You have already mintend an NFT in Public Sale.");
        }
        _safeMint(msg.sender, quantity);
        emit NewrugOrDiamondNFTMinted(_nextTokenId() - 1);
    }

    function burn(uint256 tokenId, bool approvalCheck) external {
        require(!paused, "The contract is paused.");
        _burn(tokenId, approvalCheck);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Modifier to check if msg.sender is Admin or Developer.

    modifier isAdminOrDeveloper() {
        require(hasRole(ADMIN, msg.sender) || hasRole(DEVELOPER, msg.sender), "The account does not have ADMIN or DEVELOPER role.");
        _;
    }

    // Privileged actions.

    function setBaseURI(string calldata uri) external {
        require(hasRole(ADMIN, msg.sender) || hasRole(DEVELOPER, msg.sender));
        baseURI = uri;
    }

    function setPresale(bool value) external isAdminOrDeveloper {
        presale = value;
    }

    function setPublicSale(bool value) external isAdminOrDeveloper {
        publicsale = value;
    }

    function setPaused(bool value) external isAdminOrDeveloper {
        paused = value;
    }

    function setMerkleRoot(bytes32 _newRoot) external isAdminOrDeveloper {
        _merkleRootWhitelisted = _newRoot;
    }
}
