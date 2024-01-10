// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./Counters.sol";

/* 
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNmmmmmNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNmmddmNNNmddmmNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNmhhdNNNNmdddmNNNNmhhmNNNNNNNNNNNNNNN
NNNNNNNNNNmhs+///+syhdmNNNmmhyo/:::/shmNNNNNNNNNNN
NNNNNNNNNNy:::::/:://+shdho/:-------..oNNNNNNNNNNN
NNNNNNNNNNs::::::::::::::.............+NNNNNNNNNNN
NNNNNNNNNNs:::::::::::::-.....--......+NNNNNNNNNNN
NNNNNNNNNNs:::::://:///:--------......+NNNNNNNNNNN
NNNNNNNNNNs::::+///:////:::------:....+NNNNNNNNNNN
NNNNNNNNNNs::::mdyo/////:::-::+ydm:...+NNNNNNNNNNN
NNNNNNNNNNs::::NNNNhdyo+:/+ydhNNNN:...+NNNNNNNNNNN
NNNNNNNNNNs::::mNNNdNNNmymNNNdNNNm:...+NNNNNNNNNNN
NNNNNNNNNNs:::/mmmmhNNNNdNNNNhmmmm:...+NNNNNNNNNNN
NNNNNNNNNNd+//:NNNNhmmmmdNmmmhNNNN:.-/yNNNNNNNNNNN
NNNNNNNNNNNNmdymmNNdNNNNhmNNNdNNNmyhmNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNmmhmNNNdNNNNhmmmNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNmmmhmmmmNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
*/

/// @title ERC-721 token for Meta Mint Software License.
/// @author @ItsCuzzo

