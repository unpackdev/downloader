// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";


contract Besthash is ERC721A, Ownable {
  using Address for address;
  using Strings for uint256;

  bytes32 public root;
  bytes32[] public merkleProof;

  mapping(address => bool) public whitelistClaimed;

  string private baseURI; //URL do json: 
  string private baseExtension = ".json";
  string private notRevealedUri = "https://gateway.pinata.cloud/ipfs/QmdCvKZje4ASsqwnHkekthf69CgXks9g8MLfRubLcSe2kJ/1.json";
  uint256 private maxSupply = 10000;
  uint256 private maxMintAmount = 5;
  uint256 private FreeMintPerAddressLimit = 1;
  bool private paused = true;
  bool private onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) private addressMintedBalance;
  mapping(uint256 => uint) private _availableTokens;
  uint256 private _numAvailableTokens;

  string private _contractUri;

  address _contractOwner;

  mapping (address => bool) private _affiliates;
  bool private _allowAffiliateProgram = true;
  uint private _affiliateProgramPercentage = 5;

  bool private _allowRecommendation = true;
  uint256 private _recommendationPercentage = 5;
  uint256 private _royalties = 5;
  uint256 royaltiesSpender;

  mapping(address => uint256) private _addressLastMintedTokenId;

  bool private _isFreeMint = false;
  uint256 private _nftEtherValue = 100000000000000;

  event _transferSend(address _from, address _to, uint _amount);

  constructor(
    string memory _initBaseURI,
    bytes32 _root,
    string memory _contractURI
  ) ERC721A("Best Hash", "BHash") {
    setBaseURI(_initBaseURI);
    root = _root;
    _contractUri = _contractURI;
    _contractOwner = msg.sender;
  }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
      return MerkleProof.verify(proof, root, leaf);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
      baseURI = _newBaseURI;
    }

    function setFreeMintPerAddressLimit(uint256 _limit) public onlyOwner {
      FreeMintPerAddressLimit = _limit;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
      onlyWhitelisted = _state;
    }

    function isOnlyWhitelist() public view returns (bool) {
      return onlyWhitelisted;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
      maxMintAmount = _maxMintAmount;
    }

    function pause(bool _state) public onlyOwner {
      paused = _state;
    }

    function setAllowAffiliateProgram(bool _state) public onlyOwner {
      _allowAffiliateProgram = _state;
    }

    function setAffiliateProgramPercentage(uint256 percentage) public onlyOwner {
      _affiliateProgramPercentage = percentage;
    }

    function withdraw() public payable onlyOwner {
      (bool os, ) = payable(owner()).call{value: address(this).balance}("");
      require(os);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
      maxSupply = _maxSupply;
    }

    function setNftEtherValue(uint256 nftEtherValue) public onlyOwner {
      _nftEtherValue = nftEtherValue;
    }

    function setAffiliate(address manager, bool state) public onlyOwner {
      _affiliates[manager] = state;
    }

    function setIsFreeMint(bool state) public onlyOwner {
        _isFreeMint = state;
    }

    function getQtdAvailableTokens() public view returns (uint256) {
      if(_numAvailableTokens > 0){
        return _numAvailableTokens;
      }
      return maxSupply;
    }

    function getMaxSupply() public view returns (uint) {
      return maxSupply;
    }

    function getNftEtherValue() public view returns (uint) {
      return _nftEtherValue;
    }

    function getAddressLastMintedTokenId(address wallet) public view returns (uint256) {
      return _addressLastMintedTokenId[wallet];
    }

    function getMaxMintAmount() public view returns (uint256) {
      return maxMintAmount;
    }

    function getBalance() public view returns (uint) {
     return msg.sender.balance;
    }

    function getBaseURI() public view returns (string memory) {
      return baseURI;
    }

    function getNFTURI(uint256 tokenId) public view returns(string memory){
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId), baseExtension));
    }

    function isAffliliated(address wallet) public view returns (bool) {
     return _affiliates[wallet];
    }

    function contractIsFreeMint() public view returns (bool) {
     return _isFreeMint;
    }

    function isPaused() public view returns (bool) {
      return paused;
    }

    function isWhitelisted(address _user, bytes32[] memory proof) public view returns (bool) {
      if( isValid( proof, keccak256( abi.encodePacked(_user) ) ) ) {
        if (whitelistClaimed[_user]) {
          return false;
        }
        return true;
      } else {
        return false;
      }
    }

  
    function mintWhitelist(
      uint256 _mintAmount,
      address payable _recommendedBy,
      uint256 _indicationType, //1=directlink, 2=affiliate, 3=recomendation
      address payable endUser,
      bytes32[] memory proof
    ) public payable {
      require(!paused, "O contrato esta pausado");
      uint256 supply = totalSupply();
      require(_mintAmount > 0, "Precisa mintar pelo menos 1 NFT");
      require(_mintAmount + balanceOf(endUser) <= maxMintAmount, "Quantidade limite de mint por carteira excedida");
      require(supply + _mintAmount <= maxSupply, "Quantidade limite de NFT excedida");

      if(onlyWhitelisted) {
        require(!whitelistClaimed[endUser], "Address ja reivindicou");
        require(isValid(proof, keccak256(abi.encodePacked(endUser))), "Nao faz parte da Whitelist");
      }

      if(_indicationType == 2) {
        require(_allowAffiliateProgram, "No momento o programa de afiliados se encontra inativo");
      }

      if(!_isFreeMint ) {
        if(!isValid(proof, keccak256(abi.encodePacked(endUser)))) {
          split(_mintAmount, _recommendedBy, _indicationType);
        } else {
          uint tokensIds = walletOfOwner(endUser);
          if(tokensIds > 0){
            split(_mintAmount, _recommendedBy, _indicationType);
          }
        }
      }

      uint256 updatedNumAvailableTokens = maxSupply - totalSupply();
      
      for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[endUser]++;
        _safeMint(endUser, 1);
        uint256 newIdToken = supply + 1;
        tokenURI(newIdToken);
        --updatedNumAvailableTokens;
        _addressLastMintedTokenId[endUser] = i;
      }

      if (onlyWhitelisted) {
        whitelistClaimed[endUser] = true;
      }
      _numAvailableTokens = updatedNumAvailableTokens;
    }

    function mint(
      uint256 _mintAmount,
      address payable _recommendedBy,
      uint256 _indicationType, //1=directlink, 2=affiliate, 3=recomendation
      address payable endUser
    ) public payable {
      require(!paused, "O contrato pausado");
      uint256 supply = totalSupply();
      require(_mintAmount > 0, "Precisa mintar pelo menos 1 NFT");
      require(_mintAmount + balanceOf(endUser) <= maxMintAmount, "Quantidade limite de mint por carteira excedida");
      require(supply + _mintAmount <= maxSupply, "Quantidade limite de NFT excedida");

      if(onlyWhitelisted) {
        require(!whitelistClaimed[endUser], "Address ja reivindicou");
      }

      if(_indicationType == 2) {
        require(_allowAffiliateProgram, "No momento o programa de afiliados se encontra inativo");
      }

      split(_mintAmount, _recommendedBy, _indicationType);

      uint256 updatedNumAvailableTokens = maxSupply - totalSupply();
      
      for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[endUser]++;
        _safeMint(endUser, 1);
        uint256 newIdToken = supply + 1;
        tokenURI(newIdToken);
        --updatedNumAvailableTokens;
        _addressLastMintedTokenId[endUser] = i;
      }

      if (onlyWhitelisted) {
        whitelistClaimed[endUser] = true;
      }
      _numAvailableTokens = updatedNumAvailableTokens;
    }

    function contractURI() external view returns (string memory) {
      return _contractUri;
    }
  
    function setContractURI(string memory contractURI_) external onlyOwner {
      _contractUri = contractURI_;
    }

    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      returns (string memory)
    {
      require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );

      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
          ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
          : "";
    }

    function walletOfOwner(address _owner)
      public
      view
      returns (uint)
    {
      return addressMintedBalance[_owner];
    }

    function split(uint256 _mintAmount, address payable _recommendedBy, uint256 _indicationType ) public payable{
      require(msg.value >= (_nftEtherValue * _mintAmount), "Valor da mintagem diferente do valor definido no contrato");

      uint ownerAmount = msg.value;

      if(_indicationType > 1){

        uint256 _splitPercentage = _recommendationPercentage;
        if(_indicationType == 2 && _allowAffiliateProgram){
            if( _affiliates[_recommendedBy] ){
              _splitPercentage = _affiliateProgramPercentage;
            }
        }

        uint256 amount = msg.value * _splitPercentage / 100;
        ownerAmount = msg.value - amount;

        emit _transferSend(msg.sender, _recommendedBy, amount);
        _recommendedBy.transfer(amount);
      }
      payable(_contractOwner).transfer(ownerAmount);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
      _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
      address from,
      address to,
      uint256 tokenId,
      bytes memory _data
    ) public virtual override {
      _transfer(from, to, tokenId);
      if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
          revert TransferToNonERC721ReceiverImplementer();
      }
      emit Transfer(from, to, tokenId);
    }
}