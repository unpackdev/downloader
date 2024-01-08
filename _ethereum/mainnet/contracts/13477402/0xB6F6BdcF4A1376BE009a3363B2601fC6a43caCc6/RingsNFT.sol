//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Strings.sol";

contract RingsNFT is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 _tokensCount,
        uint256 _value
    );

    address payable public ownerAddress;
    address public admin;
    string public projectBaseURI = 'https://andrewfernandez-art-api.herokuapp.com/projects/0/tokens/metadata/';
    string public script;
    bool public active = false;
    uint256 public maxPurchaseable = 1;
    uint256 public maxTokens = 999;
    uint256 public tokensCount;
    uint256 public pricePerTokenInWei = 0;
    
    mapping(uint256 => bytes32[]) internal tokenIdToHashes; // what tokens belong to what hashes
    
    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID does not exist");
        _;
    }

    //only allow this if the sender is an admin
    modifier onlyAdmin() {  
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor() ERC721("RingsNFT", "RINGS") {
        admin = msg.sender; // set admin to the creator
        ownerAddress = payable(msg.sender); //set the payable address to the creator
    }

    function mint(uint256 tokenQuantity) external payable {
        require(!_isContract(msg.sender), "Contract minting is not allowed"); // dont let contracts mints
        require(tokenQuantity > 0, "You must mint at least one."); // gotta mint atleast 1
        require(tokenQuantity <= maxPurchaseable, "You are minting too many at once!"); // minting more than max allowed
        
        // don't allow overminting the max invocations
        require(totalSupply() + tokenQuantity <= maxTokens, "The amount you are trying to mint exceeds the max supply of 999."); 
        
        //the project must be active or its the admin
        require(active || msg.sender == admin, "Project must exist and be active");

        //make sure the amount per token is corrent in the message value
        require(pricePerTokenInWei * tokenQuantity <= msg.value, "Incorrect Ether value.");

        //loop through how many the user wants and call mint of the specific project
        for (uint256 i = 0; i < tokenQuantity; i++) {
            //call the minttoken method for the project
            _mintToken(msg.sender);
        }
    }

    // mint function take the to address , project, and returns a token id...only internal method
    function _mintToken(address _to) internal returns (uint256 _tokenId) {

        //set the token id ..project 0 * million + token id ex: 0*1M + 2045 = 2045 for project 0
        uint256 tokenIdToBe = tokensCount;
        
        // update the internal count of invocations
        tokensCount = tokensCount.add(1);

        //create a hash based on the project id invocations number
        bytes32 hash = keccak256(abi.encodePacked(tokensCount, block.number.add(1), msg.sender));
        
        //add that hash to the tokenIdToBe hash
        tokenIdToHashes[tokenIdToBe].push(hash);

        //call the real safemint to create the token
        _safeMint(_to, tokenIdToBe);

        // emit the mint event
        emit Mint(_to, tokenIdToBe, tokensCount, pricePerTokenInWei);

        // return the token ID
        return tokenIdToBe;
    }

    //gets the token hash for the script for the art
    function showTokenHashes(uint _tokenId) public view returns (bytes32[] memory){
        return tokenIdToHashes[_tokenId];
    }

    // update the project price
    function updatePricePerTokenInWei(uint256 _pricePerTokenInWei) onlyAdmin external {
        pricePerTokenInWei = _pricePerTokenInWei;
    }

    //get the tokenURI for the project
    function tokenURI(uint256 _tokenId) public view virtual override onlyValidTokenId(_tokenId) returns (string memory) {
        return string(abi.encodePacked(projectBaseURI, Strings.toString(_tokenId)));
    }

    //set the scripts
    function updateScript(string memory _script)  onlyAdmin external {
        require(tokensCount == 0, "Can not switch after a 1 is minted.");
        script = _script;
    }

    //toggle as active
    function toggleIsActive() public onlyAdmin {
        active = !active;
    }

    //update project URI
    function updateProjectBaseURI(string memory _projectBaseURI) public onlyAdmin {
        projectBaseURI = _projectBaseURI;
    }

    //transfer ownership of project to a new owner
    function transferOwnership(address newOwner) public override onlyOwner {
        //make sure its not an empty address
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        //set the new owner to admin
        admin = newOwner;
        //update the payout address so its the new owner
        ownerAddress = payable(newOwner);
        //call the loaded transfer method
        super.transferOwnership(newOwner);
    }

    function _isContract(address _addr) internal view returns (bool) {
		uint32 _size;
		assembly {
			_size:= extcodesize(_addr)
		}
		return (_size > 0);
	}

}


