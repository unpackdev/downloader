// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./SignatureChecker.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

contract CREWCoin is Initializable, UUPSUpgradeable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    address payable public qtWallet;
    address _signer;
    
    uint256 public minted;
    
    string public baseURI;
    string _name;
    string _symbol;

    mapping(bytes32 => uint) public skuHash;

    function initialize(string memory _uri, address payable _qtWallet, address __signer) initializer public {
      __ERC721_init('CREW Coin', 'CREW');
      __Ownable_init();
      __UUPSUpgradeable_init();
      qtWallet = _qtWallet;  
      _signer = __signer;
      baseURI = _uri;
      _symbol = 'CREW';
      _name = 'CREW Coin';
      minted = 13; // match with the current variable minted at address 0x46A9E5b490175724699D09F0F6104c95DEfd447a
      // transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
    }

    function _authorizeUpgrade(address newImplementation)
      internal
      onlyOwner
      override
    {}
    receive() payable external {}
    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function setSigner(address __signer) external onlyOwner {
        _signer = __signer;
    }

    function mint(bytes32 sku, uint timestamp, bytes memory signature, address to) external virtual {
        require(recover(sku, timestamp, signature, to), "Signature Verifier: Invalid sigature"); 
        require(skuHash[sku] == 0, "Doji already used");
        require(_msgSender() == to, "Only rank 9 owner can mint the token");
        require(timestamp >= block.timestamp, "SignatureVerifier: Signature expired");
        skuHash[sku] = minted;
        _safeMint(to, minted);
        ++minted;
    }

    function setMinted(uint _startTokenId) external onlyOwner virtual {
      minted = _startTokenId;
    }

    function walletDistro() external {
        AddressUpgradeable.sendValue(qtWallet, address(this).balance);
    }

    function changeWallets(address payable _qtWallet) external onlyOwner {
        qtWallet = _qtWallet;
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);
      uint256[] memory tokensId = new uint256[](tokenCount);
      for (uint256 i = 0; i < tokenCount; i++) {
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokensId;
    }

    function burn(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

  function _getMessageHash(bytes32 sku, uint timestamp, address to) internal view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _getMessage(sku, timestamp, to))); 
  }

  function _getMessage(bytes32 sku, uint timestamp, address to) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(sku, _msgSender(),timestamp, to)); 
  }

  function recover(bytes32 sku, uint timestamp, bytes memory signature, address to) public view returns(bool) {
    bytes32 hash = _getMessageHash(sku, timestamp, to);
    return SignatureChecker.isValidSignatureNow(_signer, hash, signature);
  }
}