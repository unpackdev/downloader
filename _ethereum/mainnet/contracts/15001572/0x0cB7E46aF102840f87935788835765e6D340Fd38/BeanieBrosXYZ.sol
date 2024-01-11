// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC721A.sol";

contract BeanieBrosXYZ is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI = "ipfs://bafybeib3a6tk3226wej4rber26re7litftk54ryulnfvjadlv62cuo7rbq/";
    string public baseExtension = ".json";
    uint256 public multiplePrice = 0.00 ether;
    uint256 public freeprice = 0.000 ether;
    uint256 public maxPerTx = 5;
    uint256 public maxSupply = 3000;
    uint256 public nextOwnerToExplicitlySet;
    bool public mintEnabled = true;

    constructor() ERC721A("Beaniebros.xyz", "BEANIEBROSXYZ"){

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
            ? string(abi.encodePacked(currentBaseURI,Strings.toString(_tokenId) , baseExtension))
            : "";
    }

    function mint(uint256 amount) external payable
    {
        uint256 cost = freeprice;
        if(amount > 1 || (numberMinted(msg.sender) >= 1)) {
            cost = multiplePrice;
        }
        require(totalSupply() + amount <= maxSupply,"too many!");
        require(msg.value >= amount * cost,"Please send the exact amount.");
        require(mintEnabled, "Minting is not live yet, hold on.");
        require( amount <= maxPerTx, "Max per TX reached.");

        _safeMint(msg.sender, amount);
    }

    function ownerBatchMint(uint256 amount) external onlyOwner
    {
        require(totalSupply() + amount <= maxSupply ,"too many!");

        _safeMint(msg.sender, amount);
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPrice(uint256 price_) external onlyOwner {
        multiplePrice = price_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
}