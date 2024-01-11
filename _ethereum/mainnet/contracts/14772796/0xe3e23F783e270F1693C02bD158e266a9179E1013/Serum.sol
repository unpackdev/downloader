// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721ABurnable.sol";

interface IKlub {
    function burnFrom(address account, uint amount) external;
    function balanceOf(address account) external view returns (uint);
}

interface ITombstone {
    function ownerOf(uint tokenId) external returns (address);
}

/// @title DAZK Serum
/// @author Burn0ut#8868 hello@notableart.io
/// @notice https://www.thedeadarmyskeletonklub.army/ https://twitter.com/The_DASK
contract Serum is ERC721ABurnable, Ownable {
    using Strings for uint;

    uint public constant MAX_TOKENS = 6969;
    uint public constant MAX_PER_MINT = 20;
    IKlub public klub = IKlub(0xa0DB234a35AaF919b51E1F6Dc21c395EeF2F959d);
    ITombstone public tomb = ITombstone(0x40f8719f2919a5DEDD2D5A67065df6EaC65c149C);

    address public constant w1 = 0x9AEc8C528263746A6058CafaF7099bf5DCa452e3;
    address public constant w2 = 0x8deddE67889F0Bb474E094165A4BA37872A7c26B;

    uint public price = 0.069 ether;
    uint public KLUBS_PER_SERUM = 600 * 1 ether;
    bool public isRevealed = false;

    string public baseURI = "";

    event SerumApplied(address owner, uint tombId, uint serumId);

    constructor() ERC721A("DAZK Serum", "DAZKSERUM") {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        if (isRevealed) {
            return super.tokenURI(tokenId);
        } else {
            return string(abi.encodePacked("ipfs://QmYrYS17HQC3mEqhznZjbjgYkm7DR1dsB3DuQFjr98Tnxe/", tokenId.toString()));
        }
    }
 
    function mint(uint tokens) external payable {
        require(tokens <= MAX_PER_MINT, "SERUM: Cannot purchase this many tokens in a transaction");
        require(_totalMinted() + tokens <= MAX_TOKENS, "SERUM: Minting would exceed max supply");
        require(tokens > 0, "SERUM: Must mint at least one token");
        require(price * tokens == msg.value, "SERUM: ETH amount is incorrect");

        _safeMint(_msgSender(), tokens);
    }

    function mintWithKLUB(uint tokens) external {
        require(tokens <= MAX_PER_MINT, "SERUM: Invalid number of tombs");
        require(_totalMinted() + tokens <= MAX_TOKENS, "SERUM: Minting would exceed max supply");
        require(klub.balanceOf(_msgSender()) >= tokens * KLUBS_PER_SERUM, "SERUM: Insufficent KLUB balance");
        klub.burnFrom(_msgSender(), tokens * KLUBS_PER_SERUM);
        _safeMint(_msgSender(), tokens);
    }

    function applyToTomb(uint tombId, uint serumId) external {
        require(tomb.ownerOf(tombId) == _msgSender(), "SERUM: You are not the owner of this tombstone");
        require(ownerOf(serumId) == _msgSender(), "SERUM: You are not the owner of this serum");
        burn(serumId);
        emit SerumApplied(_msgSender(), tombId, serumId);
    }

    function setKlubsPerTomb(uint _KLUBS_PER_SERUM) external onlyOwner {
        KLUBS_PER_SERUM = _KLUBS_PER_SERUM * 1 ether;
    }

    function setKlubAddress(address _klub) external onlyOwner {
        klub = IKlub(_klub);
    }
    function setTombstoneAddress(address _tomb) external onlyOwner {
        tomb = ITombstone(_tomb);
    }
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        isRevealed = true;
        baseURI = _newBaseURI;
    }

    function setPrice(uint _newPrice) external onlyOwner {
        price = _newPrice * (1 ether);
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function ownerMint(address to, uint tokens) external onlyOwner {
        require(_totalMinted() + tokens <= MAX_TOKENS, "SERUM: Minting would exceed max supply");
        require(tokens > 0, "SERUM: Must mint at least one token");
        _safeMint(to, tokens);
    }

    /// Distribute funds to wallets
    function withdrawAll() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "SERUM: Insufficent balance");
        _widthdraw(w2, ((balance * 5) / 100));
        _widthdraw(w1, address(this).balance);
    }

    function _widthdraw(address _address, uint _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "SERUM: Failed to widthdraw Ether");
    }
}
