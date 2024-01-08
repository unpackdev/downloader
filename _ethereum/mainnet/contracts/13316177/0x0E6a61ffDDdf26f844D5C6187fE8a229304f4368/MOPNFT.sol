pragma solidity ^0.7.3;
// SPDX-License-Identifier: MIT
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract MOPNFT is ERC721, Ownable {
    using SafeMath for uint256;
    uint256 public constant nftPrice = 80000000000000000;
    uint public constant maxTokenPurchase = 8008;
    uint256 constant public MAX_TOKENS = 8008;
    bool public saleIsActive = true;

    constructor() public ERC721("March of Progress NFT", "MOPNFT") {
        _setBaseURI("https://api.mopnft.com/");
    }

    function mintNFT(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint MOPNFT");
        require(numberOfTokens <= maxTokenPurchase, "Can only mint 8008 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of MOPNFT");
        require(nftPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TOKENS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function withdrawToken(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(msg.sender, _amount);
    }

    function withdrawWithAmount(uint256 _amount) public onlyOwner {
        msg.sender.transfer(_amount);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
}