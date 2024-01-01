// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "./ERC20.sol";
import "./IERC721.sol";
import "./ConfirmedOwner.sol";
import "./VRFV2WrapperConsumerBase.sol";

contract VapeGame is ERC20, VRFV2WrapperConsumerBase, ConfirmedOwner {
    // game config params
    uint256 public immutable MIN_INVEST_TICK = 0.001 ether;
    uint256 public immutable VAPE_PRICE_TICK = 0.0005 ether;
    uint256 public immutable DIVIDEND_CONTRIBUTION = 35; // 35%
    uint256 public immutable POT_CONTRIBUTION = 35; // 35%
    uint256 public immutable TREASURY_CONTRIBUTION = 15; // 15%
    uint256 public immutable LOTTO_CONTRIBUTION = 15; // 15%
    uint256 public minInvest = 0.01 ether;
    uint256 public vapeTokenPrice = 0.0005 ether;
    uint256 public immutable ZOOMER_HITS = 20;
    uint256 public immutable MIN_ZOOMER = 10000000 ether;
    uint256 public immutable GAME_TIME;

    // game state
    uint256 public potValueETH = 0;
    uint256 public lottoValueETH = 0;
    uint256 public totalDividendsValueETH = 0;
    uint256 public finalPotValueETH = 0;
    uint256 public finalLottoValueETH = 0;
    address public finalLottoWinner;
    uint256 public collectedFee = 0; // accumulated eth fee
    uint256 public lastPurchasedTime;
    address payable public lastPurchasedAddress;
    mapping(uint256 => address) public hitters;
    mapping(address => uint256) paidDividends;
    uint256 public numHits = 0;
    bool public isPaused = true;

    // whitelisted tokens/nfts
    ERC20 public zoomer;
    address[] public nfts;

    // chainlink stuff
    uint32 callbackGasLimit = 100000;
    uint32 numWords = 1;
    uint16 requestConfirmations = 3;
    address public linkAddress;

    event TookAHit(
        address indexed user,
        uint256 amount,
        uint256 vapeTokenValue,
        uint256 potValueETH,
        uint256 lottoValueETH,
        uint256 totalDividendsValueETH,
        uint256 nextHitPrice
    );
    event GotDividend(address indexed user, uint256 amount, uint256 totalDividendsValueETH);
    event TookTheLastHit(address indexed user, uint256 amount);
    event LottoWon(address indexed user, uint256 amount);

    modifier notPaused() {
        require(!isPaused, "Contract is paused.");
        _;
    }

    constructor(uint256 _gameTime, address _zoomer, address[] memory _nfts, address _linkAddress, address _vrfV2Wrapper)
        ERC20("Vape", "VAPE")
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(_linkAddress, _vrfV2Wrapper)
    {
        GAME_TIME = _gameTime;
        zoomer = ERC20(_zoomer);

        nfts = _nfts;

        lastPurchasedTime = block.timestamp;
        linkAddress = _linkAddress;
    }

    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    function sweep() external onlyOwner {
        require(isPaused, "Can only sweep when paused.");
        potValueETH = 0;
        lottoValueETH = 0;
        totalDividendsValueETH = 0;
        payable(owner()).transfer(address(this).balance);
    }

    function startGame() external onlyOwner {
        isPaused = false;
        lastPurchasedTime = block.timestamp;
    }

    function hasEnoughZoomer(address user) public view returns (bool) {
        return zoomer.balanceOf(user) >= MIN_ZOOMER;
    }

    function hasNft(address user) public view returns (bool) {
        for (uint256 i = 0; i < nfts.length; i++) {
            if (IERC721(nfts[i]).balanceOf(user) > 0) {
                return true;
            }
        }
        return false;
    }

    function takeAVapeHit() public payable notPaused {
        require(msg.value >= minInvest, "ETH value below min invest");
        require((block.timestamp - lastPurchasedTime) <= GAME_TIME, "Time is over, pot can be claimed by winner.");
        if (numHits < ZOOMER_HITS) {
            require(
                hasEnoughZoomer(msg.sender) || hasNft(msg.sender),
                "You need at least MIN_ZOOMER or a whitelisted NFT to play the game."
            );
        }

        hitters[numHits] = msg.sender;
        numHits++;

        uint256 amount = _processEtherReceived(msg.value);

        uint256 vapetokenvalue = (amount * 1e18) / vapeTokenPrice;

        lastPurchasedTime = block.timestamp;
        lastPurchasedAddress = payable(msg.sender);

        minInvest = minInvest + MIN_INVEST_TICK;
        vapeTokenPrice = vapeTokenPrice + VAPE_PRICE_TICK;

        _mint(msg.sender, vapetokenvalue);
        emit TookAHit(msg.sender, amount, vapetokenvalue, potValueETH, lottoValueETH, totalDividendsValueETH, minInvest);
    }

    function getMyDividend(address useraddress) public view returns (uint256) {
        uint256 userbalance = balanceOf(useraddress);

        uint256 share = (totalDividendsValueETH * userbalance) / totalSupply() - paidDividends[useraddress];
        return share;
    }

    function payMyDividend() public {
        require(getMyDividend(msg.sender) > 0, "No dividend for payout");
        uint256 remainingDividend = getMyDividend(msg.sender);
        paidDividends[msg.sender] += remainingDividend;
        payable(msg.sender).transfer(remainingDividend);
        emit GotDividend(msg.sender, remainingDividend, totalDividendsValueETH);
    }

    function paydDevFee() public onlyOwner {
        payable(owner()).transfer(collectedFee);
        collectedFee = 0;
    }

    function takeTheLastHit() public onlyOwner notPaused {
        require((block.timestamp >= lastPurchasedTime), "No.");
        require((block.timestamp - lastPurchasedTime) > GAME_TIME, "Time is not over yet, countdown still running.");
        lastPurchasedAddress.transfer(potValueETH);
        emit TookTheLastHit(lastPurchasedAddress, potValueETH);
        finalPotValueETH = potValueETH;
        potValueETH = 0;
        isPaused = true;
        requestRandomness(callbackGasLimit, requestConfirmations, numWords);
    }

    function _processEtherReceived(uint256 _amountIn) internal returns (uint256 amountOut) {
        uint256 _dividend = (_amountIn * DIVIDEND_CONTRIBUTION * 1000) / 100000;
        uint256 _pot = (_amountIn * POT_CONTRIBUTION * 1000) / 100000;
        uint256 _treasury = (_amountIn * TREASURY_CONTRIBUTION * 1000) / 100000;
        uint256 _lotto = _amountIn - _dividend - _pot - _treasury;

        // amountOut is dividend and pot together
        amountOut = _dividend + _pot;

        collectedFee += _treasury;
        lottoValueETH += _lotto;
        potValueETH += _pot;
        totalDividendsValueETH += _dividend;
    }

    function fulfillRandomWords(uint256, /*_requestId*/ uint256[] memory _randomWords) internal override {
        uint256 randomnumber = _randomWords[0] % numHits;
        address winner = hitters[randomnumber];
        payable(winner).transfer(lottoValueETH);
        emit LottoWon(winner, lottoValueETH);
        finalLottoValueETH = lottoValueETH;
        lottoValueETH = 0;
        finalLottoWinner = winner;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require((msg.sender == owner() || from == address(0)), "You are not the owner, only owner can transfer tokens.");
    }

    receive() external payable {
        _processEtherReceived(msg.value);
    }
}
