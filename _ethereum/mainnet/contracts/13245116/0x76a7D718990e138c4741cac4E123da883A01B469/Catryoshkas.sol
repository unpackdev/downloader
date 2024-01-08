//SPDX-License-Identifier: Unlicense
pragma solidity ^ 0.8.0;
import "./Ownables.sol";
import "./IE721Comp.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
contract Catryoshkas is ERC721, IE721Comp, ERC721Enumerable, Ownables {

    using SafeMath for uint256;

    string private _metadataAPI;

    bool private _hasSaleStarted = false;
    bool private _hasPresaleStarted = true;

    uint256 private _drops;
    uint256 private _kittensMinted;
    uint256 private _bigCatsMinted;
    uint256 private _MINT_PRICE = 0.06 ether;
    uint256 private constant _MAX_MINT_SUPPLY = 8888;
    uint256 private constant _PRESALE_MAX_SUPPLY = 1000;

    mapping(uint256 => bool) private _catsBreed;
    
    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        string memory initMetadataAPI_,
        address secondOwner_
    ) ERC721(tokenName_, tokenSymbol_) {

        _metadataAPI = initMetadataAPI_;
        _setSecondOwner(secondOwner_);

    }
  
    function mintTokens(uint256 numberOfTokens_) public payable {
        
        require(_hasSaleStarted || _hasPresaleStarted,  "Invalid mint action");
        require(msg.value >= numberOfTokens_.mul(_MINT_PRICE),  "Invalid ether value");
        
        if(_hasPresaleStarted){

            require(totalMintedSupply().add(numberOfTokens_) <= _PRESALE_MAX_SUPPLY, "Exceeds presale limit");

        }

        if(_hasSaleStarted){

             require(
                totalMintedSupply().add(numberOfTokens_) <= _MAX_MINT_SUPPLY,
                "Exceeds mint supply"
            );

        }

        _mintTokens(numberOfTokens_);
        
    }

    function _mintTokens(uint256 numberOfTokens_) internal {
        
        for (uint256 index = 0; index < numberOfTokens_; index++) {

            uint256 nextKittenIndex = _MAX_MINT_SUPPLY.add(111).add(_kittensMinted);

            _safeMint(_msgSender(), totalMintedSupply());
            
            if(isKittenCreator(totalMintedSupply())) {

                _safeMint(_msgSender(), nextKittenIndex);

                _kittensMinted = _kittensMinted.add(1);

            }
           

        }

    }

   
    function breed(uint256 idCat1_ , uint256 idCat2_) public {

        require(_bigCatsMinted <= 111, "all big cats minted");

        require( ownerOf(idCat1_) == _msgSender(), "cat1 not owned");
        require( ownerOf(idCat2_) == _msgSender(), "cat2 not owned");

        require(isSpecialCat(idCat1_), "cat1 not special");
        require(isSpecialCat(idCat2_), "cat2 not special");

        require(!hasBreed(idCat1_), "cat1 has breed");
        require(!hasBreed(idCat2_), "cat2 has breed");

        _safeMint(_msgSender(), _MAX_MINT_SUPPLY.add(_bigCatsMinted));

        _bigCatsMinted = _bigCatsMinted.add(1);

        _catsBreed[idCat1_] = true;
        _catsBreed[idCat2_] = true;

    }

    function setMetadataAPI(string memory newMetadataAPI_) public onlyOwner {

        _metadataAPI = newMetadataAPI_;

    }

    function toggleSaleStarted() public onlyOwners {

        _hasSaleStarted = !_hasSaleStarted;

    }

    function togglePresaleStarted() public onlyOwners {

        _hasPresaleStarted = !_hasPresaleStarted;

    }
    
    function setMintPrice(uint newPrice_) public onlyOwners {
        _MINT_PRICE = newPrice_;
    }

    function maxMintSupply() public pure returns (uint256) {
        return _MAX_MINT_SUPPLY;
    }
    
    function mintPrice() public view returns (uint256) {
        return _MINT_PRICE;
    }
    
    function bigCatsMinted() public view returns (uint256) {
        return _bigCatsMinted;
    }

    function kittensMinted() public view returns (uint256) {
        return _kittensMinted;
    }

    function drops() public view returns (uint256) {
        return _drops;
    }

    function hasBreed(uint256 id_) public view returns(bool) {

        require(isSpecialCat(id_), "Not special cat");

        return _catsBreed[id_];

    }

    function hasSaleStarted() public view returns(bool) {

        return _hasSaleStarted;

    }
    
    function hasPresaleStarted() public view returns(bool) {

        return _hasPresaleStarted;

    }

    function totalMintedSupply() public view returns(uint256) {

        return totalSupply().sub(reserveSupplyMinted());

    }

    function reserveSupplyMinted() public view returns(uint256) {

        return _drops.add(_kittensMinted).add(_bigCatsMinted); 

    }
    
    function giveAway(uint256[] memory numberOfTokens_, address[] memory toAddresses_) public onlyOwners {

        require(totalSupply() <= 10000);

        for (uint256 addressIndex = 0; addressIndex < toAddresses_.length; addressIndex++) {

            address reciever = toAddresses_[addressIndex];
            uint256 amount = numberOfTokens_[addressIndex];

            for (uint256 counter = 0; counter < amount; counter++) {
                    
                uint256 nextDropIndex = _MAX_MINT_SUPPLY.add(222).add(_drops);
                
                _safeMint(reciever, nextDropIndex);
                
                _drops = _drops.add(1);

            }

        }       

    }

    function _baseURI() internal view override returns(string memory) {
        return _metadataAPI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}

}