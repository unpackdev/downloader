// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

/// @creator:     GeneXProject
/// @author:      shintalha - twitter.com/shintalha

//      ___           ___           ___           ___           ___     
//     /  /\         /  /\         /__/\         /  /\         /__/|    
//    /  /:/_       /  /:/_        \  \:\       /  /:/_       |  |:|    
//   /  /:/ /\     /  /:/ /\        \  \:\     /  /:/ /\      |  |:|    
//  /  /:/_/::\   /  /:/ /:/_   _____\__\:\   /  /:/ /:/_   __|__|:|    
// /__/:/__\/\:\ /__/:/ /:/ /\ /__/::::::::\ /__/:/ /:/ /\ /__/::::\____
// \  \:\ /~~/:/ \  \:\/:/ /:/ \  \:\~~\~~\/ \  \:\/:/ /:/    ~\~~\::::/
//  \  \:\  /:/   \  \::/ /:/   \  \:\  ~~~   \  \::/ /:/      |~~|:|~~ 
//   \  \:\/:/     \  \:\/:/     \  \:\        \  \:\/:/       |  |:|   
//    \  \::/       \  \::/       \  \:\        \  \::/        |  |:|   
//     \__\/         \__\/         \__\/         \__\/         |__|/    
//
//           ___         ___           ___         ___          ___           ___                 
//     /  /\       /  /\         /  /\       /  /\        /  /\         /  /\          ___   
//    /  /::\     /  /::\       /  /::\     /  /:/       /  /:/_       /  /:/         /  /\  
//   /  /:/\:\   /  /:/\:\     /  /:/\:\   /__/::\      /  /:/ /\     /  /:/         /  /:/  
//  /  /:/~/:/  /  /:/~/:/    /  /:/  \:\  \__\/\:\    /  /:/ /:/_   /  /:/  ___    /  /:/   
// /__/:/ /:/  /__/:/ /:/___ /__/:/ \__\:\    \  \:\  /__/:/ /:/ /\ /__/:/  /  /\  /  /::\   
// \  \:\/:/   \  \:\/:::::/ \  \:\ /  /:/     \__\:\ \  \:\/:/ /:/ \  \:\ /  /:/ /__/:/\:\  
//  \  \::/     \  \::/~~~~   \  \:\  /:/      /  /:/  \  \::/ /:/   \  \:\  /:/  \__\/  \:\ 
//   \  \:\      \  \:\        \  \:\/:/      /__/:/    \  \:\/:/     \  \:\/:/        \  \:\
//    \  \:\      \  \:\        \  \::/       \__\/      \  \::/       \  \::/          \__\/
//     \__\/       \__\/         \__\/                    \__\/         \__\/                
                                                                                                    

import "./ONFT721.sol";
import "./MerkleProof.sol";

