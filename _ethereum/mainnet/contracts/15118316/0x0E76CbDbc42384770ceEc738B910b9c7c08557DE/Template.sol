//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract Saibapanku is ERC721A, Ownable {
    using Strings for uint256;

    string public uriPrefix;
    string public uriSuffix = ".json";

    uint256 public cost;
    uint256 public price = 0.0069 ether;
    uint256 public maxSupply = 5000;
    uint256 public totalFree = 1500;
    uint256 public maxPerWallet = 5;
    uint256 public maxPerFreeWallet = 5;
    bool public paused = true;

    constructor() ERC721A("Saibapanku", "SAI") {
        _mint(0x02E8B7E4BE833F81513A053079793fA62b8Be99c, 50);
        _mint(0x7470A3FC1eBAfad9028A1d8A1Fd8003308552D00, 20);
        _mint(0x91b6DFa9Fdc28d3C8064830F17D5768B1d082EFf, 20);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded"
        );
        _;
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
    {
        require(!paused);

        if (totalSupply() + _mintAmount <= totalFree) {
            require(
                numberMinted(msg.sender) + _mintAmount <= maxPerFreeWallet,
                "Wallet free mint limit reached"
            );
        } else {
            if (cost == 0) {
                cost = price;
            }
            require(msg.value >= cost * _mintAmount, "Insufficient funds");
            require(
                numberMinted(msg.sender) + _mintAmount <= maxPerWallet,
                "Wallet mint limit reached"
            );
        }
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _mint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        price = _cost;
        if (totalSupply() > totalFree) {
            cost = _cost;
        }
    }

    function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxPerFreeWallet(uint256 _maxPerFreeWallet) public onlyOwner {
        maxPerFreeWallet = _maxPerFreeWallet;
    }

    function setTotalFree(uint256 _totalFree) public onlyOwner {
        totalFree = _totalFree;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function withdraw() public onlyOwner {
        (bool hs, ) = payable(0x02E8B7E4BE833F81513A053079793fA62b8Be99c).call{
            value: (address(this).balance * 80) / 100
        }("");
        require(hs);

        (bool os, ) = payable(0x91b6DFa9Fdc28d3C8064830F17D5768B1d082EFf).call{
            value: (address(this).balance * 20) / 100
        }("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // View
    function freeActive(uint256 _mintCount)
        external
        view
        returns (bool _freeActive)
    {
        return totalSupply() + _mintCount <= totalFree;
    }
}
