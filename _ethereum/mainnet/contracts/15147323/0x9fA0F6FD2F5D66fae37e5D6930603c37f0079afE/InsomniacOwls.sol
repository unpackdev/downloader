//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract InsomniacOwls is ERC721A, Ownable, ReentrancyGuard{

    string private baseURI;
    string public contractURI;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    string public baseExtension = ".json";
    bool public paused = true;

    constructor(
        string memory _initBaseURI,
        string memory _initContractURI,
        uint256 _initMaxSupply,
        uint256 _initMaxMintAmount,
        uint256 _initCost
    ) ERC721A("Insomniac Owls", "IO") ReentrancyGuard(){
        setBaseURI(_initBaseURI);
        setContractURI(_initContractURI);
        setMaxSupply(_initMaxSupply);
        setMaxMintAmount(_initMaxMintAmount);
        setCost(_initCost);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
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

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), baseExtension))
            : "";
    }

    function mint(uint256 _quantity) external payable nonReentrant callerIsUser{
        require(!paused);
        require(_quantity > 0);
        require(_quantity <= maxMintAmount);
        require(totalSupply() + _quantity <= maxSupply, "Not enough tokens left");

        require(msg.value >= cost * _quantity, "Not enough ether sent");
        require(
            _numberMinted(msg.sender) + _quantity <= maxMintAmount, "You have reached the mint limit."
        );
        _safeMint(msg.sender, _quantity);
    }

    function ownerMint(uint256 _quantity) external onlyOwner{
        _safeMint(msg.sender, _quantity);
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    function setMaxSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = _newSupply;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function withdraw() public payable nonReentrant onlyOwner {
        (bool wd, ) = payable(owner()).call{value: address(this).balance}("");
        require(wd);
    }
}
