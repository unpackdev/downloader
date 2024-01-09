// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";


contract AsciiDoodles is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public constant MAX_MINT_PER_TX = 10;

    uint256 public constant PRICE = 0.025 ether;

    bool public mintable = false;

    event Mintable(bool mintable);

    constructor() ERC721A("Ascii Doodles", "ASCIIDOODLES", MAX_MINT_PER_TX) {}

    modifier isMintable() {
        require(mintable, "NFT cannot be minted yet.");
        _;
    }

    modifier isNotExceedMaxMintPerTx(uint256 quantity) {
        require(quantity > 0, "Mint quantity exceeds max limit per tx.");
        require(
            quantity <= MAX_MINT_PER_TX,
            "Mint quantity exceeds max limit per tx."
        );
        _;
    }

    modifier isNotExceedAvailableSupply(uint256 quantity) {
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "There are no more remaining NFT's to mint."
        );
        _;
    }

    modifier isPaymentSufficient(uint256 quantity) {
        if (totalSupply() + quantity > 3000 && totalSupply() < 3000) {
            require(
                PRICE * (totalSupply() + quantity - 3000) <= msg.value,
                "There was not enough/extra ETH transferred to mint an NFT."
            );
        } else if (totalSupply() + quantity > 3000 && totalSupply() > 3000) {
            require(
                PRICE * quantity <= msg.value,
                "There was not enough/extra ETH transferred to mint an NFT."
            );
        }
        _;
    }

    function flipMintable() public onlyOwner {
        mintable = !mintable;

        emit Mintable(mintable);
    }

    function mint(uint256 quantity)
        public
        payable
        isMintable
        isNotExceedMaxMintPerTx(quantity)
        isNotExceedAvailableSupply(quantity)
        isPaymentSufficient(quantity)
    {
        _safeMint(msg.sender, quantity);
    }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
}