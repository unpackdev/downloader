//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";

contract BigFatCats is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256   public constant _maxSupply        = 7777;
    uint256   public constant _maxMintCount     = 10;
    uint256   public constant _maxPresaleCount  = 3;
    uint256   public _maxCollabSupply           = 4500;
    uint256   public _collabMintCount           = 0;
    uint256   public _collabAddrCount           = 0;
    uint256   public _plusMintTokenLimit        = 0;
    uint256   public _mintPrice                 = 0.077 ether;           //77000000000000000 wei
    bool      public _publicSaleIsActive        = false;
    bool      public _presaleIsActive           = false;
    bool      public _plusMintIsActive          = false;

    address   private _signer               = address(0);
    address   private _multiSig1            = address(0);
    address   private _multiSig2            = address(0);
    string    private _tokenPreRevealURI    = '';
    string    private _tokenRevealBaseURI = '';

    mapping(address => uint) public _presaleMintCount;
    mapping(uint16 => bool) public _isTokenClaimed;
    mapping(address => bool) public _isCollab;
    mapping(uint256 => address) public _collabAddr;

    constructor(address signer, address multiSig1, address multiSig2) ERC721A("BigFatCats NFT", "BFC") {
      _signer = signer;
      _multiSig1 = multiSig1;
      _multiSig2 = multiSig2;
    }

    function startPresale(bool state) external onlyOwner {
      _presaleIsActive = state;
    }

    function MintBFC (uint256 mintCount) internal {
      require(mintCount > 0, "count<=zero");
      require(totalSupply() + mintCount < _maxSupply, "Max Out");

      _safeMint(msg.sender, mintCount);
    }

    function split(uint256 multiplier) internal {
      bool sent;
      uint share1 = 0.03 ether;
      share1 = share1 * multiplier;
      ( sent, ) = payable(_multiSig1).call{value: share1}("");
      require(sent, "Failed share1");

      uint share2 = msg.value - share1;
      delete share1;
      ( sent, ) = payable(_multiSig2).call{value: share2}("");
      require(sent, "Failed share2");
      delete sent;
      delete share2;
    }

    function presaleMint(uint256 tokenCount, bytes memory signature) public payable {
      require(!(_publicSaleIsActive), "Public Sale active");
      require(_presaleIsActive, "Presale not active");
      require(verify(msg.sender, signature), "Not on Presale");
      require(_mintPrice * tokenCount <= msg.value, "Incorrect Eth");

      _presaleMintCount[msg.sender] += tokenCount;
      require(_presaleMintCount[msg.sender] <= _maxPresaleCount, "Exceeds max allowed");

      MintBFC(tokenCount);
      split(tokenCount);
    }

    function addCollab(address collab) external onlyOwner {
      _isCollab[collab] = true;
      _collabAddrCount += 1;
      _collabAddr[_collabAddrCount] = collab;
    }

    function collabMint(uint256 tokenCount, address collab) public payable {
      require(!(_publicSaleIsActive), "Public Sale active");
      require(_presaleIsActive, "Presale not active");
      require(_isCollab[collab],"Invalid Collab");
      _collabMintCount += tokenCount;
      require(_collabMintCount < _maxCollabSupply,"Max Quota Reached");
      IERC721 _collab = IERC721(collab);
      require((_collab.balanceOf(msg.sender) > 0), "Not collab holder");
      require(_mintPrice * tokenCount <= msg.value, "Incorrect Eth");

      _presaleMintCount[msg.sender] += tokenCount;
      require(_presaleMintCount[msg.sender] <= _maxPresaleCount, "Exceeds max allowed");

      MintBFC(tokenCount);
      split(tokenCount);
    }

    function startPublicSale(bool state) external onlyOwner {
      _publicSaleIsActive = state;
    }

    function publicMint(uint256 tokenCount) public payable {
      require(_publicSaleIsActive, "Public Sale not active");
      require(!(_presaleIsActive), "Presale is active");
      require(tokenCount <= _maxMintCount, "Only 10 per TX");
      require(_mintPrice * tokenCount == msg.value, "Incorrect Eth");

      MintBFC(tokenCount);
      split(tokenCount);
    }

    function reserveMint(uint256 tokenCount) external onlyOwner {
        MintBFC(tokenCount);
    }

    function verify(address signedAddr, bytes memory signature) internal  view returns (bool) {
      require(signedAddr != address(0), "INVALID_SIGNER");
      bytes32 hash = keccak256(abi.encode(signedAddr));
      require (signature.length == 65,"Invalid signature length");
      bytes32 sigR;
      bytes32 sigS;
      uint8   sigV;
      // ecrecover takes the signature parameters, and the only way to get them
      // currently is to use assembly.
      assembly {
          sigR := mload(add(signature, 0x20))
          sigS := mload(add(signature, 0x40))
          sigV := byte(0, mload(add(signature, 0x60)))
      }

      bytes32 data =  keccak256(
          abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
      );
      delete hash;

      address recovered = ecrecover(
              data,
              sigV,
              sigR,
              sigS
          );

      delete data;
      delete sigR;
      delete sigS;
      delete sigV;

      return _signer == recovered;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
      _mintPrice = newPrice;
    }

    function setCollabSupply(uint256 supply) external onlyOwner {
      _maxCollabSupply = supply;
    }

    function setCollabState(address collab, bool state) external onlyOwner {
      _isCollab[collab] = state;
    }

    function withdraw(uint256 amt) public payable onlyOwner {
      require(amt <= address(this).balance, "Amount > Balance");
      payable(msg.sender).transfer(amt);
    }

    function setPreRevealURI(string calldata URI) external onlyOwner {
      _tokenPreRevealURI = URI;
    }

    function setRevealBaseURI(string calldata URI) external onlyOwner {
      _tokenRevealBaseURI = URI;
    }

    function OGmint(address og, uint256 mintCount) public onlyOwner {
      require(totalSupply() + mintCount < _maxSupply, "Max Out");

      _safeMint(og, mintCount);
    }

    function giveaway(address winner, uint256 mintCount) public onlyOwner {
      require(totalSupply() + mintCount < _maxSupply, "Max Out");

      _safeMint(winner, mintCount);
    }

    function startPlusMint(bool state) external onlyOwner {
      _plusMintIsActive = state;
      _plusMintTokenLimit = totalSupply();

    }

    function plusMint(uint16[] calldata tokenNum) public nonReentrant {
      require(_plusMintIsActive, "Plus mint not Active");
      for(uint i = 0; i < tokenNum.length; i++) {
        require(tokenNum[i]<_plusMintTokenLimit,"Invalid");
        require(msg.sender == ownerOf(tokenNum[i]),"Not Token Owner");
        require(!(_isTokenClaimed[tokenNum[i]]), "Already claimed");
        _isTokenClaimed[tokenNum[i]] = true;
      }

      MintBFC(tokenNum.length);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        string memory baseURI = _tokenRevealBaseURI;
        return bytes(baseURI).length > 0 ?
        string(abi.encodePacked(baseURI, tokenId.toString())) :
        _tokenPreRevealURI;
    }

    // --- recovery of tokens sent to this address

    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}
