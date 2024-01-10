// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity ^0.8.0;

/**
    Main chain contract: where all the purchases will happen, regardless of
    minting chain
 */

import "./NFTFactory.sol";
import "./ILayerZeroReceiver.sol";
import "./ILayerZeroEndpoint.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC721Receiver.sol";
import "./SafeMath.sol";

/// @title Marketplace escrow contract for fixed price sales
contract NFTMarketplaceMain is IERC721Receiver, Ownable, ILayerZeroReceiver {
    using SafeMath for uint256;
    NFTFactory private nft;
    IERC20 public token;   // Currency

    address public nftFactoryAddress;
    address payable public mktWallet;
    // Price
    uint256 public price;
    // Time
    uint startTime;
    uint endTime;
    // Struct to pass to other chain
    struct payload {
        uint tokenId;
        address owner;
        bool mint;
    }
    // Map for token ID ownership
    mapping(uint => address) public tokenMap;
    // Child chain information
    uint16 public childChainId;
    bytes public childChainAddress;

    ILayerZeroEndpoint public endpoint; 

    event NFTSold(uint256 indexed tokenId, address indexed newOwner);

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4)
    {
        return this.onERC721Received.selector;
    }

    /// @notice Constructor
    /// @param _nftAddress NFT factory address
    /// @param _tokenAddress Payment token address
    /// @param _price NFT price
    /// @param _mktWallet Marketplace wallet address where all sales go
    /// @param _startTime Sale start time
    /// @param _endTime Sale end time
    /// @param _endpoint endpoint address
    constructor(
        address _nftAddress,
        address _tokenAddress,
        uint256 _price,
        address payable _mktWallet,
        uint _startTime,
        uint _endTime,
        address _endpoint
    ) {
        nftFactoryAddress = _nftAddress;
        nft = NFTFactory(nftFactoryAddress);
        token = IERC20(_tokenAddress);
        mktWallet = _mktWallet;
        price = _price;
        startTime = _startTime;
        endTime = _endTime;
        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    /// @notice Buy NFT
    /// @param _tokenId Token ID
    /// @param _mintOnMain Mint here or child
    function buy(uint _tokenId, bool _mintOnMain) public payable {
        // Time constraints
        require(block.timestamp > startTime, "Sale has not started yet");
        require(block.timestamp < endTime, "Sale has ended");
        require(
            tokenMap[_tokenId] == address(0x0000000000000000000000000000000000000000),
            "Token ID already sold"
        );
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= price, "Check the token allowance");
        payload memory _payload; 
        if (_mintOnMain) {
            // Main
            _payload = payload(_tokenId, msg.sender, false);
        } else {
            // Mumbai
            _payload = payload(_tokenId, msg.sender, true);
        }
        bytes memory _payloadBytes = abi.encode(_payload);

        // Collect tokens on Main
        token.transferFrom(msg.sender, address(this), price);

        // Mint/lock NFT
        if (_mintOnMain) {
            // mint here
            nft.safeMint(msg.sender, _tokenId);
        } else {
            // Mint in mumbai - lock!
            tokenMap[_tokenId] = msg.sender;
        }

        // notify child chain
        endpoint.send{value:msg.value}(
            childChainId, 
            childChainAddress,
            _payloadBytes,
            payable(msg.sender),
            address(0x0),
            bytes("")
        );

        emit NFTSold(_tokenId, msg.sender);
    }

    // function bridge ()


    function claim() public onlyOwner {
        token.transferFrom(address(this), msg.sender, token.balanceOf(address(this)));
    }

    function setChildChain(bytes memory _address, uint16 _childChainId) public onlyOwner {
        childChainAddress = _address;
        childChainId = _childChainId;
    }


    function lzReceive(uint16 , bytes memory _srcCounterMockAddress, uint64 _nonce, bytes memory _payload) override external {
        require(msg.sender == address(endpoint));
        // Receive and mint or transfer
        payload memory _inPayload = abi.decode(_payload, (payload));
        if (_inPayload.mint) {  // this will be always true, since it comes from child
            // Mint
            // TODO: validate if already minted, just transfer back
            nft.safeMint(_inPayload.owner, _inPayload.tokenId);
        }
    }

}
