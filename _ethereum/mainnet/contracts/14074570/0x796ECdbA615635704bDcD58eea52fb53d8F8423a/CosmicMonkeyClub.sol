// SPDX-License-Identifier: MIT
// Made with ❤ by Rens L
// Email: info@renslaros.com
// Twitter: @humanrens 
pragma solidity ^0.8.7;
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./VRFConsumerBase.sol";

contract CosmicMonkeyClub is ERC721Enumerable, Ownable, VRFConsumerBase {
    using Strings for uint256;
    string public CMC_PROVENANCE = "";
    string public baseURI = "";
    string public contractUrl = "";
    bytes32 private merkleRoot;
    bytes32 internal keyHash;
    uint256 public maxSupply = 10000;
    uint256 public maxPresaleSupply = 10000;
    uint256 public presalePrice = 0.088 ether;
    uint256 public publicPrice = 0.1 ether;
    uint256 internal maxPublicSaleMint = 30;
    uint256 internal maxMintPerTransaction = 6;
    uint256 internal maxPresaleMint = 4;
    uint256 internal fee;
    uint256 internal tokenId;
    uint256 public randomResult;
    bool public isPublicSale = false;
    bool public isPresale = false;
    bool public isRevealed = false;
    address[] public ogList;
    mapping(address => uint256) internal addressMintedBalance;
    constructor(string memory name, string memory symbol,string memory _initBaseURI) 
    ERC721(name, symbol) 
    VRFConsumerBase(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,0x514910771AF9Ca656af840dff83E8264EcF986CA) 
    {
        baseURI = _initBaseURI;
        // Chainlink VRF keyhash + fee
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; 
    }
    // Request random number from Chainlink VRF Coordinator
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(randomResult == 0);
        require(LINK.balanceOf(address(this)) >= fee);
        return requestRandomness(keyHash, fee);
    }
    // randomness callback function used by Chainlink VRF coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness + 1;
    }
    
    function mintPresale(uint256 _amount,address account, bytes32[] calldata proof) external payable {
        require(_amount > 0);
        require(randomResult > 0);
        require(_amount  <= maxPresaleMint);
        if (msg.sender != owner()) {
            require(isPresale,"Presale isn't live");
            require(isWhiteListed(account, proof), "You're not whitelisted");
            require(msg.value >= (presalePrice * _amount), "Amount to low");
            require((addressMintedBalance[msg.sender] + _amount) <= maxPresaleMint, "Max. 4 NFT's in Presale.");     
        }
        for (uint256 i = 1; i <= _amount; i++) {
            tokenId = ((randomResult + totalSupply()) % maxSupply);
            if(tokenId == 0){
                tokenId = maxSupply;
            }
            _safeMint(msg.sender, tokenId);
            addressMintedBalance[msg.sender]++;
            if(addressMintedBalance[msg.sender] == 4){
                ogList.push(msg.sender);
            }
        }
    }

     function mintPublicSale(uint256 _amount) external payable {
        require(_amount > 0 );
        require(randomResult > 0);
        require(_amount  <= maxMintPerTransaction, "Exceeding max. mint amount per tx.");
        require(totalSupply() + _amount <= maxSupply,"Amount exceeds max. supply");
        require(isPublicSale,"Public Sale isn't live");
        require(msg.value >= (publicPrice * _amount), "Amount is to low");
        require(_amount <= maxPublicSaleMint);    
        require((addressMintedBalance[msg.sender] + _amount) <= maxPublicSaleMint, "Max. 30 NFT's per wallet.");
        for (uint256 i = 1; i <= _amount; i++) {
            tokenId = ((randomResult + totalSupply()) % maxSupply);
            if(tokenId == 0){
                tokenId = maxSupply;
            }
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, tokenId);
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

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        CMC_PROVENANCE = provenanceHash;
    }

    // URI's
     function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        if (isRevealed) {
            return bytes(_baseURI()).length > 0
                ? string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"))
                : "";
        }
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function contractURI() public view returns (string memory) {
        return contractUrl;
    }

    function setContractUri(string memory _newContractUrl) public onlyOwner {
        contractUrl = _newContractUrl;
    }

    // Sale Controls

    function setPresalePrice(uint256 _amount) external onlyOwner {
        presalePrice = _amount; 
    }

    function setPublicPrice(uint256 _amount) external onlyOwner {
        publicPrice = _amount; 
    }

    function startPresale(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
        isPresale = true;
    }

    function stopPresale() external onlyOwner{
        require(isPublicSale == false);
        isPresale = false;     
    }
 
    function startPublicSale() external onlyOwner{
        require(isPresale == false);
        isPublicSale = true;
    }

    function stopPublicSale() external onlyOwner {
        isPublicSale = false;
    }

    function reveal(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function giftNftToAddress(address _sendNftsTo, uint256 _amount)
        external
        onlyOwner
    {
        require(randomResult > 0, "Generate random number first");
        require(totalSupply() + _amount <= maxSupply,"Gift amount exceeds max. supply");
        require(_amount <= 50,"Limit is 50 per transaction");
        for (uint256 i = 1; i <= _amount; i++){
            tokenId = ((randomResult + totalSupply()) % maxSupply);
            if(tokenId == 0){
                tokenId = maxSupply;            
            }
            _safeMint(_sendNftsTo,tokenId);
        }
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}