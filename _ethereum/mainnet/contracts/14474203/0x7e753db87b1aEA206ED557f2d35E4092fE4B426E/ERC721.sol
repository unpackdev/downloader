// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract JackpotRoyale is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 private Max_Total_Supply = 9999; 
    uint256 private Supply_Per_Address = 5;
    uint256 private Unit_Price = 0.05 ether;
    string private BaseURI;

    mapping(address => uint256) private tokenMintedByAddress;

    enum MintingStatus {
        Start,
        Pause,
        Close
    }

    MintingStatus private CurrentMintingStatus;

    struct Digit {
        bool isRevelead;
        uint256 digit;
    }

    Digit private Thousands;
    Digit private Hundreds;
    Digit private Tens;
    Digit private Ones;

    event MintingStatusChange(MintingStatus _status);
    event OnDigitReveal(string _digits);
    event OnMintToken(uint256 _mintedTokens);
    event OnTokenPerAddress(uint256 _tokenPerAddress);

    modifier isEligibleToMint(uint256 _numberOfTokens) {
        require(
           tx.origin==msg.sender && !Address.isContract(msg.sender),"Not allow EOA!"
        );
        require(
            CurrentMintingStatus == MintingStatus.Start,
            "Minting not started yet!"
        );
        require(
            totalSupply() < Max_Total_Supply,
            "No tokens left to be minted!"
        ); 
        require(
            _numberOfTokens > 0,
            "Number of minting tokens should be more than zero!"
        );
        require(
            _numberOfTokens <= Supply_Per_Address,
            string(
                abi.encodePacked(
                    "Only ",
                    Strings.toString(Supply_Per_Address),
                    " tokens per address"
                )
            )
        );
        require(
            tokenMintedByAddress[msg.sender] + _numberOfTokens <=
                Supply_Per_Address,
            "You are exceeding your minting limit"
        );
        require(
            totalSupply() + _numberOfTokens <= Max_Total_Supply,
            string(
                abi.encodePacked(
                    "Only ",
                    Strings.toString(Max_Total_Supply - totalSupply()),
                    " token(s) left for minting"
                )
            )
        );
        require(
            msg.value >= getUnitPrice() * _numberOfTokens,
            "Not enough ETH sent"
        );
        _;
    }

    modifier beforeSendReward(uint256 _tokenId) {
        require(
           tx.origin==msg.sender && !Address.isContract(msg.sender),"Not allow EOA!"
        );
        require(
            CurrentMintingStatus == MintingStatus.Close,
            "Kindly close the minting"
        );
        require(allDigitRevealed(), "All digits are not revealed yet");
        require(
            ownerOf(_tokenId) != address(0),
            "There is no owner for this token "
        );
        _;
    }

    modifier beforeRevealingDigit(uint256 _digit) {
        require(
           tx.origin==msg.sender && !Address.isContract(msg.sender),"Not allow EOA!"
        );
        require(
            CurrentMintingStatus == MintingStatus.Close,
            "Minting is not closed yet!"
        );
        require(_digit >= 0 && _digit <= 9, "Invalid digit");
        _;
    }

    constructor(
        string memory _initBaseURI,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        CurrentMintingStatus = MintingStatus.Pause;
        setBaseUri(_initBaseURI);
        Thousands.isRevelead = false;
        Hundreds.isRevelead = false;
        Tens.isRevelead = false;
        Ones.isRevelead = false;
    }

    function mintToken(uint256 numberOfTokens)
        public
        payable
        isEligibleToMint(numberOfTokens)
    {
        uint256 supply = totalSupply();
        if (supply + numberOfTokens == Max_Total_Supply) {
            CurrentMintingStatus = MintingStatus.Close;
            emit MintingStatusChange(CurrentMintingStatus);
        }

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, supply + i);
            tokenMintedByAddress[msg.sender] += 1;
        }
        emit OnMintToken(totalSupply());
    }

    // ================================= Getters / Setters =================================

    // Contract Settings
    function getContractSetting()
        public
        view
        returns (
            uint256 uintPrice,
            uint256 totalSupply,
            uint256 mintedCount,
            uint256 mintingLimit,
            MintingStatus mintingStatus,
            bool allDigitsRevealed,
            string memory revealedDigits
        )
    {
        return (
            Unit_Price,
            Max_Total_Supply,
            getMintedCount(),
            Supply_Per_Address,
            CurrentMintingStatus,
            allDigitRevealed(),
            getRevealDigits()
        );
    }

    function getMintedCount() internal view returns (uint256) {
        return totalSupply();
    }

    // START / STOP MINTING
    function startMinting() public onlyOwner {
        require(
            CurrentMintingStatus != MintingStatus.Close,
            "Not allow to start minting"
        );
        CurrentMintingStatus = MintingStatus.Start;
        emit MintingStatusChange(CurrentMintingStatus);
    }

    function pauseMinting() public onlyOwner {
        require(
            CurrentMintingStatus != MintingStatus.Close,
            "Not allow to pause minting"
        );
        CurrentMintingStatus = MintingStatus.Pause;
        emit MintingStatusChange(CurrentMintingStatus);
    }

    function closeMinting() public onlyOwner {
        CurrentMintingStatus = MintingStatus.Close;
        emit MintingStatusChange(CurrentMintingStatus);
    }

    // Current minting status
    function getCurrentMintingStatus() public view returns (MintingStatus) {
        return CurrentMintingStatus;
    }

    // TOKEN PRICE
    function getUnitPrice() public view returns (uint256) {
        return Unit_Price;
    }

    // BASEURI
    function setBaseUri(string memory _baseUri) public onlyOwner {
        BaseURI = _baseUri;
    }

    function getBaseUri() public view returns (string memory) {
        return BaseURI;
    }

    // TOTAL TOKEN TO BE MINTED (10000)
    function setTotalToken(uint256 _totalToken) public onlyOwner {
        require(
            _totalToken >= totalSupply(),
            "Total token must be greater than currently minted token!"
        );
        Max_Total_Supply = _totalToken;
    }

    function getTotalToken() public view returns (uint256) {
        return Max_Total_Supply;
    }

    // TOTAL TOKEN PER ADDRESS
    function setTokenPerAddress(uint256 _mintingLimit) public onlyOwner {
        Supply_Per_Address = _mintingLimit;
        emit OnTokenPerAddress(Supply_Per_Address);
    }

    function getTokenPerAddress() public view returns (uint256) {
        return Supply_Per_Address;
    }

    // GET CONTRACT BALANCE
    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    // SEND AWARD TO WINNER
    function sendAward(uint256 _tokenId)
        public
        onlyOwner
        beforeSendReward(_tokenId)
    {
        uint256 balance = address(this).balance;
        address winner = ownerOf(_tokenId);
        payable(winner).transfer(balance);
    }

    // IS ADDRESS REACH HIS MINGINTG LIMIT
    function mintingLimitReached(address _minter) public view returns (bool) {
        return tokenMintedByAddress[_minter] == Supply_Per_Address;
    }

    // Digits Reveal
    function revealThousands(uint256 _digit)
        public
        onlyOwner
        beforeRevealingDigit(_digit)
    {
        Thousands.isRevelead = true;
        Thousands.digit = _digit;
        emit OnDigitReveal(getRevealDigits());
    }

    function revealHundreds(uint256 _digit)
        public
        onlyOwner
        beforeRevealingDigit(_digit)
    {
        Hundreds.isRevelead = true;
        Hundreds.digit = _digit;
        emit OnDigitReveal(getRevealDigits());
    }

    function revealTens(uint256 _digit)
        public
        onlyOwner
        beforeRevealingDigit(_digit)
    {
        Tens.isRevelead = true;
        Tens.digit = _digit;
        emit OnDigitReveal(getRevealDigits());
    }

    function revealOnes(uint256 _digit)
        public
        onlyOwner
        beforeRevealingDigit(_digit)
    {
        Ones.isRevelead = true;
        Ones.digit = _digit;
        emit OnDigitReveal(getRevealDigits());
    }

    function allDigitRevealed() public view returns (bool) {
        return
            Thousands.isRevelead &&
            Hundreds.isRevelead &&
            Tens.isRevelead &&
            Ones.isRevelead;
    }

    function getRevealDigits() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    Thousands.isRevelead
                        ? Strings.toString(Thousands.digit)
                        : "* ",
                    Hundreds.isRevelead
                        ? Strings.toString(Hundreds.digit)
                        : "* ",
                    Tens.isRevelead ? Strings.toString(Tens.digit) : "* ",
                    Ones.isRevelead ? Strings.toString(Ones.digit) : "*"
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        string memory val = Strings.toString(_tokenId);
        uint256 length = bytes(val).length;
        require(length > 0 && length <= 4, "Invalid token number");
        for (uint256 i = 1; i <= 4 - length; ++i) {
            val = string(abi.encodePacked("0", val));
        }
        return string(abi.encodePacked(BaseURI, val, ".json"));
    }
}
