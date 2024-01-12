// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Neanderlings is ERC721A("Neanderlings","Neanderlings"), Ownable{
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 700;
    uint256 public MAX_PUBLIC_MINT = 1;
    uint256 public MAX_WHITELIST_MINT = 1;
    //uint256 public constant PUBLIC_SALE_PRICE = .099 ether;
    //uint256 public constant WHITELIST_SALE_PRICE = .0799 ether;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause;
    //bool public teamMinted;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Neaderlings :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external callerIsUser{
        require(publicSale, "Neaderlings :: Not Yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Neaderlings :: Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Neaderlings :: Already minted 3 times!");
        //require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Neaderlings :: Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external callerIsUser{
        require(whiteListSale, "Neaderlings :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Neaderlings :: Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "Neaderlings :: Cannot mint beyond whitelist max mint!");
        //require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "Neaderlings :: Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "Neaderlings :: You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    // function teamMint() external onlyOwner{
    //     require(!teamMinted, "Neaderlings :: Team already minted");
    //     teamMinted = true;
    //     _safeMint(msg.sender, 200);
    // }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        }
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
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
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function setMaxPublicMint(uint256 _maxPublicMint) external onlyOwner{
        MAX_PUBLIC_MINT = _maxPublicMint;
    }

    function setMaxWhitelistMint(uint256 _maxWhitelistMint) external onlyOwner{
        MAX_WHITELIST_MINT = _maxWhitelistMint;
    }

    function setSupply(uint256 _supply) external onlyOwner{
        MAX_SUPPLY = _supply;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }
}