// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./Math.sol";

interface IObelisk {
    function burn(address from, uint256 id, uint256 amount) external;
}

interface IVRFv2SubscriptionManager {
    function requestRandomWords() external returns(uint256);
}

contract Land is ERC1155, Ownable {

    using Strings for uint256;

    string public constant NAME = "Land";
    string public constant SYMBOL = "LAND";
    string public baseTokenURI;

    address public tropyAddress;
    address public obeliskAddress;

    uint256 private oneDay = 1 days;
    
    uint256 public maxSupply = 500;
    uint256[] public maxSupplyperID = [200, 150, 100, 40, 10];
    uint256[] public rewardRate = [100000000000000000000, 110000000000000000000, 125000000000000000000, 150000000000000000000, 200000000000000000000];
    uint256 public maxTokenID = 5;
    uint256 public tropyAmountToMint = 1000000000000000000000;
    uint256 public totalMinted = 0;
    bool public paused = false;

    mapping(address => uint256) public amountPerWallets;
    address public stakingAddress = address(0);

    struct HOLDINFO{
        uint256 rewardLockup;
        uint256 depositTime;
    }
    mapping(address => mapping(uint256 => HOLDINFO)) public holdInfo;
    mapping(address => uint256) public genesisInfo;  

    IVRFv2SubscriptionManager public vrfRandomGenerator;

    modifier onlyNotPaused() {
        require(!paused, '1');
        _;
    }
    modifier onlyStakingContract() {
        require(msg.sender == stakingAddress, 'Only Staking contract can call this function.');
        _;
    }
    event TropyAddressChanged(address indexed owner, address indexed tropyAddress);
    event StakingAddressChanged(address indexed owner, address indexed stakingAddress);
    event ObeliskAddressChanged(address indexed owner, address indexed obeliskAddress);

    constructor(string memory _baseTokenURI, address _tropyAddress, address _obeliskAddress, address _vrfRandomGenerator) ERC1155(_baseTokenURI) {
        setBaseURI(_baseTokenURI);
        changeTropyAddress(_tropyAddress);
        changeObeliskAddress(_obeliskAddress);
        vrfRandomGenerator = IVRFv2SubscriptionManager(_vrfRandomGenerator);
    }
        
    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function changeTropyAddress(address _tropyAddress) public onlyOwner {
        require(_tropyAddress != address (0), "ZeroAddress is not available");
        tropyAddress = _tropyAddress;
        emit TropyAddressChanged(msg.sender, tropyAddress);
    }
    function changeObeliskAddress(address _obeliskAddress) public onlyOwner {
        require(_obeliskAddress != address (0), "ZeroAddress is not available");
        obeliskAddress = _obeliskAddress;
        emit ObeliskAddressChanged(msg.sender, obeliskAddress);
    }
    function changeStakingAddress(address _stakingAddress) public onlyOwner {
        require(_stakingAddress != address (0), "ZeroAddress is not available");
        stakingAddress = _stakingAddress;
        emit StakingAddressChanged(msg.sender, stakingAddress);
    }

    function getRewardNum(address _account) public view returns(uint256) {
        if (genesisInfo[_account] == 0) return 0;
        uint256 rewardAmount = 0;
        for(uint256 id = 1; id <= maxTokenID; id++) {
            HOLDINFO memory info = holdInfo[_account][id];
            rewardAmount = rewardAmount + info.rewardLockup + balanceOf(_account, id) * (block.timestamp - Math.max(genesisInfo[_account], info.depositTime)) * rewardRate[id-1] / oneDay;
        }
        return rewardAmount;
    }

    function getDailyRewardOfUser(address _account) public view returns(uint256) {
        if (genesisInfo[_account] == 0) return 0;

        uint256 rewardAmount = 0;
        for(uint256 id = 1; id <= maxTokenID; id++) {
            rewardAmount = rewardAmount + balanceOf(_account, id) * rewardRate[id-1];
        }
        return rewardAmount;
    }

    function reSetRewardInfo(address _account) internal {
        for(uint256 id = 1; id <= maxTokenID; id++) {
            HOLDINFO storage info = holdInfo[_account][id];
            info.rewardLockup = 0;
            info.depositTime = block.timestamp;
        }
    }

  /// @dev Overridden to handle secondary sales
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override{
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if(amount <= 0) continue;
            if(from != address(0) && balanceOf(from, id) > 0) {       
                HOLDINFO storage fromInfo = holdInfo[from][id];
                if (genesisInfo[from] != 0) {
                    fromInfo.rewardLockup = fromInfo.rewardLockup + balanceOf(from, id) * (block.timestamp - Math.max(genesisInfo[from], fromInfo.depositTime)) * rewardRate[id-1] / oneDay;
                    fromInfo.depositTime = block.timestamp;
                }
            }
            if(to != address(0)) {
                HOLDINFO storage toInfo = holdInfo[to][id];
                if (genesisInfo[to] != 0) {
                    toInfo.rewardLockup = toInfo.rewardLockup + balanceOf(to, id) * (block.timestamp - Math.max(genesisInfo[to], toInfo.depositTime)) * rewardRate[id-1] / oneDay;
                    toInfo.depositTime = block.timestamp;
                }
            }            
        }
    }

  /// @notice Mint Land
  /// @dev Burns one of each obelisik type, plust costs $TROPY
    function mint(uint256 amount) public onlyNotPaused {
        IObelisk(obeliskAddress).burn(msg.sender, 1, amount);
        IObelisk(obeliskAddress).burn(msg.sender, 2, amount);
        IObelisk(obeliskAddress).burn(msg.sender, 3, amount);
        IObelisk(obeliskAddress).burn(msg.sender, 4, amount);
        require(totalMinted + amount < maxSupply, "12");
        amountPerWallets[msg.sender] += amount;
        totalMinted += amount;
    
        uint256 _tropyAmountToMint = tropyAmountToMint*amount;
        bool transferResult = IERC20(tropyAddress).transferFrom(msg.sender, address(this), _tropyAmountToMint);
        require(transferResult, "13");
        if(transferResult){
            for(uint256 i = 0; i < amount;) {
                uint256 randomID = getRandomID();
                _mint(msg.sender, randomID, 1, "");
                unchecked{ i++; }
            }
        }
    }

    function getRandomID() public returns(uint256) {
        uint256 randomNum = vrfRandomGenerator.requestRandomWords();
        randomNum = (randomNum & 0xFFFF) % 10000;
        uint256 randomID = 1;
        if(randomNum < 4000) randomID = 1;
        else if(randomNum >= 4000 && randomNum < 7000) randomID = 2;
        else if(randomNum >= 7000 && randomNum < 9000) randomID = 3;
        else if(randomNum >= 9000 && randomNum < 9800) randomID = 4;
        else randomID = 5;
        return randomID;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && tokenId <= maxTokenID, "Land: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    
    function setTropyAmountToMint(uint256 _tropyAmount) public onlyOwner {
        tropyAmountToMint = _tropyAmount;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function recoverTropy() external onlyOwner {
        uint256 tokenAmount = IERC20(tropyAddress).balanceOf(address(this));
        IERC20(tropyAddress).transfer(this.owner(), tokenAmount);
    }

    function stakeGenesis(address _account) external onlyStakingContract {
        genesisInfo[_account] = block.timestamp;
        reSetRewardInfo(_account);
    }

    function unStakeGenesis(address _account) external onlyStakingContract {
        genesisInfo[_account] = 0;
    }

    function harvest(address _account) external onlyStakingContract {
        genesisInfo[_account] = block.timestamp;
    }
    function withdraw() public payable onlyOwner {
      (bool os, ) = payable(owner()).call{value: address(this).balance}("");
      require(os);
    }
}