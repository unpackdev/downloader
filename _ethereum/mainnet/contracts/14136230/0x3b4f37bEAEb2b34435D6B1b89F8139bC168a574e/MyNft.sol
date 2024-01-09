// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";

contract MyNFT is ERC721A {
    using Strings for uint256;

    address public owner;
    string public baseURI = "https://bunks-nft-bhm.herokuapp.com/";
    string public baseExtension = ".json";
    string public notRevealedUri = "https://bunks-nft-bhm.herokuapp.com";
    uint256 public cost = .035 ether;
    uint256 public maxSupply = 7000;
    uint256 public maxMintAmount = 20;
    uint256 public nftPerAddressLimit = 100000;
    uint256 public freeBunks = 500;

    bool public paused = false;
    bool public revealed = false;

    mapping(address => uint256) public addressMintedBalance;

    constructor() ERC721A("Bunks NFT", "BUNKS") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner");
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function freeMint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(supply + _mintAmount <= freeBunks, "Free bunks are sold out");
        _safeMint(msg.sender, _mintAmount);
        delete supply;
    }

    function mint(uint256 _mintAmount) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");
        _safeMint(msg.sender, _mintAmount);
        delete supply;
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
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setTotalFree(uint256 _totalFree) public onlyOwner {
        freeBunks = _totalFree;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxLimit(uint256 _state) public onlyOwner {
        maxSupply = _state;
    }

    function withdraw() public payable onlyOwner {
        uint256 totalBalance = address(this).balance;

        payable(owner).transfer((totalBalance * 19) / 100);

        payable(0x63a3f55523F61DA9d77721f03eD2774fEB8df78d).transfer(
            (totalBalance * 10) / 100
        );
        payable(0x5D110dbCc5c0d07A460Ee604902AC4223CB99d3c).transfer(
            (totalBalance * 10) / 100
        );
        payable(0x82111fB488c0c327734baf2A415838B14490F9BB).transfer(
            (totalBalance * 20) / 100
        );
        payable(0xCca632bCeA6ab08ddE0E444711371548783E2D39).transfer(
            (totalBalance * 21) / 100
        );
    }

    function withdrawByOwner() public payable onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
