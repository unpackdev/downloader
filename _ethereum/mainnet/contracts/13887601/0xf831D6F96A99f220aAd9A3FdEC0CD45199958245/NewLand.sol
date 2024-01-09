// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";

interface IToken {
    function ownerOf(uint id) external view returns (address);
    function isPirate(uint16 id) external view returns (bool);
    function transferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) external;
    function isApprovedForAll(address owner, address operator) external returns(bool);
    function setApprovalForAll(address operator, bool approved) external;
}
interface IGold {
    function mint(address account, uint amount) external;
}
interface ISail {
    function isWaterproof(uint16 id) external view returns (bool);
}

contract NewLand is Ownable, IERC721Receiver, Pausable {
    uint public constant TAX_PERCENTAGE = 20;
    uint public constant MINIMUM_TIME_TO_EXIT = 2 days;

    bool zeroClaim = false;

    // Daily reward rates
    //    rewardRates[0] = 2000 ether - GoldMiner
    //    rewardRates[1] = 4000 ether - Ship
    //    rewardRates[2] = 6000 ether - PirateShip
    mapping(uint16 => uint) public rewardRates;

    // References to other contracts
    IToken public ships;
    IToken public goldHunter;
    ISail public sail;
    IGold public gold;

    // Global stats fields
    uint public totalGoldClaimed;
    uint public pirateReward;
    uint public unaccountedRewards;

    struct Stake {
        address owner;
        uint16 tokenId;
        uint80 value;
    }

    mapping(address => bool) public approvedManagers;

    // Land stake fields
    mapping(uint => uint) shipIndices;
    mapping(uint => uint) goldMinerIndices;
    mapping(uint => uint) pirateIndices;
    mapping(address => Stake[]) goldMinerStake;
    mapping(address => Stake[]) pirateStake;
    mapping(address => Stake[]) shipStake;

    // For steal mechanics
    mapping(address => uint) pirateHolderIndex;
    address[] pirateHolders;

    // Land counters
    uint public totalGoldMinerStaked;
    uint public totalShipStaked;
    uint public totalPirateStaked;
    uint public tokenStolenCounter;

    event TokenStolen(address owner, uint16 tokenId, address thief);
    event LandTokenStaked(address owner, uint16 tokenId, uint value);

    event ShipClaimed(uint16 tokenId, uint earned, bool unstaked);
    event GoldMinerClaimed(uint16 tokenId, uint earned, bool unstaked);
    event PirateClaimed(uint16 tokenId, uint earned, bool unstaked);

    function addManager(address _address) public onlyOwner {
        approvedManagers[_address] = true;
    }

    function removeManager(address _address) public onlyOwner {
        approvedManagers[_address] = false;
    }

    constructor() {
       rewardRates[0] = 2000 ether;
       rewardRates[1] = 4000 ether;
       rewardRates[2] = 6000 ether;

        _pause();
    }

    function setGoldHunter(address _address) external onlyOwner {
        addManager(_address);
        goldHunter = IToken(_address);
    }
    function setOcean(address _address) external onlyOwner {
        addManager(_address);
        sail = ISail(_address);
    }
    function setShip(address _address) external onlyOwner {
        addManager(_address);
        ships = IToken(_address);
    }
    function setZeroClaim(bool _status) external onlyOwner {
        zeroClaim = _status;
    }
    function setGold(address _address) external onlyOwner {
        gold = IGold(_address);
    }
    function getAccountGoldMiners(address user) external view returns (Stake[] memory) {
        return goldMinerStake[user];
    }
    function getAccountPirates(address user) external view returns (Stake[] memory) {
        return pirateStake[user];
    }
    function getAccountShips(address user) external view returns (Stake[] memory) {
        return shipStake[user];
    }
    function changeRewardRates(uint16 _key, uint16 _wei) external onlyOwner {
        rewardRates[_key] = _wei;
    }

    // Here should be an ability to Stake from Ocean to Land directly
    function stakeTokens(address _account, uint16[] memory _tokenIds) public {
        require(_account == msg.sender || msg.sender == address(sail), "Only manager or owner can do this");

        // 1. Handle ships
        if (_tokenIds[0] != 0) {
            require(ships.ownerOf(_tokenIds[0]) == msg.sender, "This NTF does not belong to address");
            require(sail.isWaterproof(_tokenIds[0]) == true, "Token is not ready");
            ships.transferFrom(msg.sender, address(this), _tokenIds[0]);
            _stakeShips(_account, _tokenIds[0]);
        }
        // 2. Stake the rest of the tokens starting from index 1
        for (uint i = 1; i < _tokenIds.length; i++) {
            require(goldHunter.ownerOf(_tokenIds[i]) == msg.sender, "This NTF does not belong to address");
            require(sail.isWaterproof(_tokenIds[i]) == true, "Token is not ready");
            goldHunter.transferFrom(msg.sender, address(this), _tokenIds[i]);
            
            if (goldHunter.isPirate(_tokenIds[i])) {
                _stakePirates(_account, _tokenIds[i]);
            } else {
                _stakeGoldMiners(_account, _tokenIds[i]);
            }
        }
    }

    function _stakeShips(address account, uint16 tokenId) internal whenNotPaused {
        totalShipStaked += 1;

        shipIndices[tokenId] = shipStake[account].length;
        shipStake[account].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        }));

        emit LandTokenStaked(account, tokenId, block.timestamp);
    }

    function _stakeGoldMiners(address account, uint16 tokenId) internal whenNotPaused {
        totalGoldMinerStaked += 1;

        goldMinerIndices[tokenId] = goldMinerStake[account].length;
        goldMinerStake[account].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        }));
        emit LandTokenStaked(account, tokenId, block.timestamp);
    }

    function _stakePirates(address account, uint16 tokenId) internal {
        totalPirateStaked += 1;

        // If account already has some pirates no need to push it to the tracker
        if (pirateStake[account].length == 0) {
            pirateHolderIndex[account] = pirateHolders.length;
            pirateHolders.push(account);
        }

        pirateIndices[tokenId] = pirateStake[account].length;
        pirateStake[account].push(Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(pirateReward)
            }));

        emit LandTokenStaked(account, tokenId, pirateReward);
    }

    function claimFromStake(uint16[] calldata shipTokenIds, uint16[] calldata tokenIds, bool unstake) external whenNotPaused {
        uint owed = 0;
        for (uint i = 0; i < shipTokenIds.length; i++) {
            owed += _claimFromShip(shipTokenIds[i], unstake);
        }
        for (uint i = 0; i < tokenIds.length; i++) {
            if (goldHunter.isPirate(tokenIds[i])) {
                owed += _claimFromPirate(tokenIds[i], unstake);
            } else {
                owed += _claimFromMiner(tokenIds[i], unstake);
            }
        }
        if (owed == 0) return;
        gold.mint(msg.sender, owed);
        totalGoldClaimed += owed;
    }

    function _claimFromMiner(uint16 tokenId, bool unstake) internal returns (uint owed) {
        Stake memory stake = goldMinerStake[msg.sender][goldMinerIndices[tokenId]];
        require(stake.owner == msg.sender, "This NTF does not belong to address");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TIME_TO_EXIT), "Need to wait 2 days since last claim");

        owed = zeroClaim ? 0 : ((block.timestamp - stake.value) * rewardRates[0]) / 1 days;
        if (unstake == true) {
            bool stolen = false;
            address luckyPirate;
            if (tokenId >= 10000) {
                if (getSomeRandomNumber(tokenId, 100) <= 5) {
                    luckyPirate = randomPirateOwner();
                    if (luckyPirate != address(0x0) && luckyPirate != msg.sender) {
                        stolen = true;
                    }
                }
            }
            if (getSomeRandomNumber(tokenId, 100) <= 50) {
                _payTax(owed);
                owed = 0;
            }
            totalGoldMinerStaked -= 1;

            Stake memory lastStake = goldMinerStake[msg.sender][goldMinerStake[msg.sender].length - 1];
            goldMinerStake[msg.sender][goldMinerIndices[tokenId]] = lastStake;
            goldMinerIndices[lastStake.tokenId] = goldMinerIndices[tokenId];
            goldMinerStake[msg.sender].pop();
            delete goldMinerIndices[tokenId];

            if (!stolen) {
                goldHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");
            } else {
                if (!goldHunter.isApprovedForAll(address(this), luckyPirate)) {
                    goldHunter.setApprovalForAll(luckyPirate, true);
                }
                goldHunter.safeTransferFrom(address(this), luckyPirate, tokenId, "");
                emit TokenStolen(msg.sender, tokenId, luckyPirate);
                tokenStolenCounter += 1;
            }
        } else {
            _payTax((owed * TAX_PERCENTAGE) / 100);
            owed = (owed * (100 - TAX_PERCENTAGE)) / 100;
            
            uint80 timestamp = uint80(block.timestamp);

            goldMinerStake[msg.sender][goldMinerIndices[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: timestamp
            });
        }

        emit GoldMinerClaimed(tokenId, owed, unstake);
    }

    function _claimFromShip(uint16 tokenId, bool unstake) internal returns (uint owed) {
        Stake memory stake = shipStake[msg.sender][shipIndices[tokenId]];
        require(stake.owner == msg.sender, "This NTF does not belong to address");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TIME_TO_EXIT), "Need to wait 2 days since last claim");

        uint rate = ships.isPirate(tokenId) ? rewardRates[2] : rewardRates[1];
        owed = zeroClaim ? 0 : ((block.timestamp - stake.value) * rate) / 1 days;

        _payTax((owed * TAX_PERCENTAGE) / 100);
        owed = (owed * (100 - TAX_PERCENTAGE)) / 100;

        if (unstake == true) {
            totalShipStaked -= 1;

            Stake memory lastStake = shipStake[msg.sender][shipStake[msg.sender].length - 1];
            shipStake[msg.sender][shipIndices[tokenId]] = lastStake;
            shipIndices[lastStake.tokenId] = shipIndices[tokenId];
            shipStake[msg.sender].pop();
            delete shipIndices[tokenId];

            ships.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            uint80 timestamp = uint80(block.timestamp);

            shipStake[msg.sender][shipIndices[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: timestamp
            });
        }

        emit ShipClaimed(tokenId, owed, unstake);
    }

    function _claimFromPirate(uint16 tokenId, bool unstake) internal returns (uint owed) {
        require(goldHunter.ownerOf(tokenId) == address(this), "This NTF does not belong to address");

        Stake memory stake = pirateStake[msg.sender][pirateIndices[tokenId]];

        require(stake.owner == msg.sender, "This NTF does not belong to address");
        owed = zeroClaim ? 0 : (pirateReward - stake.value);

        if (unstake == true) {
            totalPirateStaked -= 1;

            Stake memory lastStake = pirateStake[msg.sender][pirateStake[msg.sender].length - 1];
            pirateStake[msg.sender][pirateIndices[tokenId]] = lastStake;
            pirateIndices[lastStake.tokenId] = pirateIndices[tokenId];
            pirateStake[msg.sender].pop();
            delete pirateIndices[tokenId];
            updatePirateOwnerAddressList(msg.sender);

            goldHunter.safeTransferFrom(address(this), msg.sender, tokenId, "");
        } else {
            pirateStake[msg.sender][pirateIndices[tokenId]] = Stake({
                owner: msg.sender,
                tokenId: uint16(tokenId),
                value: uint80(pirateReward)
            });
        }
        emit PirateClaimed(tokenId, owed, unstake);
    }

    function updatePirateOwnerAddressList(address account) internal {
        if (pirateStake[account].length != 0) {
            return; // No need to update holders
        }

        // Update the address list of holders, account unstaked all pirates
        address lastOwner = pirateHolders[pirateHolders.length - 1];
        pirateHolderIndex[lastOwner] = pirateHolderIndex[account];
        pirateHolders[pirateHolderIndex[account]] = lastOwner;
        pirateHolders.pop();
        delete pirateHolderIndex[account];
    }

    function _payTax(uint _amount) internal {
        if (totalPirateStaked == 0) {
            unaccountedRewards += _amount;
            return;
        }

        pirateReward += (_amount + unaccountedRewards) / totalPirateStaked;
        unaccountedRewards = 0;
    }

    function getSomeRandomNumber(uint _seed, uint _limit) internal view returns (uint16) {
        uint random = uint(
            keccak256(
                abi.encodePacked(
                    _seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    block.timestamp,
                    msg.sender
                )
            )
        );

        return uint16(random % _limit);
    }

    function randomPirateOwner() public view returns (address) {
        if (totalPirateStaked == 0) return address(0x0);

        uint holderIndex = getSomeRandomNumber(totalPirateStaked, pirateHolders.length);

        return pirateHolders[holderIndex];
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function onERC721Received(
        address,
        address from,
        uint,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to this contact directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}
