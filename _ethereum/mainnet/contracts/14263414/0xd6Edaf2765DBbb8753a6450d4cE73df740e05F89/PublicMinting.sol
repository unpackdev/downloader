//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Minting.sol";

interface OldMinting {
    function amount() external view returns (uint256);

    function indexes(uint256 index) external view returns (uint256);
}

contract PublicMinting is Ownable {
    IERC721Custom public nft;
    OldMinting public minting;

    uint256 public startTimestamp;
    uint256 public duration = 7 days;
    uint256 public maxQuantity = 20;

    mapping(uint256 => uint256) public indexes;
    uint256 public amount;

    event Start(uint256 indexed timestamp, address indexed user);
    event Stop(uint256 indexed timestamp, address indexed user);
    event Mint(uint256 indexed timestamp, address indexed user, uint256 tokenId);
    event SyncAmount(uint256 indexed timestamp, address indexed user, uint256 amount);

    event SetMaxQuantity(
        uint256 indexed timestamp,
        address indexed user,
        uint256 maxQuantity
    );
    event SetDuration(uint256 indexed timestamp, address indexed user, uint256 duration);

    /// @dev mints nft to user
    /// @param quantity amount of nft to mint
    function mint(uint256 quantity) external {
        require(startTimestamp > 0, 'Minting has not been started');
        _mint(quantity, msg.sender);
    }

    /// @dev mints nfts for user by owner
    /// @param quantities amount of nft to mint
    /// @param users users
    function mintMass(uint256[] memory quantities, address[] memory users)
        external
        onlyOwner
    {
        require(startTimestamp == 0, 'Minting has been started');
        require(quantities.length == users.length, 'Different sizes');
        uint256 length = quantities.length;
        for (uint256 i = 0; i < length; i++) {
            _mint(quantities[i], users[i]);
        }
    }

    function _mint(uint256 quantity, address user) internal {
        // quantity = min(quantity, maxQuantity, amount)
        quantity = quantity > maxQuantity ? maxQuantity : quantity;
        quantity = quantity > amount ? amount : quantity;
        // ---------------------------------------------

        for (uint256 i = 0; i < quantity; i++) {
            uint256 randomness = addSalt(getRandomNumber(), i);
            uint256 index = range(randomness, 1, amount + 1);
            uint256 realIndex = getIndex(index);
            setIndex(index);
            nft.mint(user, realIndex);
            emit Mint(block.timestamp, user, realIndex);
        }
    }

    /// @dev returns real index from old minting contract
    function getIndex(uint256 index) internal view returns (uint256) {
        uint256 result = indexes[index];
        if (result == 0) result = minting.indexes(index);
        if (result == 0) result = index;
        return result;
    }

    /// @dev sets index of new tokenId
    function setIndex(uint256 index) internal {
        uint256 result = indexes[amount];
        if (result == 0) result = minting.indexes(amount);
        if (result == 0) result = amount;
        indexes[index] = result;
        amount--;
    }

    /// @dev starts minting
    function start() external onlyOwner {
        startTimestamp = block.timestamp;
        if (amount == 0) amount = minting.amount();
        emit Start(block.timestamp, msg.sender);
    }

    /// @dev stops minting
    function stop() external onlyOwner {
        startTimestamp = 0;
        emit Stop(block.timestamp, msg.sender);
    }

    /// @dev sets maxQuantity
    /// @param maxQuantity_ new max quantity
    function setMaxQuantity(uint256 maxQuantity_) external onlyOwner {
        maxQuantity = maxQuantity_;
        emit SetMaxQuantity(block.timestamp, msg.sender, maxQuantity_);
    }

    /// @dev sets new duration of public mint from startTimestamp
    /// @param duration_ new duration of minting
    function setDuration(uint256 duration_) external onlyOwner {
        duration = duration_;
        emit SetDuration(block.timestamp, msg.sender, duration_);
    }

    /// @dev syncs amount from old minting
    function syncAmount() external onlyOwner {
        amount = minting.amount();
        emit SyncAmount(block.timestamp, msg.sender, amount);
    }

    /// @dev generates random number
    function getRandomNumber() public view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))
            );
    }

    /// @dev maps number to range from `from` (includes) to `to` (excludes)
    /// @param number initial number
    /// @param from start of range
    /// @param to stop of range
    /// @return map result
    function range(
        uint256 number,
        uint256 from,
        uint256 to
    ) public pure returns (uint256) {
        return (number % (to - from)) + from;
    }

    /// @dev adds salt to value with hash function
    /// @param value which salting
    /// @param salt salt
    function addSalt(uint256 value, uint256 salt) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(value, salt)));
    }

    /// @dev contructor
    constructor(address nft_, address minting_) {
        nft = IERC721Custom(nft_);
        minting = OldMinting(minting_);
    }
}
