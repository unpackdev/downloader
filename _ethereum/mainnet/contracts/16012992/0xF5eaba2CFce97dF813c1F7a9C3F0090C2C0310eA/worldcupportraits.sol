// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//  __          __        _     _    _____              ___   ___ ___  ___  
//  \ \        / /       | |   | |  / ____|            |__ \ / _ \__ \|__ \ 
//   \ \  /\  / /__  _ __| | __| | | |    _   _ _ __      ) | | | | ) |  ) |
//    \ \/  \/ / _ \| '__| |/ _` | | |   | | | | '_ \    / /| | | |/ /  / / 
//     \  /\  / (_) | |  | | (_| | | |___| |_| | |_) |  / /_| |_| / /_ / /_ 
//      \/  \/ \___/|_|  |_|\__,_|  \_____\__,_| .__/  |____|\___/____|____|
//                                             | |                          
//                                             |_|                          

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract WorldCupPortraits is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 555;
    uint256 public MAX_MINT = 3;
    uint256 public SALE_PRICE = 0.005 ether;
    bool public mintStarted = false;

    string public baseURI = "ipfs://Qmdfed9D7Dsve3QPCpynduu8VG1GBbTMwKHmwXJfck5aK5/";
    mapping(address => uint256) public mintPerWallet;

    constructor() ERC721A("WorldCupPortraits", "WCP") {}

    function mint(uint256 _quantity) external payable {
        require(mintStarted, "Minting is not live yet.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Beyond max supply."
        );
        require(
            (mintPerWallet[msg.sender] + _quantity) <= MAX_MINT,
            "Wrong mint amount."
        );
        require(msg.value >= (SALE_PRICE * _quantity), "Wrong mint price.");

        mintPerWallet[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 mintAmount) external onlyOwner {
        _safeMint(msg.sender, mintAmount);
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
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        SALE_PRICE = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}