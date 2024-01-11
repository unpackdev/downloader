//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";


contract AlphaPass is ERC721A, Ownable {
    using ECDSA for bytes32;

    event Redeemed(bytes32);

    uint256 immutable maxSupply = 100;

    string private _baseTokenURI;

    address public immutable signer;

    mapping (address => bool) claimed;

    constructor(
      address _signer,
      address team,
      string memory baseURI
      ) ERC721A("AlphaPass", "ALPHA") {
      _safeMint(team, 16);
      signer = _signer;
      _baseTokenURI = baseURI;
    }

    function mintAlphaPass(bytes calldata signature) public {
      require(totalSupply() + 1 <= maxSupply);
      require(!claimed[msg.sender], "ALREADY_CLAIMED");
      require(keccak256(
        abi.encodePacked("\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(msg.sender))
        )).recover(signature) == signer);
      _safeMint(msg.sender, 1);
      claimed[msg.sender] = true;
    }

    function redeem(uint256 tokenId, bytes32 content) external {
        require(ownerOf(tokenId) == msg.sender, "NOT_OWNER");
        _burn(tokenId);
        emit Redeemed(content);
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string memory _base) public onlyOwner {
      _baseTokenURI = _base;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
      return _baseURI();
    }

}
