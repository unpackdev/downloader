// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./PausableClaim.sol";
import "./VaccineClaimSnapshot.sol";

abstract contract VaccineSelling is ERC1155, Ownable, Pausable, PausableClaim, VaccineClaimSnapshot {
    using Strings for uint256;
    // 1 = vaccine with 25%
    // 2 = vaccine with 50%
    // 3 = vaccine with 100%
    uint constant maxTokenId = 3;
    uint constant maxTotalSupply = 1200;
    uint[] supplyById;
    uint constant singleTokenPrice = 32100000 gwei;  // 0.0321 eth
    uint constant maxTokensToBuyAtOnce = 10;
    uint maxCurrentSupply = 0;
    uint totalMinted = 0;
    
    string _contractURI = "https://api.pork1984.io/contract/vaccine";
    
    constructor() ERC1155("https://api.pork1984.io/api/vaccine/token/") {
        _pause();
        supplyById = new uint[](maxTokenId + 1);
    }
    
    function getMaxTotalSupply() public pure returns(uint) {
        return maxTotalSupply;
    }
    
    function getMaxCurrentSupply() public view returns(uint) {
        return maxCurrentSupply;
    }
    
    function getSupplyById(uint256 id) public view returns(uint) {
        return supplyById[id];
    }
    
    function _isValidTokenId(uint256 tokenId) internal pure returns(bool) {
        return tokenId > 0 && tokenId <= maxTokenId;
    }
    
    function addForSale(uint256 id, uint amountToAdd) public onlyOwner {
        maxCurrentSupply += amountToAdd;
        require(maxCurrentSupply <= maxTotalSupply);
        
        supplyById[id] += amountToAdd;
    }
    
    function removeFromSale(uint256 id) public onlyOwner {
        require(supplyById[id] > 0);
        maxCurrentSupply -= supplyById[id];
        supplyById[id] = 0;
    }
    
    function leftForSale() public view returns(uint) {
        return maxCurrentSupply - totalMinted;
    }
    
    function howManyFreeTokens() public view returns (uint8) {
        return howManyFreeTokensForAddress(msg.sender);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function pauseClaim() public onlyOwner {
        _pauseClaim();
    }

    function unpauseClaim() public onlyOwner {
        _unpauseClaim();
    }
    
    function _calculateAmountsToBuy(uint256 totalAmount, uint256[] memory ids, uint256[] memory amounts) private {
        require(ids.length == amounts.length);
        require(ids.length == maxTokenId);
        
        for (uint256 tokenId = 1; tokenId <= maxTokenId; tokenId++) {
            ids[tokenId - 1] = tokenId;
            amounts[tokenId - 1] = 0;
        }
        
        for (uint256 i = 0; i < totalAmount; i++) {
            uint256 rnd = _getRandomInteger(i) % leftForSale();
            uint256 accumulator = 0;
            for (uint256 tokenId = 1; tokenId <= maxTokenId; tokenId++) {
                accumulator += supplyById[tokenId];
                if (rnd < accumulator) {
                    amounts[tokenId - 1] += 1;
                    _registerMint(tokenId, 1);
                    break;
                }
            }
        }
    }
    
    function _getRandomInteger(uint256 salt) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, salt)));
    }

    function buy(uint256 tokensToBuy) public payable whenNotPaused {
        require(tokensToBuy <= maxTokensToBuyAtOnce, "Cannot buy that many tokens at once");
        require(msg.value >= singleTokenPrice * tokensToBuy, "Insufficient funds sent.");
        _internalMint(tokensToBuy);
    }
    
    function claim() public whenClaimNotPaused {
        uint256 tokensToMint = howManyFreeTokens();
        _internalMint(tokensToMint);
        _cannotClaimAnymore(msg.sender);
    }
    
    function _internalMint(uint256 tokensToMint) internal {
        require(tokensToMint > 0, "Cannot mint 0 tokens");
        require(leftForSale() >= tokensToMint, "Not enough tokens left on sale");
        
        uint256[] memory ids = new uint256[](maxTokenId);
        uint256[] memory amounts = new uint256[](maxTokenId);
        
        _calculateAmountsToBuy(tokensToMint, ids, amounts);
        
        _mintBatch(msg.sender, ids, amounts, "100500");
    }
    
    function giveaway(address account, uint256 id, uint256 amount) public onlyOwner {
        require(amount > 0, "Cannot give 0 tokens");
        require(leftForSale() >= amount, "Not enough tokens left on sale");
        require(supplyById[id] >= amount, "Not enough tokens left on sale");
        
        _registerMint(id, amount);
        _mint(account, id, amount, "100500");
    }
    
    function _registerMint(uint256 tokenId, uint256 amount) private {
        totalMinted += amount;
        supplyById[tokenId] -= amount;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        require(_isValidTokenId(_id), "Vaccine#uri: NONEXISTENT_TOKEN");
        string memory baseURI = super.uri(_id);
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, _id.toString()))
            : '';
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setContractURI(string memory newURI) public onlyOwner {
        _contractURI = newURI;
    }
    
    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }
    
    function withdraw(address sendTo) public payable onlyOwner {
        uint balance = address(this).balance;
        
        uint share = 25;  // 25 * 0.001 = 2.5%
        uint ethShare = balance * share / 1000;
        for (uint i = 0; i < _snapshotAddresses.length; i++) {
            payable(_snapshotAddresses[i]).transfer(ethShare);
        }
        
        balance -= ethShare * _snapshotAddresses.length;
        
        payable(sendTo).transfer(balance);
    }
}
