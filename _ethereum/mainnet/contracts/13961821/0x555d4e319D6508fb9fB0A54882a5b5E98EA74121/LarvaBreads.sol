// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract LarvaBreads is ERC721Enum, Ownable, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;

    // sale settings
    uint256 public cost = 0.01337 ether;
    uint256 public maxSupply = 5000;
    uint256 public freeMint = 1000;
    uint256 public maxMint = 15;
    bool public status = false;

    mapping(address => uint256) public minted;

    // share settings
    address[] private addressList = [
        0x490258f2f9600F3a80005DbfF6b3F16f924DBacf,
        0xfe0C6901744105F9C6FB78536cD242abEb957334,
        0x0f815cf47663D8b365cA63d7CBA751dabD5feB01,
        0xc927B64D22D0be9926F581f7860c8ff2b471398c
    ];
    uint[] private shareList = [35, 35, 22, 8];

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721P(_name, _symbol) PaymentSplitter(addressList, shareList){
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    // public minting
    function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();

        require(status, "Off");
        require(_mintAmount > 0, "Duh");
        require(_mintAmount + minted[msg.sender] <= maxMint, "Too many");
        require(s + _mintAmount <= maxSupply, "Sorry");

        if (_mintAmount <= freeMint) {
            freeMint -= _mintAmount;
        } else {
            require(msg.value >= cost * (_mintAmount - freeMint), "Insufficient");
            freeMint = 0;
        }

        for (uint256 i = 0; i < _mintAmount; ++i) {
            _safeMint(msg.sender, s + i + 1, "");
        }

        minted[msg.sender] += _mintAmount;

        delete s;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMint = _newMaxMintAmount;
    }

    function setFreeMintAmount(uint256 _newFreeMintAmount) public onlyOwner {
        freeMint = _newFreeMintAmount;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSaleStatus(bool _status) public onlyOwner {
        status = _status;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}