pragma solidity ^0.8.17;

contract JRLottery {
    address public Admin;
    address private houseAddress = 0xEf257E9Fe8016ceFD7D5352EF082d153007880b6;
    uint256 houseCut = 4;
    uint256 winnerCut = 96;

    // lotteries

    address payable[] public playersSilverLottery;
    uint256 public silverLotteryEntryPrice = 0.01 ether;
    uint256 public silverLotteryPotMaxAmount = 0.1 ether;
    uint256 public silverLotteryMaxEntries = 10;
    bool public silverLotteryIsLive = true;

    address payable[] public playersGoldLottery;
    uint256 public goldLotteryEntryPrice = 0.05 ether;
    uint256 public goldLotteryPotMaxAmount = 0.5 ether;
    uint256 public goldLotteryMaxEntries = 10;
    bool public goldLotteryIsLive = true;

    address payable[] public playersDiamondLottery;
    uint256 public diamondLotteryEntryPrice = 0.1 ether;
    uint256 public diamondLotteryPotMaxAmount = 1 ether;
    uint256 public diamondLotteryMaxEntries = 10;
    bool public diamondLotteryIsLive = true;

    event EntrySilverLottery(address indexed _from, uint256 _value);
    event WinnerSilverLottery(address indexed _from, uint256 _value);
    event FinalPlayersSilverLottery(address payable[] playersSilverLottery);

    event EntryGoldLottery(address indexed _from, uint256 _value);
    event WinnerGoldLottery(address indexed _from, uint256 _value);
    event FinalPlayersGoldLottery(address payable[] playersGoldLottery);

    event EntryDiamondLottery(address indexed _from, uint256 _value);
    event WinnerDiamondLottery(address indexed _from, uint256 _value);
    event FinalPlayersDiamondLottery(address payable[] playersDiamondLottery);

    // battles

    address payable[] public playersSilverBattle;
    uint256 public silverBattleEntryPrice = 0.01 ether;
    uint256 public silverBattlePotMaxAmount = 0.02 ether;
    uint256 public silverBattleMaxEntries = 2;
    bool public silverBattleIsLive = true;

    address payable[] public playersGoldBattle;
    uint256 public goldBattleEntryPrice = 0.05 ether;
    uint256 public goldBattlePotMaxAmount = 0.1 ether;
    uint256 public goldBattleMaxEntries = 2;
    bool public goldBattleIsLive = true;

    address payable[] public playersDiamondBattle;
    uint256 public diamondBattleEntryPrice = 0.1 ether;
    uint256 public diamondBattlePotMaxAmount = 0.2 ether;
    uint256 public diamondBattleMaxEntries = 2;
    bool public diamondBattleIsLive = true;

    event EntrySilverBattle(address indexed _from, uint256 _value);
    event WinnerSilverBattle(address indexed _from, uint256 _value);

    event EntryGoldBattle(address indexed _from, uint256 _value);
    event WinnerGoldBattle(address indexed _from, uint256 _value);

    event EntryDiamondBattle(address indexed _from, uint256 _value);
    event WinnerDiamondBattle(address indexed _from, uint256 _value);

    constructor() {
        Admin = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == Admin, "You are not the owner");
        _;
    }

    modifier isSilverLotteryPotFull() {
        require(
            silverLotteryMaxEntries == playersSilverLottery.length,
            "silverLottery pot is not full"
        );
        _;
    }

    modifier isGoldLotteryPotFull() {
        require(
            goldLotteryMaxEntries == playersGoldLottery.length,
            "goldLottery pot is not full"
        );
        _;
    }

    modifier isDiamondLotteryPotFull() {
        require(
            diamondLotteryMaxEntries == playersDiamondLottery.length,
            "diamondLottery pot is not full"
        );
        _;
    }

    modifier isSilverBattlePotFull() {
        require(
            silverBattleMaxEntries == playersSilverBattle.length,
            "silverBattle pot is not full"
        );
        _;
    }

    modifier isGoldBattlePotFull() {
        require(
            goldBattleMaxEntries == playersGoldBattle.length,
            "goldBattle pot is not full"
        );
        _;
    }

    modifier isDiamondBattlePotFull() {
        require(
            diamondBattleMaxEntries == playersDiamondBattle.length,
            "diamondBattle pot is not full"
        );
        _;
    }

    /* silverLottery */

    function enterSilverLottery(uint256 _count) public payable {
        require(silverLotteryIsLive, "silver lottery is not live");
        require(
            msg.value == silverLotteryEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersSilverLottery.length + _count <= silverLotteryMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersSilverLottery.push(payable(msg.sender));
        }
        if (silverLotteryMaxEntries == playersSilverLottery.length) {
            pickSilverLotteryWinner();
        }
        emit EntrySilverLottery(msg.sender, msg.value);
    }

    function pickSilverLotteryWinner() public isSilverLotteryPotFull {
        uint256 index = randomSilverLottery() % playersSilverLottery.length;
        address payable winningAddress = playersSilverLottery[index];
        uint256 winningAmount = (silverLotteryPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddress).transfer(
            (silverLotteryPotMaxAmount * houseCut) / 100
        );
        emit FinalPlayersSilverLottery(playersSilverLottery);
        emit WinnerSilverLottery(winningAddress, winningAmount);
        delete playersSilverLottery;
    }

    function setSilverLotteryEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        silverLotteryEntryPrice = _newEntryPrice;
    }

    function setSilverLotteryMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        silverLotteryMaxEntries = _newMaxEntries;
    }

    function randomSilverLottery() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersSilverLottery
                    )
                )
            );
    }

    function getPlayersSilverLottery()
        public
        view
        returns (address payable[] memory)
    {
        return playersSilverLottery;
    }

    /* goldLottery */

    function enterGoldLottery(uint256 _count) public payable {
        require(goldLotteryIsLive, "gold lottery is not live");
        require(
            msg.value == goldLotteryEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersGoldLottery.length + _count <= goldLotteryMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersGoldLottery.push(payable(msg.sender));
        }
        if (goldLotteryMaxEntries == playersGoldLottery.length) {
            pickGoldLotteryWinner();
        }
        emit EntryGoldLottery(msg.sender, msg.value);
    }

    function pickGoldLotteryWinner() public isGoldLotteryPotFull {
        uint256 index = randomGoldLottery() % playersGoldLottery.length;
        address payable winningAddress = playersGoldLottery[index];
        uint256 winningAmount = (goldLotteryPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddress).transfer(
            (goldLotteryPotMaxAmount * houseCut) / 100
        );
        emit FinalPlayersGoldLottery(playersGoldLottery);
        emit WinnerGoldLottery(winningAddress, winningAmount);
        delete playersGoldLottery;
    }

    function setGoldLotteryEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        goldLotteryEntryPrice = _newEntryPrice;
    }

    function setGoldLotteryMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        goldLotteryMaxEntries = _newMaxEntries;
    }

    function randomGoldLottery() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersGoldLottery
                    )
                )
            );
    }

    function getPlayersGoldLottery()
        public
        view
        returns (address payable[] memory)
    {
        return playersGoldLottery;
    }

    /* diamondLottery */

    function enterDiamondLottery(uint256 _count) public payable {
        require(diamondLotteryIsLive, "diamond lottery is not live");
        require(
            msg.value == diamondLotteryEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersDiamondLottery.length + _count <= diamondLotteryMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersDiamondLottery.push(payable(msg.sender));
        }
        if (diamondLotteryMaxEntries == playersDiamondLottery.length) {
            pickDiamondLotteryWinner();
        }
        emit EntryDiamondLottery(msg.sender, msg.value);
    }

    function pickDiamondLotteryWinner() public isDiamondLotteryPotFull {
        uint256 index = randomDiamondLottery() % playersDiamondLottery.length;
        address payable winningAddress = playersDiamondLottery[index];
        uint256 winningAmount = (diamondLotteryPotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddress).transfer(
            (diamondLotteryPotMaxAmount * houseCut) / 100
        );
        emit FinalPlayersDiamondLottery(playersDiamondLottery);
        emit WinnerDiamondLottery(winningAddress, winningAmount);
        delete playersDiamondLottery;
    }

    function setDiamondLotteryEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        diamondLotteryEntryPrice = _newEntryPrice;
    }

    function setDiamondLotteryMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        diamondLotteryMaxEntries = _newMaxEntries;
    }

    function randomDiamondLottery() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersDiamondLottery
                    )
                )
            );
    }

    function getPlayersDiamondLottery()
        public
        view
        returns (address payable[] memory)
    {
        return playersDiamondLottery;
    }

    /* silverBattle */

    function enterSilverBattle(uint256 _count) public payable {
        require(silverBattleIsLive, "silver battle is not live");
        require(
            msg.value == silverBattleEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersSilverBattle.length + _count <= silverBattleMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersSilverBattle.push(payable(msg.sender));
        }
        if (silverBattleMaxEntries == playersSilverBattle.length) {
            pickSilverBattleWinner();
        }

        emit EntrySilverBattle(msg.sender, msg.value);
    }

    function pickSilverBattleWinner() public isSilverBattlePotFull {
        uint256 index = randomSilverBattle() % playersSilverBattle.length;
        address payable winningAddress = playersSilverBattle[index];
        uint256 winningAmount = (silverBattlePotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddress).transfer(
            (silverBattlePotMaxAmount * houseCut) / 100
        );
        delete playersSilverBattle;

        emit WinnerSilverBattle(winningAddress, winningAmount);
    }

    function setSilverBattleEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        silverBattleEntryPrice = _newEntryPrice;
    }

    function setSilverBattleMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        silverBattleMaxEntries = _newMaxEntries;
    }

    function randomSilverBattle() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersSilverBattle
                    )
                )
            );
    }

    function getPlayersSilverBattle()
        public
        view
        returns (address payable[] memory)
    {
        return playersSilverBattle;
    }

    /* goldBattle */

    function enterGoldBattle(uint256 _count) public payable {
        require(goldBattleIsLive, "gold battle is not live");
        require(
            msg.value == goldBattleEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersGoldBattle.length + _count <= goldBattleMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersGoldBattle.push(payable(msg.sender));
        }
        if (goldBattleMaxEntries == playersGoldBattle.length) {
            pickGoldBattleWinner();
        }

        emit EntryGoldBattle(msg.sender, msg.value);
    }

    function pickGoldBattleWinner() public isGoldBattlePotFull {
        uint256 index = randomGoldBattle() % playersGoldBattle.length;
        address payable winningAddress = playersGoldBattle[index];
        uint256 winningAmount = (goldBattlePotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddress).transfer(
            (goldBattlePotMaxAmount * houseCut) / 100
        );
        delete playersGoldBattle;

        emit WinnerGoldBattle(winningAddress, winningAmount);
    }

    function setGoldBattleEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        goldBattleEntryPrice = _newEntryPrice;
    }

    function setGoldBattleMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        goldBattleMaxEntries = _newMaxEntries;
    }

    function randomGoldBattle() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersGoldBattle
                    )
                )
            );
    }

    function getPlayersGoldBattle()
        public
        view
        returns (address payable[] memory)
    {
        return playersGoldBattle;
    }

    /* diamondBattle */

    function enterDiamondBattle(uint256 _count) public payable {
        require(diamondBattleIsLive, "diamond battle is not live");
        require(
            msg.value == diamondBattleEntryPrice * _count,
            "incorrent value sent to contract"
        );
        require(
            playersDiamondBattle.length + _count <= diamondBattleMaxEntries,
            "maximum entries reached"
        );
        for (uint256 i = 0; i < _count; i++) {
            playersDiamondBattle.push(payable(msg.sender));
        }
        if (diamondBattleMaxEntries == playersDiamondBattle.length) {
            pickDiamondBattleWinner();
        }

        emit EntryDiamondBattle(msg.sender, msg.value);
    }

    function pickDiamondBattleWinner() public isDiamondBattlePotFull {
        uint256 index = randomDiamondBattle() % playersDiamondBattle.length;
        address payable winningAddress = playersDiamondBattle[index];
        uint256 winningAmount = (diamondBattlePotMaxAmount * winnerCut) / 100;
        winningAddress.transfer(winningAmount);
        payable(houseAddress).transfer(
            (diamondBattlePotMaxAmount * houseCut) / 100
        );
        delete playersDiamondBattle;

        emit WinnerDiamondBattle(winningAddress, winningAmount);
    }

    function setDiamondBattleEntryPrice(uint256 _newEntryPrice)
        external
        restricted
    {
        diamondBattleEntryPrice = _newEntryPrice;
    }

    function setDiamondBattleMaxEntries(uint256 _newMaxEntries)
        external
        restricted
    {
        diamondBattleMaxEntries = _newMaxEntries;
    }

    function randomDiamondBattle() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        block.difficulty,
                        block.timestamp,
                        playersDiamondBattle
                    )
                )
            );
    }

    function getPlayersDiamondBattle()
        public
        view
        returns (address payable[] memory)
    {
        return playersDiamondBattle;
    }

    /* admin */

    function setSilverLotteryIsLive(bool _state) external restricted {
        silverLotteryIsLive = _state;
    }

    function setGoldLotteryIsLive(bool _state) external restricted {
        goldLotteryIsLive = _state;
    }

    function setDiamondLotteryIsLive(bool _state) external restricted {
        silverLotteryIsLive = _state;
    }

    function setSilverBattleIsLive(bool _state) external restricted {
        silverBattleIsLive = _state;
    }

    function setGoldBattleIsLive(bool _state) external restricted {
        goldBattleIsLive = _state;
    }

    function setDiamondBattleIsLive(bool _state) external restricted {
        diamondBattleIsLive = _state;
    }

    function setWinnerCut(uint256 _newWinnerCut) external restricted {
        winnerCut = _newWinnerCut;
    }

    function setHouseCut(uint256 _newHouseCut) external restricted {
        houseCut = _newHouseCut;
    }

    function setHouseAddress(address _newAddress) external restricted {
        houseAddress = _newAddress;
    }

    function withdrawFallback() external payable restricted {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}