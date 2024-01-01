// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./MerkleProofUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./console.sol";

contract LibraryLockDataLayout {
  bool public initializedFlag;
}

contract EnstoolsAuction is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721Holder {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    address private signer;

    struct AuctionEntry {
        address creator;
        uint256 tokenId;
        uint256 createdAt;
        uint256 auctionUntil;
        uint256 selectedAt;
        uint256 startPrice;
        string auctionName;
        address buyer;
        uint256 buyAmount;
        bool cancelled;
    }

    event AuctionCreated(uint256 auctionIndex, address creator, uint256 tokenId, uint256 createdAt, uint256 auctionUntil, uint256 startPrice, string auctionName);
    event NewBuy(uint256 auctionIndex, address bidder, uint256 amount, uint256 bidAt);
    event AuctionCancelled(uint256 auctionIndex);

    mapping(uint256 => AuctionEntry) public auctionEntries;
    mapping(uint256 => uint256) public bidCount;
    uint256 auctionCount;

    address ensNFT;

    uint256 FEE_PERCENTAGE;
    uint256 FEE_DENOMINATOR;

    bool initializedFlag;

    address newOwner;

    uint256 PRICE_OFFSET;

    function initialize(
        address _ensNFT
    ) public initializer {
        require(!initializedFlag, "Contract is already initialized");
        signer = _msgSender();
        ensNFT = _ensNFT;
        auctionCount = 0;
        FEE_PERCENTAGE = 1000;
        FEE_DENOMINATOR = 10000;
        PRICE_OFFSET = 100;
    }

    function createAuction(string calldata _auctionName, uint256 _tokenId, uint256 _auctionUntil, uint256 _startPrice) external {
        IERC721(ensNFT).safeTransferFrom(msg.sender, address(this), _tokenId);

        AuctionEntry storage _auctionEntry = auctionEntries[auctionCount];

        _auctionEntry.creator = msg.sender;
        _auctionEntry.tokenId = _tokenId;
        _auctionEntry.createdAt = getTimestamp();
        _auctionEntry.auctionUntil = _auctionUntil;
        _auctionEntry.startPrice = _startPrice;
        _auctionEntry.auctionName = _auctionName;
        _auctionEntry.cancelled = false;

        auctionCount += 1;
        emit AuctionCreated(auctionCount - 1, _auctionEntry.creator, _auctionEntry.tokenId, _auctionEntry.createdAt, _auctionEntry.auctionUntil, _auctionEntry.startPrice, _auctionEntry.auctionName);
    }

    function buy(uint256 _auctionId, uint256 _paymentValue) external payable {
        require(_auctionId < auctionCount, concatenateStrings("Auction Id should be less than ", uint2str(auctionCount)));
        require(_paymentValue == msg.value);

        AuctionEntry storage _auctionEntry = auctionEntries[_auctionId];
        require(getTimestamp() < _auctionEntry.auctionUntil, "Auction is ended");
        require(!_auctionEntry.cancelled, "Auction is cancelled");

        uint256 currentPrice = _auctionEntry.startPrice * (_auctionEntry.auctionUntil - getTimestamp()) / (_auctionEntry.auctionUntil - _auctionEntry.createdAt);
        uint256 rangeStart = currentPrice * (FEE_DENOMINATOR - PRICE_OFFSET) / FEE_DENOMINATOR;
        uint256 rangeEnd = currentPrice * (FEE_DENOMINATOR + PRICE_OFFSET) / FEE_DENOMINATOR;
        
        require(_paymentValue >= rangeStart && _paymentValue <= rangeEnd, "Payment value is not reasonable");

        _auctionEntry.selectedAt = getTimestamp();
        _auctionEntry.buyer = msg.sender;
        _auctionEntry.buyAmount = _paymentValue;

        payable(_auctionEntry.creator).transfer(_auctionEntry.buyAmount * (FEE_DENOMINATOR - FEE_PERCENTAGE) / FEE_DENOMINATOR);
        IERC721(ensNFT).safeTransferFrom(address(this), msg.sender, _auctionEntry.tokenId);
            
        emit NewBuy(_auctionId, msg.sender, _paymentValue, _auctionEntry.selectedAt);
    }

    function cancelAuction(uint256 _auctionId) external {
        AuctionEntry storage _auctionEntry = auctionEntries[_auctionId];
        require(_auctionEntry.creator == msg.sender, "Should be creator");
        require(_auctionEntry.cancelled == false, "Already cancelled");
        require(_auctionEntry.selectedAt == 0, "Already ended");

        IERC721(ensNFT).safeTransferFrom(address(this), msg.sender, _auctionEntry.tokenId);
        _auctionEntry.cancelled = true;
        _auctionEntry.selectedAt = getTimestamp();

        emit AuctionCancelled(_auctionId);
    }

    function getCurrentPrice(uint256 _auctionId) public view returns(uint256 currentPrice) {
        require(_auctionId < auctionCount, concatenateStrings("Auction Id should be less than ", uint2str(auctionCount)));

        AuctionEntry memory _auctionEntry = auctionEntries[_auctionId];
        require(getTimestamp() < _auctionEntry.auctionUntil, "Auction is ended");
        require(!_auctionEntry.cancelled, "Auction is cancelled");

        currentPrice = _auctionEntry.startPrice * (getTimestamp() - _auctionEntry.createdAt) / (_auctionEntry.auctionUntil - _auctionEntry.createdAt);
    }

    function uint2str(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        
        return string(buffer);
    }

    function concatenateStrings(string memory a, string memory b) public pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function verify(
        bytes memory _input,
        bytes memory _signature
    ) private view returns (bool) {
        bytes32 messageHash = getMessageHash(_input);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHash(bytes memory _input) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_input));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function getSigner() public view returns (address) {
        return signer;
    }

    function updateSigner(address _signer) external isSigner {
        signer = _signer;
    }

    function setNewOwner(address _newOwner) external isSigner {
        newOwner = _newOwner;
    }

    function updateFee(uint256 _newFee) external isSigner {
        FEE_PERCENTAGE = _newFee;
    }

    function updatePriceOffset(uint256 _newOffset) external isSigner {
        PRICE_OFFSET = _newOffset;
    }

    function setEnsNFT(address _ensNFT) external isSigner {
        ensNFT = _ensNFT;
    }

    function recoverETH() external isSigner {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}('');
            require(success);
        }
    }

    function getAuctionCount() public view returns (uint256) {
        return auctionCount;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    modifier isSigner {
        require(_msgSender() == signer || _msgSender() == newOwner, "This function can only be called by an signer");
        _;
    }

    modifier delegatedOnly() {
        require(initializedFlag, "The library is locked. No direct 'call' is allowed");
        _;
    }
}