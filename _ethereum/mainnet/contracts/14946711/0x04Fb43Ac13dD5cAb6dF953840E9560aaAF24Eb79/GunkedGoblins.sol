// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract GunkedGoblins is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MAX_PUBLIC_MINT = 20;
    uint256 public constant MAX_WHITELIST_MINT = 1;
    uint256 public PUBLIC_SALE_PRICE = 0.01 ether;
    uint256 public constant WHITELIST_SALE_PRICE = 0 ether;
    uint256 public TOTAL_WHITELIST_MINTS = 200;
    uint256 public TOTAL_FREE_MINTS = 1000;
    uint256 public MAX_FREE_MINTS = 1000;

    string private  baseTokenUri;
    string public   placeholderTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause;
    bool public teamMinted; 

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;


    constructor() ERC721A("Gunkedgoblintown.wtf", "GNKGOB"){
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Gunkedgoblintown.wtf :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        if(TOTAL_FREE_MINTS != 0 ) {
            require(!pause, "Gunkedgoblintown.wtf :: Minting is on Pause");
            require((totalSupply() + _quantity) <= TOTAL_FREE_MINTS, "Gunkedgoblintown.wtf :: Cannot mint beyond max free mints");
            require(_quantity <= MAX_PUBLIC_MINT, "Gunkedgoblintown.wtf :: Cannot mint more than 20 tokens at a time..");
            _safeMint(msg.sender, _quantity);
            TOTAL_FREE_MINTS--;
        } else {
            require(!pause, "Gunkedgoblintown.wtf :: Minting is on Pause");
            require((totalSupply() + _quantity) <= MAX_SUPPLY, "Gunkedgoblintown.wtf :: Beyond Max Supply");
            require(_quantity <= MAX_PUBLIC_MINT, "Gunkedgoblintown.wtf :: Cannot mint more than 20 tokens at a time..");
            require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Gunkedgoblintown.wtf :: Payment is below the price");
            _safeMint(msg.sender, _quantity);
        }

    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(whiteListSale, "Gunkedgoblintown.wtf :: Minting is on Pause");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Gunkedgoblintown.wtf :: Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "Gunkedgoblintown.wtf :: Cannot mint beyond whitelist max mint!");
        require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "Gunkedgoblintown.wtf :: Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "Gunkedgoblintown.wtf :: You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserveMint() external onlyOwner{
        _safeMint(msg.sender, 888);
    }


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

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }
	
	function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
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

    function withdraw() public payable onlyOwner {
    // This will payout the owner 100% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}