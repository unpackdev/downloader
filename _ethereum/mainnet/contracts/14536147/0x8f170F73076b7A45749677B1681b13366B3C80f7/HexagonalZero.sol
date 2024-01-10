// SPDX-License-Identifier: MIT

// Original Author: @marco_lipparini & @hashlipsnft
// Royalty logic learned from: https://ethereum-blockchain-developer.com/ & https://www.youtube.com/watch?v=LHZC9wX3r0I
// Modified and further developed by: @calculatingzero for @zero_beings
// Public Good: hopenlc.org

//////////////////////////////////////////////////////////////////////////////////////
    //                              ,«≤φφ░░φ░░░░░░░░░φφ≥≡,
    //                        ,≤φ▒░░▄▄▓▓███████████████▓▄▄░░φφ≥,
    //                    ,φ▒░▄▄██████████████████████████████▄▄░φφ,
    //                 «φ░Q▄██████████████████████████████████████▓▄░░≥
    //              ,φ░▄▓█████████████████████████████████████████████▄░φ,
    //            «φ░▄██████████████████████████████████████████████████▓░░≥
    //          «░░▓██████████████████████████████████████████████████████▓▒░≥
    //        ,φ░▄██████████████████████████████████████████████████████████▓░░,
    //       φ░▄██████████████████████████████████████████████████████████████▄░φ
    //      φ░▄█████████████████████████████████████████████████████████████████░φ
    //    _φ░▓████████████████████████▀╠▄▓▓▓▓▓▓▓▓▓▓▓▓▄▄╙█████████████████████████░░
    //    φ░▓███████████████████████▒▄████████▀▀████████▌╙████████████████████████░░
    //   φ░▓███████████████████████│▓██████▀▄▓███▄╙███████░████████████████████████░░
    //  «░▐███████████████████████▌░██████▌]██████░╟██████▒╟███████████████████████▌░≥
    //  ░░████████████████████████▌░██████▌▐█████░▓███████▒╟████████████████████████░░
    // :░]████████████████████████▌░██████▌▐████░█████████▒╟████████████████████████▌░≥
    // φ░╫████████████████████████▌░██████▌▐██▀╓██▀▐██████▒╟████████████████████████▌░░
    // ░░╫████████████████████████▌░██████▌▐█▀▄██▒░▐██████▒╟█████████████████████████░░
    // ░░█████████████████████████▌░██████▌░│▓██│▓▌▐██████▒╟█████████████████████████░░
    // φ░╫████████████████████████▌░██████▌░███░██▌▐██████▒╟█████████████████████████░░
    // «░╟████████████████████████▌░██████▌██▌½███▌▐██████▒╟████████████████████████▌░Γ
    // _░░████████████████████████▌░████████▀▄████▌▐██████▒╟████████████████████████░░
    //  ╙░╟███████████████████████▌░███████▒▄█████▌▐██████▒╟████████████████████████░░
    //  _░░████████████████████████░███████░██████░███████░╫███████████████████████│░
    //   `░╙███████████████████████▌╙███████▓▄╠╠▄▓███████▒▄███████████████████████▒░Γ
    //    "░╙████████████████████████▄╙▀██████████████▀╙▄████████████████████████▀░Γ
    //     "░│██████████████████████████▓▄▄▄▄▄▄▄▄▄▄▄▄▓██████████████████████████▒░Γ
    //      `░░▀███████████████████████████████████████████████████████████████│░`
    //       _7░╙████████████████████████████████████████████████████████████▀░╚
    //         `φ░╙████████████████████████████████████████████████████████▀│░`
    //           `φ░╙████████████████████████████████████████████████████▀│░"
    //             `╙░╙▀███████████████████████████████████████████████╙░╚`
    //                "φ░╙▀████████████████████████████████████████▀▀│░"
    //                  _"╙░│╙▀█████████████████████████████████▀│░╚"
    //                      _"=░│╙╙▀██████████████████████▀▀││░╙"
    //                           _"ⁿ=φ░░││╙╙╙╙╙╙╙╙╙╙││░░≥╙ⁿ"
////////////////////////////////////////////////////////////////////////////////////



pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

import "./RoyaltiesV2Impl.sol";
import "./IERC2981.sol";
import "./LibPart.sol";
import "./LibRoyalties2981.sol";
import "./RoyaltiesV2.sol";


contract HexagonalZero is ERC721A, Ownable, ReentrancyGuard, RoyaltiesV2Impl {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }
 
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

////////////////////////////////////////////////////////////////////////////////////
//
//  Royalties
//  https://github.com/rarible/protocol-contracts/tree/master/royalties/contracts
//
////////////////////////////////////////////////////////////////////////////////////

function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
        
    }

function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        if(interfaceId == LibRoyalties2981._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

////////////////////////////////////////////////////////////////////////////////////
//
//  Withdraw from Contract
//
////////////////////////////////////////////////////////////////////////////////////

  function withdraw() public onlyOwner nonReentrant {
    // This will pay HashLips Lab Team 5% of the initial sale.
    // =============================================================================
    (bool hs, ) = payable(0x146FB9c3b2C13BA88c6945A759EbFa95127486F4).call{value: address(this).balance * 5 / 100}('');
    require(hs);
    // =============================================================================

    // This will send 20% of initial sales to the designated Hope NLC address.
 // =============================================================================
    (bool hnlc, ) = payable(0x668969dDE924E22eF18712c662DF168FC0e0e50c).call{value: address(this).balance * 20 / 100}('');
    require(hnlc);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

////////////////////////////////////////////////////////////////////////////////////

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}
