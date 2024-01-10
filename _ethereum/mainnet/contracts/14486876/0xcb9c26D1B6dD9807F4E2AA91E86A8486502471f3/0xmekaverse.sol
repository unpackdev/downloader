// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// 0xMeka from the 0xMekaVerse - 8888 unique 0xMeka who need YellowArmy Drivers - Not Affiliated with MekaVerse.
contract xMekaVerse is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI = "";
    string public baseExtension = ".json";
    uint256 public cost = 0.019 ether;
    uint256 public maxSupply = 8888;
    uint256 public maxMintAmount = 5;
    bool public paused = false;
    bool public revealed = false;
    string public notRevealedUri = "https://ipfs.io/ipfs/QmeMHGubf8ZWyGK1bKhfDnnM5H34jkNhBpzhgifQjaUmfX";
    uint256 public freeMintAmount = 888;
    address public withdrawalAddress = 0x9873F3567E8cEA630dB8b8aDF73B195023bF3B9C;

    constructor() ERC721("0xMekaVerse", "0xMEKA") {
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        mintTo(msg.sender, _mintAmount);
    }

    function mintTo(address to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            uint256 paidMintAmount = _mintAmount;
            if (supply < freeMintAmount) {
                uint256 freeMintAmountLeft = max(0, freeMintAmount - supply);
                paidMintAmount = max(0, paidMintAmount - freeMintAmountLeft);
            }
            require(msg.value >= cost * paidMintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setFreeMintAmount(uint256 _freeMintAmount) public onlyOwner {
        freeMintAmount = _freeMintAmount;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setWithdrawalAddress(address _withdrawalAddress) public onlyOwner {
        withdrawalAddress = _withdrawalAddress;
    }

    function withdraw() public payable onlyOwner {
        (bool ts,) = payable(withdrawalAddress).call{value : address(this).balance}("");
        require(ts);
    }

    //utils

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}
