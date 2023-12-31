// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";

import "./ISwappableRenderer.sol";

contract Claimable is ERC721, Ownable, ISwappableRenderer {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter private tokenIdCounter;

    uint256 public maxSupply = 10_000;

    address public rendererAddress;

    address private minterAddress;

    bool private openMintEnabled = false;

    event Mint(uint256 tokenId, address minter);

    constructor() ERC721("Family Portraits", "PORTRAIT") {
        minterAddress = _msgSender();
    }

    function totalSupply() public view virtual returns (uint256) {
        return tokenIdCounter.current();
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        require(max >= tokenIdCounter.current());
        maxSupply = max;
    }

    function setRendererAddress(address to) external onlyOwner {
        rendererAddress = to;
    }

    function setMinterAddress(address to) external onlyOwner {
        minterAddress = to;
    }

    function setOpenMint(bool enabled) external onlyOwner {
        openMintEnabled = enabled;
    }

    function claim(address to, bytes calldata signature) external {
        // validate
        require(_msgSender() == minterAddress, "only minter");
        require(totalSupply() < maxSupply, "max supply reached");

        // verify signature was signed by / contains "to" address
        bytes32 data = keccak256(abi.encodePacked(to));
        address signer = data.toEthSignedMessageHash().recover(signature);
        require(to == signer, "invalid signature");

        // execute mint
        mint(to);
    }

    function openMint(address to) external {
        // validate
        require(openMintEnabled, "not enabled");
        require(totalSupply() < maxSupply, "max supply reached");

        // execute mint
        mint(to);
    }

    // internal

    function mint(address to) private {
        require(balanceOf(to) == 0, "wallet limit reached");

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();
        _mint(to, tokenId);

        emit Mint(tokenId, to);
    }

    // delegate to renderer contract
    function render(
        uint256 tokenId
    ) public view override returns (string memory) {
        return ISwappableRenderer(rendererAddress).render(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return render(tokenId);
    }
}
