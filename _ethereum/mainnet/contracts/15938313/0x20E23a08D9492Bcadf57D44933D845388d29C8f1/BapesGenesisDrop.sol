// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Ownable.sol";
import "./IERC721.sol";
import "./MerkleProof.sol";

contract BapesGenesisDrop is Ownable {
  using Strings for uint256;

  bool private isMintStarted = true;
  bytes32 private merkleRoot;
  uint256 public mintPerWallet = 1;
  uint256 public startTokenId = 2300;
  mapping(address => uint256) private mintedWallets;

  address private holder;
  IERC721 private gen1;

  constructor() {
    holder = address(0xc6F53a31dE0ED6753F021224905772C706eE71ea);
    gen1 = IERC721(0x8Ce66fF0865570D1ff0BB0098Fa41B4dc61E02e6);
  }

  function addressToString() internal view returns (string memory) {
    return Strings.toHexString(uint160(msg.sender), 20);
  }

  function transferTo(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      gen1.safeTransferFrom(holder, _receiver, startTokenId);

      startTokenId++;
    }
  }

  function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public {
    uint256 minted = mintedWallets[msg.sender];

    require(isMintStarted, "Minting is paused");
    require(minted < mintPerWallet, "This wallet has already minted");

    bytes32 leaf = keccak256(abi.encodePacked(addressToString(), "-", _mintAmount.toString()));

    require(
      MerkleProof.verify(_merkleProof, merkleRoot, leaf),
      "Invalid proof, this wallet is not eligible for selected amount of NFTs"
    );

    mintedWallets[msg.sender] = mintPerWallet;

    transferTo(msg.sender, _mintAmount);
  }

  function mintFor(uint256 _mintAmount, address _receiver) external onlyOwner {
    require(isMintStarted, "Minting is paused");

    transferTo(_receiver, _mintAmount);
  }

  function toggleMint(bool _state) external onlyOwner {
    isMintStarted = _state;
  }

  function updateMintPerWallet(uint256 _amount) external onlyOwner {
    mintPerWallet = _amount;
  }

  function updateStartTokenId(uint256 _tokenId) external onlyOwner {
    startTokenId = _tokenId;
  }

  function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }
}
