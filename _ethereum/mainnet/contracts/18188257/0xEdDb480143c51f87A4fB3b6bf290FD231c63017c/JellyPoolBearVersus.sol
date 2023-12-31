// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ERC721A.sol";

/**
 * @title JellyPoolBear Versus
 * @custom:version 1.0
 * @notice ERC721A NFT Contract
 */
contract JellyPoolBearVersus is Ownable, ERC721A {
  using Strings for uint256;

  uint256 public constant NUMBER_OF_FREE_MINTS = 10;
  uint256 public constant PRICE = 0.01 ether;
  uint256 public immutable STARTING_TIME;

  uint256 public votesGuilty;

  /// @dev Thrown when not enough ether provided to mint the specified amount of tokens
  error InvalidPayment();

  /// @dev Thrown when trying to mint, but mint already closed
  error MintClosed();

  /// @dev Thrown when trying to query the URI for a non existent token
  error InvalidTokenId();

  /// @dev Thrown when withdraw to owner failed
  error WithdrawFailed();

  /// @dev ERC-4906: EIP-721 Metadata Update Extension
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  /// @notice Inits the ERC721A contract and sets the STARTING_TIME to the current blocknumber
  constructor() ERC721A("JellyPoolBear Versus", "JPBVS1") {
    STARTING_TIME = block.timestamp;
  }

  /**
   * @notice Mint tokens, first 100 tokens free, rest costs 0.01 ether
   * @param quantity The number of tokens to mint.
   * @param voteGuilty Vote => True = Guilty, False = Not Guilty.
   */
  function mint(uint256 quantity, bool voteGuilty) external payable {
    if (!isMintOpen()) revert MintClosed();

    uint256 neededValue = totalSupply() < NUMBER_OF_FREE_MINTS &&
      balanceOf(msg.sender) == 0
      ? PRICE * quantity - PRICE
      : PRICE * quantity;
    if (msg.value < neededValue) revert InvalidPayment();

    _mint(msg.sender, quantity);

    if (voteGuilty) votesGuilty += quantity;

    emit BatchMetadataUpdate(0, totalSupply());
  }

  /// @notice Withdraw collected minting fees
  function withdraw() external onlyOwner {
    uint256 amount = address(this).balance;

    (bool success, ) = payable(owner()).call{ value: amount }("");
    if (!success) revert WithdrawFailed();
  }

  /**
   * @notice Mint is open for 4 weeks
   * @return a boolean if the mint is open
   */
  function isMintOpen() public view returns (bool) {
    return block.timestamp - STARTING_TIME < 4 weeks;
  }

  /**
   * @notice tokenURI funtion from ERC721
   * @param tokenId The id of the token
   * @return The metadata of the given token id
   */
  function tokenURI(
    uint256 tokenId
  ) public view override returns (string memory) {
    if (!_exists(tokenId)) revert InvalidTokenId();

    string memory image = _getImage();
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Trial by Token: Trump #',
            tokenId.toString(),
            '", "description": "Trial by Token: Trump is an interactive art project by Manuel W Stepan. Drawing from his JellyPoolBear series, Stepan offers a living piece of art that thrives on viewer interaction and the dynamics of collective decision-making. The piece stands to face a perpetual trial by its token holders, who are entrusted with the power to cast votes - guilty or not guilty. Each vote influences the artwork`s visual state, making it an ever-evolving entity that reflects the prevailing sentiments of its collective audience. Trial by Token: Trump thus becomes a real-time critique of art valuation, an exercise in collective power, and an immersive, ever-changing spectacle.", "image": "',
            image,
            '", "external_url": "',
            image,
            '"}'
          )
        )
      )
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
  }

  /**
   * @notice
   * @return IPFS uri to the current state (Guilty / Not Guilty) of the tokens
   */
  function _getImage() internal view returns (string memory) {
    if ((votesGuilty * 100) / totalSupply() >= 90) {
      return string(abi.encodePacked(_baseURI(), "JPB_Trump_5.jpg")); // more than or equal to 90% votes for guilty
    } else if ((votesGuilty * 100) / totalSupply() >= 65) {
      return string(abi.encodePacked(_baseURI(), "JPB_Trump_4.jpg")); // more than or equal to 65 % votes for guilty
    } else if ((votesGuilty * 100) / totalSupply() <= 10) {
      return string(abi.encodePacked(_baseURI(), "JPB_Trump_1.jpg")); // more than or equal to 90 % votes for not guilty
    } else if ((votesGuilty * 100) / totalSupply() <= 35) {
      return string(abi.encodePacked(_baseURI(), "JPB_Trump_2.jpg")); // more than or equal to 65 % votes for not guilty
    } else {
      return string(abi.encodePacked(_baseURI(), "JPB_Trump_3.jpg")); // balanced votes
    }
  }

  /**
   * @notice ERC721 BaseURI for computing tokenURI
   * @return IPFS uri to the current state (Guilty / Not Guilty) of the tokens
   */
  function _baseURI() internal pure override returns (string memory) {
    return
      "ipfs://bafybeibqve3evmkggvnb2chjmkcf2a3v6cdrbjjrnz5xw6mwyqkr7oblji/";
  }
}
