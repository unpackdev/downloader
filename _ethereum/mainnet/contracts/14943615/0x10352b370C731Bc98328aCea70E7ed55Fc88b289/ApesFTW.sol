// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract ApesFTW is ERC721A("Apes FTW", "AFTW"), Ownable{
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 6969;
    uint256 public MAX_MINT = 3;

    string private baseTokenUri;

    bool public publicSale;
    bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Apes FTW :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external callerIsUser{
        require((totalSupply() + _quantity) < MAX_SUPPLY, "Apes FTW :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] + _quantity) <= MAX_MINT, "Apes FTW :: Already Minted 3");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external callerIsUser{
        require((totalSupply() + _quantity) < MAX_SUPPLY, "Apes FTW :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] + _quantity) <= MAX_MINT, "Apes FTW :: Already Minted 3");

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "Apes FTW :: You are not whitelisted");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(address _to, uint256 _quantity) external onlyOwner{
        require(!teamMinted, "Apes FTW :: Team already minted");
        teamMinted = true;
        _safeMint(_to, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, tokenId.toString())) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

}