//██████╗  █████╗ ██████╗     ██████╗  ██████╗ ██╗   ██╗███████╗     ██████╗ ███████╗    ██╗    ██╗███████╗██████╗ ██████╗ 
//██╔══██╗██╔══██╗██╔══██╗    ██╔══██╗██╔═══██╗╚██╗ ██╔╝██╔════╝    ██╔═══██╗██╔════╝    ██║    ██║██╔════╝██╔══██╗╚════██╗
//██████╔╝███████║██║  ██║    ██████╔╝██║   ██║ ╚████╔╝ ███████╗    ██║   ██║█████╗      ██║ █╗ ██║█████╗  ██████╔╝ █████╔╝
//██╔══██╗██╔══██║██║  ██║    ██╔══██╗██║   ██║  ╚██╔╝  ╚════██║    ██║   ██║██╔══╝      ██║███╗██║██╔══╝  ██╔══██╗ ╚═══██╗
//██████╔╝██║  ██║██████╔╝    ██████╔╝╚██████╔╝   ██║   ███████║    ╚██████╔╝██║         ╚███╔███╔╝███████╗██████╔╝██████╔╝
//╚═════╝ ╚═╝  ╚═╝╚═════╝     ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝     ╚═════╝ ╚═╝          ╚══╝╚══╝ ╚══════╝╚═════╝ ╚═════╝ 
                                                                                                                         
// GAWDDESS WAS HERE

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

contract BadBoysWeb3 is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    bool public publicMintOpen = false;
    uint256 public constant totalPossible = 1440;
    uint256 public mintPrice = 0.055 ether;

    string private URI;
    string private baseExt = ".json";
    string private preRevealURI = "ipfs://bafybeibydi6ynflcjatcmkfimwq3udb5nkoi27dv5nq2hidtwe3zqbqj3q/badboy.json/";
    bool public revealed = false;

    address public teamWallet = 0x49Aff98582160d0f7830A9459A59abf2Dcff91BA;

    constructor() ERC721A("Bad Boys of Web3", "BB3") {
        _mint(owner(), 10);
        _setDefaultRoyalty(owner(), 500); 
    }

    // Modifiers
    modifier canMint(uint amount) {
        require(publicMintOpen, "Public is not open yet.");
        require(msg.value >= mintPrice * amount, "Insufficient ETH for minting");
        require(totalSupply() + amount <= totalPossible, "SOLD OUT");
        _;
    }

    modifier isRevealed() {
        require(revealed, "NFTs not revealed yet");
        _;
    }

    // Functions
    function setTeamWallet(address _teamWallet) external onlyOwner {
        require(_teamWallet != address(0), "Invalid address");
        teamWallet = _teamWallet;
    }

    function withdrawETH() external onlyOwner {
        require(teamWallet != address(0), "Team wallet not set");
        (bool sent, ) = payable(teamWallet).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function publicMint(uint amount) external payable nonReentrant canMint(amount) {
        _mint(msg.sender, amount);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setURI(string calldata newURI) external onlyOwner {
        URI = newURI;
    }

    function togglePublic() external onlyOwner {
        publicMintOpen = !publicMintOpen;
    }

    function setPreRevealURI(string calldata _preRevealURI) external onlyOwner {
        preRevealURI = _preRevealURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setURIExtension(string calldata newBaseExt) external onlyOwner {
        baseExt = newBaseExt;
    }

    function setDefaultRoyalty(address recipient, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(recipient, feeBasisPoints);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (!revealed) {
            return preRevealURI;
        }

        return string(abi.encodePacked(URI, _toString(tokenId), baseExt));
    }

    function isPublicActive() external view returns (bool) {
        return publicMintOpen;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
