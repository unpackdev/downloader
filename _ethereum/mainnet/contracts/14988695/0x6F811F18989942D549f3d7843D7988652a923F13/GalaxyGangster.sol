// contracts/GalaxyGangster.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

error CallerIsContract();
error EtherValueIncorrect();
error MaxMintReached();
error ExceedsMaxSupply();
error MintQuantityZero();

contract GalaxyGangster is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_OWNABLE = 5;
    uint256 public constant MINT_PRICE = 0.05 ether;

    string public BASE_URI;

    constructor() ERC721A("Galaxy Gangster", "GG") {}

    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerIsContract();
        _;
    }

    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    function withdrawEth() public onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
        value: address(this).balance
        }("");
        require(success);
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        if (msg.value < MINT_PRICE * _quantity) revert EtherValueIncorrect();
        if (_quantity < 1) revert MintQuantityZero();
        if (totalSupply() + _quantity >= MAX_SUPPLY) revert ExceedsMaxSupply();
        if (_numberMinted(msg.sender) + _quantity > MAX_OWNABLE) revert MaxMintReached();
        _safeMint(msg.sender, _quantity);
    }
}