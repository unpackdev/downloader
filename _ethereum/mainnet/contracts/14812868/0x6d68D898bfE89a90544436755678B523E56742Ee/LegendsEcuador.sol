// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract LegendsEcuador is Ownable, ERC721A, ReentrancyGuard {

    uint256 public maxMintPerTx = 5;
    uint256 public amountForWhitelist = 90;
    uint256 public amountCollection = 593;
    uint256 public mintPrice = 0.1 ether;

    bool public whitelistActive = true;
    bool public saleActive = false;
    bool public revealed = false;

    string private baseURI = "https://legendsecuador.s3.amazonaws.com/";

    address public paymentAddress = 0x6E896A283C9bF7b8439D9fFE164e790A52AFa080;

    mapping(address => uint256) public allowlist;

    constructor() ERC721A ("Legends Ecuador", "LEGEND") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mintWhitelist() external payable callerIsUser {
        require(whitelistActive,                            "Whitelist isn't active" );
        require(allowlist[msg.sender] > 0,                  "Not eligible for allowlist mint");
        require(totalSupply() + 1 <= amountForWhitelist,    "Not enough remaining reserved for whitelist");
        require(msg.value == mintPrice,                     "Incorrect amount of ETH"); 
        allowlist[msg.sender]--;
        _safeMint(msg.sender, 1);
    }

    function mintPublic(uint256 quantity) external payable callerIsUser
    {
        require(saleActive,                                     "Public sale is not yet active.");
        require(totalSupply() + quantity <= amountCollection,   "reached max supply");
        require(quantity > 0 && quantity <= maxMintPerTx,       "You can only mint 1 to 5 tokens per transaction.");
        require(msg.value == mintPrice * quantity,              "Incorrect amount of ETH"); 
        _safeMint(msg.sender, quantity);
    }

    function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner
    {
        require(addresses.length == numSlots.length, "addresses does not match numSlots length");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function changeRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI_ = _baseURI();

        if (revealed) {
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, Strings.toString(tokenId), ".json")) : "";
        } else {
            return string(abi.encodePacked(baseURI_, "hidden.json"));
        }
    }

    function setNewmintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function setWhitelistActive(bool val) public onlyOwner {
        whitelistActive = val;
    }
    
    function setPaymentAddress(address _paymentAddress) external onlyOwner {
        paymentAddress = _paymentAddress;
    }
    
    function withdrawMoney() external onlyOwner nonReentrant{
        (bool success, ) = payable(paymentAddress).call{value: address(this).balance}("");
        require(success, "TRANSFER_FAILED");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
}