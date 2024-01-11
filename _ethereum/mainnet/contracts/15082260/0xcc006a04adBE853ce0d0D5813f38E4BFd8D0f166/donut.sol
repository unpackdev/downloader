// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A-noQuery.sol";
import "./Strings.sol";
import "./Address.sol";
import "./ERC2981.sol";
import "./SafeERC20.sol";


contract Donut is ERC2981, ERC721A, Ownable {
    using Address for address payable;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    string public baseURI = "";
    string public notRevealedURI= "https://datanft.mypinata.cloud/ipfs/QmchantEJRqGteuxU7TTT5PLqkNG5xf3tGzugCWNkphedk";

    bool public started = true;
    bool public revealed = false;

    uint256 public maxSupplyAmount = 8888;
    uint256 public publicSalePrice = 0.0098 ether;
    uint32 public walletLimit = 15;


    constructor(
    ) ERC721A("Donut Normad", "DN") {
        setFeeNumerator(800);
    }

    function mint(uint256 amount) external payable {
        require(started, "Sale is not started");
        require(_numberMinted(msg.sender) + amount <= walletLimit, "Exceed the limit of each address");
        require(amount + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");

        uint256 requiredValue = 0;
        if (_numberMinted(msg.sender) > 0) {
            requiredValue = publicSalePrice * amount;
        } else {
            requiredValue = publicSalePrice * (amount - 1);
        }
        
        require(msg.value >= requiredValue);
        if (msg.value > requiredValue) {
            payable(msg.sender).sendValue(msg.value - requiredValue);
        }
        _safeMint(msg.sender, amount);
    }

    function burn(uint256 tokenId) external{
        _burn(tokenId);
    }
    /********************************* view ********************************/
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedURI;
        }
        
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }


    struct Status {
        uint256 price;
        uint32 walletLimit;
        uint256 maxSupply;
        uint32 userMinted;
        bool soldout;
        bool started;
    }

    function status(address minter) external view returns (Status memory) {
        return Status({
            price: publicSalePrice,
            walletLimit: walletLimit,
            maxSupply: maxSupplyAmount,

            userMinted: uint32(_numberMinted(minter)),
            soldout: totalSupply() >= maxSupplyAmount,
            started: started
        });
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721A).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /************************************* onlyOwner ********************/
    function devmint(address to, uint32 amount) external onlyOwner {
        require(amount + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");
        _safeMint(to, amount);
    }

    function multidevmint(address [] calldata tos, uint32 [] calldata amounts) external onlyOwner {
        require(tos.length == amounts.length, "tos length must eq amounts");
        for(uint l = 0; l < tos.length; l ++) {
            require(amounts[l] + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");
            _safeMint(tos[l], amounts[l]);
        }
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setNotRevealedURI(string memory newURI)external onlyOwner {
        notRevealedURI = newURI;
    }

    address private wallet1 = 0xB19a3fA871bab86430A00b1AD224Deaa42964459;
    address private wallet2 = 0x3518226246A8Ad79fCeD9056D48540a1D3a8e2cf;
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success1, ) = payable(wallet1).call{value: balance*20/100}("");
        require(success1, "Failed to withdraw to wallet1");

        balance = address(this).balance;
        (bool success2, ) = payable(wallet2).call{value: balance}("");
        require(success2, "Failed to withdraw to wallet2");
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool _started) external onlyOwner {
        started = _started;
    }

    function setPrice(uint256 _newValue) external onlyOwner {
        publicSalePrice = _newValue;
    }

    function setMaxSupply(uint32 _newValue) external onlyOwner {
        maxSupplyAmount = _newValue;
    }

    function toggleRevealed() external onlyOwner {
        revealed = !revealed;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}