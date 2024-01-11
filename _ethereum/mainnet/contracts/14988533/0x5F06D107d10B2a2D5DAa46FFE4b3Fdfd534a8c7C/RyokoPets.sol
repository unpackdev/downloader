//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC2981.sol";
import "./Options.sol";

contract RyokoPets is ERC721A, ERC2981, Ownable, ReentrancyGuard, Options{
    string private baseURI;
    constructor(
        string memory _initBaseURI,
        string memory _initContractURI,
        uint96 _royaltyFees,
        uint256 _initCost
    ) ERC721A("RyokoPets", "RPETS") ReentrancyGuard(){
        setBaseURI(_initBaseURI);
        setContractURI(_initContractURI);
        setRoyaltyFees(msg.sender, _royaltyFees);
        setCost(_initCost);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function mint(uint256 _quantity) nonReentrant external payable callerIsUser publicSaleStep{
        require(_quantity > 0);
        require(_quantity <= maxMintAmount);
        if(block.timestamp > blockTime){
            maxPublicSupply = maxSupply;
        }
        require(totalSupply() + _quantity <= maxPublicSupply, "Not enough tokens left");
        require(_quantity + _numberMinted(msg.sender) <= maxMintAmount, "Exceeded the limit");
        require(msg.value >= mintCost * _quantity, "Not enough ether sent");
        _safeMint(msg.sender, _quantity);
    }
    function whiteListMint(bytes32[] calldata _proof) nonReentrant external callerIsUser publicSaleStep{
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(wlValid(_proof, _leaf), "Invalid proof");
        require(!wlTokens[msg.sender], "You already minted your token");
        wlTokens[msg.sender] = true;
        _safeMint(msg.sender, maxWlPerWallet);
    }
    function claimMint(bytes32[] calldata _proof) nonReentrant external callerIsUser callerIsRyokoHolder publicSaleStep{
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        require(claimValid(_proof, _leaf), "Invalid proof");
        require(!claimedTokens[msg.sender], "You already claimed");
        claimedTokens[msg.sender] = true;
        _safeMint(msg.sender, maxClaimPerWallet);
    }
    function holdersMint() nonReentrant external callerIsUser callerIsRyokoHolder publicSaleStep{
        require(!holdersMinted[msg.sender], "You already minted your token");
        holdersMinted[msg.sender] = true;
        _safeMint(msg.sender, holdersMintPerWallet);
    }
    function ownerMint(uint256 _quantity) external onlyOwner{
        _safeMint(msg.sender, _quantity);
    }
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }
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
        if(revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), baseExtension))
            : "";
    }
    function supportsInterface(bytes4 _interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
    //Only Owner
    function setStep(Steps _state) public onlyOwner {
        step = _state;
    }
    function setBlockTime(uint256 _time) external onlyOwner{
        blockTime = _time;
    }
    function reveal() public onlyOwner {
        revealed = true;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }
    function setRoyaltyFees(address _receiver, uint96 _newRoyaltyFees) public onlyOwner {
        _setDefaultRoyalty(_receiver, _newRoyaltyFees);
    }
    function setMaxMintAmount(uint256 _amount) external onlyOwner {
        maxMintAmount = _amount;
    }
    function setCost(uint256 _newCost) public onlyOwner {
        mintCost = _newCost;
    }
    function setWhiteListRoot(bytes32 _initwhiteListRoot) public onlyOwner {
        whiteListRoot = _initwhiteListRoot;
    }
    function setClaimListRoot(bytes32 _initclaimListRoot) public onlyOwner {
        claimListRoot = _initclaimListRoot;
    }
    function withdraw() nonReentrant public payable onlyOwner {
        (bool wd, ) = payable(owner()).call{value: address(this).balance}("");
        require(wd);
    }
}