// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./ECDSA.sol";
import "./Context.sol";
import "./Counters.sol";
import "./ERC721A.sol";
import "./IERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";

contract NFTEntry is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable {
    constructor() ERC721A("Libes Entry NFT", "LbENT") {}

    using ECDSA for bytes32;

    receive() external payable {}

    string private _baseURIExtended;
    address public entryAddress;
    uint256 public quantityUserMinted = 0;
    uint256[] Tokens;
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    mapping(address => mapping(uint256 => bool)) seenNonces;
    mapping(uint256 => uint256[]) public orders;

    event AdminMint(address caller, uint256 quantity, uint256 totalSupply);
    event UserMint(
        address caller,
        uint256 quantity,
        uint256 orderId,
        uint256[] tokenId
    );
    event Withdraw(address caller, uint256 amount);

    modifier verifySignature(
        uint256 nonce,
        uint256 orderId,
        uint256 timestamp,
        uint256 quantity,
        bytes memory signature
    ) {
        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, nonce, orderId, quantity)
        );
        // This recreates the message hash that was signed on the client.
        bytes32 messageHash = hash.toEthSignedMessageHash();
        // Verify that the message's signer is the owner of the order
        require(messageHash.recover(signature) == owner(), "INVALID SIGNATURE");
        require(!seenNonces[msg.sender][nonce], "USED NONCE");
        require(timestamp >= block.timestamp, "SIGNATURE EXPIRED");
        seenNonces[msg.sender][nonce] = true;
        _;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIExtended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function getOwnershipAt(
        uint256 index
    ) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function totalMinted() public view onlyOwner returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view onlyOwner returns (uint256) {
        return _totalBurned();
    }

    function numberBurned(
        address owner
    ) public view onlyOwner returns (uint256) {
        return _numberBurned(owner);
    }

    function numberMinted(
        address owner
    ) public view onlyOwner returns (uint256) {
        return _numberMinted(owner);
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setEntryAddress(address _entryAddress) public onlyOwner {
        require(_entryAddress != address(0), "INVALID ENTRY ADDRESS.");
        entryAddress = _entryAddress;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function userMint(
        uint256 eth,
        uint256 quantity,
        uint256 nonce,
        uint256 timestamp,
        uint256 orderId,
        bytes memory signature
    )
        public
        payable
        verifySignature(nonce, orderId, timestamp, quantity, signature)
    {
        require(quantity > 0, "QUANTITY MUST BE GREATER THAN 0");
        require(
            balanceOf(address(this)) >= quantity,
            "QUANTITY IS MORE THAN POOL"
        );
        require(
            msg.value >= eth,
            "BALANCE TO MINT INSUFFICIENT"
        );
        TransferHelper.safeTransferETH(
            address(this),
            eth
        );

        for (
            uint256 i = quantityUserMinted;
            i < (quantityUserMinted + quantity);
            i++
        ) {
            transferToken(address(this), msg.sender, i);
            orders[orderId].push(i);
        }

        quantityUserMinted += quantity;
        emit UserMint(msg.sender, quantity, orderId, orders[orderId]);
    }

    function getOrder(uint256 _orderId) public view returns (uint256[] memory) {
        return orders[_orderId];
    }

    function mint(uint256 quantity) public onlyOwner {
        _mint(address(this), quantity);
        uint256 totalSupply = totalSupply();
        emit AdminMint(msg.sender, quantity, totalSupply);
    }

    function safeMint (
        address to,
        uint256 quantity,
        bytes memory _data
    ) public onlyOwner {
        _safeMint(to, quantity, _data);
    }
 
    function withdraw(uint256 amount) public onlyOwner {
        require(amount > 0, "AMOUNT MUST BE GREATER THAN 0");

        address _owner = owner();
        (bool sent, ) = _owner.call{value: amount}("");
        require(sent, "FAILED TO SEND ETHER");
        emit Withdraw(msg.sender, amount);
    }

    function safeMint(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    function lockToken(uint256[] memory tokenid) public {
        require(msg.sender == entryAddress, "YOU NOT ALLOWED TO LOCK TOKEN");
        _lockToken(tokenid);
    }

    function unlockToken(uint256[] memory tokenid) public {
        require(msg.sender == entryAddress, "YOU NOT ALLOWED TO LOCK TOKEN");
        _unlockToken(tokenid);
    }

    function burn(uint256 tokenId, bool approvalCheck) public onlyOwner {
        _burn(tokenId, approvalCheck);
    }

    function toString(uint256 x) public pure returns (string memory) {
        return _toString(x);
    }

    function getOwnershipOf(
        uint256 index
    ) public view returns (TokenOwnership memory) {
        return _ownershipOf(index);
    }

    function initializeOwnershipAt(uint256 index) public onlyOwner {
        _initializeOwnershipAt(index);
    }

    function random(uint256 number) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % number;
    }

    function transferToken(address from, address to, uint256 tokenId) private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
        require(lock[tokenId] != true, "TOKEN HAS BEEN LOCKED!");

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED |
                    _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }
}
