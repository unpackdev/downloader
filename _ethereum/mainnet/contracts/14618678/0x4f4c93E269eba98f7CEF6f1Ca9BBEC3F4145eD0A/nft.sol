// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./NonblockingReceiver.sol";

// An improved TinyDinos by WhiteSatin
contract Omnimals is ERC721, NonblockingReceiver {

    string public baseURI;
    uint256 public nextTokenId;
    uint256 public maxChainSupply;
    uint256 public gasForDestinationLzReceive = 350000;
    bool public mintEnabled = false;

    uint256 private chainSupply = 2000;

    constructor(uint256 _startingTokenID, string memory baseURI_, address _layerZeroEndpoint)
        ERC721("Omnimals", "OMLS")
    {
        nextTokenId = _startingTokenID;
        maxChainSupply = _startingTokenID + chainSupply;
        baseURI = baseURI_;
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
    }

    /**
     * @dev Toggle mint enablement 
     */
    function toggleMintEnabled() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    /**
     * @dev Mint function, free for cheap bastards, but it accepts donations 
     */
    function mint(uint8 _amount) external payable {
        require(mintEnabled, "Mint is disabled");
        require(_amount < 3, "You can only mint 2 per tx greedy bastard");
        require(balanceOf(msg.sender) + _amount <= 4, "You can only mint 4 per account greedy bastard");
        require (nextTokenId + _amount <= maxChainSupply, "You are late as fuck");

        _safeMint(msg.sender, ++nextTokenId);
        if (_amount == 2) {
            _safeMint(msg.sender, ++nextTokenId);
        }
    }

    /**
     * @dev Transfer the NFT from your address on the source chain, to the same
     * address on the destination chain 
     */
    function traverseChains(uint16 _chainId, uint256 tokenId) external payable {
        require(
            msg.sender == ownerOf(tokenId),
            "You must own the token to traverse"
        );
        require(
            trustedRemoteLookup[_chainId].length > 0,
            "This chain is currently unavailable for travel"
        );

        // burn NFT, eliminating it from circulation on src chain
        _burn(tokenId);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint256 messageFee, ) = endpoint.estimateFees(
            _chainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        require(
            msg.value >= messageFee,
            "Not enough value to cover messageFee. Send more value for traverse fees"
        );

        endpoint.send{value: msg.value}(
            _chainId, // destination chainId
            trustedRemoteLookup[_chainId], // destination address of nft contract
            payload, // abi.encoded()'ed bytes
            payable(msg.sender), // refund address
            address(0x0), // 'zroPaymentAddress' unused for this
            adapterParams // txParameters
        );
    }

    /**
     * @dev Estimate your transfer fees 
     */
    function estimateFees(uint16 _chainId, uint256 _tokenId) external view returns (uint256, bytes memory) {
        require(
            trustedRemoteLookup[_chainId].length > 0,
            "This chain is currently unavailable for travel"
        );

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, _tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint256 messageFee, ) = endpoint.estimateFees(
            _chainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        return (messageFee, payload);
    }

    /**
     * @dev In case LZ gasForDestination needs to be updated 
     */
    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    /**
     * @dev On msg receive from Layer Zero, mint a new token 
     */
    function _lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal override {
        // decode
        (address toAddr, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        _safeMint(toAddr, tokenId);
    }

    /**
     * @dev Overwrite OpenZepellin _baseURI to get the base for TokenURI
     * from a variable
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Allow contract owner to update BaseURI in case
     * Metadata URL changes or for late reveal 
     */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    /**
     * @dev Allow donations from non cheap bastards
     */
    function donate() external payable {
        // thank you
    }

    /**
     * @dev Allow us to take kind donations from the non-cheap bastards
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }


    receive() external payable {}
    fallback() external payable {}
}