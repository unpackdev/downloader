// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";


interface ExternalContract {
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract JackpotRoyale_SE_HWS_R1 is ERC1155, Ownable {
    string private baseUri; // Pinata URL
    string public name; // Collection Name
    string public symbol; // Collection symbol
    address private externalContractAddress =
        0xFdbb8329f5755c4cD0A1Ac172D8a4dF66969c1ef; // Collabrated contract address
    address private communityWalletAddress =
        0xC416a17966FdD5023Fc00E4e0b79558416e7D531; // Community wallet address

    uint256 private _unitPrice = 0.015 ether;
    uint256 private maxSupply = 9999;

    uint256[] private mintedTokenIds;
    mapping(uint256 => address) private tokenOwner;

    enum MintingStatus {
        Start,
        Pause,
        Close
    }

    MintingStatus private CurrentMintingStatus;

    // Events
    event MintingStatusChange(MintingStatus status);
    event OnMintToken(uint256[] mintedTokens, uint256 contractBalance);
    event OnSendAward(
        uint256 firstPrize,
        uint256 secondPrize,
        uint256 thirdPrize,
        uint256 communityPrize
    );

    // Modifiers
    modifier beforeMint(uint256[] memory _tokenIds) {
        require(
            tx.origin == msg.sender && !Address.isContract(msg.sender),
            "Not allow EOA!"
        );
        require(
            externalContractBalance(msg.sender) > 0,
            "You are not eligible for mint"
        );
        require(
            CurrentMintingStatus == MintingStatus.Start,
            "Minting not started yet!"
        );
        require(_tokenIds.length > 0, "Token id's missing");
        require(
            mintedTokenIds.length + _tokenIds.length <= maxSupply,
            string(
                abi.encodePacked(
                    Strings.toString(maxSupply - mintedTokenIds.length),
                    " Tokens left to be mint "
                )
            )
        );

        bool _validTokenIds = true;
        bool _tokenNotMintedYet = true;
        uint256 _tokenId;

        for (uint256 index = 0; index < _tokenIds.length; ++index) {
            _tokenId = _tokenIds[index];
            if (tokenOwner[_tokenId] != address(0)) {
                _tokenNotMintedYet = false;
                break;
            }
            if (_tokenId < 1 || _tokenId > maxSupply) {
                _validTokenIds = false;
                break;
            }
        }
        require(
            _validTokenIds,
            string(
                abi.encodePacked(
                    Strings.toString(_tokenId),
                    " is invalid token Id "
                )
            )
        );
        require(
            _tokenNotMintedYet,
            string(
                abi.encodePacked(
                    "Token Id ",
                    Strings.toString(_tokenId),
                    " is already minted"
                )
            )
        );

        require(
            msg.value >= getUnitPrice() * _tokenIds.length,
            "Not enough ETH sent"
        );
        _;
    }

    modifier beforeSendReward(
        uint256 _firstWinnerTokenId,
        uint256 _secondWinnerTokenId,
        uint256 _thirdWinnerTokenId
    ) {
        require(
            tx.origin == msg.sender && !Address.isContract(msg.sender),
            "Not allow EOA!"
        );
        require(
            CurrentMintingStatus == MintingStatus.Close,
            "Kindly close the minting"
        );
        require(
            ownerOf(_firstWinnerTokenId) != address(0),
            string(
                abi.encodePacked(
                    "Token Id ",
                    Strings.toString(_firstWinnerTokenId),
                    " has no owner"
                )
            )
        );
        require(
            ownerOf(_secondWinnerTokenId) != address(0),
            string(
                abi.encodePacked(
                    "Token Id ",
                    Strings.toString(_secondWinnerTokenId),
                    " has no owner"
                )
            )
        );
        require(
            ownerOf(_thirdWinnerTokenId) != address(0),
            string(
                abi.encodePacked(
                    "Token Id ",
                    Strings.toString(_thirdWinnerTokenId),
                    " has no owner"
                )
            )
        );
        _;
    }

    constructor(
        string memory _baseUri,
        string memory _name,
        string memory _symbol
    ) ERC1155(string(abi.encodePacked(_baseUri, "{id}.json"))) {
        name = _name;
        symbol = _symbol;
        baseUri = _baseUri;
        CurrentMintingStatus = MintingStatus.Pause;
    }

    function mintToken(uint256[] memory _tokenIds)
        public
        payable
        beforeMint(_tokenIds)
    {
        if (mintedTokenIds.length + _tokenIds.length == maxSupply) {
            CurrentMintingStatus = MintingStatus.Close;
            emit MintingStatusChange(CurrentMintingStatus);
        }
        for (uint256 index = 0; index < _tokenIds.length; ++index) {
            uint256 _tokenId = _tokenIds[index];
            _mint(msg.sender, _tokenId, 1, "");
            tokenOwner[_tokenId] = msg.sender;
            mintedTokenIds.push(_tokenId);
        }
        emit OnMintToken(mintedTokenIds, getContractBalance());
    }

    // Set - Get external contract address
    function getExternalContractAddress() public view returns (address) {
        return externalContractAddress;
    }

    function setExternalContractAddress(address _address) public onlyOwner {
        externalContractAddress = _address;
    }

    // Balance of minter in external contract
    function externalContractBalance(address _address)
        public
        view
        returns (uint256)
    {
        return ExternalContract(externalContractAddress).balanceOf(_address);
    }

    // Contract Settings
    function getContractSetting()
        public
        view
        returns (
            uint256 unitPrice,
            uint256 totalSupply,
            uint256 mintedCount,
            uint256 contractBalance,
            MintingStatus mintingStatus
        )
    {
        return (
            _unitPrice,
            maxSupply,
            getMintedCount(),
            getContractBalance(),
            CurrentMintingStatus
        );
    }

    // Total token minted
    function getMintedCount() internal view returns (uint256) {
        return mintedTokenIds.length;
    }

    // Get contract balance
    function getContractBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    // Owner of token id
    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_tokenId > 0 && _tokenId <= maxSupply, "Invalid token id");
        return tokenOwner[_tokenId];
    }

    // Get array of minted token ids
    function getMintedTokenIds() public view returns (uint256[] memory) {
        return mintedTokenIds;
    }

    // Token price
    function getUnitPrice() public view returns (uint256) {
        return _unitPrice;
    }

    // Start, stop and close MINTING
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

    // Send Award To Winner
    function sendAward(
        uint256 _firstWinnerTokenId,
        uint256 _secondWinnerTokenId,
        uint256 _thirdWinnerTokenId
    )
        public
        onlyOwner
        beforeSendReward(
            _firstWinnerTokenId,
            _secondWinnerTokenId,
            _thirdWinnerTokenId
        )
    {
        uint256 balance = address(this).balance;
        uint256 firstWinnerPrize = (balance / 100) * 30; // 30%
        uint256 secondWinnerPrize = (balance / 100) * 15; // 15%
        uint256 thirdWinnerPrize = (balance / 100) * 5; // 05%
        uint256 communityPrize = balance -
            (firstWinnerPrize + secondWinnerPrize + thirdWinnerPrize); // 50%

        address firstWinner = ownerOf(_firstWinnerTokenId);
        address secondWinner = ownerOf(_secondWinnerTokenId);
        address thirdWinner = ownerOf(_thirdWinnerTokenId);

        payable(firstWinner).transfer(firstWinnerPrize);
        payable(secondWinner).transfer(secondWinnerPrize);
        payable(thirdWinner).transfer(thirdWinnerPrize);
        payable(communityWalletAddress).transfer(communityPrize);
        emit OnSendAward(firstWinnerPrize,secondWinnerPrize, thirdWinnerPrize, communityPrize);
    }

    // ERC1155 Override Methods

    // @ Override
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        super.safeTransferFrom(from, to, id, amount, data);
        tokenOwner[id] = to;
    }

    // @ Override
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual override {
        require(false, "Method not allowed");
    }

    // @ Override
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }
}
