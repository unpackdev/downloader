// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IERC721Receiver.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./DBH.sol";
import "./DBUX.sol";

contract Dojo is IERC721Receiver, Ownable, Pausable
{
    struct Stake {
        address owner;
        uint256 time;
    }

    event TokenStaked(address owner, uint256 tokenId);
    event TokenUnstaked(uint256 tokenId, uint256 earned);

    mapping(uint256 => Stake) public dojo;
    mapping(address => uint16[]) public ownedTokens;     // Mapping from owner to array of staked token IDs
    mapping(address => uint256) public ownedTokenCount;  // Mapping from owner to staked token count
    mapping(uint256 => uint256) public ownedTokensIndex; // Mapping from token ID to index in ownedTokens
    uint256 public dickbucksPerDay = 5000 ether;

    DBH dickbutt;
    DBUX dickbucks;

    constructor(address _dickbutt, address _dickbucks)
    {
        dickbutt = DBH(_dickbutt);
        dickbucks = DBUX(_dickbucks);
    }

    /**
    * Stakes Dickbutt Heroes tokens in the Dojo, earning DBUX in the process
    * @param tokenIds array of DBH token IDs owned by caller
    */
    function addDickbuttsToDojo(uint16[] calldata tokenIds) external whenNotPaused
    {
        for(uint i = 0; i < tokenIds.length; i++) {
            require(_msgSender() == dickbutt.ownerOf(tokenIds[i]), "Not your token");
            dickbutt.transferFrom(_msgSender(), address(this), tokenIds[i]);
            addDickbuttToDojo(_msgSender(), tokenIds[i]);
        }
    }

    /**
    * Unstakes Dickbutt Heroes tokens from the Dojo and credits owner with earned DBUX
    * @param tokenIds array of DBH token IDs owned by caller
    */
    function removeDickbuttsFromDojo(uint16[] calldata tokenIds) external whenNotPaused
    {
        for(uint i = 0; i < tokenIds.length; i++) {
            require(_msgSender() == dojo[tokenIds[i]].owner, "Can't touch this");
            dickbutt.transferFrom(address(this), dojo[tokenIds[i]].owner, tokenIds[i]);
            removeDickbuttFromDojo(tokenIds[i]);
        }
    }

    /**
    * Credits owner with earned DBUX
    * @param tokenIds array of DBH token IDs owned by caller
    */
    function collectDickbucks(uint16[] calldata tokenIds) external whenNotPaused
    {
        for(uint i = 0; i < tokenIds.length; i++) {
            require(_msgSender() == dojo[tokenIds[i]].owner, "Can't touch this");
            creditEarned(tokenIds[i]);
            dojo[tokenIds[i]].time = uint256(block.timestamp);
        }
    }

    /**
    * Used for rescuing Dickbutts in the event Dojo contract is permanently paused due
    * to deprecation. Note: DBUX are not credited when using this method.
    * @param tokenIds array of DBH token IDs owned by caller
    */
    function rescue(uint16[] calldata tokenIds) external whenPaused
    {
        for(uint i = 0; i < tokenIds.length; i++) {
            require(_msgSender() == dojo[tokenIds[i]].owner, "Can't touch this");
            dickbutt.transferFrom(address(this), dojo[tokenIds[i]].owner, tokenIds[i]);
            clearDojo(tokenIds[i], dojo[tokenIds[i]].owner);
        }
    }

    function pause() external onlyOwner
    {
        _pause();
    }

    function unpause() external onlyOwner
    {
        _unpause();
    }

    /**
    * Set the number of DBUX earned per day
    * @param _dickbucksPerDay DBUX earned per day in Wei-equivalent (1000000000000000000 = 1 DBUX)
    */
    function setDickbucksPerDay(uint256 _dickbucksPerDay) external onlyOwner
    {
        dickbucksPerDay = _dickbucksPerDay;
    }

    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4)
    {
        require(from == address(0x0), "Do not send to Dojo directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
    * Adds DBH token to Dojo, setting properties necessary to track ownership and DBUX earnings
    */
    function addDickbuttToDojo(address owner, uint256 tokenId) private
    {
        dojo[tokenId] = Stake({
            owner: owner,
            time : uint256(block.timestamp)
        });
        ownedTokensIndex[tokenId] = ownedTokens[owner].length;
        ownedTokens[owner].push(uint16(tokenId));
        ownedTokenCount[owner]++;
        emit TokenStaked(owner, tokenId);
    }

    /**
    * Removes DBH token from Dojo and credits owner with earned DBUX
    */
    function removeDickbuttFromDojo(uint256 tokenId) private
    {
        uint256 earned = creditEarned(tokenId);

        clearDojo(tokenId, dojo[tokenId].owner);
        
        emit TokenUnstaked(tokenId, earned);
    }

    /**
    * Credits owner with earned DBUX
    */
    function creditEarned(uint256 tokenId) private returns (uint256)
    {
        address owner = dojo[tokenId].owner;
        uint256 secondsStaked = uint256(block.timestamp) - uint256(dojo[tokenId].time);
        
        // DBUX earnings multiply by number of days staked up to a max of 5
        // i.e. 2 days staked = double earnings, 3 days staked = triple earnings, etc.
        uint256 multiplier = (secondsStaked / 86400) + 1;
        if(multiplier > 5) multiplier = 5;
        uint256 earned = (dickbucksPerDay / 86400) * secondsStaked * multiplier;

        uint256 rand = random(tokenId);
        // There is a 13% chance of DBH being "injured" per day staked, starting with day 2
        // and up to max of 52%. Injury may lead to some earned DBUX being forfeited.
        if((rand & 0xffff) % 100 < (multiplier - 1) * 13) {
            // 18% of earnings per day staked may potentially be forfeited (up to 5 days/90%)
            // i.e. 2 days staked = up to 36%, 3 days staked = up to 54%, etc.
            earned = (earned / 100) * (100 - (((rand >> 16) & 0xffff) % (multiplier * 18)));
        }

        if(earned > 0) {
            dickbucks.mint(owner, earned);
        }

        return earned;
    }

    /**
    * Clears properties tracking ownership and DBUX earnings
    */
    function clearDojo(uint256 tokenId, address owner) private
    {
        uint256 lastTokenIndex = ownedTokens[owner].length - 1;
        uint256 tokenIndex = ownedTokensIndex[tokenId];
        if(tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedTokens[owner][lastTokenIndex];
            ownedTokens[owner][tokenIndex] = uint16(lastTokenId);
            ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete ownedTokensIndex[tokenId];
        ownedTokens[owner].pop();
        ownedTokenCount[owner]--;
        delete dojo[tokenId];
    }

    function random(uint256 seed) internal view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
        )));
    }
}