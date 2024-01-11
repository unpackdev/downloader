// SPDX-License-Identifier: MIT
// tokenists.galleryland.xyz                                                                     

pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./MerkleProof.sol";

import "./ERC721Accesslist.sol";

import "./NonblockingReceiver.sol";
                                                           
/*                                                                             
 * @title The Tokenists - ETHEREUM
 * TheTokenists - a contract for the The Tokenists Galleries                                                            
 */
contract TheTokenists is ERC721Accesslist, NonblockingReceiver {

    // set the max supply ever - although we may lock this to a lower number this sets a total upper bound
    uint256 constant  maxEverSupply = 10000;
    bool public changeSupplyLocked = false; // fix the max supply for good
    bool public publicSaleActive = false;   //public sale active
    uint public maxTokenPurchase = 10;   // what's the max someone can buy
    uint public maxAccesslistPurchase = 2;   // what's the max someone on the access list can buy

    ////////////////////////////////////////////////////////////////////////////////////////
    // Ethereum Settings
    // Current Network : MAINNET
    ////////////////////////////////////////////////////////////////////////////////////////

    address public layerZeroEndpoint = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;  // Mainnet endpoint
    uint256 public baseTokenId = 0;
    uint256 public maxSupply = 7500;  // current release limit - can change to allow second mint, or to allow accesslist limits
    uint256 public basePrice = 200000000000000000; //0.20 ETH
    uint256 public accesslistPrice = 200000000000000000; //0.20 ETH


    // set provenance
    string public PROVENANCE;

    // url data for the meta data
    string public tokenURIPrefix = "";

    uint256 gasForDestinationLzReceive = 350000;

    constructor()
        ERC721Accesslist("TheTokenists", "TOKENISTS")
    {
         endpoint = ILayerZeroEndpoint(layerZeroEndpoint);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    // token meta data url functions
    function baseTokenURI() override public view returns (string memory) {
        return tokenURIPrefix;
    }

    function updateTokenURIPrefix(string memory newPrefix) external onlyOwner {
        tokenURIPrefix = newPrefix;
    }

    // get and set the public sale state
    function setPublicSale(bool _setSaleState) public onlyOwner{
        publicSaleActive = _setSaleState;
    }    
        
 
    // allow us to slowly release up to the max ever supply
    function setMaxSupply(uint _maxSupply) public onlyOwner{
        if (_maxSupply <= maxEverSupply && !changeSupplyLocked)
            maxSupply = _maxSupply;
    }    

    function lockSupply() virtual public onlyOwner{
        changeSupplyLocked = true;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    // set a new price for the main mint
    function updatePrice(uint _newPrice) public onlyOwner{
        basePrice =  _newPrice;
    }

    // set a new price for the access list mint
    function updateAccesslistPrice(uint newPrice) public onlyOwner{
        accesslistPrice =  newPrice;
    }    

    // update the max number that can be minted in a single transaction in a public mint
    function updateMaxTokenPurchase(uint _maxTokenPurchase) public onlyOwner{
        maxTokenPurchase =  _maxTokenPurchase;
    }

    // update the total number that can be minted via an accesslist
    function updateMaxAccesslistPurchase(uint _maxAccesslistPurchase) public onlyOwner{
        maxAccesslistPurchase =  _maxAccesslistPurchase;
    }

    // allow the owner to pre-mint or save a number of tokens
    function reserveTokens(uint _amount, address _receiver) public onlyOwner {        

        uint256 newSupply = totalSupply + _amount;
        require(newSupply <= maxSupply, "MAX_SUPPLY_EXCEEDED");

        for (uint256 i = 0; i < _amount; i++) {
            _mint(_receiver, totalSupply + i + baseTokenId);
        }    
        // update the total supply
        totalSupply = newSupply;    
    }

    // mint 
    function mint(uint256 amount) external payable {
        require(amount != 0, "INVALID_AMOUNT");
        require(publicSaleActive, "SALE_CLOSED");
        require(amount <= maxTokenPurchase, "AMOUNT_EXCEEDS_MAX_PER_CALL");
        require(amount * basePrice <= msg.value, "WRONG_ETH_AMOUNT");

        uint256 newSupply = totalSupply + amount;
        require(newSupply <= maxSupply, "MAX_SUPPLY_EXCEEDED");

        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply + i + baseTokenId);
        }
        // update the totaly supply
        totalSupply = newSupply;
    }

    function accesslistMint(uint256 amount, bytes32[] calldata proof) public payable {
   //     string memory payload = string(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, accesslistRoot, keccak256(abi.encodePacked(msg.sender))), "BAD_MERKLE_PROOF");

        require(accesslistSaleActive, "SALE_CLOSED");
        require(amount <= maxTokenPurchase, "AMOUNT_EXCEEDS_MAX_PER_CALL");
        require(amount * accesslistPrice <= msg.value, "WRONG_ETH_AMOUNT");
        require(accesslistMinted[msg.sender] + amount <= maxAccesslistPurchase, "EXCEEDS_ALLOWANCE"); 

        uint256 newSupply = totalSupply + amount;
        require(newSupply <= maxSupply, "MAX_SUPPLY_EXCEEDED");

        accesslistMinted[msg.sender] += amount;
        for (uint256 i = 0; i < amount; i++) {
            _mint(msg.sender, totalSupply + i);
        }
        // update the totaly supply
        totalSupply = newSupply;
    }







    // This function transfers the nft from your address on the
    // source chain to the same address on the destination chain
    function traverseChains(uint16 _chainId, uint256 tokenId) public payable whenNotPaused {
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
            "the tokenists: msg.value not enough to cover messageFee. Send gas for message fees"
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



    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    // ------------------
    // Internal Functions
    // ------------------

    function _LzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        // decode
        (address toAddr, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
    }





}
