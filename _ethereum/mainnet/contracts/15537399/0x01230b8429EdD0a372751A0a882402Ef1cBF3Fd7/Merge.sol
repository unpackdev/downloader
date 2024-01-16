// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.11;

import "./Base64.sol";

import "./Tiny721.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CannotExceedAllowance();

/**
  @title An on-chain generative celebration of the Merge.
  @author Tim Clancy
  @author 0xthrpw

  This contract generates a piece of pseudorandom data upon each token's mint.
  This data is then used to generate 100% on-chain an SVG celebrating the
  Ethereum merge.

  Should auld acquaintance be forgot
  And never brought to mind?
  Should auld acquaintance be forgot
  And days of auld lang syne?
  For auld lang syne, my dear
  For auld lang syne
  We'll tak a cup o' kindness yet
  For days of auld lang syne
  We twa hae run about the braes
  And pu'd the gowans fine
  But we've wander'd mony a weary fit
  Sin days of auld lang syne
  And we twa hae paidl'd I' the burn
  Frae morning sun 'til dine
  But seas between us braid hae roar'd
  Sin days of auld lang syne
  For auld lang syne, my dear
  For auld lang syne
  We'll tak a cup o' kindness yet
  For days of auld lang syne
  And surely ye'll be your pint-stowp
  And surely I'll be mine
  And we'll tak a cup o' kindness yet
  For auld lang syne
  And there's a hand, my trusty fiere
  And gie's a hand o' thine
  And we'll tak a right gude-willy waught
  For auld lang syne
  For auld lang syne, my dear
  For auld lang syne
  We'll tak a cup o' kindness yet
  For auld lang syne
  For auld lang syne, my dear
  For auld lang syne
  We'll tak a cup o' kindness yet
  For auld lang syne

  Wishing the world a very happy Merge from everyone at Super Studios.

  @custom:date September 15th, 2022.
*/
contract Merge is
  Tiny721
{
  using Strings for uint256;

  /// A mapping from each token ID to the pseudorandom hash when it was minted.
  mapping ( uint256 => uint256 ) public mintData;

  /// A counter for how many items a single address has minted.
  mapping ( address => uint256 ) public mintCount;

  /**
    Construct a new instance of this ERC-721 contract.
  */
  constructor (
  ) Tiny721("Merge", "M", "", 10000) {

    // Mint to the early birds. Hoorah!
    mint(0xbe4f0cdf3834bD876813A1037137DcFAD79AcD99, 2);
    mint(0xf18DC02b46e8F9345BcA11f502d03B3792D90Ce9, 2);
    mint(0xC600c0B7f0C35c337C41f8c01E289255ebd80331, 2);
    mint(0x592234c63AC3c816B0485761BC00Fc1B932d18fd, 2);
  }

  /**
    Retrieve the token's pregenerated pseudorandom value and mix it with a given
    `_index` to keep it pseudorandom on successive calls.

    @param _id The ID of the token to retrieve the pregenerated value for.
    @param _index An index to prevent duplicating the random roll.

    @return A pseudorandom value.
  */
  function _getRandom (
    uint256 _id,
    uint256 _index
  ) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      mintData[_id],
      _index
    )));
  }

  /**
    Directly return the metadata of the token with the specified `_id` as a
    packed base64-encoded URI.

    @param _id The ID of the token to retrive a metadata URI for.

    @return The metadata of the token with the ID of `_id` as a base64 URI.
  */
  function tokenURI (
    uint256 _id
  ) external view virtual override returns (string memory) {
    if (!_exists(_id)) { revert URIQueryForNonexistentToken(); }

    /*
      Retrieve the random roll and generate some randomized curve information.
    */
    uint256 strokeWidth = 8 + (_getRandom(_id, 3000) % 24);

    // Encode the SVG into a base64 data URI.
    string memory encodedImage = string(abi.encodePacked(
      "data:image/svg+xml;base64,",
      Base64.encode(
        bytes(
          string(abi.encodePacked(
            "<svg version=\"1.1\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\" stroke-linecap=\"round\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"><style>.small { font: 64px sans-serif; text-anchor: middle; } .merge { stroke-dasharray: 25; stroke-dashoffset: 100; animation: dash 1s linear forwards; animation-iteration-count: infinite; } @keyframes dash { to { stroke-dashoffset: 0; } }</style><rect width=\"100%\" height=\"100%\" fill=\"black\"/><text x=\"33%\" y=\"95%\" fill=\"white\" class=\"small\">The Merge, 5.875e22</text><path id=\"pow\" class=\"merge\" stroke=\"red\" stroke-width=\"",
            (strokeWidth).toString(),
            "\" d=\"M 0 0 C 0 0, 128 0, 128 512\" fill=\"transparent\"/>",
            "<path id=\"beacon\" class=\"merge\" stroke=\"blue\" stroke-width=\"",
            (strokeWidth).toString(),
            "\" d=\"M 0 1024 C 0 1024, 256 1024, 128 512\" fill=\"transparent\"/>",
            "<path id=\"merge\" class=\"merge\" stroke=\"white\" stroke-width=\"",
            (strokeWidth).toString(),
            "\" d=\"M 128 512 C 128 512, 256 0, 512 512 C 512 512, 768 1024, 1024 512\" fill=\"transparent\"/>",
            "<animate id=\"pulse\" href=\"#merge\" attributeName=\"d\" begin=\"0s;first.end\" values=\"M 128 512 C 128 512, 256 0, 512 512 C 512 512, 768 1024, 1024 512;M 128 512 C 128 512, 128 0, 512 512 C 512 512, 768 768, 1024 512;M 128 512 C 128 512, 256 0, 512 512 C 512 512, 768 1024, 1024 512\" dur=\"3s\" /><animate id=\"color\" href=\"#merge\" attributeName=\"stroke\" begin=\"0s;color.end\" values=\"#FFFFFF;#FF0000;#00FF00;#0000FF;#FFFFFF\" dur=\"3s\" /></svg>"
          ))
        )
      )
    ));

    // Return the base64-encoded packed metadata.
    return string(
      abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            abi.encodePacked(
              "{ \"name\": \"",
              "Merge ",
              (_id).toString(),
              "\", \"description\": \"\", ",
              "\"image\": \"",
              encodedImage,
              "\"}"
            )
          )
        )
      )
    );
  }

  /**
    This function allows permissioned minters of this contract to mint one or
    more tokens dictated by the `_amount` parameter. Any minted tokens are sent
    to the `_recipient` address.

    Note that tokens are always minted sequentially starting at one. That is,
    the list of token IDs is always increasing and looks like [ 1, 2, 3... ].
    Also note that per our use cases the intended recipient of these minted
    items will always be externally-owned accounts and not other contracts. As a
    result there is no safety check on whether or not the mint destination can
    actually correctly handle an ERC-721 token.

    @param _recipient The recipient of the tokens being minted.
    @param _amount The amount of tokens to mint.
  */
  function mint (
    address _recipient,
    uint256 _amount
  ) public {

    /*
      Limit the number of items that a single caller may mint. Normally I split
      logic like this out of the item itself and host it in a separate shop
      contract for better composability. This is a silly little NFT project so I
      don't feel the need to do that.
    */
    if (mintCount[_msgSender()] + _amount > 10) {
      revert CannotExceedAllowance();
    }
    mintCount[_msgSender()] += _amount;

    // Store a piece of pseudorandom data tied to each item that will be minted.
    uint256 startTokenId = nextId;
    unchecked {
      uint256 updatedIndex = startTokenId;
      for (uint256 i; i < _amount; i++) {
        mintData[updatedIndex] = uint256(keccak256(abi.encodePacked(
          _msgSender(),
          _recipient,
          _amount,
          updatedIndex,
          block.timestamp,
          block.difficulty
        )));
        updatedIndex++;
      }
    }

    // Actually mint the items.
    super.mint_Qgo(_recipient, _amount);
  }
}
