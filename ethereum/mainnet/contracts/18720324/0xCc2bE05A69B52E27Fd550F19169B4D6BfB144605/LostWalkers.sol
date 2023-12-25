// SPDX-License-Identifier: UNLICENSED
/* @dev: Walker Labs */
pragma solidity ^0.8.19;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract LostWalkers is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint;
  using ECDSA for bytes32;

  /* @notice Variables */
  string public baseUri;
  uint256 public immutable maxSupply = 3455;
  mapping(bytes => bool) public usedSignatures;
  address public signer = address(0);
  State public state;

  /* @notice Events */
  event Minted(address indexed _address, uint indexed _amount);
  event BaseURIUpdated();
  event StateUpdated();
  event SignerUpdated();

  /* @notice Errors */
  error MaxSupplyReached();
  error NotEqual();
  error SignatureUsed();
  error InvalidSignature();
  error NotOpen();
  error NotMeantForYou();
  error NotAllowed();
  error TooMany();

  enum State {
    Stopped,
    Started
  }

  constructor(address _signer) ERC721A("Walker World: Lost Walkers", "Lost Walkers") {
    signer = _signer;
  }

  /* @notice: Claim a Lost Walker */
  function claimMint(bytes[] calldata _proofs, bytes[] calldata _encodeds) external nonReentrant {
    if (state != State.Started) revert NotOpen();
    if (_proofs.length != _encodeds.length) revert NotEqual();
    uint _amount = _proofs.length;
    if (totalSupply() + _amount > maxSupply) revert MaxSupplyReached();
    if (_amount > 10) revert TooMany();
    for (uint i = 0; i < _proofs.length; i++) {
      bytes calldata proof = _proofs[i];
      if (usedSignatures[proof] == true) revert SignatureUsed();
      if (!_verify(_encodeds[i], proof)) revert InvalidSignature();
      address to = abi.decode(_encodeds[i], (address));
      if (to != msg.sender) revert NotMeantForYou();
      usedSignatures[proof] = true;
    }

    _mint(msg.sender, _amount);

    emit Minted({_address: msg.sender, _amount: _amount});
  }

  /* @notice Allows dev to premint */
  function devMint(address _to) external onlyOwner {
    if (totalSupply() > 150) revert NotAllowed();
    _mint(_to, 10);
    _mint(_to, 10);
    _mint(_to, 10);
    _mint(_to, 10);
    _mint(_to, 10);
  }

  /* @notice: Allows admin to pause and unpause minting */
  function setState(State _state) external onlyOwner {
    state = _state;
    emit StateUpdated();
  }

  /* @notice Allows signer to be updated */
  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
    emit SignerUpdated();
  }

  /* @notice Allows admin to update the base uri */
  function updateBaseURI(string memory _baseUri) external onlyOwner {
    baseUri = _baseUri;
    emit BaseURIUpdated();
  }

  /* @notice: Returns the tokenUri for each token */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseUri, tokenId.toString()));
  }

  /* @notice: Verify ECDSA signatures */
  function _verify(bytes memory message, bytes calldata signature) internal view returns (bool) {
    bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
    address recoveredAddress = ECDSA.recover(messageHash, signature);
    return recoveredAddress == signer;
  }

  /* @notice: Project should start from tokenId 1 */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}
