// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./INFTree.sol";
import "./IERC20.sol";
import "./Ownable.sol";

//               ,@@@@@@@,
//       ,,,.   ,@@@@@@/@@,  .oo8888o.
//    ,&%%&%&&%,@@@@@/@@@@@@,8888\88/8o
//   ,%&\%&&%&&%,@@@\@@@/@@@88\88888/88'
//   %&&%&%&/%&&%@@\@@/ /@@@88888\88888'
//   %&&%/ %&%%&&@@\ V /@@' `88\8 `/88'
//   `&%\ ` /%&'    |.|        \ '|8'
//       |o|        | |         | |
//       |.|        | |         | |
//    \\/ ._\//_/__/  ,\_//__\\/.  \_//__/_

/**  
    @title NFTreeFactory
    @author Lorax + Bebop
    @notice Enables the purchase/minting of Genesis Colletion NFTrees.
 */

contract NFTreeFactory is Ownable {

    INFTree nftree;
    address treasury;
    uint256[] levels;
    string[] coins;
    bool public isLocked;

    mapping(uint256 => Level) levelMap;
    mapping(string => Coin) coinMap;

    struct Level {
        bool isValid;
        uint256 cost;
        uint256 carbonValue;
        uint256 numMinted;
        string tokenURI;
    }

    struct Coin {
        bool isValid;
        IERC20 coinContract;
    }

    /**
        @dev Sets values for {nftree} and {treasury}.
        @param _nftreeAddress NFTree contract address.
        @param _treasuryAddress NFTrees vault wallet address.
     */
    constructor(address _nftreeAddress, address _treasuryAddress)
    {   
        nftree = INFTree(_nftreeAddress);
        treasury = _treasuryAddress;
        isLocked = false;
    }

    /**
        @dev Locks/unlocks minting.
     */
    function toggleLock() external onlyOwner {
        isLocked = !isLocked;
    }

    /**
        @dev Updates {nftree} contract address.
        @param _nftreeAddress New NFTree contract address.
     */
    function setNFTreeContract(address _nftreeAddress) external {
        nftree = INFTree(_nftreeAddress);
    }

    /**
        @dev Retrieves current NFTree contract instance.
        @return INFTree {nftree}.
     */
    function getNFTreeContract() external view returns(INFTree) {
        return nftree;
    }

    /**
        @dev Updates {treasury} wallet address.
        @param _address New NFTrees vault wallet address.
     */
    function setTreasury(address _address) external onlyOwner {
        treasury = _address;
    }
    
    /**
        @dev Retrieves current NFtree vault wallet address.
        @return address {treasury}.
     */
    function getTreasury() external view onlyOwner returns(address) {
        return treasury;
    }

    /**
        @dev Creates new Level instance and maps to the {levels} array. If the level already exists,
        the function updates the struct but does not push to the levels array.
        @param _level Carbon value.
        @param _cost Cost of level.
        @param _tokenURI IPFS hash of token metadata.
     */
    function addLevel(uint256 _level, uint256 _cost, string memory _tokenURI) external onlyOwner {
        if (!levelMap[_level].isValid) {
            levels.push(_level);
        }
            
        levelMap[_level] = Level(true, _cost, _level, 0, _tokenURI);
    }

    /**
        @dev Deletes Level instance and removes from {levels} array.
        @param _level Carbon value of level to be removed.

        requirements: 
            - {_level} must be a valid level.

     */
    function removeLevel(uint256 _level) external onlyOwner {
        require(levelMap[_level].isValid, 'Not a valid level.');

        uint256 index;

        for (uint256 i = 0; i < levels.length; i++) {
            if (levels[i] == _level){
                index = i;
            }
        }

        levels[index] = levels[levels.length - 1];

        levels.pop();
        delete levelMap[_level];
    }

    /**
        @dev Retrieves variables in that carbon value's Level struct.
        @param _level Carbon value of level to be returned.
        @return uint256 {levelMap[_level].cost}.
        @return uint256 {levelMap[_level].carbonValue}.
        @return uint256 {levelMap[_level].numMinted}.

        requirements:
            - {_level} must be a valid level.
     */
    function getLevel(uint256 _level) external view returns(uint256, uint256, uint256, string memory) {
        require(levelMap[_level].isValid, 'Not a valid level');
        return (levelMap[_level].carbonValue, levelMap[_level].cost, levelMap[_level].numMinted, levelMap[_level].tokenURI);
    }

    /**
        @dev Retrieves array of valid levels.
        @return uint256[] {levels}.
     */
    function getValidLevels() external view returns(uint256[] memory) {
        return sort_array(levels);
    }

    /**
        @dev Creates new Coin instance and maps to the {coins} array.
        @param _coin Coin name.
        @param _address Contract address for the coin.

        Requirements:
            - {_coin} must not already be a valid coin.
     */
    function addCoin(string memory _coin, address _address) external onlyOwner {
        require(!coinMap[_coin].isValid, 'Already a valid coin.');

        coins.push(_coin);
        coinMap[_coin] = Coin(true, IERC20(_address));

    }

    /**
        @dev Deletes Coin instance and removes from {coins} array.
        @param _coin Name of coin.

        requirements: 
            - {_coin} must be a valid coin.
     */
    function removeCoin(string memory _coin) external onlyOwner {
        require(coinMap[_coin].isValid, 'Not a valid coin.');

        uint256 index;

        for (uint256 i = 0; i < coins.length; i++) {
            if (keccak256(abi.encodePacked(coins[i])) == keccak256(abi.encodePacked(_coin))) {
                index = i;
            }
        }

        coins[index] = coins[coins.length - 1];

        coins.pop();
        delete coinMap[_coin];
    }

    /**
        @dev Retrieves array of valid coins.
        @return uint256[] {coins}.
     */
    function getValidCoins() external view returns(string[] memory) {
        return coins;
    }

    /**
        @dev Mints NFTree to {msg.sender} and transfers payment to {treasury}. 
        @param _tonnes Carbon value of NFTree to purchase.
        @param _amount Dollar value to be transferred to {treasury} from {msg.sender}.
        @param _coin Coin to be used to purchase.

        Requirements:
            - {isLocked} must be false, mint lock must be off.
            - {msg.sender} can not be the zero address.
            - {_level} must be a valid level.
            - {_coin} must be a valid coin.
            - {_amount} must be creater than the cost to mint that level.
            - {msg.sender} must have a balance of {_coin} that is greater than or equal to {_amount}.
            - Allowance of {address(this)} to spend {msg.sender}'s {_coin} must be greater than or equal to {_amount}.

     */
    function mintNFTree(uint256 _tonnes, uint256 _amount, string memory _coin) external {
        // check requirements
        require(!isLocked, 'Minting is locked.');
        require(msg.sender != address(0) && msg.sender != address(this), 'Sending from zero address.'); 
        require(levelMap[_tonnes].isValid, 'Not a valid level.');
        require(coinMap[_coin].isValid, 'Not a valid coin.');
        require(_amount >= levelMap[_tonnes].cost, 'Not enough value.');
        require(coinMap[_coin].coinContract.balanceOf(msg.sender) >= _amount, 'Not enough balance.');
        require(coinMap[_coin].coinContract.allowance(msg.sender, address(this)) >= _amount, 'Not enough allowance.');
        
        // transfer tokens
        coinMap[_coin].coinContract.transferFrom(msg.sender, treasury, _amount * 1e18);
        nftree.mintNFTree(msg.sender, levelMap[_tonnes].tokenURI, _tonnes, "Genesis");
        
        // log purchase
        levelMap[_tonnes].numMinted += 1;
    }

    /**
        @dev Sorts array.
        @return uint256[] {arr}.
     */
    function sort_array(uint256[] memory arr) private pure returns (uint256[] memory) {
        uint256 l = arr.length;
        for(uint i = 0; i < l; i++) {
            for(uint j = i+1; j < l ;j++) {
                if(arr[i] > arr[j]) {
                    uint256 temp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = temp;
                }
            }
        }
        return arr;
    }
}
