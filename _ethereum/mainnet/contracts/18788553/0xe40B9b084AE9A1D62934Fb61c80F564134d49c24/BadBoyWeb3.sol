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
import "./AccessControl.sol";

contract BadBoysWeb3 is ERC721A, ERC2981, Ownable, ReentrancyGuard, AccessControl {
    uint256 public constant TOTAL_POSSIBLE = 1440;
    uint256 public mintPrice = 0.055 ether;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string private URI;
    string private preRevealURI;
    string private baseExt;

    bool public revealed = false;
    bool public publicMintOpen = false;
    address public teamWallet;

    constructor() ERC721A("Bad Boys of Web3", "BB3") {
        _setDefaultRoyalty(owner(), 500);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); 
        _grantRole(MINTER_ROLE, msg.sender);
        
    }

    function setTeamWallet(address _teamWallet) external onlyOwner {
        require(_teamWallet != address(0), "Invalid address");
        teamWallet = _teamWallet;
    }

    function withdrawETH() external onlyOwner {
        require(teamWallet != address(0), "Team wallet not set");
        (bool sent, ) = payable(teamWallet).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function publicMint(uint amount, address recipient) external payable nonReentrant onlyRole(MINTER_ROLE) {
        require(publicMintOpen && recipient != address(0), "Minting not allowed or invalid address");
        require(msg.value >= mintPrice * amount, "Insufficient ETH for minting");
        require(totalSupply() + amount <= TOTAL_POSSIBLE, "SOLD OUT");
        
        _mint(recipient, amount);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setURI(string calldata newURI) external onlyOwner {
        URI = newURI;
    }

    function setPreRevealURI(string calldata _preRevealURI) external onlyOwner {
        preRevealURI = _preRevealURI;
    }

    function toggleReveal() external onlyOwner {
        revealed = true;
    }

    function togglePublic() external onlyOwner {
        publicMintOpen = !publicMintOpen;
    }

    function setURIExtension(string calldata newBaseExt) external onlyOwner {
        baseExt = newBaseExt;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed) {
            return string(abi.encodePacked(URI, _toString(tokenId), baseExt));
        } else {
            return preRevealURI;
        }
    }

    function setRoyaltyInfo(address recipient, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(recipient, feeBasisPoints);
    }

    function airdrop(uint amount, address recipient) external {
        require(owner() == _msgSender() || hasRole(MINTER_ROLE, _msgSender()), "Caller is not the owner or Crossmint");

        require(totalSupply() + amount <= TOTAL_POSSIBLE, "Exceeds max supply");
        _mint(recipient, amount);
    }
    
    function grantMinterRole(address account) public onlyOwner {
        grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) public onlyOwner {
        revokeRole(MINTER_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, AccessControl) returns (bool) {
        return interfaceId == 0x80ac58cd || 
           super.supportsInterface(interfaceId);
    }

}