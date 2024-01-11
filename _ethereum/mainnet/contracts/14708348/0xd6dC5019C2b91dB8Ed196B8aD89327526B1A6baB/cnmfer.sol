// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract mfercn420 is ERC721, ERC721Enumerable, Ownable{

    // mfers mainnet contract address
    address public constant MFERS_ADDRESS = 0x79FCDEF22feeD20eDDacbB2587640e45491b757f;
    uint256 public constant MAX_SUPPLY = 420;
    bool public freeMintActive = false;
    string private _baseURIextended;

    IERC721 internal mfersContract = IERC721(MFERS_ADDRESS);

    constructor() ERC721("mfers cn 420", "MFERCN"){}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function airdropMfercn(
        address[] calldata to
    ) external onlyOwner {
        require(to.length + totalSupply() <= MAX_SUPPLY, "Airdrop addresses too many");
        for (uint256 i=0;i<to.length;i++) {
            require(balanceOf(to[i]) < 1, "One address only airdrop one MFERCN");
            _safeMint(to[i], totalSupply() + 1);
        }
    }

    function freeMint() external {
        require(freeMintActive, "Free mint closed");
        require(balanceOf(msg.sender) < 1, "You can only mint one MFERCN");
        require(mfersContract.balanceOf(msg.sender) > 0, "Free mint is currently for mfer holders only");
        require(totalSupply() < MAX_SUPPLY, "Sold out");

        _safeMint(msg.sender, totalSupply() + 1);
    }

    function setFreeMintActive(bool newActive) external onlyOwner {
        freeMintActive = newActive;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIextended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function isFreeMintActive() external view returns (bool) {
        return freeMintActive;
    }
}