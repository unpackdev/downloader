//    .^7??????????????????????????????????????????????????????????????????7!:       .~7????????????????????????????????:
//     :#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y   ^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5
//    ^@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB&@@@@@B ~@@@@@@#BBBBBBBBBBBBBBBBBBBBBBBBBBBBB#7
//    Y@@@@@#                                                                ~@@@@@@ P@@@@@G
//    .&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G~ ~@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y :@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~
//      J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#.!B@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B~   .Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B
//         ...........................B@@@@@5  .7#@@@@@@@#?^....................          ..........................:#@@@@@J
//    ^5YYYJJJJJJJJJJJJJJJJJJJJJJJJJJY&@@@@@?     .J&@@@@@@&5JJJJJJJJJJJJJJJJJJJYYYYYYYYYYJJJJJJJJJJJJJJJJJJJJJJJJJJY@@@@@@!
//    5@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?         :5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7
//    !GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPY~              ^JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPJ^

//  _____________________________________________________ Tomb Series  _____________________________________________________

//       :!JYYYYJ!.                   .JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?~.   7YYYYYYYYY?~.              ^JYYYYYYYYY^
//     ~&@@@@@@@@@@#7.                ?@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P  &@@@@@@@@@@@@B!           :@@@@@@@@@@@5
//    ^@@@@@@BB@@@@@@@B!              ?@@@@@&PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG&@@@@@# JGGGGGGG#@@@@@@@G^         !PGGGGGGGGG!
//    5@@@@@5  .7#@@@@@@@P^           ?@@@@@P                                .@@@@@@.         .J&@@@@@@&5:
//    Y@@@@@Y     .J&@@@@@@&5:        ?@@@@@G                                 @@@@@@.            :Y&@@@@@@&J.
//    Y@@@@@5        :5&@@@@@@&J.     ?@@@@@G                                 @@@@@@.               ^P@@@@@@@#7.
//    Y@@@@@5           ^P@@@@@@@#7.  J@@@@@G                                 @@@@@@.                  ~G@@@@@@@B!
//    Y@@@@@5              ~B@@@@@@@BG@@@@@@! PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@# JGPPPPPPPP5:        .7#@@@@@@@GPPPPPPG~
//    5@@@@@5                .7#@@@@@@@@@@&! .@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G  &@@@@@@@@@@&           .J&@@@@@@@@@@@@5
//    ^5YYY5~                   .!JYYYYY7:    Y5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ~.   ?5YYYYYYY5J.              :7JYYYYYYYY5^

//  __________________________________________________ Tomb Index Marker ___________________________________________________

// ________________________________________________ Deployed by TERRAIN 2022 _______________________________________________

// ____________________________________________ All tombs drawn by David Rudnick ___________________________________________

// ____________________________________________ Contract architect: Luke Miles _____________________________________________

// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ECDSA.sol";
import "./Strings.sol";
import "./Ownable.sol";

pragma solidity >=0.8.0;

contract IndexMarker is Ownable, ERC721 {
  string public baseURI;
  address public signer;

  bool public isMintingAllowed = false;
  uint256 public mintExpiry = 1672531199; // Sat Dec 31 2022 23:59:59 GMT+0000
  uint256 public royaltyPct = 10;
  uint16 public maxIndex = 3000;

  ERC721 indexContract;

  mapping(bytes32 => uint256) public premintTimes;

  address public royaltyDestination;
  address internal _tombArtist = 0x4a61d76ea05A758c1db9C9b5a5ad22f445A38C46;

  constructor(
    address _signer,
    string memory _baseURI,
    address _indexContract,
    address _royaltyDestination
  ) ERC721("Tomb Index Marker", "MKR") {
    royaltyDestination = _royaltyDestination;
    signer = _signer;
    baseURI = _baseURI;
    indexContract = ERC721(_indexContract);

    // initialize RONIN
    _mint(msg.sender, 0);
  }

  function canMint() public view returns (bool) {
    // solhint-disable-next-line not-rely-on-time
    return isMintingAllowed && mintExpiry > block.timestamp;
  }

  function calculateMintHash(
    uint256 tokenID,
    bytes memory signature,
    address sender
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(tokenID, signature, sender));
  }

  function premint(bytes32 _hash) public {
    // This function reserve the tokenID for the user calling the key.
    // Prevents against someone checking the mempool for calls to mint.

    // Don't allow overriding the hash, otherwise someone could frontrun
    // by resetting someone's hash value to the current timestamp.
    require(premintTimes[_hash] == 0, "Can't override hash value");

    // solhint-disable-next-line not-rely-on-time
    premintTimes[_hash] = block.timestamp;
  }

  function mint(uint256 tokenID, bytes memory signature) public {
    require(canMint(), "Public minting is not active");
    require(tokenID <= maxIndex, "Index is too high");
    bytes32 mintHash = calculateMintHash(tokenID, signature, msg.sender);
    uint256 premintTime = premintTimes[mintHash];
    require(premintTime != 0, "Token is not preminted");

    require(
      // solhint-disable-next-line not-rely-on-time
      block.timestamp - premintTime > 60,
      "Claim is too new"
    );

    (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(
      keccak256(abi.encodePacked(tokenID)),
      signature
    );
    require(
      error == ECDSA.RecoverError.NoError && recovered == signer,
      "Invalid signature"
    );

    _mint(msg.sender, tokenID);
  }

  function creatorClaim(uint256[] calldata tokenIDs, address destination)
    public
    onlyOwner
  {
    require(!canMint(), "Can't admin claim when mint active");
    for (uint256 i = 0; i < tokenIDs.length; i++) {
      require(tokenIDs[i] <= maxIndex, "Index is too high");
      _mint(destination, tokenIDs[i]);
    }
  }

  function updateSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function updateRoyaltyPct(uint256 _newRoyaltyPct) public onlyOwner {
    royaltyPct = _newRoyaltyPct;
  }

  function updateRoyaltyDestination(address _newRoyaltyDestination)
    public
    onlyOwner
  {
    royaltyDestination = _newRoyaltyDestination;
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setMintInformation(bool _isMintingAllowed, uint256 _mintExpiry)
    public
    onlyOwner
  {
    isMintingAllowed = _isMintingAllowed;
    mintExpiry = _mintExpiry;
  }

  function tokenURI(uint256 tokenID)
    public
    view
    override
    returns (string memory)
  {
    // for the RONIN metadata
    if (tokenID == 0) {
      return indexContract.tokenURI(21);
    }

    return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
  }

  function royaltyInfo(uint256 _tokenID, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    if (royaltyPct < 1) {
      return (address(0), 0);
    }

    receiver = royaltyDestination;

    if (_tokenID == 0) {
      receiver = _tombArtist;
    }

    royaltyAmount = _salePrice / royaltyPct;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override(ERC721)
    returns (bool)
  {
    return
      interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
      interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC721Metadata
      interfaceId == 0x2a55205a; // ERC165 Interface ID for https://eips.ethereum.org/EIPS/eip-2981
  }
}
