// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRPF {
    event BaseTokenURIChanged(string baseTokenURI);

    event URIChanged(string contractURI, string tokenURI);
    
    event IsBurnEnabledChanged(bool newIsBurnEnabled);
    
    event priceChanged(uint256 newTokenPrice);
    
    event supplyChanged(uint256 totalSupply, uint256 maxMintLimitPerTX);
    
    event FRENSMinted(address owner, uint256 numMint, uint256 totalSupply);
    
    function setSupply(uint256 _MAX_FRENS, uint256 _MAX_MINT_PER_TX) external;
    
    function setPrice(uint256 _FREN_PRICE) external;
    
    function isPresaleEligible(uint256 _MAX_CLAIM_FRENS_ON_PRESALE, uint256 _START_PRESALE_MINT_TIMESTAMP, bytes memory _SIGNATURE) external view returns (bool);
    
    function setPresaleStatus(bool _isPreSaleActive) external;
    
    function setPublicSale(bool _isPublicSaleActive, uint256 _publicSaleStartTimestamp) external;
    
    function setMintedReservedFrens(uint256 _MINTED_RESERVED_FRENS) external;
    
    function claimReservedFrens(uint256 quantity, address addr) external;
    
    function mintPresaleFrens(uint256 quantity, uint256 _MAX_CLAIM_FRENS_ON_PRESALE, uint256 _START_PRESALE_MINT_TIMESTAMP, bytes memory _SIGNATURE) external payable;
    
    function mintFrens(uint256 quantity) external payable;
    
    function ownerClaimFrens(uint256 quantity, address addr) external;
    
    function ownerClaimFrensId(uint256[] memory id, address addr) external;
    
    function setIsBurnEnabled(bool _isBurnEnabled) external;
    
    function burn(uint256 tokenId) external;
    
    function setURI(string calldata __contractURI, string calldata __tokenURI) external;
    
    function contractURI() external view returns (string memory);
    
    function tokenURI(uint256 tokenId) external view returns (string memory);
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory );
    
    function setTreasury(address treasury) external;
    
    function withdraw() external;
    
    function ownerOf(uint256 tokenId) external view returns (address owner);
}