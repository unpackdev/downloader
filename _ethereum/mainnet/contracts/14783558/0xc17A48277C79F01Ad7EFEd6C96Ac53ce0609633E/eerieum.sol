// SPDX-License-Identifier: MIT
// Creator: LIBC (https://liblockchain.org)
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

 /*
   ||====================================================================||
   ||//$\\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\//$\\||
   ||(100)==================|       Eerieum        |================(100)||
   ||\\$//        ~         '------========--------'                \\$//||
   ||<< /        /$\              // ____ \\                         \ >>||
   ||>>|  12    //L\\            // ///..) \\         L38036133B   12 |<<||
   ||<<|        \\ //           || <||  >\  ||                        |>>||
   ||>>|         \$/            ||  $$ --/  ||        One Hundred     |<<||
||====================================================================||>||
||//$\\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\//$\\||<||
||(100)==================|       Eerieum        |================(100)||>||
||\\$//        ~         '------========--------'                \\$//||\||
||<< /        /$\              // ____ \\                         \ >>||)||
||>>|  12    //L\\            // ///..) \\         L38036133B   12 |<<||/||
||<<|        \\ //           || <||  >\  ||                        |>>||=||
||>>|         \$/            ||  $$ --/  ||        One Hundred     |<<||
||<<|      L38036133B        *\\  |\_/  //* series                 |>>||
||>>|  12                     *\\/___\_//*   1989                  |<<||
||<<\      Treasurer     ______/Hamilton\________     Secretary 12 />>||
||//$\                 ~|UNITED STATES OF AMERICA|~               /$\\||
||(100)===================  ONE HUNDRED DOLLARS =================(100)||
||\\$//\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\\$//||
||====================================================================||
*/

contract Eerieum is ERC721A, Ownable, ReentrancyGuard {

    uint256 public immutable amountForDevs;
    uint256 public immutable amountForSaleAndDev;
    uint256 public immutable collectionSize;
    uint256 public maxPerAddressDuringMint;
    uint256 public price;

    string private _baseTokenURI;
    string private _contractMeta;

    address private _royaltyAddr;
    uint256 private _royaltyBps;

    bool public hasSaleStarted;
    bool public hasWhiteListStarted;
    uint256 public whiteListStartTime;

    bytes32 public merkleRoot = 0x3651a7fdd642f52f94bae279cdcbe1eae9627502de63b156b82fa88974f26499; 

    constructor(
        uint256 maxBatchSize_,
        uint256 collectionSize_,
        uint256 amountForSaleAndDev_,
        uint256 amountForDevs_,
        uint256 price_,
        string memory contractMeta_,
        string memory baseURI_) ERC721A("eerieum_", "VALUE") {
        _contractMeta = contractMeta_;
        _baseTokenURI = baseURI_;

        maxPerAddressDuringMint = maxBatchSize_;
        amountForSaleAndDev = amountForSaleAndDev_;
        amountForDevs = amountForDevs_;
        collectionSize = collectionSize_;
        price = price_;
        hasSaleStarted = false;
        hasWhiteListStarted = false;
        whiteListStartTime = 0; 

        require(
            amountForSaleAndDev_ <= collectionSize_,
            "larger collection size needed"
        );
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function mint(uint256 quantity) external payable {
        require(hasSaleStarted == true, "Sale has not started");
        require(
            totalSupply() + quantity <= amountForSaleAndDev,
            "not enough remaining reserved for sale to support desired mint amount"
        );
        require(
            quantity <= maxPerAddressDuringMint,
            "can not mint this many"
        );

        uint256 totalCost = price * quantity;

        // First 500 are free.
        if(_currentIndex + quantity <= 500) {
            totalCost = 0;
        }

        // Make sure the value sent is enough to cover the cost.
        require(
            msg.value >= totalCost,
            "not enough ETH sent to mint"
        );

        // Get our mint on.
        _safeMint(msg.sender, quantity);

        // If we sent to much, lets return the remainder
        if(totalCost > 0) {
            refundIfOver(totalCost);
        }
    }
    
    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setMaxPerAddressDuringMint(uint256 maxPerAddressDuringMint_) external onlyOwner {
        maxPerAddressDuringMint = maxPerAddressDuringMint_;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractMeta;
    }

    function setContractURI(string memory uri) public {
        _contractMeta = uri;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function greenListMint(bytes32[] calldata _merkleProof) external payable callerIsUser nonReentrant {
        require(hasWhiteListStarted == true, "greenlist sale has not begun yet");
        require(totalSupply() + 1 <= collectionSize, "reached max supply");
        require(_currentIndex <= 500, "greenlist tokens are all gone, check secondary markets.");

        // Lets verify the address
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Address not on greenlist");
        require(balanceOf(msg.sender) == 0, "Limited to one greenlist mint per address");
        
        // Get our mint on!
        _safeMint(msg.sender, 1);
    }

    function refundIfOver(uint256 price_) private {
        require(msg.value >= price_, "No value to refund.");

        if (msg.value > price_) {
            payable(msg.sender).transfer(msg.value - price_);
        }
    }

    function royaltyInfo(uint256 tokenId_, uint256 value_) public view returns (address _reciever, uint256 _royaltyAmount) {
        return (_royaltyAddr, _royaltyBps);
    }

    function setRoyalty(uint256 bps, address distAddress) external onlyOwner {
        _royaltyBps = bps;
        _royaltyAddr = distAddress;
    }

    function startSale() external onlyOwner  {
        hasSaleStarted = true;
    }

    function pauseSale() external onlyOwner  {
        hasSaleStarted = false;
    }

    function startGreenListSale() external onlyOwner  {
        hasWhiteListStarted = true;
        whiteListStartTime = block.timestamp;
    }

    function stopGreenListSale() external onlyOwner  {
        hasWhiteListStarted = false;
    }

    // Support the Royalties Interface ERC-2981
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A) returns (bool) {
        return interfaceId == 0x2a55205a // ERC-2981
            || super.supportsInterface(interfaceId);
    }
}