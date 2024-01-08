// SPDX-License-Identifier: MIT
                                                                                                                                     
      //(,@                                            @.,&            
     //(/                                  (@%  &       &@//            
    //@(       %*@(*(@& #      &#&  @,.@  @@#@#@,@.      @&//          
   //@/         @@#   ./@..    &%(*@& ,*  @@ &, @ &.      %(@//         
   //@/          *#(/(%%  &    (,*.&       %@% @           (@./         
   //#&       @ *@@, .(  #@    (%&         (@.#/           %&//          
   //@       ...&      %  @    #**         (& ,@/          ,@*         
    //&      &# * #@*&    @#   %.#         # &* ,@@@      %@//         
    //%&       /( .#%     #/   @&            # *         &(@          
     //*@@,                                             @.%/%           
       //&                                             #@%             
                                                                                
pragma solidity >=0.8.6;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./Mirage.sol";

contract ProcessedArtManifest is ERC721Enumerable, ERC721URIStorage, AccessControl, Ownable {

    event mintedManifest(bytes32 indexed tokenHash, bytes32 indexed mirageHash);
    event processedMirage(uint256 indexed mirageId);
    event PermanentURI(string _value, uint256 indexed _id);

    ProcessedArtMirage private immutable mirage;

    string internal _currentBaseURI = "https://api.processed.art/manifest/";
    string public scriptArweave = "";
    string public scriptIPFS = "";
    
    bool public isActive = false;
    uint256 public totalMints = 0;
    uint256 public constant maxManifests = 768;

    uint256 public constant royaltiesPercentage = 10;
    address private _royaltiesReceiver;
    mapping (uint256 => bool) private _mirageMinted;
    mapping (uint256 => bytes32) public tokenHash;
    mapping (uint256 => bytes32) public mirageHash;

    constructor(address mirageAddress) ERC721("processed (art): manifest", "MANIFEST")  {
        _royaltiesReceiver = msg.sender;
        mirage = ProcessedArtMirage(mirageAddress);
        transferOwnership(msg.sender);
    }

    function baseURI() public view virtual returns (string memory) {
        return _currentBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory theURI) public onlyOwner {  
        _currentBaseURI = theURI;
    }

    function freezeMetadata(string memory theURI, uint256 token_id) public onlyOwner {  
        emit PermanentURI(theURI, token_id);
    }

    function setScriptIPFS(string memory _scriptIPFS) public onlyOwner {  
        scriptIPFS = _scriptIPFS;
    }

    function setScriptArweave(string memory _scriptArweave) public onlyOwner {  
        scriptArweave = _scriptArweave;
    }

    function royaltiesReceiver() external view returns(address) {
        return _royaltiesReceiver;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 100;
        return (_royaltiesReceiver, _royalties);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens ) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            for (uint256 i=0; i<tokenCount; i++) {
                result[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return result;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _generateRandomHash(bytes32 mirageSeed) internal view returns (bytes32) {
        return keccak256(abi.encode(blockhash(block.number-1), block.coinbase, totalMints, tokenHash[totalMints-1], mirageSeed));
    }

    function processManifest(uint256 mirageId) public payable {
        require(isActive, "chill, the minting is not yet active");
        require(totalMints < maxManifests, "inconceivable");
        require(mirage.ownerOf(mirageId) == msg.sender, "address must own mirage to be processed");
        require(!_mirageMinted[mirageId], "mirage has already been processed");
        _mirageMinted[mirageId] = true;
        totalMints = totalMints + 1;
        tokenHash[totalMints] = _generateRandomHash(mirage.tokenHash(mirageId));
        mirageHash[totalMints] = mirage.tokenHash(mirageId);
        _safeMint(msg.sender, totalMints);
        emit processedMirage(mirageId);
        emit mintedManifest(tokenHash[totalMints], mirageHash[totalMints]);
    }

    function flipState() public onlyOwner {
        isActive = !isActive;
    }
 
    function sweep() public onlyOwner {  
        uint balance = address(this).balance;
        address payable to;
        to.transfer(balance);
    }

    function setRoyaltiesReceiver(address newRoyaltiesReceiver) external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
