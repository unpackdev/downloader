/*

████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████                          ██████      ██████
██████████████████████████████████  ,,██████████████████████,,  ████      ██████
██████████████████████████████▀▀  ▄▄██╬╬╬╬╬╬''''''''''''''''▀▀▄▄  ▀▀      ██████
████████████▀▀▀▀▀▀▀▀██████████░ ▄▄██╬╬╬╬╬╬╬╬                  ▀▀▄▄        ██████
██████████▀▀  ▄▄▄▄  ▀▀████████░ ██╬╬╬╬╬╬╬╬╬╬    ▄▄▄▄      ▄▄▄▄  ██░       ██████
██████████░ ██▀▀▀▀██  ╙▀▀▀▀▀▀▀  ██╬╬╬╬╬╬╬╬╬╬    ██▀▀      ██▀▀  ██░       ██████
██████████░ ██    `╙██████████████╬╬╬╬╬╬╬╬      ``         `    ██░       ██████
██████████░ ╙╙██                    ╬╬╬╬╬╬              ██      ██░   ==  ██████
████████████    ██░                                     ``  ██████████░   ██████
██████████████░   ██                                    ████        ││██  ██████
████████████████  ██                                        ██████████░   ██████
████████████████  ██                                        ██░         ████████
██████████████  ▄▄██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██░ ████████████████
████████████  ▄▄▀▀░╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙╙▄▄▀▀  ████████████████
████████████  ██''''''''''''''''''''''''''''''''''''''''''██  ▄▄████████████████
████████████  ██                              ╗╗╗╗╗╗╗╗    ██  ██████████████████
████████████  ██      ████▓▓▓▓▓▓████████      ██████╬╬    ██  ██████████████████
████████████  ██''''██└ ██╬╬╬╬██        ██∩'''██  ██╬╬∩'██└   ██████████████████
████████████  ██░░░░██░ ██╬╬╬╬██  ████░ ██░░░░██  ██╬╬░░██░ ████████████████████
████████████    ████      ████    ████░   ████      ████    ████████████████████
██████████████░       ██        ████████        ██░       ██████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████
████████████████████████████████████████████████████████████████████████████████


THE CRYPTOPOCALYPSE DAWNS
Will your pet survive?

@art:   pixantle
        @pixantle

@tech:  white lights
        @iamwhitelights

@title  RADIOACTIVEPETS

@dev    Extends ERC721 Non-Fungible Token Standard. Uses the ERC721A extension
        to allow for cheap batch minting, as well as pausing, burning and freezing
        metadata updates. Royalties are defined via the Rarible V1 Protocol and
        ERC2981 NFT Royalty Standard. The metadata is stored on Arweave,
        creating a completely on-chain collectible series. If any NFTs were to
        survive nuclear fallout, these would be the ones. Tokens are only
        mintable by a signed EIP-718 transaction to ward off contract
        attacks and minting via Etherscan. As an "Anti-Whale" mechanism,
        purchasers can only mint 100 NFTs lifetime on this contract, though they
        can own as many as they want.
*/

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ERC721ABurnable.sol";
import "./IERC20.sol";
import "./ERC721APausable.sol";
import "./HasSecondarySaleFees.sol";
import "./ERC2981.sol";


