// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20Burnable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IChains.sol";

contract BallerBars is Context, ERC20Burnable, Ownable {

    /**

     _______  ________ __    __      _______   ______  __       __       ________ _______
    |       \|        \  \  |  \    |       \ /      \|  \     |  \     |        \       \
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓\ | ▓▓    | ▓▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓     | ▓▓     | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓__   | ▓▓▓\| ▓▓    | ▓▓__/ ▓▓ ▓▓__| ▓▓ ▓▓     | ▓▓     | ▓▓__   | ▓▓__| ▓▓
    | ▓▓    ▓▓ ▓▓  \  | ▓▓▓▓\ ▓▓    | ▓▓    ▓▓ ▓▓    ▓▓ ▓▓     | ▓▓     | ▓▓  \  | ▓▓    ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓  | ▓▓\▓▓ ▓▓    | ▓▓▓▓▓▓▓\ ▓▓▓▓▓▓▓▓ ▓▓     | ▓▓     | ▓▓▓▓▓  | ▓▓▓▓▓▓▓\
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓ \▓▓▓▓    | ▓▓__/ ▓▓ ▓▓  | ▓▓ ▓▓_____| ▓▓_____| ▓▓_____| ▓▓  | ▓▓
    | ▓▓    ▓▓ ▓▓     \ ▓▓  \▓▓▓    | ▓▓    ▓▓ ▓▓  | ▓▓ ▓▓     \ ▓▓     \ ▓▓     \ ▓▓  | ▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓\▓▓   \▓▓     \▓▓▓▓▓▓▓ \▓▓   \▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓▓▓▓▓▓▓\▓▓   \▓▓

     _______  ______ _______       ________ __    __ ________
    |       \|      \       \     |        \  \  |  \        \
    | ▓▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓▓▓▓▓▓\     \▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓▓▓▓▓▓▓
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓__| ▓▓ ▓▓__
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓    ▓▓ ▓▓  \
    | ▓▓  | ▓▓ | ▓▓ | ▓▓  | ▓▓       | ▓▓  | ▓▓▓▓▓▓▓▓ ▓▓▓▓▓
    | ▓▓__/ ▓▓_| ▓▓_| ▓▓__/ ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓_____
    | ▓▓    ▓▓   ▓▓ \ ▓▓    ▓▓       | ▓▓  | ▓▓  | ▓▓ ▓▓     \
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓\▓▓▓▓▓▓▓         \▓▓   \▓▓   \▓▓\▓▓▓▓▓▓▓▓

     _______  __        ______   ______  __    __  ______  __    __  ______  ______ __    __
    |       \|  \      /      \ /      \|  \  /  \/      \|  \  |  \/      \|      \  \  |  \
    | ▓▓▓▓▓▓▓\ ▓▓     |  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\ ▓▓ /  ▓▓  ▓▓▓▓▓▓\ ▓▓  | ▓▓  ▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓\ | ▓▓
    | ▓▓__/ ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓   \▓▓ ▓▓/  ▓▓| ▓▓   \▓▓ ▓▓__| ▓▓ ▓▓__| ▓▓ | ▓▓ | ▓▓▓\| ▓▓
    | ▓▓    ▓▓ ▓▓     | ▓▓  | ▓▓ ▓▓     | ▓▓  ▓▓ | ▓▓     | ▓▓    ▓▓ ▓▓    ▓▓ | ▓▓ | ▓▓▓▓\ ▓▓
    | ▓▓▓▓▓▓▓\ ▓▓     | ▓▓  | ▓▓ ▓▓   __| ▓▓▓▓▓\ | ▓▓   __| ▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓ | ▓▓ | ▓▓\▓▓ ▓▓
    | ▓▓__/ ▓▓ ▓▓_____| ▓▓__/ ▓▓ ▓▓__/  \ ▓▓ \▓▓\| ▓▓__/  \ ▓▓  | ▓▓ ▓▓  | ▓▓_| ▓▓_| ▓▓ \▓▓▓▓
    | ▓▓    ▓▓ ▓▓     \\▓▓    ▓▓\▓▓    ▓▓ ▓▓  \▓▓\\▓▓    ▓▓ ▓▓  | ▓▓ ▓▓  | ▓▓   ▓▓ \ ▓▓  \▓▓▓
     \▓▓▓▓▓▓▓ \▓▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓▓ \▓▓   \▓▓ \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓   \▓▓\▓▓▓▓▓▓\▓▓   \▓▓

    **/

    // RGV2YmVycnkjNDAzMCBhbmQgcG9ua3lwaW5rIzc5MTMgd2VyZSBoZXJl

    // Constants
    uint256 public constant SECONDS_IN_A_DAY = 86400;

    // Public variables
    uint256 public _emissionStart;
    uint256 public _emissionEnd = 1735689661;
    uint256 public _emissionOffset = 0;
    uint256 public _baseMultiplier = 10;

    bool public _paused = true;

    mapping(uint256 => uint256) private _lastClaim;

    address public _genOneChainsAddress;
    address public _genTwoChainsAddress;

    constructor() ERC20("BallerBars", "BB") {
        _emissionStart = block.timestamp;
    }

    /**
     * @dev Returns the time rewards were last claimed
     * @param _tokenId The token to reference
     */

    function lastClaim(uint256 _tokenId) public view returns (uint256) {
        return __lastClaim(_tokenId,getChainsContract(getChainsGeneration(_tokenId)));
    }

    /**
     * @dev Returns the time rewards were last claimed
     * @param _tokenId The token to reference
     * @param chainsContract The chains token contract
     */

    function __lastClaim(uint256 _tokenId, IChains chainsContract) internal view returns (uint256) {

        require(chainsContract.ownerOf(_tokenId) != address(0),"TOKEN_NOT_MINTED");

        uint256 lastClaimed = _lastClaim[_tokenId];

        if(lastClaimed == 0 || lastClaimed < _emissionStart){

            uint256 mintedAt = chainsContract.getTokenTimestamp(_tokenId);

            if(mintedAt<_emissionStart){
                lastClaimed = _emissionStart;
            }else{
                lastClaimed = mintedAt;
            }
        }

        return lastClaimed + _emissionOffset;
    }

    /**
     * @dev Returns the amount of rewards accumulated since last claim for token
     * @param _tokenId The token to reference
     */

    function accumulated(uint256 _tokenId) public view returns (uint256) {
        return _accumulated(_tokenId,getChainsContract(getChainsGeneration(_tokenId)));
    }


    /**
     * @dev Returns the amount of rewards accumulated since last claim for token
     * @param _tokenId The token to reference
     * @param chainsContract The chains contract to reference
     */

    function _accumulated(uint256 _tokenId, IChains chainsContract) internal view returns (uint256) {

        uint256 lastClaimed = __lastClaim(_tokenId,chainsContract);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= _emissionEnd) return 0;

        uint256 accumulationPeriod = block.timestamp < _emissionEnd ? block.timestamp : _emissionEnd;

        uint256 tokenEmissionPerDay = (0.1 ether + ((33 ether / 1000) * _getBoost(_tokenId,chainsContract))) * _baseMultiplier;

        uint256 totalAccumulated = ((accumulationPeriod - lastClaimed) * tokenEmissionPerDay) / SECONDS_IN_A_DAY;

        return totalAccumulated;
    }

    /**
     * @dev Returns the rewards boost for token
     * @param _tokenId The token to reference
     */

    function getBoost(uint256 _tokenId) public view returns (uint256) {
        return _getBoost(_tokenId,getChainsContract(getChainsGeneration(_tokenId)));
    }

    /**
     * @dev Returns the rewards boost for token
     * @param _tokenId The token to reference
     * @param chainsContract The chains contract to reference
     */

    function _getBoost(uint256 _tokenId, IChains chainsContract) internal view returns (uint256){
        if(_tokenId < 3406) {
            return chainsContract.getTokenRarityCount(_tokenId);
        }
        return _calculateBoost(chainsContract._tokenIdToHash(_tokenId));
    }

    /**
     * @dev Returns the rewards boost for token hash
     * @param _hash The token hash to calculate boost for
     */

    function _calculateBoost(string memory _hash) public pure returns (uint256){

        require(bytes(_hash).length==7,"INVALID_LENGTH");

        bytes32 hash = bytes32(bytes(_hash));

        uint256 boost = 8;  // Base is 8

        uint8 t1 = uint8(hash[1]);

        if(t1<50){     // Clarity
            if(
                t1==48 // Flawless
            ){
                boost += 10;
            }else if(
                t1==49 // Very^2 slightly included
            ){
                boost += 8;
            }
        }

        uint8 t2 = uint8(hash[2]);

        if(t2<51){     // Gem
            if(
                t2==48 // Canary Diamond
            ){
                boost += 10;
            }else if(
                t2==49 // Oval Diamond
            ){
                boost += 8;
            }else if(
                t2==50 // Radiant Ruby
            ){
                boost += 6;
            }
        }

        uint8 t3 = uint8(hash[3]);

        if(t3<52){     // Chain Gems
            if(
                t3==48 // Black Diamond
            ){
                boost += 10;
            }else if(
                t3==49 // Pink Diamond
            ){
                boost += 8;
            }else if(
                t3==50 // Diamond
            ){
                boost += 6;
            }else if(
                t3==51 // Ruby
            ){
                boost += 4;
            }
        }

        uint8 t4 = uint8(hash[4]);

        if(t4<51){     // Chain
            if(
                t4==48 // Mariner Glitch
            ){
                boost += 10;
            }else if(
                t4==49 // Braid Rose Gold
            ){
                boost += 8;
            }else if(
                t4==50 // Mariner Yellow Gold
            ){
                boost += 6;
            }
        }

        uint8 t5 = uint8(hash[5]);

        if(t5<55){     // Watermark
            if(
                t5==48 // BB
            ){
                boost += 10;
            }else if(
                t5==49 // DAI
            ){
                boost += 8;
            }else if(
                t5==50 // Square
            ){
                boost += 6;
            }else if(
                t5==51 // Radiant
            ){
                boost += 6;
            }else if(
                t5==52 // Butterfly
            ){
                boost += 6;
            }else if(
                t5==53 // Music
            ){
                boost += 4;
            }else if(
                t5==54 // Dollar
            ){
                boost += 2;
            }
        }

        uint8 t6 = uint8(hash[6]);

        if(t6<55){     // Background
            if(
                t6==48 // Gold
            ){
                boost += 10;
            }else if(
                t6==49 // Royal Blue
            ){
                boost += 8;
            }else if(
                t6==50 // Turquoise
            ){
                boost += 6;
            }else if(
                t6==51 // Graphite
            ){
                boost += 6;
            }else if(
                t6==52 // Peach
            ){
                boost += 6;
            }else if(
                t6==53 // Periwinkle
            ){
                boost += 4;
            }else if(
                t6==54 // Gainsboro
            ){
                boost += 2;
            }
        }

        return boost;
    }

    /**
     * @dev Sets chain contracts address based on generation
     * @param chainsAddress The chains contract address
     * @param generation The generation of chains contract
     */

    function setChainsAddress(address chainsAddress,uint256 generation) onlyOwner public {
        require(generation==1||generation==2,"INVALID_GEN");
        if(generation == 1){
            _genOneChainsAddress = chainsAddress;
        }else if(generation == 2){
            _genTwoChainsAddress = chainsAddress;
        }
    }

    /**
     * @dev Changes the last time of the BB emission.
     * @param emissionEnd The time, in seconds, emissions will end
     */

    function setEmissionEnd(uint256 emissionEnd) onlyOwner public {
        _emissionEnd = emissionEnd;
    }

    /**
     * @dev Changes the offset for emissions in-case of emergency pausing / un-pausing
     * @param emissionOffset The time, in seconds, emissions will offset
     */

    function setEmissionOffset(uint256 emissionOffset) onlyOwner public {
        require(_emissionStart+emissionOffset<=block.timestamp,"OFFSET_TOO_HIGH");
        _emissionOffset = emissionOffset;
    }

    /**
     * @dev Changes base multiplier for rewards calculation.
     * @param baseMultiplier The base multiplier. Default is 5 (0.5) (50%)
     */

    function setBaseMultiplier(uint256 baseMultiplier) onlyOwner public {
        _baseMultiplier = baseMultiplier;
    }

    /**
     * @dev Toggles pause status
     */

    function togglePauseStatus() external onlyOwner {
        _paused = !_paused;
    }

    /**
     * @dev Claims rewards for tokens
     * @param _tokenIds An array of tokens to claim rewards for
     */

    function claim(uint256[] memory _tokenIds) public returns (uint256) {

        require(_paused==false,"PAUSED");

        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {

            IChains chainsContract = getChainsContract(getChainsGeneration(_tokenIds[i]));

            require(
                chainsContract.ownerOf(_tokenIds[i])==msg.sender,
                "NOT_TOKEN_OWNER"
            );

            // Duplicate token index check
            for (uint256 j = i + 1; j < _tokenIds.length; j++) {
                require(
                    _tokenIds[i] != _tokenIds[j],
                    "DUP_TOKEN_INDEX"
                );
            }

            uint256 claimQty = _accumulated(_tokenIds[i],chainsContract);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty + claimQty;
                _lastClaim[_tokenIds[i]] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "ZERO_CLAIMABLE");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    /**
     * @dev Returns generation of chain based on token id
     * @param _tokenId The token to reference
     */

    function getChainsGeneration(uint256 _tokenId) public view returns (uint256) {
        try IChains(_genTwoChainsAddress).ownerOf(_tokenId) returns (address genTwoOwner){
            if (genTwoOwner != 0x000000000000000000000000000000000000dEaD) {
                return 2;
            }
        }catch{
            if(_tokenId < 3406) {
                try IChains(_genOneChainsAddress).ownerOf(_tokenId) returns (address genOneOwner){
                    if (genOneOwner != 0x000000000000000000000000000000000000dEaD) {
                        return 1;
                    }
                }catch{
                    // Do nothing
                }
            }
        }
        return 0;
    }

    /**
     * @dev Returns chains contract address based on generation
     * @param generation The generation of contract to return. 1 or 2
     */

    function getChainsAddress(uint256 generation) internal view returns (address) {
        if(generation == 1){
            return _genOneChainsAddress;
        }
        if(generation == 2){
            return _genTwoChainsAddress;
        }
        revert("INVALID_GEN");
    }

    /**
     * @dev Returns chains contract based on generation
     * @param generation The generation of contract to return. 1 or 2
     */

    function getChainsContract(uint256 generation) internal view returns (IChains) {
        return IChains(getChainsAddress(generation));
    }

    /**
     * @dev Burns amount of BB for account
     * @param account Address to burn BB for
     * @param amount Amount of BB to burn
     */

    function burnFrom(address account, uint256 amount) public override {
        if (_msgSender() == _genTwoChainsAddress) {
            _burn(account, amount);
        }
        else {
            super.burnFrom(account, amount);
        }
    }

}
