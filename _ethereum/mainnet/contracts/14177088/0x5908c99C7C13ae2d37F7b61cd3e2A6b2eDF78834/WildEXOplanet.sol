//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./SignatureChecker.sol";
import "./SafeMath.sol";

contract WildEXOplanet is ERC721, EIP712, Ownable{
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;
    using SafeMath for uint256;

    //Whitelist sale signer
    address WHITELIST_SIGNER = 0x093423fa2a98b1c7752a9122b7DD7426837c9ad9;

    Counters.Counter private _tokenIds;

    //baseuri for the tokens.
    string[] public tierBaseUris = [
      'ipfs://QmawPbpJZvfAkaz4G63yYdajQqfsXzctNxqfm38RKQiUHf/',
      'ipfs://QmdSqPfwrFCqi3p1yqhh5YeemHokuY4UJgaAv5oYfCWWsq/',
      'ipfs://QmVxFJFt3FK4s1UsWeL9qmJi4yQ51waTBKzEW9g4bsgxCz/',
      'ipfs://QmZPmMb84CTEY5CDnAXRNHWiy1V5xFm1XzNaaUGGkvCdvU/',
      'ipfs://QmRNBfxdPHHrL9otKsDgAWw3KrSfot2AVVChCnTJG1TjhX/'
    ];
    
    //Minting start time in uinx-epoch [phase 1 start, phase 2 start]
    uint256[] public tierStartMintTimes = [1645020000, 1647374400];
    //Minting ending time in unix-epoch [phase 1 start, phase 2 start]
    uint256[] public tierMintEndTimes = [1645106400, 1647460800];
    //Minting tier fee
    uint256[] public tierMintFees = [0.25 ether, 0.7 ether, 1.1 ether, 1.5 ether, 2.5 ether];
    //Max supply for each tier
    uint256[] public tierMaxSupply = [6907, 1498, 898, 498, 198]; 
    //Running supply for each tier
    uint256[] public tierRunningSupply = [0,0,0,0,0];

    //Tier mapping for the token
    mapping(uint256 => uint8) public tokenTier;

    //Mapping for different token id to their real token id in tier.  
    mapping(uint256 => uint256) public realTokenIds;

    //Public giveaway token baseuris
    string[] public giveawayBaseUris = [
      'ipfs://QmYoCBBQu7qwhJNw6ti9gxUhhHw2zLd9qZYELP93WKsUqL/',
      'ipfs://QmZArfk8EfP6fNtZCRV8eJiuPLHYRFf4X8SxjmZtkSEpfH/',
      'ipfs://QmPVJW9YCj9Rsv7pXquKm5HcBm2LAvcHRdWQvkyvmYroYd/',
      'ipfs://QmerqyWsXSum5kXCcReWAzRWfGHXpTuM6moQsEdK9iGmQV/'
    ];

    //Total giveaway for the each tiers
    uint8[] public totalGiveaway = [24, 24, 24, 27];
    //Total giveaway for each tiers 
    uint8[] public giveawayCompleted = [0,0,0,0];

    //Whitelist mint fee
    uint256 public whitelistMintFee = 0.2 ether;
    //Whitelist disable time
    uint256 public whitelistSaleDisableTime = 1645016400;
    uint256 public whitelistSaleStartTime = 1644930000;
    //Reveal time for Phase 1 and Phase 2 tokens
    uint256[] public revealTime = [1645110000, 1647460800];

    //Maximum supply of the NFT
    uint128 public maxSupply = 9999;
    //Counts the successful total giveaway 
    uint256 public giveawayDoneCount = 0;
    
    //claimed bitmask for whitelist sale 
    mapping(uint256 => uint256) public whitelistSaleClaimBitMask;

    //number of nft in wallet
    //tier => address => number
    mapping(uint8 => mapping(address => uint8)) public nftNumber;
    
    //Events
    event WhiteListSale(uint256 tokenId, address wallet);
    event Giveaway(uint256 tokenId, address wallet);

    constructor() 
    ERC721("Wild EXOplanet", "WEXO")
    EIP712("Wild EXOplanet", "1.0.0"){} 

   ///@notice Mint the token to the address sent
    ///@param to address to mint token  
    ///@param amount of token to mint
    ///@param tier tier of token to mint
    function mint(address to, uint8 amount, uint8 tier) public payable {
      if(tier == 0){
        require(block.timestamp <= tierMintEndTimes[0], "NFT: Phase 1 Mint Ended!");
        require(block.timestamp >= tierStartMintTimes[0], "NFT: Phase 1 Mint Not Started!");

      }
      else{
        require(block.timestamp <= tierMintEndTimes[1], "NFT: Public sale already ended!");
        require(block.timestamp >= tierStartMintTimes[1], "NFT: Public sale Not Started!");
      }
      require(tierRunningSupply[tier] < tierMaxSupply[tier], "NFT: Max Supply Of NFT reached!");
      require(nftNumber[tier][to]+amount <= 2, "NFT: NFT wallet maximum capacity exceeded!!");
      require(msg.value >= tierMintFees[tier]*amount, "NFT: Not enough Minting Fee!");
      for(uint8 i = 0; i<amount; i++){
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current().add(99);
        if(tier > 0){
          tierRunningSupply[tier] += 1;
          realTokenIds[newTokenId] = tierRunningSupply[tier];
        }
        tokenTier[newTokenId] = tier;
        _mint(to, newTokenId);
      }
      nftNumber[tier][to] += amount;
    }

    ///@notice Whitelist user claims for sales
    ///@param _signature signature signed by whitelist signer
    ///@param to account to Mint NFT 
    ///@param _nftIndex index of NFT for claim
    function claimWhitelistSale(bytes[] calldata _signature, address to, uint256[] calldata _nftIndex) external payable{
      require(block.timestamp >= whitelistSaleStartTime, "NFT: Whitelist sale not started!");
      require(block.timestamp <= whitelistSaleDisableTime, "NFT: Whitelist sale ended!");
      require(tierRunningSupply[0] < tierMaxSupply[0], "NFT: Max Supply Of NFT reached!");
      require(nftNumber[0][to] + _nftIndex.length <=2, "NFT: Max NFT already minted!");
      require(msg.value >= whitelistMintFee * _nftIndex.length, "NFT: Not enough Mint Fee!");

      for(uint256 i=0;i< _nftIndex.length; i++){
        require(!isClaimed(_nftIndex[i]), "NFT: Token already claimed!");
        require(_verify(_hash(to, _nftIndex[i]), _signature[i]), "NFT: Invalid Claiming!");
        _setClaimed(_nftIndex[i]);
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current().add(99);
        tokenTier[newTokenId] = 0;
        _mint(to, newTokenId);
        nftNumber[0][to] += 1;
        tierRunningSupply[0]+=1;
        emit WhiteListSale(newTokenId, to);
      }
    }

    ///@notice Used by the team for giveaway
    ///@param _userAddress giveaway user addresses
    ///@param _tokenTiers token tier to mint 
    function claimReserve(address[] memory _userAddress, uint8[] memory _tokenTiers) external onlyOwner{
      require(_tokenTiers.length == _userAddress.length, "NFT: Token Tiers and User Address length mismatch!");
      for(uint8 i=0; i<_tokenTiers.length; i++){
        address currentUser = _userAddress[i];
        uint8 currentTier = _tokenTiers[i];
        require(nftNumber[currentTier][currentUser]+1 <= 2, "NFT: NFT wallet maximum capacity exceeded!");
        require(giveawayCompleted[currentTier] < totalGiveaway[currentTier], "NFT: Giveaway amount exceeded!");
        giveawayCompleted[currentTier] += 1 ;
        giveawayDoneCount += 1;
        nftNumber[currentTier][currentUser] +=1 ;
        realTokenIds[giveawayDoneCount] = giveawayCompleted[currentTier];
        tokenTier[giveawayDoneCount] = currentTier;
        _mint(currentUser, giveawayDoneCount);
        emit Giveaway(giveawayDoneCount, currentUser);
      }
    }

    ///@notice Checks if the nft index is claimed or not
    ///@param _nftIndex NFT index for claiming 
    function isClaimed(uint256 _nftIndex) public view returns (bool) {
      uint256 wordIndex = _nftIndex / 256;
      uint256 bitIndex = _nftIndex % 256;
      uint256 mask = 1 << bitIndex;
      return whitelistSaleClaimBitMask[wordIndex] & mask == mask;
    }

    ///@notice Sets claimed nftIndex
    function _setClaimed(uint256 _nftIndex) internal{
      uint256 wordIndex = _nftIndex / 256;
      uint256 bitIndex = _nftIndex % 256;
      uint256 mask = 1 << bitIndex;
      whitelistSaleClaimBitMask[wordIndex] |= mask;
    }

    ///@notice hash the data for signing data
    function _hash(address _account, uint256 _nftIndex)
    internal view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFT(address _account,uint256 _nftIndex)"),
            _account,
            _nftIndex
        )));
    }

    ///@notice verifies data for signature
    function _verify(bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {   
      return SignatureChecker.isValidSignatureNow(WHITELIST_SIGNER, digest, signature);
    }
    
    ///@notice Return Base Uri for the token 
    function _baseURI() internal view virtual override returns (string memory) {
      return tierBaseUris[0];
    }

    ///@notice Return base uri for token
    ///@param _tokenId token id to return the metadata uri
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId), "NFT: URI query for nonexistent token");
      string memory uri;
      uint8 tier = tokenTier[_tokenId];
      uint256 realTokenId = realTokenIds[_tokenId];
      if(_tokenId <= 99){
        //giveaway
        uri = bytes(giveawayBaseUris[tier]).length > 0 ? string(abi.encodePacked(giveawayBaseUris[tier], realTokenId.toString(), ".json")) : "";
      }
      else{
        //non give away
        if(tier > 0){
          if(block.timestamp >= revealTime[1] )
            uri = bytes(tierBaseUris[tier]).length > 0 ? string(abi.encodePacked(tierBaseUris[tier], realTokenId.toString(), ".json")) : "";
          else 
            uri = 'ipfs://QmdF2XaRXKSaFg1kcoQW566zMN1d8pba8VUb9wwxnsS8yt/';
        }
        else{
          if(block.timestamp >= revealTime[0])
            uri = bytes(tierBaseUris[0]).length > 0 ? string(abi.encodePacked(tierBaseUris[0], realTokenId.toString(), ".json")) : "";
          else
            uri = 'ipfs://QmdF2XaRXKSaFg1kcoQW566zMN1d8pba8VUb9wwxnsS8yt/';
        }
      }
      return uri;
    }

    ///@notice Total supply of the token
    function totalSupply() public view virtual returns (uint256) {
        return maxSupply;
    }

    ///@notice Update Tier Mint Fee by Owner
    ///@param _updateFees updated fee for the different Tier
    function updatesTierMintFees(uint256[] memory _updateFees) external onlyOwner{
        tierMintFees = _updateFees;
    }

    ///@notice Update Whitelist Sale mint fee
    ///@param _whitelistMintFee updated whitelist mint fee
    function updateWhiteListMintFee(uint256 _whitelistMintFee) external onlyOwner{
      whitelistMintFee = _whitelistMintFee;
    }

    ///@notice Update Pase Minting start time
    ///@param _tierMintTimes updated Phase Minting start time 
    function updateTierMintStartTimes(uint256[] memory _tierMintTimes) external onlyOwner{
      tierStartMintTimes = _tierMintTimes;
    }

    ///@notice Update Phase Minting end time
    ///@param _tierMintTimes updated Phase Minting end time
    function updateTierMintEndTimes(uint256[] memory _tierMintTimes) external onlyOwner{
      tierMintEndTimes = _tierMintTimes;
    }

    ///@notice Update Whitelist Sale disable time
    ///@param _disableTime Updated whitelist sale disable time
    function updateWhiteListDisableTime(uint256 _disableTime) external onlyOwner{
      whitelistSaleDisableTime = _disableTime;
    }

    ///@notice Update Reveal Time for phases
    ///@param _revealTimes updated reveal time for the 
    function updateRevealTime(uint256[] memory _revealTimes) external onlyOwner{
      revealTime = _revealTimes;
    }

    ///@notice Withdraw Eth by the owner
    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }


}