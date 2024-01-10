
import "./ERC721A.sol";
import "./Ownable.sol";
import "./NonblockingReceiver.sol";

//    ___ _               _   _         ___                 _      _           _       __                    _       
//   / _ \ |__   ___  ___| |_| |_   _  /___\_ __ ___  _ __ (_) ___| |__   __ _(_)_ __ / _\ ___  ___ _ __ ___| |_ ___ 
//  / /_\/ '_ \ / _ \/ __| __| | | | |//  // '_ ` _ \| '_ \| |/ __| '_ \ / _` | | '_ \\ \ / _ \/ __| '__/ _ \ __/ __|
// / /_\\| | | | (_) \__ \ |_| | |_| / \_//| | | | | | | | | | (__| | | | (_| | | | | |\ \  __/ (__| | |  __/ |_\__ \
// \____/|_| |_|\___/|___/\__|_|\__, \___/ |_| |_| |_|_| |_|_|\___|_| |_|\__,_|_|_| |_\__/\___|\___|_|  \___|\__|___/
//                              |___/                                                                                

contract GhostlyOmnichainSecrets is Ownable, ERC721A, NonblockingReceiver {

    address public _owner;
    string private baseURI;
    uint256 nextTokenId = 0;
    uint256 MAX_MINT_ETHEREUM = 5000;
    uint256 public price = 0.04 ether;

    uint gasForDestinationLzReceive = 350000;

    constructor(string memory baseURI_, address _layerZeroEndpoint) ERC721A("Ghostly Omnichain Secrets", "GOS") {
        _owner = msg.sender;
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        baseURI = baseURI_;
    }

    function setPrice(uint256 _price)
        external
        onlyOwner
    {
        price = _price;
    }

    // mint function
    function mint(uint8 numTokens) external payable {
        require((price * numTokens) <= msg.value, "Not enough amount sent.");
        require(nextTokenId + numTokens <= MAX_MINT_ETHEREUM, "GOS: Mint exceeds supply");
         _safeMint(msg.sender, numTokens);
    }

    // This function transfers the nft from your address on the
    // source chain to the same address on the destination chain
    function traverseChains(uint16 _chainId, uint tokenId) public payable {
        require(msg.sender == ownerOf(tokenId), "You must own the token to traverse");
        require(trustedRemoteLookup[_chainId].length > 0, "This chain is currently unavailable for travel");

        // burn NFT, eliminating it from circulation on src chain
        _burn(tokenId);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint messageFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);

        require(msg.value >= messageFee, "GOS: msg.value not enough to cover messageFee. Send gas for message fees");

        endpoint.send{value: msg.value}(
            _chainId,                           // destination chainId
            trustedRemoteLookup[_chainId],      // destination address of nft contract
            payload,                            // abi.encoded()'ed bytes
            payable(msg.sender),                // refund address
            address(0x0),                       // 'zroPaymentAddress' unused for this
            adapterParams                       // txParameters
        );
    }

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function donate() external payable {
        // thank you
    }

    // This allows the devs to receive kind donations
    function withdraw(uint amt) external onlyOwner {
        (bool sent, ) = payable(_owner).call{value: amt}("");
        require(sent, "GOS: Failed to withdraw Ether");
    }

    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    // ------------------
    // Internal Functions
    // ------------------

    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) override internal {
        // decode
        (address toAddr, uint tokenId) = abi.decode(_payload, (address, uint));

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
    }

    function _baseURI() override internal view returns (string memory) {
        return baseURI;
    }

    function summon(address[] memory recipients) onlyOwner external {
      for (uint16 i = 0; i < recipients.length; i++) {
        _safeMint(recipients[i], 1);
      }
    }
}