// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./Create2.sol";
import "./Address.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./TableHelper.sol";
import "./IOneHiTableLogic.sol";
import "./IOneHiController.sol";
import "./IFractonSwap.sol";
import "./OneHiEvent.sol";

contract OneHiController is Ownable, VRFConsumerBaseV2, IOneHiController, OneHiEvent {

    struct Record {
        uint256 number;
        address player;
    }

    struct TableInfo {
        Record[] records;
        address nftAddr;
        address winner;
        address maker;
        address lucky;
        uint256 time;
        uint256 targetAmount;
    }

    struct ChainLinkVrfParam {
        VRFCoordinatorV2Interface vrfCoordinator;
        uint16 requestConfirmations;
        bytes32 keyHash;
        uint32 callbackGasLimit;
        uint32 numWords;
        uint64 subscriptionId;
    }

    struct NFTInfo {
        bool isSupport;
        uint256 createTableFee;
        address miniNftAddr;
        address fftAddr;
    }

    address private fractonSwapAddr;
    address private vaultAddr;
    address public implTableAddr;

    mapping(address=>NFTInfo) public nftAddr2nftInfo;
    mapping(address=>TableInfo) public tableAddr2Info;
    
    uint8 private splitProfitRatio = 50;
    uint8 private luckySplitProfitRatio = 80;
    uint256 public minTargetAmount = 1_050_000;

    //ChainLink VRF
    ChainLinkVrfParam public chainLinkVrfParam;
    mapping(uint256=>address) private requestId2Table;

    constructor(address _implTableAddr, address _fractonSwapAddr, address _vaultAddr,
        address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId
    ) VRFConsumerBaseV2(_vrfCoordinator) {

        implTableAddr = _implTableAddr;
        fractonSwapAddr = _fractonSwapAddr;
        vaultAddr = _vaultAddr;

        chainLinkVrfParam.vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        chainLinkVrfParam.numWords = 1;
        chainLinkVrfParam.callbackGasLimit = 1000000;
        chainLinkVrfParam.requestConfirmations = 3;
        chainLinkVrfParam.subscriptionId = _subscriptionId;
        chainLinkVrfParam.keyHash = _keyHash;
    }

    error InvalidChainLinkVrfParam(ChainLinkVrfParam);

    function _requestRandom(address tableAddr) internal {
        uint256 requestId = chainLinkVrfParam.vrfCoordinator.requestRandomWords(
            chainLinkVrfParam.keyHash,
            chainLinkVrfParam.subscriptionId,
            chainLinkVrfParam.requestConfirmations,
            chainLinkVrfParam.callbackGasLimit,
            chainLinkVrfParam.numWords
        );
        requestId2Table[requestId] = tableAddr;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
    internal virtual override {
        address tableAddr = requestId2Table[requestId];
        _pickUpWinner(tableAddr, randomWords[0]);
    }

    function _pickUpWinner(address tableAddr, uint256 randomWord) internal {
        uint256 left = 0;
        uint256 right = tableAddr2Info[tableAddr].records.length - 1;

        uint256 middle;
        uint256 middleNumber;

        uint256 random = (randomWord % tableAddr2Info[tableAddr].targetAmount) + 1;
        uint256 winnerNumber = random;

        while (true) {
            if (right - left <= 1) {
                if (random <= tableAddr2Info[tableAddr].records[left].number) {
                    tableAddr2Info[tableAddr].winner = tableAddr2Info[tableAddr].records[left].player;
                } else {
                    tableAddr2Info[tableAddr].winner = tableAddr2Info[tableAddr].records[right].player;
                }
                break;
            } else {
                middle = (right + left) / 2;
                middleNumber = tableAddr2Info[tableAddr].records[middle].number;

                if (middleNumber == random) {
                    tableAddr2Info[tableAddr].winner = tableAddr2Info[tableAddr].records[middle].player;
                    break;
                }

                if (middleNumber < random) {
                    left = middle;
                } else {
                    right = middle;
                }
            }
        }
        _emitChooseWinnerEvent(tableAddr, tableAddr2Info[tableAddr].winner, winnerNumber);
    }

    function createTable(address nftAddr, uint256 targetAmount, bytes32 salt) external {
        require(nftAddr2nftInfo[nftAddr].isSupport, "not support nft-address");
        require(targetAmount >= minTargetAmount, "minTargetAmount not met");
        address fftAddr = nftAddr2nftInfo[nftAddr].fftAddr;
        require(IERC20(fftAddr).transferFrom(msg.sender, vaultAddr, nftAddr2nftInfo[nftAddr].createTableFee));

        address tableAddr = Create2.deploy(
            0,
            salt,
            TableHelper.getBytecode(implTableAddr)
        );

        require(tableAddr != address(0), "tableAddr deploy failed");

        IOneHiTableLogic(tableAddr).initialize(address(this), fftAddr);

        tableAddr2Info[tableAddr].nftAddr = nftAddr;
        tableAddr2Info[tableAddr].maker = msg.sender;
        tableAddr2Info[tableAddr].time = block.timestamp;
        tableAddr2Info[tableAddr].targetAmount = targetAmount;

        _emitCreateTableEvent(tableAddr, msg.sender, nftAddr, targetAmount);

        buyTickets(tableAddr, targetAmount * 5 / 10000);
    }

    function buyTickets(address tableAddr, uint256 ticketsAmount) public returns(uint256) {
        require(ticketsAmount > 0);
        address nftAddr = tableAddr2Info[tableAddr].nftAddr;
        require(nftAddr != address(0), "Invalid tableAddr");

        require(block.timestamp <= (tableAddr2Info[tableAddr].time + 4 hours), "Table is timeout");
        tableAddr2Info[tableAddr].time = block.timestamp;

        uint256 amount = tableAddr2Info[tableAddr].targetAmount - getTableAccumulation(tableAddr);
        require(amount > 0, "Controller: table is finished.");
        if (amount < ticketsAmount) {
            ticketsAmount = amount;
        }
        require(IERC20(nftAddr2nftInfo[nftAddr].fftAddr).transferFrom(msg.sender, tableAddr,
            ticketsAmount * 1e18));

        _buyTickets(tableAddr, ticketsAmount);
        return ticketsAmount;
    }

    function _buyTickets(address tableAddr, uint256 actualAmount) internal {
        Record[] storage records = tableAddr2Info[tableAddr].records;
        uint256 accumulation;
        if (records.length != 0) {
            accumulation = records[records.length - 1].number;
        }

        uint256 targetAmount = tableAddr2Info[tableAddr].targetAmount;
        uint256 afterAmount = accumulation + actualAmount;
        records.push(Record(afterAmount, msg.sender));

        _emitBuyTicketsEvent(tableAddr, msg.sender, accumulation+1, afterAmount);

        if (afterAmount == targetAmount) {
            _emitUpToTargetAmountEvent(tableAddr);
            _liquidate(tableAddr);
        }
    }
    function _liquidate(address tableAddr) internal {
        address nftAddr = tableAddr2Info[tableAddr].nftAddr;
        _swapNFT(tableAddr, nftAddr, nftAddr2nftInfo[nftAddr].miniNftAddr,
            nftAddr2nftInfo[nftAddr].fftAddr);
        _splitProfit(tableAddr, nftAddr2nftInfo[nftAddr].fftAddr);
        _requestRandom(tableAddr);
    }
    function _swapNFT(address tableAddr, address nftAddr, address miniNFTAddr, address fftAddr) internal {
        uint256 miniNFTAmount = 1000 + IFractonSwap(fractonSwapAddr).nftTax();

        IOneHiTableLogic(tableAddr).swapNFT(fractonSwapAddr, fftAddr, miniNFTAddr, miniNFTAmount,
            nftAddr);
    }
    function _splitProfit(address tableAddr, address fftAddr) internal {
        uint256 balance = IERC20(fftAddr).balanceOf(tableAddr);
        uint256 profitOfMaker = balance * splitProfitRatio / 100;
        uint256 profitOfVault = balance - profitOfMaker;

        require(IERC20(fftAddr).transferFrom(tableAddr, tableAddr2Info[tableAddr].maker, profitOfMaker));
        require(IERC20(fftAddr).transferFrom(tableAddr, vaultAddr, profitOfVault));
        _emitSplitProfitEvent(tableAddr, tableAddr2Info[tableAddr].maker,
            profitOfMaker, vaultAddr, profitOfVault);
    }

    function claimTreasure(address tableAddr, uint256 tokenId) external {
        address nftAddr = tableAddr2Info[tableAddr].nftAddr;
        require(tableAddr2Info[tableAddr].winner != address(0));
        require(tableAddr2Info[tableAddr].winner == msg.sender, "winner is invalid");
        require(IOneHiTableLogic(tableAddr).claimTreasure(msg.sender, nftAddr, tokenId));
        _emitClaimTreasureEvent(tableAddr);
    }

    function luckyClaim(address tableAddr) external {
        address nftAddr = tableAddr2Info[tableAddr].nftAddr;
        require(nftAddr != address(0), "TableAddr is invalid");
        address fftAddr = nftAddr2nftInfo[nftAddr].fftAddr;

        Record[] storage records = tableAddr2Info[tableAddr].records;
        require(block.timestamp > (tableAddr2Info[tableAddr].time + 4 hours), "Table isn't timeout");
        require(records.length != 0, "Table is empty");
        require(msg.sender == records[records.length - 1].player, "invalid luckyAddr");
        require(records[records.length - 1].number != tableAddr2Info[tableAddr].targetAmount, "Table is full");

        tableAddr2Info[tableAddr].lucky = msg.sender;
        uint256 balance = IERC20(fftAddr).balanceOf(tableAddr);
        require(balance > 0, "table balance is zero");
        uint256 profitOfLucky = balance * luckySplitProfitRatio / 100;
        uint256 profitOfVault = balance - profitOfLucky;

        require(IERC20(fftAddr).transferFrom(tableAddr, msg.sender, profitOfLucky));
        require(IERC20(fftAddr).transferFrom(tableAddr, vaultAddr, profitOfVault));
        _emitLuckyClaimEvent(tableAddr);
        _emitSplitProfitEvent(tableAddr, msg.sender, profitOfLucky, vaultAddr, profitOfVault);
    }

    function updateHiStatus(address nftAddr, bool isSupport, uint256 createTableFee) external onlyOwner {
        address miniNftAddr = IFractonSwap(fractonSwapAddr).NFTtoMiniNFT(nftAddr);
        require(miniNftAddr != address(0), "miniNftAddr is zero");
        address fftAddr = IFractonSwap(fractonSwapAddr).miniNFTtoFFT(miniNftAddr);
        require(fftAddr != address(0), "fftAddr is zero");

        nftAddr2nftInfo[nftAddr].isSupport = isSupport;
        nftAddr2nftInfo[nftAddr].createTableFee = createTableFee * 1e18;
        nftAddr2nftInfo[nftAddr].miniNftAddr = miniNftAddr;
        nftAddr2nftInfo[nftAddr].fftAddr = fftAddr;
        _emitUpdateHiStatusEvent(nftAddr, miniNftAddr, fftAddr, isSupport, createTableFee*1e18);
    }

    function updateSplitProfitRatio(uint8 _splitProfitRatio) external onlyOwner {
        splitProfitRatio = _splitProfitRatio;
        _emitUpdateRatio(splitProfitRatio, luckySplitProfitRatio);
    }

    function updateLuckySplitProfitRatio(uint8 _luckySplitProfitRatio) external onlyOwner {
        luckySplitProfitRatio = _luckySplitProfitRatio;
        _emitUpdateRatio(splitProfitRatio, luckySplitProfitRatio);
    }

    function updateVaultAddr(address _vaultAddr) external onlyOwner {
        vaultAddr = _vaultAddr;
    }

    function updateVrfParam(ChainLinkVrfParam memory _chainLinkVrfParam) external onlyOwner {
        if (chainLinkVrfParam.numWords == 0 || chainLinkVrfParam.callbackGasLimit == 0 ||
            chainLinkVrfParam.requestConfirmations == 0 ||
            address(chainLinkVrfParam.vrfCoordinator) == address(0)) {
            revert InvalidChainLinkVrfParam(_chainLinkVrfParam);
        }

        chainLinkVrfParam = _chainLinkVrfParam;
    }

    //table
    function getFractonSwapAddr() external view returns(address) {
        return fractonSwapAddr;
    }
    function getVaultAddr() external view returns(address) {
        return vaultAddr;
    }
    function getSplitProfitRatio() external view returns(uint256) {
        return splitProfitRatio;
    }
    function getLuckySplitProfitRatio() external view returns(uint256) {
        return luckySplitProfitRatio;
    }

    function getTableAccumulation(address tableAddr) public view returns(uint256) {
        if (tableAddr2Info[tableAddr].records.length == 0) {
            return 0;
        }
        return tableAddr2Info[tableAddr].records[tableAddr2Info[tableAddr].records.length - 1].number;
    }

    function getTableLucky(address tableAddr) external view returns(address) {
        require(block.timestamp > (tableAddr2Info[tableAddr].time + 4 hours), "Table isn't timeout");
        require(tableAddr2Info[tableAddr].records.length != 0, "Table is empty");

        return tableAddr2Info[tableAddr].records[tableAddr2Info[tableAddr].records.length - 1].player;
    }
}
