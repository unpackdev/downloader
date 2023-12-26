// SPDX-License-Identifier: MIT
// Made with ❤ by Kraft Ai
pragma solidity ^0.8.4;
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract StrangerWorlds is ERC721A, Ownable{
    using Strings for uint256;
    string public baseURI;

    bool public isPresale = false;
    bool public isPublicSale = false;
    bool public isRevealed = false;

    bytes32 private merkleRoot;

    uint256 public maxSupply = 555;
    uint256 internal maxPublicSaleMint = 1;
    uint256 internal tokenId;
    uint256 public whitelistSize = 330;

    // Community managers
    address stelphar = 0x007bEf5FC4eAdCD0F8FD3d2aa656cAdbB523d341;
    address bobby = 0xdB7Fe6D9C53B9C15c04cfeEd2a3057c7297B782A;
    address monsieur_ri = 0xb8fe53EeFa79045Bf3ef6Ec7092547F552cC0BFf;

    // Collab & Promoters
    address collab_manager = 0xb866aC2683AA0d46d19f44AC2E3bA2e5B3C82959;
    address promoter = 0x2A8aB864Af376EB4167171fc9400B9314EC0Ef47;

    // Giveaways wallet
    address giveaway_wallet = 0x0Fc697AE7274213FbA53f6ddAA92d44734079B25;

    mapping(address => uint256) public addressMintedBalance;

    constructor(string memory name, string memory symbol,string memory _initBaseURI) 
    ERC721A(name, symbol)  
    {
        baseURI = _initBaseURI;
        _safeMint(giveaway_wallet,1);
        _safeMint(monsieur_ri,1);
        _safeMint(giveaway_wallet,1);
        _safeMint(monsieur_ri,1);
        
        for(uint256 i=0;i<=4;i++){
            _safeMint(stelphar,1);
            _safeMint(bobby,1);
            _safeMint(collab_manager,1);
            _safeMint(promoter,1);
        }
    }


    //Whitelist Mint
    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable{
        require(isPresale, "Whitelist sale is not activated");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        if(totalSupply() +_quantity <= ((maxSupply-24)-whitelistSize)*2){
            require(addressMintedBalance[msg.sender] + _quantity <= 2, "Max mint per wallet exceeded for presale");
        } else {
            require(addressMintedBalance[msg.sender] + _quantity <= 1, "Max mint per wallet exceeded for presale");
        }

        require(totalSupply() + _quantity <= maxSupply, "Max supply exceeded");
        _safeMint(_account, _quantity);
        addressMintedBalance[msg.sender] += _quantity;
        if (totalSupply() == maxSupply){
            isPresale = false;
        }
    }

    //Public Mint
    function publicSaleMint(address _account, uint _quantity) external payable{
        require(isPublicSale, "Public sale is not activated");
        require(totalSupply() + _quantity <= maxSupply, "Max supply exceeded");
        require(addressMintedBalance[msg.sender] + _quantity <= maxPublicSaleMint, "Public mint is 1 token only");
        _safeMint(_account, _quantity);
        addressMintedBalance[msg.sender] += _quantity;
        if(totalSupply() == maxSupply){
            isPublicSale = false;
        }
    }


    //Merkle Proof
    function isWhiteListed(address account, bytes32[] calldata proof) internal view returns(bool) {
        return _verify(_leaf(account), proof);
    }

    function _leaf(address account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    // URI's
     function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        if (isRevealed) {
            return bytes(_baseURI()).length > 0
                ? string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"))
                : "";
        }
        return _baseURI();
    }

    function reveal(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        isRevealed = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    // Sale Controls

    function StartPresale(bytes32 _merkleRoot) external onlyOwner{
        require(isPublicSale == false);
        merkleRoot = _merkleRoot;
        isPresale = true;
    }

    function StopPresale() external onlyOwner{
        require(isPublicSale == false);
        isPresale = false;     
    }
 
    function StartPublicSale() external onlyOwner{
        require(isPresale == false);
        isPublicSale = true;
    }

    function StopPublicSale() external onlyOwner {
        isPublicSale = false;
    } 
}