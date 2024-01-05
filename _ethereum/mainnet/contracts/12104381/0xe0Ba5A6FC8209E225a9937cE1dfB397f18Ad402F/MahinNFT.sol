// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Roles.sol";
import "./Randomness.sol";
import "./Fees.sol";


contract MahinNFT is Roles, ERC721("Mahin", "MAHIN"), Randomness, HasFees  {
  event TokenDataStorage(
    uint256 indexed tokenId,
    bytes[] states
  );

  event Diagnosed(
    uint256 indexed tokenId
  );

  struct Piece {
    string name;
    bytes[] imageData;
    string[] ipfsHashes;
    string[] arweaveHashes;
    uint8 currentState;
  }

  // The beneficiary (the charity or someone acting in their name) - receives royalties.
  address public beneficiary;

  mapping(uint256 => Piece) public pieces;

  constructor(VRFConfig memory vrfConfig) Randomness(vrfConfig) {
  }

  function withdraw() public onlyOwner {
    address payable owner = payable(owner());
    owner.transfer(address(this).balance);
  }

  function withdrawToken(address tokenAddress) public onlyOwner {
    IERC20 token = IERC20(tokenAddress);
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  // Returns the current SVG/PNG of the piece.
  function getImageData(uint256 tokenId) public view returns (bytes memory) {
    require(_exists(tokenId), "not a valid token");
    return pieces[tokenId].imageData[0];
  }

  function setImageData(uint256 tokenId, bytes calldata state1, bytes calldata state2) public onlyOwner {
    pieces[tokenId].imageData[0] = state1;
    pieces[tokenId].imageData[1] = state2;
  }

  // Will be used by the owner during setup to create all pieces of the work.
  // ipfsHashes - the ipfs location of each state - needed so provided an off-chain metadata url.
  function initToken(uint256 tokenId, string memory name, string[] memory arweaveHashes, string[] memory ipfsHashes) public onlyOwner {
    require(pieces[tokenId].ipfsHashes.length == 0, "invalid id");

    pieces[tokenId].name = name;
    pieces[tokenId].ipfsHashes = ipfsHashes;
    pieces[tokenId].arweaveHashes = arweaveHashes;
    pieces[tokenId].currentState = 0;
  }

  // Init multiple tokens at once
  function initTokens(uint256[] memory tokenIds, string[] memory names, string[][] memory arweaveHashSets, string[][] memory ipfsHashSets) public onlyOwner {
    for (uint256 i=0; i<tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(pieces[tokenId].ipfsHashes.length == 0, "invalid id");

      pieces[tokenId].name = names[i];
      pieces[tokenId].ipfsHashes = ipfsHashSets[i];
      pieces[tokenId].arweaveHashes = arweaveHashSets[i];
      pieces[tokenId].currentState = 0;
    }
  }

  // Allow contract owner&minter to mint a token and assigned to to anyone they please.
  function mintToken(uint256 tokenId, address firstOwner) public onlyMinterOrOwner {
    require(pieces[tokenId].ipfsHashes.length > 0, "invalid id");
    require(!_exists(tokenId), "exists");

    _mint(firstOwner, tokenId);
  }

  // Allow contract owner to set the IPFS host
  function setIPFSHost(string memory baseURI_) public onlyOwner {
    _setBaseURI(baseURI_);
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  // Return the current IPFS link based on state
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(pieces[tokenId].ipfsHashes.length > 0, "invalid id");

    Piece memory piece = pieces[tokenId];
    string memory tokenPath = piece.ipfsHashes[piece.currentState];
    return string(abi.encodePacked(baseURI(), tokenPath));
  }

  function onDiagnosed(uint256 tokenId) internal override {
    pieces[tokenId].currentState = 1;
    emit Diagnosed(tokenId);
  }

  function diagnose(uint256 tokenId) public onlyDoctor {
    onDiagnosed(tokenId);
  }

  function getBeneficiary() internal override view returns (address) {
    return beneficiary;
  }

  function getFee(uint256 tokenId) override internal view returns (uint256) {
    if (pieces[tokenId].currentState >= 1) {
      return 15;
    } else {
      return 5;
    }
  }
}

