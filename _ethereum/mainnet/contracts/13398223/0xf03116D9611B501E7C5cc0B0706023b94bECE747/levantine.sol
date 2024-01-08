// SPDX-License-Identifier: MIT 
// Levantine NFT -- https://levantine-nft.art , regoumbare

pragma solidity >=0.8.7;

import "./Context.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./ERC721.sol";
import "./Ownable.sol";



// =============================================================  LevantineS ============================================================================ //

pragma abicoder v2;

contract Levantine is ERC721Enumerable, Ownable {
    
   using SafeMath for uint256;

// price of a SpaceTime
    uint256 public levantinePrice = 3000000000000000; 

// max number of Levantine to purchase
    uint public constant MAX_LEVANTINE_PURCHASE = 11;

// max number of LEVANTINE overall
    uint256 public MAX_LEVANTINES = 346;

// Freeze once development / test phase is over -- can never be changed
    bool public contractParamsFrozen = false;

// is sale active?
    bool public saleIsActive = false;

// token name
    string private _name;

// base uri
    string private _mybaseuri;

// mapping from token ID to name
    mapping (uint256 => string) public levantineNames;

// mapping from tokenid
    mapping (uint256 => bool) public mintedTokens;
    
// mapping from tokenid
    mapping (uint256 => bool) public nameSet;

// event for setting name of a LEVANTINE
    event NameChange (uint256 indexed nameIndex, string newName);
    
    // Reserve levantines for promotional purposes
    uint public LEVANTINE_RESERVE = 7;

    constructor() ERC721("Levantine", "LV") { }
    
    function withdraw(address payable _owner) public onlyOwner {
        uint balance = address(this).balance;
        _owner.transfer(balance);
    }

    function updateMintPrice(uint256 newPrice) external onlyOwner {
        require(msg.sender == owner(), "only owner!");
        require(contractParamsFrozen == false, "contract params frozen!");
        levantinePrice = newPrice;
    }
    function updateSupply(uint256 newSupply) external onlyOwner {
        require(msg.sender == owner(), "only owner!");
        require(contractParamsFrozen == false, "contract params frozen!");
        MAX_LEVANTINES = newSupply;
    }

    // Once set Can never be unset -- allows tweaking before development is over then set once and that's it!
    function freezeContractParams() external onlyOwner {
        require(msg.sender == owner(), "only owner!");
        contractParamsFrozen = true;
    }
    
    function reserveLevantines(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= LEVANTINE_RESERVE, "Not enough reserve left for team");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        LEVANTINE_RESERVE = LEVANTINE_RESERVE.sub(_reserveAmount);
    }

    // override base class 
    function  _baseURI() internal override view virtual returns (string memory)  {
        return _mybaseuri;
    }    

    function setBaseURI(string memory baseURI) public onlyOwner {
        _mybaseuri = baseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setLevantineName(uint256 _tokenId, string calldata _currName) public {
        address owner = ownerOf(_tokenId);
        require(msg.sender == owner, "not the owner"); 
        require(nameSet[_tokenId] == false, "name already set"); 
        nameSet[_tokenId] = true;
        levantineNames[_tokenId] = _currName; 
        emit NameChange(_tokenId, _currName); // user can set any name. 
    }

    function viewLevantineName(uint _tokenId) public view returns(string memory){
        require( _tokenId < totalSupply(), "choose an levantine within range" );
        return levantineNames[_tokenId];
    }
    
    function mintLevantine(uint _numberOfTokens) public payable { 
        require(saleIsActive, "Sale is not active yet!");
        require(_numberOfTokens > 0 && _numberOfTokens <= MAX_LEVANTINE_PURCHASE, "you can mint only so many");
        require(totalSupply().add(_numberOfTokens) <= MAX_LEVANTINES, "no no, supply exceeded");
        require(msg.value >= levantinePrice.mul(_numberOfTokens), "insufficient eth ");
        
        for(uint i = 0; i < _numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_LEVANTINES) {
                _safeMint(msg.sender, mintIndex);
                mintedTokens[mintIndex] = true;
            }
        }
    }
}