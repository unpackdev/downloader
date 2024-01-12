// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./RandomlyAssigned.sol";

/**
 * @title ERC721Project
 * ERC721Project - a contract for non-fungible NFTs.
 */
contract ERC721Project is 
    ERC721Tradable,
    RandomlyAssigned
{

    string public _ContractURI;

    uint public _MintPrice = 0.15 ether;

    uint[] public mintedTokens;

    address[] private receiverAddress;
    mapping (address => uint) private receiverPercent; 

    uint public _TotalSupply = 0;

    uint[] public mintedReservedTokens;
    uint public reservedTokensAmount;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI,
        uint _maxTokenSupply,
        uint _reservedTokenSupply,
        address[] memory _receiverAddress,
        uint[] memory _receiverPercent,
        address _proxyRegistryAddress
    )
        ERC721Tradable(_name, _symbol, _proxyRegistryAddress)
        RandomlyAssigned(_maxTokenSupply + 1 - (_reservedTokenSupply + 1), _reservedTokenSupply + 1)
    {
        setBaseTokenURI(_baseURI);
        setContractURI(_contractURI);
        setTransactionRecipients(_receiverAddress, _receiverPercent);
        reservedTokensAmount = _reservedTokenSupply;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        _ContractURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _ContractURI;
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public virtual override view returns (uint256) {
        return tokenCount();
    }

    /**
     * @dev Mints a random token to an address with a tokenURI. SHOULD ONLY BE USED AS A GIFTING or CREATION Procedure
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public virtual override onlyOwner {
        require(!paused(), "Contract is paused");
        uint256 currentTokenId = nextToken();
        _safeMint(_to, currentTokenId);
        mintedTokens.push(currentTokenId);
    }

    mapping (uint => bool) private _minted;

    /**
     * @dev Mints a token with given id to an address. SHOULD ONLY BE USED TO SEND SPECIFIC TOKENS TO AN ADDRESS
     * @param _to address of the future owner of the token
     * @param _id the id of the token to mint
     */
    function mintReservedTokens(address _to, uint _id) public onlyOwner {
        require(!paused(), "Contract is paused");
        require(_minted[_id] == false, "Token already minted");
        require(_id <= reservedTokensAmount, "Token ID must be less than Reseved Tokens. Reserved Tokens and above to be distributed randomly");
        require(_id > 0, "Token ID must be greater than 0");
        _safeMint(_to, _id);
        _minted[_id] = true;
        mintedTokens.push(_id);
        mintedReservedTokens.push(_id);
    }

    /**
     * @dev Mints a random token to an address with a tokenURI. WILL BE USED TO MINT TOKEN TO PUBLIC
     * @param _to address of the future owner of the token
     */
    function mintPaidRandomToken(address _to, uint _amount) public payable {
        require(!paused(), "Contract is paused");
        require(msg.value == _MintPrice*_amount, "Insufficient ether cost. Amount should equal _amount * _MintPrice");
        require(tokenCount() + _amount <= maxTokenSupplyForRandomMinting(), "Amount to be minted exceeds max supply");

        for(uint i = 0; i < _amount; i++) {
            uint256 currentTokenId = nextToken();
            _safeMint(_to, currentTokenId);
            mintedTokens.push(currentTokenId);
        }

        sendTransactionCut();
    }

    function tokenURI(uint256 _tokenId) virtual override public view returns (string memory) {

        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId), ".json"));
        
    }

    function setTransactionRecipients(address[] memory _receivers, uint[] memory  _percentages) public onlyOwner {
        require(_receivers.length > 0, "No receivers specified");
        require(_receivers.length == _percentages.length, "Receivers and percentages must be of same length");
        receiverAddress = _receivers;
        for(uint i = 0; i < _receivers.length; i++) {
            require(_percentages[i] > 0, "Percentage must be greater than 0");
            receiverPercent[_receivers[i]] = _percentages[i];
        }
    }

    function totalCut() public view returns (uint256) {
        uint _totalCut = 0;
        for(uint i = 0; i < receiverAddress.length; i++) {
            _totalCut += receiverPercent[receiverAddress[i]];
        }
        return _totalCut;
    }

    function sendTransactionCut() private {
        uint _totalCut = totalCut();
        for(uint i = 0; i < receiverAddress.length; i++) {
            payable(receiverAddress[i]).transfer(msg.value * receiverPercent[receiverAddress[i]] / _totalCut);
        }
    }

    function totalMintedTokens() public view returns (uint256) {
        return mintedTokens.length;
    }

    function totalReservedTokensLeft() public view returns (uint256) {
        return maxSupply() - maxTokenSupplyForRandomMinting() - mintedReservedTokens.length;
    }

    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }

}

