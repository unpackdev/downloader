//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./StringsUpgradeable.sol";

import "./BatchReveal.sol";

contract BasedGhouls is ERC721Upgradeable, ERC2981Upgradeable, AccessControlUpgradeable, BatchReveal {
    using StringsUpgradeable for uint256;

    mapping (address => bool) public allowListRedemption;
    mapping (address => uint16[]) public ownedNFTs;

    bool public isMintable;
    uint16 public totalSupply;
    uint16 public maxGhouls;

    string public baseURI;
    string public unrevealedURI;

    bytes32 public MERKLE_ROOT;

    function initialize() initializer public {
        __ERC721_init("Based Ghouls", "GHLS");
        maxGhouls = 6666;
        baseURI = "https://ghlstest.s3.amazonaws.com/json/";
        unrevealedURI = "https://ghlsprereveal.s3.amazonaws.com/json/Shallow_Grave.json";
        MERKLE_ROOT = 0x43462521f09038fad70d2515b4dd7ed043b8e5802b16b42885cb8887d14b5d48;
        lastTokenRevealed = 0;
        isMintable = false;
        totalSupply = 0;
        _setDefaultRoyalty(0x475dcAA08A69fA462790F42DB4D3bbA1563cb474, 690);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(DEFAULT_ADMIN_ROLE, 0x98CCf605c43A0bF9D6795C3cf3b5fEd836330511);
    }

    function updateBaseURI(string calldata _newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newURI;
    }

    function updateUnrevealedURI(string calldata _newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        unrevealedURI = _newURI;
    }
 
    function setMintability(bool _mintability) public onlyRole(DEFAULT_ADMIN_ROLE) {
        isMintable = _mintability;
    }

    // u gotta... GOTTA... send the merkleproof in w the mint request. 
    function mint(bytes32[] calldata _merkleProof) public {
        require(isMintable, "NYM");
        require(totalSupply < maxGhouls, "OOG");
        address minter = msg.sender;
        require(!allowListRedemption[minter], "TMG");
        bytes32 leaf = keccak256(abi.encodePacked(minter));
        bool isLeaf = MerkleProofUpgradeable.verify(_merkleProof, MERKLE_ROOT, leaf);
        require(isLeaf, "NBG");
        allowListRedemption[minter] = true;
        totalSupply = totalSupply + 1;
        ownedNFTs[minter].push(totalSupply - 1);
        _mint(minter, totalSupply - 1);
        if(totalSupply >= (lastTokenRevealed + REVEAL_BATCH_SIZE)) {
            uint256 seed;
            unchecked {
                seed = uint256(blockhash(block.number - 69)) * uint256(block.timestamp % 69);
            }
            setBatchSeed(seed);
        }
    }


    function tokenURI(uint256 id) public view override returns (string memory) {
        if(id >= lastTokenRevealed){
            return unrevealedURI;
        } else {
             return string(abi.encodePacked(baseURI, getShuffledTokenId(id).toString(), ".json"));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC2981Upgradeable, ERC721Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
