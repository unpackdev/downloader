// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./Math.sol";

pragma solidity ^0.8.0;

interface IVRFv2SubscriptionManager {
    function requestRandomWords() external returns(uint256);
}

contract Obelisk is ERC1155, Ownable {

    using Strings for uint256;

    string public constant NAME = "Obelisk";
    string public constant SYMBOL = "OBELISK";

    address public tropyAddress;

    string public baseTokenURI;
    
    uint256 public maxSupply = 2400;
    uint256 public maxSupplyperID = 500;
    uint256 public maxTokenID = 4;
    uint256 public rewardRatePerDay = 20000000000000000000; // 20 $TROPY
    uint256 public totalNum = 1;

    uint256 private oneDay = 1 days;

    bool public paused = false;
    bytes32 internal entropySauce;

    uint256[] public initTropyAmountToMint = [90, 120, 150, 180, 210, 240, 270, 300];
    uint256 public totalMinted = 0;

    mapping(uint8 => uint256) public supplies;
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

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}
        require( (msg.sender == tx.origin && size == 0), "9");
        _;
        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    modifier onlyStakingContract() {
        require(msg.sender == stakingAddress, 'Only Staking contract can call this function.');
        _;
    }

    event TropyAddressChanged(address indexed owner, address indexed tropyAddress);
    event StakingAddressChanged(address indexed owner, address indexed stakingAddress);

    constructor(string memory _baseTokenURI, address _tropyAddress, address _vrfRandomGenerator) ERC1155(_baseTokenURI) {
        setBaseURI(_baseTokenURI);
        changeTropyAddress(_tropyAddress);
        vrfRandomGenerator = IVRFv2SubscriptionManager(_vrfRandomGenerator);
    }

    function name() public pure returns (string memory) {
        return NAME;
    }

    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    function changeTropyAddress(address _tropyAddress) public onlyOwner {
        tropyAddress = _tropyAddress;
        emit TropyAddressChanged(msg.sender, tropyAddress);
    }

    function changeStakingAddress(address _stakingAddress) public onlyOwner {
        stakingAddress = _stakingAddress;
        emit StakingAddressChanged(msg.sender, stakingAddress);
    }

    function getRewardNum(address _account) public view returns(uint256) {
        if (genesisInfo[_account] == 0) return 0;
        uint256 rewardAmount = 0;
        for(uint256 id = 1; id <= maxTokenID; id++) {
            HOLDINFO memory info = holdInfo[_account][id];
            rewardAmount = rewardAmount + info.rewardLockup + balanceOf(_account, id) * (block.timestamp - Math.max(genesisInfo[_account], info.depositTime)) * rewardRatePerDay / oneDay;
        }
        return rewardAmount;
    }

    function getDailyRewardOfUser(address _account) public view returns(uint256) {
        if (genesisInfo[_account] == 0) return 0;
        uint256 rewardAmount = 0;
        for(uint256 id = 1; id <= maxTokenID; id++) {
            rewardAmount = rewardAmount + balanceOf(_account, id) * rewardRatePerDay;
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
    ) internal virtual override {
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if(amount <= 0) continue;
            
            if(from != address(0) && balanceOf(from, id) > 0) {       
                HOLDINFO storage fromInfo = holdInfo[from][id];
                if (genesisInfo[from] != 0) {
                    fromInfo.rewardLockup = fromInfo.rewardLockup + balanceOf(from, id) * (block.timestamp - Math.max(genesisInfo[from], fromInfo.depositTime)) * rewardRatePerDay / oneDay;
                    fromInfo.depositTime = block.timestamp;
                }
            }

            if(to != address(0)) {
                HOLDINFO storage toInfo = holdInfo[to][id];
                if (genesisInfo[to] != 0) {
                    toInfo.rewardLockup = toInfo.rewardLockup + balanceOf(to, id) * (block.timestamp - Math.max(genesisInfo[to], toInfo.depositTime)) * rewardRatePerDay / oneDay;
                    toInfo.depositTime = block.timestamp;
                }
            }            
        }
    }

  /// @notice Get Tropy Amount To Mint
  /// @dev $TROPY cost for obelisks increases based on both:
  ///              - amount held by wallet  
  ///              - and total supply of obelisks
  ///       Used by Dapp.
    function getInitTropyAmountToMint() public view returns (uint256) {
        uint256 _initTropyAmountToMint = 90;
        if(totalMinted < 300) {
            _initTropyAmountToMint = initTropyAmountToMint[0];
        } else if(totalMinted < 600) {
            _initTropyAmountToMint = initTropyAmountToMint[1];
        } else if(totalMinted < 900) {
            _initTropyAmountToMint = initTropyAmountToMint[2];
        } else if(totalMinted < 1200) {
            _initTropyAmountToMint = initTropyAmountToMint[3];
        } else if(totalMinted < 1500) {
            _initTropyAmountToMint = initTropyAmountToMint[4];
        } else if(totalMinted < 1800) {
            _initTropyAmountToMint = initTropyAmountToMint[5];
        } else if(totalMinted < 2100) {
            _initTropyAmountToMint = initTropyAmountToMint[6];
        } else if(totalMinted <= 2400) {
            _initTropyAmountToMint = initTropyAmountToMint[7];
        }
        return _initTropyAmountToMint * (10 ** 18);
    }

  /// @notice Get Tropy Amount To Mint
  /// @dev $TROPY cost for obelisks increases based on both:
  ///              - amount held by wallet  
  ///              - and total supply of obelisks
    function getTropyAmountToMint(address add, uint256 amount) public view returns (uint256) {
        uint256 tropyAmount;
        uint256 _initTropyAmountToMint = getInitTropyAmountToMint();
        uint256 amountFuture = amountPerWallets[add] + amount;

        if(amountFuture <= 3) {
            tropyAmount = _initTropyAmountToMint * amount;
        } else {
            uint256 addCount;
            if(amountPerWallets[add] == 0) {
                tropyAmount = _initTropyAmountToMint * 2;
                addCount = amount - 2;
            }
            else if(amountPerWallets[add] == 1) {
                tropyAmount = _initTropyAmountToMint * 1;
                addCount = amount - 1;
            }
            else if(amountPerWallets[add] == 2) {
                addCount = amount;
            } else {
                addCount = amount;
                _initTropyAmountToMint = _initTropyAmountToMint + (amountPerWallets[add] - 2) * 100 * (10 ** 18);
            }
            uint256 amountToAdd = (_initTropyAmountToMint * 2 + (addCount - 1) * 100 * (10 ** 18) ) * addCount / 2;
            tropyAmount += amountToAdd;
        }
        return tropyAmount;
    }


    function mint(uint256 amount) public onlyNotPaused noCheaters {
        uint256 tropyAmountToMint = getTropyAmountToMint(msg.sender, amount);
        bool transferResult = IERC20(tropyAddress).transferFrom(msg.sender, address(this), tropyAmountToMint);
        require(transferResult, "10");
        require(totalMinted + amount <= maxSupply, "11");
        amountPerWallets[msg.sender] += amount;
        totalMinted += amount;

        if(transferResult){
            for(uint256 i = 0; i < amount;) {
                uint256 randomID = getRandomID();
                _mint(msg.sender, randomID, 1, "");
                unchecked{ i++; }
            }
        }
    }

  function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
  }

  function random(uint256 seed) public view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
      ))); //  ^ randomSource.seed();
  }

  function requestRandomWords() internal returns(uint256) {
    totalNum = totalNum + 1;
    return random(block.timestamp + totalNum);
  }

    function getRandomID() public returns(uint256) {
        uint256 randomNum = requestRandomWords();
        randomNum = (randomNum & 0xFFFF);
        uint256 randomID;
        if(randomNum < 16384) randomID = 1;
        else if(randomNum >= 16384 && randomNum < 32768) randomID = 2;
        else if(randomNum >= 32768 && randomNum < 49152) randomID = 3;
        else randomID = 4;
        return randomID;
    }

    function burn(address from, uint256 id, uint256 amount) external {
        _burn(from, id, amount);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && tokenId <= maxTokenID, "Obelisk: URI query for nonexistent token");
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

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function approve(address tokenAddress, address spender, uint256 amount) public onlyOwner returns (bool) {
        IERC20(tokenAddress).approve(spender, amount);
        return true;
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