abstract contract RPUNKS {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract RADIOACTIVEPETS is ERC721ABurnable, ERC721APausable, HasSecondarySaleFees, ERC2981, Ownable {

  event Frozen();

  struct Unit {
    string logIn;
  }

  RPUNKS public RPUNK = RPUNKS(
    0x073Ca28E04719C05a5a48C1d992091b4075A0F84
  );

  bool public frozen = false;
  bool[3000] private claimedArray;
  uint256 public publicActivationTime = 1648742400; // THE CRYPTOPOCALYPSE
  uint256 public privateActivationTime = 1648742400; // THE CRYPTOPOCALYPSE
  address payable public PAYMENT_SPLITTER = payable(0xFc9961d08Ef8e04DB145b9fb3d48cf8DbA96116D ); // PaymentSplitter
  uint256 public petPrice = 50000000000000000;
  uint256 public MINTS_LEFT = 2999; // 0-2999
  string public API_BASE_URL = '';
  string public METADATA_PROVENANCE_HASH = '';

  string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
  string private constant UNIT_TYPE = "Unit(string logIn)";
  bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
  bytes32 private constant UNIT_TYPEHASH = keccak256(abi.encodePacked(UNIT_TYPE));
  bytes32 private DOMAIN_SEPARATOR = keccak256(abi.encode(
    EIP712_DOMAIN_TYPEHASH,
    keccak256("RADIOACTIVEPUNKS"),
    keccak256("1"), // version
    // !!!! WARNING!!!!!!!!!WARNING!!!!!!!!!! UPDATE ON DEPLOY!!!!!!
    // !!!! WARNING!!!!!!!!!WARNING!!!!!!!!!!!!!! UPDATE ON DEPLOY!!!!!!
    // !!!! WARNING!!!!!!!!!!!!!!!!!!WARNING!!!!!!!! UPDATE ON DEPLOY!!!!!!
    // !!!! WARNING!!!!!!WARNING!!!!!!!!!!!!!!! UPDATE ON DEPLOY!!!!!!
    1,
    0xFc9961d08Ef8e04DB145b9fb3d48cf8DbA96116D // PaymentSplitter
  ));

  constructor() ERC721A("Radioactive Pets", "RPET") {}

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    PAYMENT_SPLITTER.transfer(balance);
  }

  function setPaymentSplitter(address payable newAddress) external onlyOwner {
    PAYMENT_SPLITTER = newAddress;
  }

  function setRadioactvePunksContract(address contractAddress) external onlyOwner {
    RPUNK = RPUNKS(contractAddress);
  }

  function setPublicActivationTime(uint256 timestampInSeconds) external onlyOwner {
    publicActivationTime = timestampInSeconds;
  }

  function setPrivateActivationTime(uint256 timestampInSeconds) external onlyOwner {
    privateActivationTime = timestampInSeconds;
  }

  function setPrice(uint256 newPrice) external onlyOwner {
    petPrice = newPrice;
  }

  function setAPIBaseURL(string memory URI) external onlyOwner {
    require(frozen == false, "Frozen");
    API_BASE_URL = URI;
  }

  function pause() external {
    _pause();
  }

  function unpause() external {
    _unpause();
  }

  function publiclyActivated() public view returns (bool) {
    return block.timestamp >= publicActivationTime;
  }

  function privatelyActivated() public view returns (bool) {
    return block.timestamp >= privateActivationTime;
  }

  /*
   * Once executed, metadata for NFTs can never be changed.
   */
  function freezeMetadata() external onlyOwner {
    frozen = true;
    emit Frozen();
  }

  function _baseURI() internal view override returns (string memory) {
    return API_BASE_URL;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Token DNE");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0
      ? string(abi.encodePacked(baseURI, uint2str(tokenId), '.json'))
      : '';
  }

  /*
   * Allows the owner to mint X tokens as a way
   * of reserving them for our core supporters.
   */
  function mintPetsOwner(uint256 numberOfTokens) public onlyOwner {
    require(numberOfTokens <= MINTS_LEFT, "Exceeds max supply");

    _safeMint(msg.sender, numberOfTokens);
  }

  function punkIsClaimed(uint256 tokenId) external view returns (bool) {
    return claimedArray[tokenId];
  }

  /*
   * For minting pets as a punk owner.
   */
  function mintPetsForPunks(uint8 sigV, bytes32 sigR, bytes32 sigS) public payable {
    require(privatelyActivated(), 'You are too early');
    require(verify(msg.sender, sigV, sigR, sigS) == true, "No cheaters!");

    uint256 punks = RPUNK.balanceOf(msg.sender);
    require(punks > 0, "Need RPUNK");
    require(punks <= MINTS_LEFT, "Exceeds max supply");

    // claim those tokens as no longer usable to get a pet
    uint256 punksToMint = punks;
    for (uint256 i = 0; i < punks;) {
      uint256 ownedTokenId = RPUNK.tokenOfOwnerByIndex(msg.sender, i);
      if (claimedArray[ownedTokenId]) {
        unchecked {
          punksToMint--;
        }
      } else {
        claimedArray[ownedTokenId] = true;
      }

      unchecked {
        i++;
      }
    }

    // mint one for every eligible punk
    _safeMint(msg.sender, punksToMint);
  }

  /*
   * For minting pets publicly for ethereum.
   */
  function mintPetsPublic(uint256 numberOfTokens, uint8 sigV, bytes32 sigR, bytes32 sigS) public payable {
    require(publiclyActivated(), 'You are too early');
    require(numberOfTokens <= MINTS_LEFT, "Exceeds max supply");
    require(petPrice * numberOfTokens == msg.value, "Ether value incorrect");
    require(balanceOf(msg.sender) + numberOfTokens < 100, "Antiwhale");
    require(verify(msg.sender, sigV, sigR, sigS) == true, "No cheaters!");

    _safeMint(msg.sender, numberOfTokens);
  }

  /*
   * @dev Leads to a big file on IPFS containing a list of all
   *      tokenIDs and their corresponding metadata etc.
   */
  function setProvenanceHash(string memory hash) external onlyOwner {
    METADATA_PROVENANCE_HASH = hash;
  }

  /*
   * @dev For returning ERC20s we dont know what to do with
   *      if people have issues they can contact owner/devs
   *      and we can send back their tokens.
   */
  function forwardERC20s(IERC20 _token, uint256 _amount) external onlyOwner {
    _token.transfer(address(this), _amount);
  }

  /*
   * Recreate ERC721Pausable
   */
  function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A, ERC721APausable) virtual {
    super._beforeTokenTransfers(from, to, startTokenId, quantity);
  }

  /*
   * Rarible/Foundation Royalties Protocol
   */
  function getFeeRecipients(uint256 id) public view override returns (address payable[] memory) {
    require(_exists(id), "DNE");
    address payable[] memory result = new address payable[](1);
    result[0] = PAYMENT_SPLITTER;
    return result;
  }

  /*
   * Rarible/Foundation Royalties Protocol
   */
  function getFeeBps(uint256 id) public view override returns (uint[] memory) {
    require(_exists(id), "DNE");
    uint[] memory result = new uint[](1);
    result[0] = 1000; // 10%
    return result;
  }

  /*
   * ERC2981 Royalties Standard
   */
  function royaltyInfo(uint256 _tokenId, uint256 _value, bytes calldata _data) external view override returns (address _receiver, uint256 _royaltyAmount, bytes memory _royaltyPaymentData) {
    return (PAYMENT_SPLITTER, _value / 10, _data); // 10%
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, HasSecondarySaleFees, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function uint2str(uint256 _i) internal pure returns (string memory str) {
    if (_i == 0)
    {
      return "0";
    }
    uint256 j = _i;
    uint256 length;
    while (j != 0)
    {
      length++;
      j /= 10;
    }
    bytes memory bstr = new bytes(length);
    uint256 k = length;
    j = _i;
    while (j != 0)
    {
      bstr[--k] = bytes1(uint8(48 + j % 10));
      j /= 10;
    }
    str = string(bstr);
  }

  /*
   * Generates the hash representation of the struct Unit for EIP-718 usage
   */
  function hashUnit(Unit memory unitobj) private view returns (bytes32) {
    return keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(
            UNIT_TYPEHASH,
            keccak256(bytes(unitobj.logIn))
        ))
    ));
  }

  /*
   * EIP-718 signature check
   */
  function verify(address signer, uint8 sigV, bytes32 sigR, bytes32 sigS) private view returns (bool) {
    Unit memory msgObj = Unit({
       logIn: 'Log In To Radioactive Punks!'
    });

    return signer == ecrecover(hashUnit(msgObj), sigV, sigR, sigS);
  }
}


