// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract JackpotRoyale is ERC721Enumerable, Ownable, ReentrancyGuard {
    uint256 private Max_Total_Supply = 9999;
    uint256 private Supply_Per_Address = 10;
    uint256 private Unit_Price = 0.05 ether;
    string private BaseURI;

    mapping(address => uint256) private tokenMintedByAddress;

    enum MintingStatus {
        Start,
        Pause,
        Close
    }

    MintingStatus private CurrentMintingStatus;

    event MintingStatusChange(MintingStatus status);
    event OnMintToken(uint256 mintedTokens, uint256 contractBalance);
    event OnTokenPerAddress(uint256 tokenPerAddress);

    modifier isEligibleToMint(uint256 _numberOfTokens) {
        require(
            tx.origin == msg.sender && !Address.isContract(msg.sender),
            "Not allow EOA!"
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
            tx.origin == msg.sender && !Address.isContract(msg.sender),
            "Not allow EOA!"
        );
        require(
            CurrentMintingStatus == MintingStatus.Close,
            "Kindly close the minting"
        );
        require(
            ownerOf(_tokenId) != address(0),
            "There is no owner for this token "
        );
        _;
    }

    constructor(
        string memory _initBaseURI,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        CurrentMintingStatus = MintingStatus.Pause;
        setBaseUri(_initBaseURI);
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
        emit OnMintToken(totalSupply(), getContractBalance());
    }

    // ================================= Getters / Setters =================================

    // Contract Settings
    function getContractSetting()
        public
        view
        returns (
            uint256 unitPrice,
            uint256 totalSupply,
            uint256 mintedCount,
            uint256 contractBalance,
            uint256 mintingLimit,
            MintingStatus mintingStatus
        )
    {
        return (
            Unit_Price,
            Max_Total_Supply,
            getMintedCount(),
            getContractBalance(),
            Supply_Per_Address,
            CurrentMintingStatus
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
    function getContractBalance() internal view returns (uint256) {
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
