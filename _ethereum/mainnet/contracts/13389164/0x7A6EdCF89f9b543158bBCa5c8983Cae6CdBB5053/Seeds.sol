// contracts/Seed.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";
import "./FruitsLibrary.sol";

contract Seeds is ERC20Burnable, Ownable {

    using SafeMath for uint256;

    /**
    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
    MMMMMMMMMMMMWKkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkKWMMMMMMMMMMMM
    MMMMMMMMWKOkdc'..................................'cdkOKWMMMMMMMM
    MMMMMMWKx:...',;,'''''''''''''''''''''''''''''',;,'...:xKWMMMMMM
    MMMMWKx:......',;;,,'''''''''''''''''''''''',,;;,'......:xKWMMMM
    MMWKx:..........',;;,,,,,,,,,,,,,,,,,,,,,,,,;;,'..........:xKWMM
    WKx:..............',;:;;;;;;;;;;;;;;;;;;;;:;,'..............:xKW
    No............................................................oN
    Xl. ..........''''''''''''''''''''''''''''''''''''.......... .lX
    Xl. ........,oO0000000000000000000000000000000000Oo,........ .lX
    Xl. ......,oOKKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKKOo,...... .lX
    Xl. ... .:kKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKk:. ... .lX
    Xl. ... .:OXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXO:. ... .lX
    Xl. ... .:OXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXO:. ... .lX
    Xl. ... .:OXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXO:. ... .lX
    Xl. ... .:OXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXO:. ... .lX
    Xl. ... .:OXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXO:. ... .lX
    Xl. ... .:OXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXO:. ... .lX
    Xl. ... .:OXXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXXO:. ... .lX
    Xl. .....,oOKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKOo,..... .lX
    Xl. ..... .c0XXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXX0c. ..... .lX
    Xl. .......,oOKXKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKXKOo,....... .lX
    Xl. .........,oOKXXKKKKKKKKKKKKKKKKKKKKKKKKKKXXKOo,......... .lX
    Xl. ...........,oOKXKKKKKKKKKKKKKKKKKKKKKKKKXKOo,........... .lX
    Xl. .............,oOKXXXXXXXXXXXXXXXXXXXXXXKOo,............. .lX
    Nk:................,looooooooooooooooooooool,................:kN
    MWKc. .................................................... .cKWM
    MMNk:..............,;;;;;;;;;;;;;;;;;;;;;;;;,..............:kNMM
    MMMWXx;.............','''''''''''''''''''','.............;xXWMMM
    MMMMMWXx:...........''''''''''''''''''''''''...........:xXWMMMMM
    MMMMMMMWXx:;,......................................,;:xXWMMMMMMM
    MMMMMMMMMWNX0c.                                  .c0XNWMMMMMMMMM

    :cheese::astronaut::cheese: RIP 7767 :cheese::astronaut::cheese:
    **/

    // uint256 public MAX_WALLET_STAKED = 24;
    // uint256 public EMISSIONS_RATE = 11574070000000;
    // uint256 public CLAIM_END_TIME = 1641013200;

    address nullAddress = 0x0000000000000000000000000000000000000000;

    address[] public fruitAddresses;

    //Mapping of contract to max wallet staked
    mapping(address => uint256) internal maxWalletStaked;

    //Mapping of contract to emissions rate
    mapping(address => uint256) internal emissionsRate;

    //Mapping of contract to claim end time
    mapping(address => uint256) internal claimEndTime;

    //Mapping of contract to fruit to timestamp
    mapping(address => mapping(uint256 => uint256)) internal tokenIdToTimeStamp;

    //Mapping of contract to fruit to staker
    mapping(address => mapping(uint256 => address)) internal tokenIdToStaker;

    //Mapping of contract to staker to fruits
    mapping(address => mapping(address => uint256[])) internal stakerToTokenIds;

    constructor() ERC20("Seeds", "SEEDS") {}

    function addFruitAddress(address _fruitAddress, uint256 _maxWalletStaked, uint256 _emissionsRate, uint256 _claimEndTime) public onlyOwner {
        require(!isFruitAddress(_fruitAddress),"Phew... That would've been a #7767 moment! :pepega:");
        fruitAddresses.push(_fruitAddress);
        maxWalletStaked[_fruitAddress] = _maxWalletStaked;
        emissionsRate[_fruitAddress] = _emissionsRate;
        claimEndTime[_fruitAddress] = _claimEndTime;
        return;
    }

    function isFruitAddress(address _fruitAddress) public view returns (bool){
        return getFruitIndex(_fruitAddress) != 999;
    }

    function getFruitIndex(address _fruitAddress) public view returns (uint256){
        for(uint256 i = 0; i < fruitAddresses.length; i++){
            if(fruitAddresses[i] == _fruitAddress){
                return i;
            }
        }
        return 999;
    }

    function getFruitClaimEndTime(address _fruitAddress) public view returns(uint256) {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        return claimEndTime[_fruitAddress];
    }

    function getFruitEmissionsRate(address _fruitAddress) public view returns(uint256) {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        return emissionsRate[_fruitAddress];
    }

    function getFruitMaxWalletStaked(address _fruitAddress) public view returns(uint256) {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        return maxWalletStaked[_fruitAddress];
    }

    function getTokensStaked(address _fruitAddress, address staker)
    public
    view
    returns (uint256[] memory)
    {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        return stakerToTokenIds[_fruitAddress][staker];
    }

    function remove(address _fruitAddress, address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[_fruitAddress][staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[_fruitAddress][staker].length - 1; i++) {
            stakerToTokenIds[_fruitAddress][staker][i] = stakerToTokenIds[_fruitAddress][staker][i + 1];
        }
        stakerToTokenIds[_fruitAddress][staker].pop();
    }

    function removeTokenIdFromStaker(address _fruitAddress, address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[_fruitAddress][staker].length; i++) {
            if (stakerToTokenIds[_fruitAddress][staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(_fruitAddress, staker, i);
            }
        }
    }

    function stakeByIds(address _fruitAddress, uint256[] memory tokenIds) public {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        require(
            stakerToTokenIds[_fruitAddress][msg.sender].length + tokenIds.length <=
            maxWalletStaked[_fruitAddress],
            string(abi.encodePacked("Must have less than ",FruitsLibrary.toString(maxWalletStaked[_fruitAddress])," fruits staked!"))
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(_fruitAddress).ownerOf(tokenIds[i]) == msg.sender &&
                tokenIdToStaker[_fruitAddress][tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721(_fruitAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[_fruitAddress][msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[_fruitAddress][tokenIds[i]] = block.timestamp;
            tokenIdToStaker[_fruitAddress][tokenIds[i]] = msg.sender;
        }
    }

    function unstakeAll(address _fruitAddress) public {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        require(
            stakerToTokenIds[_fruitAddress][msg.sender].length > 0,
            "Must have at least one token staked!"
        );
        uint256 totalRewards = 0;

        for (uint256 i = stakerToTokenIds[_fruitAddress][msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[_fruitAddress][msg.sender][i - 1];

            IERC721(_fruitAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards =
            totalRewards +
            ((block.timestamp - tokenIdToTimeStamp[_fruitAddress][tokenId]) *
            emissionsRate[_fruitAddress]);

            removeTokenIdFromStaker(_fruitAddress, msg.sender, tokenId);

            tokenIdToStaker[_fruitAddress][tokenId] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }

    function unstakeByIds(address _fruitAddress, uint256[] memory tokenIds) public {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[_fruitAddress][tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(_fruitAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards =
            totalRewards +
            ((block.timestamp - tokenIdToTimeStamp[_fruitAddress][tokenIds[i]]) *
            emissionsRate[_fruitAddress]);

            removeTokenIdFromStaker(_fruitAddress, msg.sender, tokenIds[i]);

            tokenIdToStaker[_fruitAddress][tokenIds[i]] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }

    function claimByTokenId(address _fruitAddress, uint256 tokenId) public {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        require(
            tokenIdToStaker[_fruitAddress][tokenId] == msg.sender,
            "Token is not claimable by you!"
        );
        require(block.timestamp < claimEndTime[_fruitAddress], "Claim period is over!");

        _mint(
            msg.sender,
            ((block.timestamp - tokenIdToTimeStamp[_fruitAddress][tokenId]) * emissionsRate[_fruitAddress])
        );

        tokenIdToTimeStamp[_fruitAddress][tokenId] = block.timestamp;
    }

    function claimAll(address _fruitAddress) public {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        require(block.timestamp < claimEndTime[_fruitAddress], "Claim period is over!");
        uint256[] memory tokenIds = stakerToTokenIds[_fruitAddress][msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[_fruitAddress][tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            totalRewards =
            totalRewards +
            ((block.timestamp - tokenIdToTimeStamp[_fruitAddress][tokenIds[i]]) *
            emissionsRate[_fruitAddress]);

            tokenIdToTimeStamp[_fruitAddress][tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function getAllRewards(address _fruitAddress, address staker) public view returns (uint256) {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        uint256[] memory tokenIds = stakerToTokenIds[_fruitAddress][staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards =
            totalRewards +
            ((block.timestamp - tokenIdToTimeStamp[_fruitAddress][tokenIds[i]]) *
            emissionsRate[_fruitAddress]);
        }

        return totalRewards;
    }

    function getRewardsByTokenId(address _fruitAddress, uint256 tokenId)
    public
    view
    returns (uint256)
    {
        require(isFruitAddress(_fruitAddress),"Fruit contract address must be valid!");
        require(
            tokenIdToStaker[_fruitAddress][tokenId] != nullAddress,
            "Token is not staked!"
        );

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[_fruitAddress][tokenId];

        return secondsStaked * emissionsRate[_fruitAddress];
    }

    function getStaker(address _fruitAddress, uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[_fruitAddress][tokenId];
    }
}
