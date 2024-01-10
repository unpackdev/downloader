// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721A.sol";

contract Nindo is ERC721A, Ownable, ReentrancyGuard {
    string private _baseURIextended;
    uint256 public constant MAX_SUPPLY = 9999;
    uint256 public immutable maxTeamAmount = 300;
    uint256 public teamMintedAmount;
    address saleAddress = address(0x209f1F088C81631c19e3B22e91Dd3F429b53e407);

    constructor() ERC721A("Nindo", "Nindo") {}

    modifier canTeamMint(uint256 numberOfTokens) {
        uint256 ts = teamMintedAmount;
        require(
            ts + numberOfTokens <= maxTeamAmount,
            "Purchase would exceed max team tokens"
        );
        _;
    }
    modifier canMint(uint256 numberOfTokens) {
        uint256 ts = totalSupply();
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function mintTransfer(address to, uint256 n) public nonReentrant {
        require(msg.sender == saleAddress, "Not authorized");
        _safeMint(to, n);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function adminMint(uint256 n)
        public
        canTeamMint(n)
        canMint(n)
        nonReentrant
        onlyOwner
    {
        _safeMint(msg.sender, n, "");
        teamMintedAmount += n;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function setSaleAddress(address newAddress) public onlyOwner {
        saleAddress = newAddress;
    }
}
