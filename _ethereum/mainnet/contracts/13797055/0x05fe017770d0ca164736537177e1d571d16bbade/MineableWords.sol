//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./MineableWordsLibrary.sol";

contract MineableWords is ERC721Enumerable, Ownable {
  IERC721 public mineablePunks;

  event BountyOffered(uint256 indexed mword);
  event BountyRemoval(uint256 indexed mword);

  uint88 private constant LENGTH_MASK = (2**4 - 1) << (88 - 8);
  uint8 private constant LENGTH_SHIFT_WIDTH = 84 - 4;
  uint88 private constant CHAR_MASK = 2**5 - 1;
  uint8 private constant REMOVE_BOUNTY_DELAY_BLOCKS = 3;

  uint88[] private wordLengthMasks;
  bytes public characters;

  uint8[] public lengthToIndex;
  uint16[] public capsByIndex;
  uint16[] public countsByIndex;

  struct Bounty {
    address buyer;
    uint256 value;
    bool isClaimed;
    uint256 safeRemoveAfterBlockNumber;
  }

  // Treasury
  uint256 public constant MINT_FEE = 20000000000000000;
  uint256 public fees = 0;
  mapping(uint256 => Bounty) public bounties;
  mapping(address => uint256) public withdrawableBalances;

  constructor(IERC721 _mineablePunks)
    ERC721("MineableWords", "MWORDS")
    Ownable()
  {
    mineablePunks = _mineablePunks;

    for (uint8 i = 97; i < 123; i++) {
      characters.push(bytes1(i));
    }

    characters.push(bytes1("_"));
    characters.push(bytes1("!"));
    characters.push(bytes1("."));
    characters.push(bytes1("@"));
    characters.push(bytes1("&"));
    characters.push(bytes1("?"));

    uint88 wordLengthMask = LENGTH_MASK | (CHAR_MASK << (80 - 5));
    for (uint8 i = 0; i < 16; i++) {
      wordLengthMask = wordLengthMask | (CHAR_MASK << (80 - (5 * (i + 1))));
      wordLengthMasks.push(wordLengthMask);
    }

    //tier 1
    lengthToIndex.push(0);
    lengthToIndex.push(0);
    lengthToIndex.push(0);
    lengthToIndex.push(0);
    lengthToIndex.push(0);
    lengthToIndex.push(0);

    //tier 2
    lengthToIndex.push(1);
    lengthToIndex.push(1);
    lengthToIndex.push(1);
    lengthToIndex.push(1);

    //tier 3
    lengthToIndex.push(2);

    //tier 4
    lengthToIndex.push(3);

    //tier 5
    lengthToIndex.push(4);
    lengthToIndex.push(5);
    lengthToIndex.push(6);
    lengthToIndex.push(7);

    //caps
    capsByIndex.push(2500);
    capsByIndex.push(1500);
    capsByIndex.push(350);
    capsByIndex.push(250);
    capsByIndex.push(200);
    capsByIndex.push(200);
    capsByIndex.push(200);
    capsByIndex.push(200);

    //counts
    countsByIndex.push(0);
    countsByIndex.push(0);
    countsByIndex.push(0);
    countsByIndex.push(0);
    countsByIndex.push(0);
    countsByIndex.push(0);
    countsByIndex.push(0);
    countsByIndex.push(0);
  }

  function isMpunkOwner(address sender) public view returns (bool) {
    return mineablePunks.balanceOf(sender) > 0;
  }

  function mint(uint96 nonce) external payable {
    require(
      msg.value >= MINT_FEE || isMpunkOwner(msg.sender),
      "mint fee not satisfied"
    );
    uint256 mword = encodeNonce(msg.sender, nonce);
    require(!ERC721._exists(mword), "mword already mined");

    uint8 length = uint8((mword & LENGTH_MASK) >> LENGTH_SHIFT_WIDTH) + 1;

    uint8 index = lengthToIndex[length - 1];
    uint16 cap = capsByIndex[index];
    uint16 count = countsByIndex[index];

    require(count < cap, "cap reached");

    ERC721._safeMint(msg.sender, mword);
    countsByIndex[index] = countsByIndex[index] + 1;
    fees += MINT_FEE;
  }

  function withdrawFees() external onlyOwner {
    uint256 payout = fees;
    fees = 0;
    payable(Ownable.owner()).transfer(payout);
  }

  function withdraw() external {
    uint256 amount = withdrawableBalances[msg.sender];
    withdrawableBalances[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }

  function offerBounty(uint256 mword) external payable {
    require(!ERC721._exists(mword), "mword already mined");
    require(msg.value > 0, "must offer > 0 eth");
    Bounty memory existing = bounties[mword];
    if (existing.value > 0) {
      require(
        msg.value > (existing.value + (existing.value / 20)),
        "value <1.05x existing bounty"
      );
      // Refund
      withdrawableBalances[existing.buyer] += existing.value;
    }

    bounties[mword] = Bounty(msg.sender, msg.value, false, 0);
    emit BountyOffered(mword);
  }

  function claimBounty(uint256 mword) external {
    require(ERC721.ownerOf(mword) == msg.sender, "sender does not own mword");
    Bounty storage existing = bounties[mword];
    require(existing.value > 0, "no bounty for this mword");
    require(!existing.isClaimed, "bounty already claimed");

    existing.isClaimed = true;
    withdrawableBalances[msg.sender] += existing.value;
  }

  function initiateBountyRemoval(uint256 mword) external {
    Bounty storage existing = bounties[mword];
    require(existing.buyer == msg.sender, "sender did not create bounty");
    require(existing.value > 0, "no bounty for this mword");
    require(!existing.isClaimed, "bounty already claimed");

    existing.safeRemoveAfterBlockNumber =
      block.number +
      REMOVE_BOUNTY_DELAY_BLOCKS;
  }

  function removeBounty(uint256 mword) external {
    Bounty memory existing = bounties[mword];
    require(existing.buyer == msg.sender, "sender did not create bounty");
    require(existing.value > 0, "no bounty for this mword");
    require(!existing.isClaimed, "bounty already claimed");
    require(existing.safeRemoveAfterBlockNumber > 0, "removal not initiated");
    require(
      block.number > existing.safeRemoveAfterBlockNumber,
      "block delay has not passed, or removal not initiated"
    );

    bounties[mword] = Bounty(address(0), 0, false, 0);
    withdrawableBalances[existing.buyer] += existing.value;
    emit BountyRemoval(mword);
  }

  /* View only functions */

  function encodeNonce(address sender, uint96 nonce)
    public
    view
    returns (uint88)
  {
    return
      encodeMword(uint256(keccak256(abi.encodePacked(uint160(sender), nonce))));
  }

  function encodeMword(uint256 data) public view returns (uint88) {
    uint8 lengthIndex = uint8((data & LENGTH_MASK) >> LENGTH_SHIFT_WIDTH);
    return uint88(data) & wordLengthMasks[lengthIndex];
  }

  function decodeMword(uint88 encoded) public view returns (string memory) {
    uint8 length = uint8((encoded & LENGTH_MASK) >> LENGTH_SHIFT_WIDTH) + 1;

    bytes memory decodedCharacters = new bytes(length);
    for (uint256 i = 0; i < length; i++) {
      uint8 shiftWidth = uint8(80 - (5 * (i + 1)));
      uint88 bitMask = CHAR_MASK << shiftWidth;
      uint8 character = uint8((encoded & bitMask) >> shiftWidth);
      decodedCharacters[i] = characters[character];
    }

    return string(decodedCharacters);
  }

  function renderData(uint256 data) public view returns (string memory) {
    string memory mword = decodeMword(uint88(data));

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          MineableWordsLibrary.encode(
            bytes(
              abi.encodePacked(
                '{"name": "',
                mword,
                '", "description": "mwords are mined, not claimed", "image": "data:image/svg+xml;base64,',
                MineableWordsLibrary.encode(
                  bytes(
                    abi.encodePacked(
                      '<svg xmlns="http://www.w3.org/2000/svg"><text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle" font-family="sans-serif" font-size="25" fill="black">',
                      mword,
                      "</text></svg>"
                    )
                  )
                ),
                '", "attributes": [] }'
              )
            )
          )
        )
      );
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(ERC721._exists(tokenId), "token does not exist");
    return renderData(tokenId);
  }
}
