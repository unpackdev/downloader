// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol"; 
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./recovery.sol";

contract GrayMatter is Ownable, ERC721Enumerable, recovery{

    uint256 public cost;
    string private _baseTokenURI;    
    string public GM_PROVENANCE = "459e07abfad91ae093e24bf7cd24de7f6b9e3187f7e056966af73b1be5621ac5"; 
    uint256 public constant maxSupply = 8080;
    uint256 public maxMintAmount = 20;
    bool public isSaleActive = true;  // can mint

    address payable public wallet; 
    event NothingToRedeem();

    constructor(
        string memory _initBaseURI,
        address payable _wallet
    ) ERC721("GrayMatter", "GRM") {
        setBaseURI(_initBaseURI);
        setWallet(_wallet);
        setCost(0.08 ether);
    }

    //SHA256(concat(for all images SHA256(images)) 
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        GM_PROVENANCE = _provenanceHash;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _baseU) public onlyOwner {
        _baseTokenURI = _baseU;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost   = _newCost;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
    
    function setWallet(address payable _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function setSaleActive(bool _state) public onlyOwner {
        isSaleActive = _state;
    }
   
    function mint(address _to, uint256 _mintAmount) public payable {
        uint mintIndex = super.totalSupply();
        require(_mintAmount > 0, "You cannot buy ZERO GM logo");
        require(_mintAmount <= maxMintAmount, "Exceeds maximum tokens you can purchase in a single transaction");
        require(mintIndex + _mintAmount <= maxSupply, "Exceeds maximum tokens available for purchase");        
        if (msg.sender != owner()) {            
            require(isSaleActive, "Sale is not active" );       
            require(msg.value >= cost * _mintAmount, "ETH value sent is not correct");             
        }        
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, mintIndex + i);
        }
        wallet.transfer(address(this).balance);        
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
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
}