contract GeneXProject is ONFT721 {
    uint public nextMintId;
    uint public maxMintId;
    
    bool public revealed = false;
    string BASE_URI;
    string HIDDEN_URI;

    bytes32 public merkleroot;
    bool public PUBLIC_SALE_STATE = false;
    bool public WL_SALE_STATE = false;

    uint constant maxTokenPerWallet = 2;

    uint gasLzReceive = 350000;

    mapping (address => uint) addressToMintCount;
    
    constructor(address _layerZerolzEndpoint, uint _startMintId, uint _endMintId) ONFT721("GeneXProject", "GXP", _layerZerolzEndpoint) 
    {
        nextMintId = _startMintId;
        maxMintId = _endMintId;
    }

    function mint() 
    internal 
    {
        _safeMint(msg.sender, nextMintId);
        nextMintId++;
    }

    function _baseURI() 
    internal 
    view 
    override 
    returns (string memory) 
    {
        return BASE_URI;
    }

    function setMerkleRoot(bytes32 _merkleroot) 
    onlyOwner 
    public 
    {
        merkleroot = _merkleroot;
    }

    function setBaseURI(string memory NEW_BASE_URI) 
    public 
    onlyOwner 
    {
        BASE_URI = NEW_BASE_URI;
    }

    function setHiddenURI(string memory NEW_HIDDEN_URI) 
    public 
    onlyOwner 
    {
        HIDDEN_URI = NEW_HIDDEN_URI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId),"ONFT721Metadata: URI query for nonexistent token");
        if(revealed == false) 
            return HIDDEN_URI;

        return bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(),  Strings.toString(tokenId), ".json")) : '';
    }

    function ownerMint(uint256 numberOfTokens) 
    public 
    onlyOwner 
    {
        require((nextMintId + numberOfTokens) - 1 <= maxMintId, "Exceeds total supply for this chain.");
        for (uint i = 0; i < numberOfTokens; i++) 
        {
            mint();   
        }
    }

    function bool_PUBLIC_SALE() public 
    onlyOwner 
    {
        PUBLIC_SALE_STATE = !PUBLIC_SALE_STATE;
    }

    function bool_WL_SALE() public 
    onlyOwner 
    {
        WL_SALE_STATE = !WL_SALE_STATE;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    modifier onlyAccounts () 
    {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function _leafHash(address account)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }
    
    function _verifyHash(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, merkleroot, leaf);
    }

    function whitelistMint(uint256 numberOfTokens, bytes32[] calldata proof)
    public
    onlyAccounts
    {
        require(WL_SALE_STATE, "Whitelist sale is not started.");
        require(numberOfTokens <= maxTokenPerWallet, "Too many requested");
        require((nextMintId + numberOfTokens) - 1 <= maxMintId, "Exceeds total supply for this chain.");
        require(addressToMintCount[msg.sender] + numberOfTokens <= maxTokenPerWallet, "Exceeds allowed mint number.");
        require(_verifyHash(_leafHash(msg.sender), proof), "Merkle proof is denied.");
        addressToMintCount[msg.sender] += numberOfTokens; 
        for (uint i = 0; i < numberOfTokens; i++) 
        {
            mint();   
        }
    }

    function publicMint(uint256 numberOfTokens) 
    public 
    onlyAccounts
    {
        require(PUBLIC_SALE_STATE, "Sale haven't started");
        require(numberOfTokens <= maxTokenPerWallet, "Too many requested");
        require((nextMintId + numberOfTokens) - 1 <= maxMintId, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + numberOfTokens <= maxTokenPerWallet, "Exceeds allowance");
        addressToMintCount[msg.sender] += numberOfTokens;
        for (uint i = 0; i < numberOfTokens; i++) 
        {
            mint();   
        }
    }
    
    function _withdraw(address _address, uint256 _amount)
    private 
    {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawAll() 
    public 
    onlyOwner 
    {
        uint256 balance_ = address(this).balance;
        require(balance_ > 0);
        _withdraw(owner(), balance_);
    }

    function traverseChains(uint16 _chainId, uint tokenId) public payable 
    {
        // _chainId is the Id of destination chain. Ids of available chains are like that:
        // ethereum: 1
        // bsc: 2
        // avalanche: 6
        // polygon: 9
        // arbitrum: 10
        // optimism: 11
        // antom: 12

        require(msg.sender == ownerOf(tokenId), "You don't own this ONFT.");
        require(trustedRemoteLookup[_chainId].length > 0, "You cannot make your ONFT to travel to this chain right now.");

        // When you transfer your nft to another chain, it must be destroyed(burned) on current chain.
        _burn(tokenId);

        bytes memory payload = abi.encode(msg.sender, tokenId);

        
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasLzReceive);

        // Getting the fees needed to pay to LayerZero + Relayer to cover message delivery. You will be refunded for extra gas paid.
        (uint messageFee, ) = lzEndpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);
        
        require(msg.value >= messageFee, "GG: msg.value not enough to cover messageFee. Send gas for message fees");

        lzEndpoint.send{value: msg.value}(
            _chainId,                           // destination chainId
            trustedRemoteLookup[_chainId],      // destination address of nft contract
            payload,                            // abi.encoded()'ed bytes
            payable(msg.sender),                // refund address
            address(0x0),                       // 'zroPaymentAddress' unused for this
            adapterParams                       // txParameters 
        );
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) 
    internal 
    override
    {
        (address toAddr, uint tokenId) = abi.decode(_payload, (address, uint));
        _safeMint(toAddr, tokenId);
    }

    function setGasLzReceive(uint newVal) 
    external 
    onlyOwner 
    {
        gasLzReceive = newVal;
    }  

}
