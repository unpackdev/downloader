// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Tag.sol";

contract RealFace is ERC721, ERC721Enumerable, Ownable {

    enum SaleState {
        Off,
        Presale1,
        Presale2,
        Public
    }

    struct PresaleData {
        uint256 maxMintPerAddress;
        uint256 price;
        bytes32 merkleroot;
        mapping(address => uint256) tokensMintedByAddress;
    }

    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    SaleState public saleState;
    uint256 public maxSupply;
    uint256 public maxMintPerTransaction;
    uint256 public price;
    PresaleData[] public presaleData;
    address public beneficiary;
    string public baseURI;

    modifier whenPublicSaleStarted() {
        require(saleState==SaleState.Public,"Public Sale not active");
        _;
    }

     modifier whenSaleStarted() {
        require(
            saleState==SaleState.Presale1 || 
            saleState==SaleState.Presale2 ||
            saleState==SaleState.Public,
            "whenSaleStarted: Sale not active"
        );
        _;
    }
    
    modifier whenSaleOff() {
        require(
            saleState==SaleState.Off,
            "whenSaleOff: Sale is active"
        );
        _;
    }

    modifier isWhitelistSale(SaleState _saleState) {
        require(
            _saleState==SaleState.Presale1 || 
            _saleState==SaleState.Presale2, 
            "isWhitelistSale: Parameter must be a valid presale"
        );
        _;
    }

    modifier whenMerklerootSet(SaleState _presaleNumber) {
        require(presaleData[uint(_presaleNumber)].merkleroot!=0,"whenMerklerootSet: Merkleroot not set for presale");
        _;
    }

    modifier whenAddressOnWhitelist(bytes32[] memory _merkleproof) {
        require(MerkleProof.verify(
            _merkleproof,
            getPresale().merkleroot,
            keccak256(abi.encodePacked(msg.sender))
            ),
            "whenAddressOnWhitelist: Not on white list"
        );
        _;
    }

    constructor(
        address _beneficiary,
        string memory _uri
    ) 
    ERC721("Real Face", "FACES") 
    {

        price = 0.06 ether;
        beneficiary = _beneficiary;
        saleState = SaleState.Off;
        maxSupply = 7753;
        maxMintPerTransaction = 7;

        baseURI = _uri;
        presaleData.push();

        //Presale 1
        createPresale(5, 0.04 ether);
        //Presale 2
        createPresale(3, 0.05 ether);

    }

    function createPresale(
        uint256 _maxMintPerAddress, 
        uint256 _price
    )
        private
    {
        PresaleData storage presale = presaleData.push();

        presale.maxMintPerAddress = _maxMintPerAddress;
        presale.price = _price;
    }

    function startPublicSale() external onlyOwner() whenSaleOff(){
        saleState = SaleState.Public;
    }

    function startWhitelistSale(SaleState _presaleNumber) external 
        whenSaleOff()
        isWhitelistSale(_presaleNumber) 
        whenMerklerootSet(_presaleNumber)
        onlyOwner() 
    {
        saleState = _presaleNumber;
    }
    
    function stopSale() external whenSaleStarted() onlyOwner() {
        saleState = SaleState.Off;
    }

    function mintPublic(uint256 _numTokens) external payable whenPublicSaleStarted() {
        uint256 supply = totalSupply();
        require(_numTokens <= maxMintPerTransaction, "mintPublic: Minting too many tokens at once!");
        require(supply.add(_numTokens) <= maxSupply, "mintPublic: Not enough Tokens remaining.");
        require(_numTokens.mul(price) <= msg.value, "mintPublic: Incorrect amount sent!");

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, supply.add(1).add(i));
        }
    }

    function mintWhitelist(uint256 _numTokens, bytes32[] calldata _merkleproof) external payable 
        isWhitelistSale(saleState)
        whenMerklerootSet(saleState)
        whenAddressOnWhitelist(_merkleproof)
    {
        uint256 currentSupply = totalSupply();
        uint256 numWhitelistTokensByAddress = getPresale().tokensMintedByAddress[msg.sender];
        
        require(numWhitelistTokensByAddress.add(_numTokens) <= getPresale().maxMintPerAddress,"mintWhitelist: Exceeds the number of whitelist mints");
        require(currentSupply.add(_numTokens) <= maxSupply, "mintWhitelist: Not enough Tokens remaining in sale.");
        require(_numTokens.mul(getPresale().price) <= msg.value, "mintWhitelist: Incorrect amount sent!");
  
        for (uint256 i; i < _numTokens; i++) {
            _safeMint(msg.sender, currentSupply.add(1).add(i));
        }

        getPresale().tokensMintedByAddress[msg.sender] = numWhitelistTokensByAddress.add(_numTokens);
    
    }

    function mintReserveTokens(address _to, uint256 _numTokens) public onlyOwner {
        require(saleState==SaleState.Off,"mintReserveTokens: Sale must be off to reserve tokens");
        require(_to!=address(0),"mintReserveTokens: Cannot mint reserve tokens to the burn address");
        uint256 supply = totalSupply();
        require(supply.add(_numTokens) <= maxSupply, "mintReserveTokens: Cannot mint more than max supply");
        require(_numTokens <= 50,"mintReserveTokens: Gas limit protection");

        for (uint256 i; i < _numTokens; i++) {
            _safeMint(_to, supply.add(1).add(i));
        }
    }

    function getPresale() private view returns (PresaleData storage) {
        return presaleData[uint(saleState)];
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function setMerkleroot(SaleState _presaleNumber, bytes32 _merkleRoot) public 
        whenSaleOff() 
        isWhitelistSale(_presaleNumber)
        onlyOwner 
    {
        presaleData[uint(_presaleNumber)].merkleroot = _merkleRoot;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        require(payable(beneficiary).send(balance));
    }

    function tokensInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}