contract MetaMint is Ownable, ERC721 {

    using Strings for uint;
    using Counters for Counters.Counter;

    string private _tokenURI;
    string private _contractURI;
    Counters.Counter private _tokenIdCounter;

    uint public maxSupply = 300;
    uint public tokenPrice = 1.25 ether;
    uint public renewalPrice = 0.3 ether;
    uint public maxTokensPerTx = 3;
    uint public gracePeriod = 3 days;

    mapping(uint => uint) public expiryTime;
    mapping(uint => bool) public isBanned;

    struct DutchAuction {
        uint32 startTime;
        uint72 startingPrice;
        uint16 stepDuration;
        uint72 reservePrice;
        uint64 decrementAmount;
    }

    enum SaleStates {
        PAUSED,
        FCFS_MINT,
        DUTCH_AUCTION
    }

    DutchAuction public auction;
    SaleStates public saleState;

    event Minted(address indexed _from, uint _amount);
    event Renewed(address indexed _from, uint _tokenId);
    event RenewedBatch(address indexed _from, uint[] _tokenIds);
    event Banned(address indexed _from, uint _tokenId);
    event Unbanned(address indexed _from, uint _tokenId);

    constructor(
        string memory tokenURI_,
        string memory contractURI_
    ) ERC721("Meta Mint", "MMAIO") {
        _tokenURI = tokenURI_;
        _contractURI = contractURI_;
    }

    /// @notice Function used to mint a token during the `DUTCH_AUCTION` sale.
    function auctionMint() external payable {
        require(tx.origin == msg.sender, "Caller should not be a contract.");
        require(SaleStates.DUTCH_AUCTION == saleState, "Auction not active.");
        require(auction.startTime <= block.timestamp, "Auction has not started.");
        
        uint tokenIndex = _tokenIdCounter.current() + 1;

        require(maxSupply >= tokenIndex, "Minted tokens would exceed supply.");
        require(msg.value >= getAuctionPrice(), "Incorrect Ether amount.");

        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenIndex);
        expiryTime[tokenIndex] = block.timestamp + 30 days;

        emit Minted(msg.sender, 1);
    }

    /// @notice Function used to mint tokens during the `FCFS_MINT` sale.
    /// @param numTokens The desired number of tokens to mint.
    function mint(uint numTokens) external payable {
        require(tx.origin == msg.sender, "Caller should not be a contract.");
        require(saleState == SaleStates.FCFS_MINT, "FCFS minting is not active.");
        require(tokenPrice * numTokens == msg.value, "Incorrect Ether amount.");
        require(maxSupply >= _tokenIdCounter.current() + numTokens, "Minted tokens would exceed supply.");
        require(maxTokensPerTx >= numTokens, "Token tx limit exceeded.");

        for (uint i=0; i<numTokens; i++) {
            _tokenIdCounter.increment();

            uint tokenIndex = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenIndex);

            expiryTime[tokenIndex] = block.timestamp + 30 days;
        }

        emit Minted(msg.sender, numTokens);
    }

    /// @notice Function that is used to extend/renew a tokens expiry date
    /// in increments of 30 days.
    /// @param tokenId The token ID to extend/renew.
    function renewToken(uint tokenId) public payable {
        require(_exists(tokenId), "Token does not exist.");
        require(ownerOf(tokenId) == msg.sender, "Caller does not own token.");
        require(!isBanned[tokenId], "Token is banned.");
        require(msg.value == renewalPrice, "Incorrect Ether amount.");

        uint _currentexpiryTime = expiryTime[tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[tokenId] += 30 days;
        }

        emit Renewed(msg.sender, tokenId);
    }

    /// @notice Function that is used to extend/renew multiple tokens expiry date
    /// in increments of 30 days.
    /// @param tokenIds The token IDs to extend/renew.
    function batchRenewToken(uint[] calldata tokenIds) public payable {
        require(tokenIds.length >= 2, "Invalid array length.");
        require(renewalPrice * tokenIds.length == msg.value, "Incorrect Ether amount.");

        for (uint i=0; i<tokenIds.length; i++) {
            require(_exists(tokenIds[i]), "Token does not exist.");
            require(ownerOf(tokenIds[i]) == msg.sender, "Caller does not own token.");
            require(!isBanned[tokenIds[i]], "Token is banned.");

            uint _currentexpiryTime = expiryTime[tokenIds[i]];
            
            if (block.timestamp > _currentexpiryTime) {
                expiryTime[tokenIds[i]] = block.timestamp + 30 days;
            } else {
                expiryTime[tokenIds[i]] += 30 days;
            }
        }

        emit RenewedBatch(msg.sender, tokenIds);
    }

    /// @notice Function that is used to mint a token free of charge, only
    /// callable by the owner.
    function ownerMint(address receiver) public onlyOwner {
        uint tokenIndex = _tokenIdCounter.current() + 1;

        require(maxSupply >= tokenIndex, "Minted tokens would exceed supply.");

        _tokenIdCounter.increment();
        _safeMint(receiver, tokenIndex);

        expiryTime[tokenIndex] = block.timestamp + 30 days;

        emit Minted(msg.sender, 1);
    }

    /// @notice Function that is used to extend/renew a tokens expiry date
    /// in increments of 30 days free of charge, only callable by the owner.
    /// @param tokenId The token ID to extend/renew.
    function ownerRenewToken(uint tokenId) public onlyOwner {
        require(_exists(tokenId), "Token does not exist.");

        uint _currentexpiryTime = expiryTime[tokenId];

        if (block.timestamp > _currentexpiryTime) {
            expiryTime[tokenId] = block.timestamp + 30 days;
        } else {
            expiryTime[tokenId] += 30 days;
        }

        emit Renewed(msg.sender, tokenId);
    }

    /// @notice Function that is used to extend/renew multiple tokens expiry date
    /// in increments of 30 days free of charge, only callable by the owner.
    /// @param tokenIds The token IDs to extend/renew.
    function ownerBatchRenewToken(uint[] calldata tokenIds) public onlyOwner {
        require(tokenIds.length >= 2, "Invalid array length.");

        for (uint i=0; i<tokenIds.length; i++) {
            require(_exists(tokenIds[i]), "Token does not exist.");

            uint _currentexpiryTime = expiryTime[tokenIds[i]];
            
            if (block.timestamp > _currentexpiryTime) {
                expiryTime[tokenIds[i]] = block.timestamp + 30 days;
            } else {
                expiryTime[tokenIds[i]] += 30 days;
            }
        }

        emit RenewedBatch(msg.sender, tokenIds);
    }

    /// @notice Function used to get the current price of a token during the
    /// dutch auction.
    /// @dev This function should be polled externally to determine how much
    /// Ether a participant should send.
    /// @return Returns a uint indicating the current price of the token in
    /// wei.
    function getAuctionPrice() public view returns (uint72) {
        if (saleState != SaleStates.DUTCH_AUCTION || auction.startTime >= block.timestamp) {
            return auction.startingPrice;
        }

        uint72 decrements = (uint72(block.timestamp) - auction.startTime) / auction.stepDuration;
        if (decrements * auction.decrementAmount >= auction.startingPrice) {
            return auction.reservePrice;
        }

        if (auction.startingPrice - decrements * auction.decrementAmount < auction.reservePrice) {
            return auction.reservePrice;
        }

        return auction.startingPrice - decrements * auction.decrementAmount;
    }

    /// @notice Function used to define the dutch auction settings.
    /// @param _startTime Starting time for the auction in seconds.
    /// @param _startingPrice Starting price for the auction in wei.
    /// @param _stepDuration Time between each price decrease, in seconds.
    /// @param _reservePrice Reserve price for the auction in wei.
    /// @param _decrementAmount Amount that price decreases every step, in wei.
    /// @dev Reasoning for doing one function for all updates is that once the
    /// auction is configured once, it shouldn't need changing until afterwards.
    function setAuctionBulk(
        uint32 _startTime, uint72 _startingPrice, uint16 _stepDuration, uint72 _reservePrice, uint64 _decrementAmount
    ) external onlyOwner {
        require(_startTime > block.timestamp, "Invalid start time.");
        require(_startingPrice > _reservePrice, "Initial price must exceed reserve.");

        auction.startTime = _startTime;
        auction.startingPrice = _startingPrice;
        auction.stepDuration = _stepDuration;
        auction.reservePrice = _reservePrice;
        auction.decrementAmount = _decrementAmount;
    }

    /// @notice Function used to set the dutch auction start time.
    /// @param _startTime A UNIX epoch, in seconds, of the intended start time.
    /// @dev Pssst, https://www.epochconverter.com/
    function setAuctionStartTime(uint32 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, "Invalid start time.");
        auction.startTime = _startTime;
    }

    /// @notice Function used to set the starting price of the dutch auction.
    /// @param _startingPrice uint value in wei representing the starting price.
    function setAuctionStartingPrice(uint72 _startingPrice) external onlyOwner {
        require(auction.startingPrice != _startingPrice, "Price has not changed.");
        auction.startingPrice = _startingPrice;
    }

    /// @notice Function used to set the step time during the dutch auction.
    /// @param _stepDuration uint value is seconds representing how frequently the
    /// price will drop. E.g. Input of 120 is equivalent to 2 minutes.
    function setAuctionStepDuration(uint16 _stepDuration) external onlyOwner {
        require(auction.stepDuration != _stepDuration, "Duration has not changed.");
        auction.stepDuration = _stepDuration;
    }

    /// @notice Function used to set the dutch auction reserve price.
    /// @param _reservePrice Represents the reserve price in units of wei.
    function setAuctionReservePrice(uint72 _reservePrice) external onlyOwner {
        require(auction.reservePrice != _reservePrice, "Price has not changed.");
        auction.reservePrice = _reservePrice;
    }

    /// @notice Function used to set the dutch auction decrement amount.
    /// @param _decrementAmount uint value representing how much the price
    /// will drop each step. E.g. 25000000000000000 is 0.025 Ether.
    function setAuctionDecrementAmount(uint64 _decrementAmount) external onlyOwner {
        require(auction.decrementAmount != _decrementAmount, "Decrement has not changed.");
        auction.decrementAmount = _decrementAmount;
    }

    /// @notice Function that is used to update the `renewalPrice` variable,
    /// only callable by the owner.
    /// @param newRenewalPrice The new renewal price in units of wei. E.g.
    /// 500000000000000000 is 0.50 Ether.
    function updateRenewalPrice(uint newRenewalPrice) external onlyOwner {
        require(renewalPrice != newRenewalPrice, "Price has not changed.");
        renewalPrice = newRenewalPrice;
    }

    /// @notice Function that is used to update the `tokenPrice` variable,
    /// only callable by the owner.
    /// @param newTokenPrice The new initial token price in units of wei. E.g.
    /// 2000000000000000000 is 2 Ether.
    function updateTokenPrice(uint newTokenPrice) external onlyOwner {
        require(tokenPrice != newTokenPrice, "Price has not changed.");
        tokenPrice = newTokenPrice;
    }

    /// @notice Function that is used to update the `maxTokensPerTx` variable,
    /// only callable by the owner.
    /// @param newMaxTokensPerTx The new maximum amount of tokens a user can
    /// mint in a single tx.
    function updateMaxTokensPerTx(uint newMaxTokensPerTx) external onlyOwner {
        require(maxTokensPerTx != newMaxTokensPerTx, "Max tokens has not changed.");
        maxTokensPerTx = newMaxTokensPerTx;
    }

    /// @notice Function that is used to update the `GRACE_PERIOD` variable,
    /// only callable by the owner.
    /// @param newGracePeriod The new grace period in units of seconds in wei. 
    /// E.g. 2592000 is 30 days.
    /// @dev Grace period should be atleast 1 day, uint value of 86400.
    function updateGracePeriod(uint newGracePeriod) external onlyOwner {
        require(gracePeriod != newGracePeriod, "Duration has not changed.");
        require(newGracePeriod % 1 days == 0, "Must provide 1 day increments.");
        gracePeriod = newGracePeriod;
    }

    /// @notice Function used to set a new `saleState` value.
    /// @param newSaleState The newly desired sale state.
    /// @dev 0 = PAUSED, 1 = FCFS_MINT, 2 = DUTCH_AUCTION.
    function setSaleState(uint newSaleState) external onlyOwner {
        require(uint(SaleStates.DUTCH_AUCTION) >= newSaleState, "Invalid sale state.");
        saleState = SaleStates(newSaleState);
    }

    /// @notice Function that is used to authenticate a user.
    /// @param tokenId The desired token owned by a user.
    /// @return Returns a bool value determining if authentication was
    /// was successful. `true` is successful, `false` if otherwise.
    function authenticateUser(uint tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist.");
        require(!isBanned[tokenId], "Token is banned.");
        require(expiryTime[tokenId] + gracePeriod > block.timestamp, "Token has expired. Please renew!");

        return msg.sender == ownerOf(tokenId) ? true : false;
    }

    /// @notice Function used to increment the `maxSupply` value.
    /// @param numTokens The amount of tokens to add to `maxSupply`.
    function addTokens(uint numTokens) external onlyOwner {
        maxSupply += numTokens;
    }
    
    /// @notice Function used to decrement the `maxSupply` value.
    /// @param numTokens The amount of tokens to remove from `maxSupply`.
    function removeTokens(uint numTokens) external onlyOwner {
        require(maxSupply - numTokens >= _tokenIdCounter.current(), "Supply cannot fall below minted tokens.");
        maxSupply -= numTokens;
    }

    /// @notice Function used to ban a token, only callable by the owner.
    /// @param tokenId The token ID to ban.
    function banToken(uint tokenId) external onlyOwner {
        require(!isBanned[tokenId], "Token already banned.");
        expiryTime[tokenId] = block.timestamp;
        isBanned[tokenId] = true;

        emit Banned(msg.sender, tokenId);
    }

    /// @notice Function used to unban a token, only callable by the owner.
    /// @param tokenId The token ID to unban.
    function unbanToken(uint tokenId) external onlyOwner {
        require(isBanned[tokenId], "Token is not banned.");
        isBanned[tokenId] = false;

        emit Unbanned(msg.sender, tokenId);
    }

    /// @notice Function that is used to get the current `_contractURI` value.
    /// @return Returns a string value of `_contractURI`.
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Function that is used to update the `_contractURI` value, only
    /// callable by the owner.
    /// @param contractURI_ A string value to replace the current 'contractURI_'.
    function setContractURI(string calldata contractURI_) external onlyOwner {
        _contractURI = contractURI_;
    }

    /// @notice Function that is used to get the `_tokenURI` for `tokenId`.
    /// @param tokenId The `tokenId` to get the `_tokenURI` for.
    /// @return Returns a string representing the `_tokenURI` for `tokenId`.
    function tokenURI(uint tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(_tokenURI, tokenId.toString()));
    }

    /// @notice Function that is used to update the `_tokenURI` value, only 
    /// callable by the owner.
    /// @param tokenURI_ A string value to replace the current `_tokenURI` value.
    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        _tokenURI = tokenURI_;
    }

    /// @notice Function used to get the total number of minted tokens.
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    /// @notice Function that is used to withdraw the total balance of the
    /// contract, only callable by the owner.
    function withdrawBalance() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    /// @notice Function used to get the tokens owned by a provided address.
    /// @param _address The specified address to perform a lookup for.
    /// @dev DO NOT CALL THIS FUNCTION ON-CHAIN.
    function getTokensOwnedByAddress(address _address) external view returns (uint[] memory) {
        uint tokenBalance = balanceOf(_address);

        if (tokenBalance == 0) {
            return new uint[](0);
        }

        uint[] memory tokensOwned = new uint[](tokenBalance);
        uint resultIndex = 0;

        for (uint i=1; i<=_tokenIdCounter.current(); i++) {
            if (ownerOf(i) == _address) {
                tokensOwned[resultIndex] = i;
                resultIndex++;
            }
        }

        return tokensOwned;
    }

    /// @notice Function used to get the tokens currently within the grace period.
    /// @dev DO NOT CALL THIS FUNCTION ON-CHAIN.
    function getTokensInGracePeriod() external view returns (uint[] memory) {
        uint tokenSupply = _tokenIdCounter.current();
        uint numTokens = 0;

        for (uint i=1; i<=tokenSupply; i++) {
            if (block.timestamp > expiryTime[i] && expiryTime[i] + gracePeriod > block.timestamp) {
                if (!isBanned[i]) {
                    numTokens++;
                }
            }
        }

        uint[] memory graceTokens = new uint[](numTokens);
        uint index = 0;

        for (uint i=1; i<=tokenSupply; i++) {
            if (block.timestamp > expiryTime[i] && expiryTime[i] + gracePeriod > block.timestamp) {
                if (!isBanned[i]) {
                    graceTokens[index] = i;
                    index++;
                }
            }
        }

        return graceTokens;
    }

    /// @notice Function that is used to safely transfer a token from one owner to another.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved.");
        if (owner() != msg.sender) {
            require(!isBanned[tokenId], "Token is banned.");
            require(expiryTime[tokenId] > block.timestamp, "Token has expired.");
        }
        _safeTransfer(from, to, tokenId, _data);
    }

    /// @notice Function that is used to transfer a token from one owner to another.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved.");
        if (owner() != msg.sender) {
            require(!isBanned[tokenId], "Token is banned.");
            require(expiryTime[tokenId] > block.timestamp, "Token has expired.");
        }
        _transfer(from, to, tokenId);
    }

}