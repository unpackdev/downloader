// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "./ERC721.sol";
import "./NonBlockingReceiver.sol";
import "./ILayerZeroEndpoint.sol";
import "./Strings.sol"; 

contract OmniFoods is ERC721, NonblockingReceiver, ILayerZeroUserApplicationConfig {
    
    uint256 public gas = 350000;
    uint256 public nextId;
    uint256 private maxMint;
    uint8 private maxMintWallet = 2;
    
    // can be used to launch and pause the sale
    bool private publicSale = false;

    // can be used to launch and pause the presale
    bool public revealed = false;
    string private uriPrefix = '';
    string private hiddenMetadataUri;

    mapping(address => uint256) public minted;

    constructor(
        address _layerZeroEndpoint,
        string memory _hiddenMetadataUri,
        string memory _uriPrefix,
        uint256 _nextId,
        uint256 _maxMint
    ) ERC721("OmniFoods", "OFN") {
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        hiddenMetadataUri = _hiddenMetadataUri;
        uriPrefix = _uriPrefix;
        nextId = _nextId;
        maxMint = _maxMint;
    }

    // starts or pauses the public sale
    function setPublicsale(bool _value) external onlyOwner {
        publicSale = _value;
    }
 
    function mintAddr(uint256 numTokens, address _receiver) public onlyOwner {
        require(nextId + numTokens <= maxMint, "Mint exceeds supply");

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(_receiver, ++nextId);
        }
    }

    function mint(uint8 numTokens) external payable {
        require(numTokens > 0, "Number of tokens cannot be lower than, or equal to 0");
        require(msg.sender == tx.origin, "User wallet required");
        require(publicSale == true, "Sales is not started");
        require(minted[msg.sender] + numTokens <= maxMintWallet, "Limit per wallet reached");
        require(nextId + numTokens <= maxMint, "Mint exceeds supply");
            
        _safeMint(msg.sender, ++nextId);
        if(numTokens == 2) {
            _safeMint(msg.sender, ++nextId);
        }

        minted[msg.sender] += numTokens;
    }

    function traverseChains(
        uint16 _chainId,
        uint256 _tokenId
    ) public payable {
        require(msg.sender == ownerOf(_tokenId), "Message sender must own the OmniFoods.");
        require(trustedSourceLookup[_chainId].length != 0, "This chain is not a trusted source source.");

        // burn NFT on source chain
         _burn(_tokenId);

        // encode payload w/ sender address and NFT token id
        bytes memory payload = abi.encode(msg.sender, _tokenId);

        // encode adapterParams w/ extra gas for destination chain
        uint16 version = 1;
        uint gasLz = gas;
        bytes memory adapterParams = abi.encodePacked(version, gasLz);

        // use LayerZero estimateFees for cross chain delivery
        (uint quotedLayerZeroFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);

        require(msg.value >= quotedLayerZeroFee, "Not enough gas to cover cross chain transfer.");

        endpoint.send{value:msg.value}(
            _chainId,                      // destination chainId
            trustedSourceLookup[_chainId], // destination address of nft
            payload,                       // abi.encode()'ed bytes
            payable(msg.sender),           // refund address
            address(0x0),                  // future parameter
            adapterParams                  // adapterParams
        );
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = uriPrefix;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json"))
            : '';
    }

    // get fund inside contract
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }

    // just in case this fixed variable limits us from future integrations
    function setGas(uint256 newVal) external onlyOwner {
        gas = newVal;
    }

    function _LzReceive(bytes memory _payload) internal override  {
        (address dstAddress, uint256 tokenId) = abi.decode(_payload, (address, uint256));
        _safeMint(dstAddress, tokenId);
    }

    // User Application Config
    function setConfig( uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config) external override onlyOwner {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        endpoint.setReceiveVersion(_version);
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }
   
}