// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract GenesisNFT is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string private _tokenURI;
    string private _contractURI;
    Counters.Counter private _tokenIdCounter;

    uint256 public maxSupply = 250;
    uint256 public tokenPrice = 0.35 ether;
    bool public saleStarted = false;

    mapping(uint256 => uint256) public expiryTime;

    constructor(string memory tokenURI_, string memory contractURI_)
        ERC721("Genesis", "GENESIS")
    {
        _tokenURI = tokenURI_;
        _contractURI = contractURI_;
    }

    /**
     * @notice Function that is used to mint a token.
     */
    function mint() public payable {
        uint256 tokenIndex = _tokenIdCounter.current() + 1;

        require(tx.origin == msg.sender, "Caller must not be a contract.");
        require(saleStarted, "Sale has not started.");
        require(balanceOf(msg.sender) == 0, "User already holds a token.");
        require(msg.value == tokenPrice, "Incorrect Ether amount sent.");
        require(
            tokenIndex <= maxSupply,
            "Minted token would exceed total supply."
        );

        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenIndex);
        expiryTime[tokenIndex] = block.timestamp + 30 days;
    }

    /**
     * @notice Function that is used to mint a token free of charge, only
     * callable by the owner.
     *
     * @param _receiver The receiving address of the newly minted token.
     */
    function ownerMint(address _receiver) public onlyOwner {
        uint256 tokenIndex = _tokenIdCounter.current() + 1;

        require(_receiver != address(0), "Receiver cannot be zero address.");
        require(
            tokenIndex <= maxSupply,
            "Minted token would exceed total supply."
        );

        if (msg.sender != _receiver) {
            require(balanceOf(_receiver) == 0, "User already holds a token.");
        }

        _tokenIdCounter.increment();

        _safeMint(_receiver, tokenIndex);
        expiryTime[tokenIndex] = block.timestamp + 30 days;
    }

    /**
     * @notice Function that is used to extend/renew a tokens expiry date.
     *
     * @param _tokenId The token ID to extend/renew.
     */
    function renewToken(uint256 _tokenId) public payable {
        require(tx.origin == msg.sender, "Caller must not be a contract.");
        require(msg.value == tokenPrice, "Incorrect Ether amount.");
        require(_exists(_tokenId), "Token does not exist.");

        uint256 _currentexpiryTime = expiryTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[_tokenId] += 30 days;
        }
    }

    /**
     * @notice Function that is used to extend/renew a tokens expiry date for
     * 30 days free of charge, only callable by the owner.
     *
     * @param _tokenId The token ID to extend/renew.
     */
    function ownerRenewToken(uint256 _tokenId) external onlyOwner {
        require(_exists(_tokenId), "Token does not exist.");

        uint256 _currentexpiryTime = expiryTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[_tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[_tokenId] += 30 days;
        }
    }

    /**
     * @notice Function that is used to update the 'tokenPrice' variable,
     * only callable by the owner.
     *
     * @param _updatedTokenPrice The new token price in units of wei.
     */
    function updateTokenPrice(uint256 _updatedTokenPrice) external onlyOwner {
        require(tokenPrice != _updatedTokenPrice, "Price has not changed.");
        tokenPrice = _updatedTokenPrice;
    }

    /**
     * @notice Function that is used to authenticate a user.
     *
     * @param _tokenId The desired token owned by a user.
     *
     * @return Returns a bool value determining if authentication was
     * was successful. 'true' is successful, 'false' if otherwise.
     */
    function authenticateUser(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(
            expiryTime[_tokenId] > block.timestamp,
            "Token has expired. Please renew!"
        );

        return msg.sender == ownerOf(_tokenId) ? true : false;
    }

    /**
     * @notice Function that is used to increase the `maxSupply` value. 
     *
     * @param _newTokens The amount of tokens to add to `maxSupply` value.
     */
    function addTokens(uint256 _newTokens) external onlyOwner {
        maxSupply += _newTokens;
    }

    /**
     * @notice Function that is used to decrease the `maxSupply` value. 
     *
     * @param _numTokens The amount of tokens to add to `maxSupply` value.
     */
    function removeTokens(uint256 _numTokens) external onlyOwner {
        require(
            maxSupply - _numTokens >= totalSupply(),
            "Supply cannot fall below minted tokens."
        );
        maxSupply -= _numTokens;
    }

    /**
     * @notice Function that is used to get the token URI for a specific token.
     *
     * @param _tokenId The token ID to fetch the token URI for.
     *
     * @return Returns a string value representing the token URI for the
     * specified token.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(_tokenURI, _tokenId.toString()));
    }

    /**
     * @notice Function that is used to update the token URI for the contract,
     * only callable by the owner.
     *
     * @param tokenURI_ A string value to replace the current '_tokenURI' value.
     */
    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    /**
     * @notice Function that is used to get the contract URI.
     *
     * @return Returns a string value representing the contract URI.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Function that is used to update the contract URI, only callable
     * by the owner.
     *
     * @param contractURI_ A string value to replace the current 'contractURI_'.
     */
    function setContractURI(string calldata contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    /**
     * @notice Function that is used to withdraw the balance of the contract,
     * only callable by the owner.
     */
    function withdrawBalance() public onlyOwner {
        payable(0x2E908f3FAC492c77850Fa3C9B2e095548B992ed5).transfer(
            address(this).balance
        );
    }

    /**
     * @notice Function that is used to flip the sale state of the contract,
     * only callable by the owner.
     */
    function toggleSale() public onlyOwner {
        saleStarted = !saleStarted;
    }

    /**
     * @notice Function that is used to get the total tokens minted.
     *
     * @return Returns a uint which indicates the total supply.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }
}
