//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

contract Enderverse is ERC2981, ERC721A, Ownable, PaymentSplitter {

    using Strings for uint256;

    enum Step {
        Before,
        PreSale,
        PublicSale,
        SoldOut
    }

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 7777;
    uint public maxGift = 0;

    bytes32 public ogMerkleRoot;
    bytes32 public wlMerkleRoot;

    mapping(address => uint) public amountNFTsperWalletOG;
    mapping(address => uint) public amountNFTsperWalletWL;
    mapping(address => uint) public amountNFTsperWalletPublic;

    string public baseURI;
    string public baseExtension = ".json";
    uint public price = 0.007777 ether;
    uint public saleStartTime = 1658073600;

    uint private teamLength;
    address[] private team;

    constructor(string memory _baseURI, address[] memory _team, uint[] memory _teamShares, bytes32 _ogMerkleRoot, bytes32 _wlMerkleRoot, string memory _name, string memory _symbol) 
    ERC721A(_name, _symbol)
    PaymentSplitter(_team, _teamShares) {
        ogMerkleRoot = _ogMerkleRoot;
        wlMerkleRoot = _wlMerkleRoot;
        sellingStep = Step.Before;
        baseURI = _baseURI;
        teamLength = _team.length;
        team = _team;
        setFeeNumerator(1000); //10%
    }

    modifier checksPresale(uint _quantity) {
        checkPresale(_quantity);
        _;
    }

    function checkPresale(uint _quantity) internal view returns(bool) {
        require(sellingStep == Step.PreSale, "PreSale has not started yet");
        require(currentTime() >= saleStartTime, "Presale Startime has not started yet");
        require(currentTime() < saleStartTime + 180 minutes, "PreSale is finished");
        require(totalSupply() + _quantity <= MAX_SUPPLY - maxGift, "Max supply exceeded");
        return true;
    }

    function getMsgSender() public view returns(address)  {
        return msg.sender;
    }

    function presaleMint(uint16 _quantity, bytes32[] calldata _ogMerkleProof, bytes32[] calldata _wlMerkleProof) checksPresale(_quantity) public payable {
        bool allowedToMint = false;
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        bool isOG = MerkleProof.verify(_ogMerkleProof, ogMerkleRoot, leaf);
        if(isOG) {
            require(amountNFTsperWalletOG[msg.sender] + _quantity <= 2, "You can only get 2 NFTs as an OG");
            amountNFTsperWalletOG[msg.sender] += _quantity;
            allowedToMint = true;
        }
        else {
            bool isWL = MerkleProof.verify(_wlMerkleProof, wlMerkleRoot, leaf);
            if(isWL) {
                require(amountNFTsperWalletWL[msg.sender] + _quantity <= 1, "You can only get 1 NFT as a WL");
                amountNFTsperWalletWL[msg.sender] += _quantity;
                allowedToMint = true;
            }
            else {
                require(false, "Nor OG nor WL !");
            }   
        }
        if(allowedToMint){
            _safeMint(msg.sender, _quantity);
        }
        else {
            require(false, "You can't mint NFTs");
        }
    }

    function ogMint(uint16 _quantity, bytes32[] calldata _ogMerkleProof) checksPresale(_quantity) public payable {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_ogMerkleProof, ogMerkleRoot, leaf), 'Invalid OG proof!');
        require(amountNFTsperWalletOG[msg.sender] + _quantity <= 2, "You can only get 2 NFTs as an OG");
        amountNFTsperWalletOG[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function wlMint(uint16 _quantity, bytes32[] calldata _wlMerkleProof) checksPresale(_quantity) public payable {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_wlMerkleProof, wlMerkleRoot, leaf), 'Invalid WL proof!');
        require(amountNFTsperWalletWL[msg.sender] + _quantity <= 2, "You can only get 1 NFT as a WL");
        amountNFTsperWalletWL[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint16 _quantity) public payable {
        require(sellingStep == Step.PublicSale, "Publis sale has not started yet");
        require(msg.value >= price * _quantity, "Not enought funds");
        require(amountNFTsperWalletPublic[msg.sender] + _quantity <= 4, "You can only get 4 NFTs per wallet");
        require(totalSupply() + _quantity <= MAX_SUPPLY + maxGift, "Max supply exceeded");
        amountNFTsperWalletPublic[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

     function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString(), baseExtension));
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

     function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

    function setStep(uint8 _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function setMaxGift(uint _maxGift) external onlyOwner {
        maxGift = _maxGift;
    }

    function setOGMerkleRoot(bytes32  _ogMerkleRoot) external onlyOwner {
        ogMerkleRoot = _ogMerkleRoot;
    }

    function getOGMerkleRoot() external view onlyOwner returns (bytes32){
        return ogMerkleRoot ;
    }

    function setWLMerkleRoot(bytes32 _wlMerkleRoot) external onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    function getWLMerkleRoot() external view onlyOwner returns (bytes32){
        return wlMerkleRoot ;
    }

    function releaseAll() external onlyOwner {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721A).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}
