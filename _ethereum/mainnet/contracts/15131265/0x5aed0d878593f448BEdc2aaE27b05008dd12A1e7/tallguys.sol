//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*

________________  .____    .____         ________ ____ ________.___. _________
\__    ___/  _  \ |    |   |    |       /  _____/|    |   \__  |   |/   _____/
  |    | /  /_\  \|    |   |    |      /   \  ___|    |   //   |   |\_____  \ 
  |    |/    |    \    |___|    |___   \    \_\  \    |  / \____   |/        \
  |____|\____|__  /_______ \_______ \   \______  /______/  / ______/_______  /
                \/        \/       \/          \/          \/              \/ 
*/

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract TallGuys is ERC721A, Ownable {
    using SafeMath for uint256;

    uint public MAX_SUPPLY = 10000;
    uint public PRICE = 0.00 ether;
    uint256 public mintLimit = 3;
    string private BASE_URI;
    bool public saleActive;
    uint256 public maxPerWallet = 200;
    
    constructor(string memory initBaseURI) ERC721A("Tall Guys", "TALL") {
        saleActive = false;
        updateBaseUri(initBaseURI);
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function getSaleActive() public view returns (bool) {
        return saleActive == true;
    }

    function updateBaseUri(string memory baseUri) public onlyOwner {
        BASE_URI = baseUri;
    }

    function updatePrice(uint price) public onlyOwner {
        PRICE = price;
    }

    function updateMaxPerWallet(uint256 newMaxPerWallet) public onlyOwner {
        maxPerWallet = newMaxPerWallet;
    }

    function updateMintLimit(uint256 newMintLimit) public onlyOwner {
        mintLimit = newMintLimit;
    }

    function ownerMint(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(saleActive, 
        "Sale is not active"
        );
        require(
            quantity <= mintLimit,
            "Too many tokens for one transaction"
        );
        require(
            PRICE * quantity <= msg.value, 
            "Insufficient funds sent"
        );
        require(
            balanceOf(msg.sender) + quantity <= maxPerWallet,
            "Too many tokens for one wallet"
        );
        secureMint(quantity);
    }

    function secureMint(uint256 quantity) internal {
        require(
            quantity > 0, 
            "Quantity cannot be zero"
        );
        require(
            totalSupply().add(quantity) < MAX_SUPPLY, 
            "No items left to mint"
        );
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
}