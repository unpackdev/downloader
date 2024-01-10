// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract MiniMichAccessory is ERC721A, Ownable, Pausable, ReentrancyGuard {
    string private _metadataBaseURI;
    bool public saleLiveToggle=true;
    bool public freezeURI;

    uint256 public constant MAX_NFT = 500;
    uint256 public constant MAX_MINT = 5;
    uint256 public MAX_BATCH = 5;
    uint256 public PRICE = 0.01 ether;

    address private _creators = 0x999eaa33BD1cE817B28459950E6DcD1dA14C411f;
 
    // ** MODIFIERS ** //
    // *************** //
    modifier saleLive() {
        require(saleLiveToggle == true, "Sale is not live yet");
        _;
    }

    modifier maxSupply(uint256 mintNum) {
       require(
            totalSupply() + mintNum <= MAX_NFT,
            "Sold out"
        );
        _;
     }

    modifier correctPayment(uint256 mintPrice, uint256 numToMint) {
        require(
            msg.value >= mintPrice * numToMint,
            "Payment failed"
        );
        _;
    }
    // ** CONSTRUCTOR ** //
    // *************** //
    constructor(string memory _mURI)
        ERC721A("MiniMichAccessory", "MMA", MAX_BATCH, MAX_NFT)
    {
        _metadataBaseURI = _mURI;
    }

    // ** ADMIN ** //
    // *********** //
    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        require(!paused(), "Contract has been paused");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /***
     *    ███╗   ███╗██╗███╗   ██╗████████╗
     *    ████╗ ████║██║████╗  ██║╚══██╔══╝
     *    ██╔████╔██║██║██╔██╗ ██║   ██║
     *    ██║╚██╔╝██║██║██║╚██╗██║   ██║
     *    ██║ ╚═╝ ██║██║██║ ╚████║   ██║
     *    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝
     */

    function publicMint(uint256 mintNum)
        external
        payable
        nonReentrant
        saleLive
        correctPayment(PRICE, mintNum)
        maxSupply(mintNum)
    {
        require(
            numberMinted(msg.sender) + mintNum <= MAX_MINT,
            "Reaches wallet limit."
        );
        _safeMint(_msgSender(), mintNum);
    }

    /***
     *     ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗
     *    ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗
     *    ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
     *    ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
     *    ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║
     *     ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
     * This section will have all the internals set to onlyOwner
     */

    function devMint(uint256 mintNum) 
        external 
        onlyOwner 
        maxSupply(mintNum) 
    {
        require(
            mintNum % MAX_BATCH == 0,
            "Multiple of the MAX_BATCH"
        );
        uint256 numChunks = mintNum / MAX_BATCH;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, MAX_BATCH);
        }
    }

    function reserve(address[] calldata receivers, uint256 mintNum)
        external
        onlyOwner
        maxSupply(mintNum*receivers.length)
    {
        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNum);
        }
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(_creators).call{value: address(this).balance}("");
        require(success, "Failed to send payment");
    }

    function setMetaURI(string calldata _URI) external onlyOwner {
        require(freezeURI == false, "Metadata is frozen");
        _metadataBaseURI = _URI;
    }

    function tglLive() external onlyOwner {
        saleLiveToggle = !saleLiveToggle;
    }

    function freezeAll() external onlyOwner {
        require(freezeURI == false, "Metadata is frozen");
        freezeURI = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updatePrice(uint256 _price) external onlyOwner {
        PRICE = _price ;
    }
}
