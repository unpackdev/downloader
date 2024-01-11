// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./ERC721.sol";
import "./NonBlockingReceiver.sol";
import "./Strings.sol"; 

import "./ILayerZeroEndpoint.sol";


/// @title A LayerZero OmnichainNonFungibleToken contract
/// @author Omniplayer Devs
/// @notice You can use this to mint ONFT and transfer across chain
/// @dev All function calls are currently implemented without side effects
contract OmniPlayer is
    ERC721,
    NonblockingReceiver,
    ILayerZeroUserApplicationConfig
{
    string public baseTokenURI;
    uint256 public gasForDestinationLzReceive = 350000;

    uint256 public nextTokenId;
    uint256 public maxMint;
    uint256 public publicSaleStartTime = 0;
    uint256 public maxMintPerWallet = 1;
    string public notRevealedURI;
    bool public revealed = false;
    mapping(address => uint256) public minted;

    /// @notice Constructor for the OmniPlayer NFT
    /// @param _baseTokenURI the Uniform Resource Identifier (URI) for tokenId token
    /// @param _notRevealedURI the not revealed URI
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _startToken the starting mint number on this chain
    /// @param _maxMint the max number of mints on this chain
    constructor(
        string memory _baseTokenURI,
        string memory _notRevealedURI,
        address _layerZeroEndpoint,
        uint256 _startToken,
        uint256 _maxMint
    ) ERC721("OmniPlayer", "OPLAYER") {
        setBaseURI(_baseTokenURI);
        notRevealedURI = _notRevealedURI;
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        nextTokenId = _startToken;
        maxMint = _maxMint;
    }

    /// Mint OmniPlayer
    function setPublicSaleStartTime(uint256 newTime) public onlyOwner {
        publicSaleStartTime = newTime;
    }

    /**
     * pre-mint for community giveaways
     */
    function devMint(uint8 numTokens,address wlAddress) public onlyOwner {
        require(nextTokenId + numTokens <= maxMint, "Mint exceeds supply");
        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(wlAddress, ++nextTokenId);
        }
    }

    // Mint is free but payment but the payment is accepted
    function mint(uint8 numTokens) external payable {
        require(msg.sender == tx.origin, "User wallet required");
        require(
            publicSaleStartTime != 0 && publicSaleStartTime <= block.timestamp,
            "sales is not started"
        );
        require(numTokens <= 1, "Max 1 NFTs per transaction");
        require(
            minted[msg.sender] + numTokens <= maxMintPerWallet,
            "limit per wallet reached"
        );
        require(nextTokenId + numTokens <= maxMint, "Mint exceeds supply");

        _safeMint(msg.sender, ++nextTokenId);
        minted[msg.sender] += numTokens;
    }

    /// @notice Burn OmniPlayer on source chain and mint on destination chain
    /// @param _chainId the destination chain id you want to transfer too
    /// @param _tokenId the id of the NFT you want to transfer
    function traverseChains(uint16 _chainId, uint256 _tokenId) public payable {
        require(
            msg.sender == ownerOf(_tokenId),
            "Message sender must own the OmniPlayer."
        );
        require(
            trustedSourceLookup[_chainId].length != 0,
            "This chain is not a trusted source source."
        );

        // burn NFT on source chain
        _burn(_tokenId);

        // encode payload w/ sender address and NFT token id
        bytes memory payload = abi.encode(msg.sender, _tokenId);

        // encode adapterParams w/ extra gas for destination chain
        uint16 version = 1;
        uint256 gas = gasForDestinationLzReceive;
        bytes memory adapterParams = abi.encodePacked(version, gas);

        // use LayerZero estimateFees for cross chain delivery
        (uint256 quotedLayerZeroFee, ) = endpoint.estimateFees(
            _chainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        require(
            msg.value >= quotedLayerZeroFee,
            "Not enough gas to cover cross chain transfer."
        );

        endpoint.send{value: msg.value}(
            _chainId, // destination chainId
            trustedSourceLookup[_chainId], // destination address of nft
            payload, // abi.encode()'ed bytes
            payable(msg.sender), // refund address
            address(0x0), // future parameter
            adapterParams // adapterParams
        );
    }

    /// @notice Set the baseTokenURI
    /// @param _baseTokenURI to set
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Get the base URI
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
    
    /// @notice Set the revealed flag
    function reveal() external onlyOwner{
        revealed = true;
    }

    // get fund inside contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    /// @notice Override the _LzReceive internal function of the NonblockingReceiver
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function _LzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (address dstAddress, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );
        _safeMint(dstAddress, tokenId);
    }
 
    // User Application Config
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        override
        onlyOwner
    {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    function tokenURI(uint _nftId) public view override(ERC721) returns (string memory) {
        require(_exists(_nftId), "This NFT doesn't exist.");
        if(revealed == false) {
            return notRevealedURI;
        }
        
        string memory currentBaseURI = _baseURI();
        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_nftId), ".json"))
            : "";
    }
}
