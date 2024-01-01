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

contract EnstoolsMarketplace is OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC721Holder {
    using Strings for uint256;
    using Counters for Counters.Counter;
    
    address private signer;

    struct ListingEntry {
        address creator;
        uint256 tokenId;
        uint256 createdAt;
        uint256 listingUntil;
        uint256 selectedAt;
        uint256 price;
        address buyer;
        bool cancelled;
    }

    event DomainListed(uint256 listingIndex, address creator, uint256 tokenId, uint256 createdAt, uint256 listingUntil, uint256 price);
    event NewBuy(uint256 listingIndex, address bidder, uint256 amount, uint256 bidAt);
    event ListingCancelled(uint256 listingIndex);

    mapping(uint256 => ListingEntry) public listingEntries;
    mapping(uint256 => uint256) public bidCount;
    uint256 listingCount;

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
        listingCount = 0;
        FEE_PERCENTAGE = 100;
        FEE_DENOMINATOR = 10000;
        PRICE_OFFSET = 100;
    }

    function createListing(uint256 _tokenId, uint256 _listingUntil, uint256 _price) external {
        IERC721(ensNFT).safeTransferFrom(msg.sender, address(this), _tokenId);

        ListingEntry storage _listingEntry = listingEntries[listingCount];

        _listingEntry.creator = msg.sender;
        _listingEntry.tokenId = _tokenId;
        _listingEntry.createdAt = getTimestamp();
        _listingEntry.listingUntil = _listingUntil;
        _listingEntry.price = _price;
        _listingEntry.cancelled = false;

        listingCount += 1;
        emit DomainListed(listingCount - 1, _listingEntry.creator, _listingEntry.tokenId, _listingEntry.createdAt, _listingEntry.listingUntil, _listingEntry.price);
    }

    function buy(uint256 _listingId, uint256 _paymentValue) external payable {
        require(_listingId < listingCount, concatenateStrings("Listing Id should be less than ", uint2str(listingCount)));

        ListingEntry storage _listingEntry = listingEntries[_listingId];
        require(_paymentValue == msg.value && _paymentValue == _listingEntry.price);        
        require(getTimestamp() < _listingEntry.listingUntil, "Listing is ended");
        require(!_listingEntry.cancelled, "Listing is cancelled");

        _listingEntry.selectedAt = getTimestamp();
        _listingEntry.buyer = msg.sender;

        payable(_listingEntry.creator).transfer(_listingEntry.price * (FEE_DENOMINATOR - FEE_PERCENTAGE) / FEE_DENOMINATOR);
        IERC721(ensNFT).safeTransferFrom(address(this), msg.sender, _listingEntry.tokenId);
            
        emit NewBuy(_listingId, msg.sender, _paymentValue, _listingEntry.selectedAt);
    }

    function cancelListing(uint256 _listingId) external {
        ListingEntry storage _listingEntry = listingEntries[_listingId];
        require(_listingEntry.creator == msg.sender, "Should be creator");
        require(_listingEntry.cancelled == false, "Already cancelled");
        require(_listingEntry.selectedAt == 0, "Already ended");

        IERC721(ensNFT).safeTransferFrom(address(this), msg.sender, _listingEntry.tokenId);
        _listingEntry.cancelled = true;
        _listingEntry.selectedAt = getTimestamp();

        emit ListingCancelled(_listingId);
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

    function getListingCount() public view returns (uint256) {
        return listingCount;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    modifier isSigner {
        require(_msgSender() == signer, "This function can only be called by an signer");
        _;
    }

    modifier delegatedOnly() {
        require(initializedFlag, "The library is locked. No direct 'call' is allowed");
        _;
    }
}