// SPDX-License-Identifier: MIT

// Amended by FullStackHustle
/**
$$$$$$$$\        $$\ $$\  $$$$$$\    $$\                         $$\       $$\   $$\                       $$\     $$\           
$$  _____|       $$ |$$ |$$  __$$\   $$ |                        $$ |      $$ |  $$ |                      $$ |    $$ |          
$$ |   $$\   $$\ $$ |$$ |$$ /  \__|$$$$$$\    $$$$$$\   $$$$$$$\ $$ |  $$\ $$ |  $$ |$$\   $$\  $$$$$$$\ $$$$$$\   $$ | $$$$$$\  
$$$$$\ $$ |  $$ |$$ |$$ |\$$$$$$\  \_$$  _|   \____$$\ $$  _____|$$ | $$  |$$$$$$$$ |$$ |  $$ |$$  _____|\_$$  _|  $$ |$$  __$$\ 
$$  __|$$ |  $$ |$$ |$$ | \____$$\   $$ |     $$$$$$$ |$$ /      $$$$$$  / $$  __$$ |$$ |  $$ |\$$$$$$\    $$ |    $$ |$$$$$$$$ |
$$ |   $$ |  $$ |$$ |$$ |$$\   $$ |  $$ |$$\ $$  __$$ |$$ |      $$  _$$<  $$ |  $$ |$$ |  $$ | \____$$\   $$ |$$\ $$ |$$   ____|
$$ |   \$$$$$$  |$$ |$$ |\$$$$$$  |  \$$$$  |\$$$$$$$ |\$$$$$$$\ $$ | \$$\ $$ |  $$ |\$$$$$$  |$$$$$$$  |  \$$$$  |$$ |\$$$$$$$\ 
\__|    \______/ \__|\__| \______/    \____/  \_______| \_______|\__|  \__|\__|  \__| \______/ \_______/    \____/ \__| \_______|
*/

pragma solidity >=0.8.9 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./ERC2981.sol";

contract RarePanthersThree is ERC721A, ERC2981, ReentrancyGuard, Ownable {

struct SendData {
        address receiver;
        uint256 amount;
    }

  using Strings for uint256;
  using Address for address;
  bytes32 public merkleRoot;
  mapping(address => bool) public allowlistClaimed;
  address payable public payments; 
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  
  
  
  bool public paused = true;
  bool public allowlistMintEnabled = false;
  

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    address _payments
    ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setPayments(payable(_payments));
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

  function allowlistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify allowlist requirements
    require(allowlistMintEnabled, 'The VIP Backstage Pass is not open yet'); 
    require(!allowlistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    
    allowlistClaimed[_msgSender()] = true;
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
      if (_exists(currentTokenId)) {
        TokenOwnership memory ownership = _ownerships[currentTokenId];

        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }
  
  function airdrop(SendData[] calldata sendData) external onlyOwner nonReentrant {
        uint256 ts = 480;

        // loop through all addresses
        for (uint256 index = 0; index < sendData.length; index++) {
            require(totalSupply() + sendData[index].amount <= ts, 'Exceeds original supply');
            _safeMint(sendData[index].receiver, sendData[index].amount);
        }
  }
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

   

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setPayments(address payable _payments) public onlyOwner {
    payments = _payments;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setallowlistMintEnabled(bool _state) public onlyOwner {
    allowlistMintEnabled = _state;
  }

  function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

   
  function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    
  function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    
  function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

  function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override( ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

  function withdraw() public onlyOwner nonReentrant {
    (bool success, ) = payable(payments).call{value: address(this).balance}('');
    require(success);
    
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

 
}