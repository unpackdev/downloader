// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./IERC2981.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

contract SamuraiCollection is ERC721URIStorage, Ownable, AccessControl, Pausable, IERC2981  {
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint256 constant TOTAL_SUPPLY = 10144;
    uint256 constant INITIAL_TOKENID = 3700;
    
    Counters.Counter private _tokenIds;
    string private _baseTokenUri;

    uint256 public mintPrice = 0.1 ether;    
    address public beneficiary;
    address public royalties; 
    bytes32 public merkleRoot;
    bool public isActive = false;  
    uint256 public royaltyFee = 425;
    bool public whiteListRequired = true;

    constructor(address _beneficiary, address _royalties, string memory _baseUrl) ERC721("NFTrader Samurai Presale", "NFTS"){
        beneficiary = _beneficiary;
        royalties = _royalties;
        _baseTokenUri = _baseUrl;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _tokenIds.setInitialValue(INITIAL_TOKENID);
    }    

    event TraderMinted(uint256 tokenId);

    function _mintTrader() private whenNotPaused returns (uint){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();        
        
        _safeMint(msg.sender, newItemId);
                
        emit TraderMinted(newItemId);
        return newItemId;
    }

    function ownerMint(uint256 count) public onlyOwner whenNotPaused returns (uint256[] memory){  
        require(count > 0, "Must insert value");
        uint256 currentId = _tokenIds.current();      
        require(currentId + count < TOTAL_SUPPLY + INITIAL_TOKENID, "Maximum supply reached"); //plus 3700 because the item id starts by 3701
        
        uint256[] memory tokens = new uint256[](count);

        for (uint256 index = 0; index < count; index++) {
            tokens[index] = _mintTrader();
        }

        return tokens;
    }

    function mintTraders(uint256 count, uint256 _maxMintAllowed, bytes32[] calldata merkleProof) public payable whenNotPaused returns (uint256[] memory) {
        require(isActive, "Sale is closed");
        require(count > 0, "Must insert value");
        require(count <= _maxMintAllowed, "You have reached mint allowed");
        require((mintPrice * count) == msg.value, "Incorrect payable amount");
        require((_verify(merkleProof, msg.sender, _maxMintAllowed) || whiteListRequired == false), "Invalid proof");
       
        uint256 tokenBalance = balanceOf(msg.sender);
        require((tokenBalance + count) <= _maxMintAllowed, "Max allowed mint reached");

        uint256 currentId = _tokenIds.current();      
        require(currentId + count < TOTAL_SUPPLY + INITIAL_TOKENID, "Maximum supply reached"); //plus 3700 because the item id starts by 3701

        uint256[] memory tokens = new uint256[](count);

        for (uint256 index = 0; index < count; index++) {
            tokens[index] = _mintTrader();
        }

        return tokens;
    }

    function addBurnedRole(address account) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        _setupRole(BURNER_ROLE, account);
    }

    function burn(uint256 tokenId) public{
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _tokenIds.decrement();
        _burn(tokenId);
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function setRoyalties(address _royalties) public onlyOwner {
        royalties = _royalties;
    }

    function setActive(bool _isActive) public onlyOwner {
        isActive = _isActive;
    }

    function setMerkleProof(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current() - INITIAL_TOKENID;
    }

    function setRoyaltyFee(uint256 value) public onlyOwner{
        royaltyFee = value;
    }

    function setBaseUri(string memory value) public onlyOwner{
        _baseTokenUri = value;
    }

    function setWhiteListRequired(bool _whiteListRequired) public onlyOwner{
        whiteListRequired = _whiteListRequired;
    }

    function _baseURI() internal view override returns(string memory){
        return _baseTokenUri;
    }

    function withdraw() public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }

    function _verify(bytes32[] calldata merkleProof, address sender, uint256 maxAmount) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount.toString()));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }
   
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl, IERC165) returns (bool){
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }   

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
        _tokenId; // silence solc warning
        royaltyAmount = _salePrice * royaltyFee / 10000;
        return (royalties, royaltyAmount);
    } 
}