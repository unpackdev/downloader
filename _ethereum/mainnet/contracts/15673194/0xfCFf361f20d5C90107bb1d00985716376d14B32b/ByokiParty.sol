// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░
░░░░░░░░░░░▒▓░░░░░░▓█░░░▒▒▒░░░░░▒██▓░░▒▓░░░░▒▒░░░░░░░░░░░▒▒▒▒▒░░░▒▒░░░░░░░░░▒▒▒░░░░▒█▓░░░▓▒░░░░░░█▓░
░▓▒▒█████▒░███▒░░░░██▒░██▓██▓░░████▒░░▓█▓░░░██░░░░░░░░▒███▓█▓██▓▒██░░░░░░▓██████▒░░▓█▓▓▓▓███░░░░░██░
░▓███░▒▒██░▒▒██░░░░██▓▓█▒░░▒██▒▓▒██░░░▒█▓░░░██░░░░░░▒████▒░▓░░▓████▒░░░▒████▒░░██▓▓███▓█▒▒▓██░░░░██░
░████▓▒▓██░░░▓█▓░▒▓███▒█▒░░░░██▒░██░░░██▓░░░▓▓░░░░░░▓▓░██▒░░░░▓█▓███░░░█▓▒█▓░░░███▓██░░▒░░░██▒▒▓███▒
▓█▒░████████▓░████▓▓██▓██░░░░██░░██▒░█████░▒█▓░░░░░░░░░██▓▓▓██▓▒▒███░░░░░▓█▓▒▓████▒██░░░░░░▒████▒▓█▒
░░░░▒██▓░░▒▓██▓█▓▓░░██▓██▒░░▓█▓░░████████▒░▓█▓░░░░░░░░░███▓▒▓▒░░▓█▒█▓░░░░█████▓▒▓█▓██░▒▓██░░██▓▒░▒█▓
░░░░████░░░░██░▓░░░░██▒▒██▓▓█▓░▒▓███▒░░██▒░▓█▓░░░░░░░░░▓█▓░░░█▓░█████▓░░░▓█▓░░░░▒█▓▓███▓▒░░░▒▒░░░░██
░░░░░▒███▓▓██▒░▒░░░░▓█▓░░░█▒▓███▓▓██░░░▒█▓░▓█▓░░░░░░░░░▒██▒░░░█████▒▓██▒░░██░░░░▒█▒▒██░░░░░░░░░░░░██
░░░░░░▒██▒▒▒░▒▓▓██████▒░░▓██▓▒░░░░▒█▓░░░▓█▓▒█▓░░░░░░░░░░▒██░░░░███░░░▓▓█████▒░░░▓█░░█▓░░░░░▒▓▓██████
░░░░░░░▓░░▒████▓▒░▒░░░░▒██▒░░░░░░░░▓█░░░░▒███░░░░░░░░░░░░░▒░░░░▒█▓░░░░░░░░░█░░░░░▓░░░░░░▒███▓█▒░▒░░░
░░░░░░░░░▒█▓░░░▒░░░░░░░▒▒░░░░░░░░░░░▒░░░░░░▒▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░▒░░░░░▓█▓░░░▒░░░░░░
*/

contract ByokiParty is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    enum MintStatus {
        PAUSED,
        BLOODYTIME
    }

    string public uriPrefix = "";
    string public uriSuffix = ".json";

    uint256 public Price = 0.0025 ether;
    uint256 public maxSupply = 2424;
    uint256 public BleedingDev = 100;
    uint256 public maxMintAmountPerTx = 10;
    uint256 public maxMintAmount = 10;

    MintStatus public mintStatus = MintStatus.PAUSED;

    constructor()ERC721A("ByokiParty", "BKPT")
    {}

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(
            _mintAmount > 0 && _numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
            "Invalid number or you mint too much."
        );
        _;
        
    }


    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= Price * _mintAmount, "Insufficient funds!");
        _;
    }

    function BurnCollection() external onlyOwner {
        setMaxSupply(totalSupply());
    }
    
    function setMaxSupply(uint256 _maxSupply) internal onlyOwner {
        maxSupply = _maxSupply;
    }

    function BloodOfDev() external onlyOwner {
        require(totalSupply() + BleedingDev <= maxSupply, "Max supply exceeded!");
        _safeMint(_msgSender(), BleedingDev);
    }

    function mint(uint256 amount)
        public
        payable
        mintCompliance(amount)
        mintPriceCompliance(amount)
        nonReentrant
    {
        require(
            mintStatus == MintStatus.BLOODYTIME,
            "ERYTHROPOIESIS..."
        );
        require(msg.sender == tx.origin, "Please no contract");
        _safeMint(_msgSender(), amount);
    }


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

    function setPrice(uint256 _price) public onlyOwner {
        Price = _price;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setMintStatus(MintStatus _status) public onlyOwner {
        mintStatus = _status;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}