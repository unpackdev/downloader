// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract SweETHeartz is ERC721, Ownable {
    using ECDSA for bytes32;

    uint256 public amountMinted = 1;
    uint256 public constant PRICE = 0.02 ether;
    // 1999 available in total, offset by 1 to skip a <= check
    uint256 public constant SUPPLY = 2000;

    string public _baseTokenURI;

    address private a1 = 0xF78Fcd79eEC783B6e8E7Fb9EFef4bd602e7305c5;
    address private b1 = 0x985AFcA097414E5510c2C4faEbDb287E4F237A1B;
    address private signer;

    event Mint(address purchaser);

    constructor(string memory baseURI, address _signer)
        ERC721("SweETHeartz", "HRTZ")
    {
        _baseTokenURI = baseURI;
        signer = _signer;
    }

    function mint(
        uint256 tokenId,
        address recipient,
        bytes memory signature
    ) external payable {
        require(amountMinted < SUPPLY, "SOLD_OUT");
        require(msg.value == PRICE, "INVALID_PRICE");
        require(
            _verify(
                keccak256(abi.encodePacked(msg.sender, tokenId)),
                signature
            ),
            "INVALID_SIGNATURE"
        );

        _mint(recipient, tokenId);

        unchecked {
            amountMinted++;
        }

        emit Mint(msg.sender);
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        require(signer != address(0), "INVALID_SIGNER_ADDRESS");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == signer;
    }

    function totalSupply() public view virtual returns (uint256) {
        return amountMinted - 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function withdraw() external onlyOwner {
        (bool s1, ) = a1.call{value: (address(this).balance * 50) / 100}("");
        (bool s2, ) = b1.call{value: (address(this).balance)}("");

        require(s1 && s2, "Transfer failed.");
    }
}
