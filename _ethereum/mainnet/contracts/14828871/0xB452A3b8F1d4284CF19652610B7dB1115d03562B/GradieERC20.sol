// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "ERC20Capped.sol";
import "ERC20.sol";
import "IERC20.sol";
import "Ownable.sol";
import "IERC721.sol";
import "ReentrancyGuard.sol";
import "ECDSA.sol";

contract GradieERC20 is Ownable, ERC20, ERC20Capped, ReentrancyGuard {
    using ECDSA for bytes32;

    IERC721 public parentNFT =
        IERC721(0xFE93785F5AD4C5a740628f9b950bef90C67260d9);
    // date that start calculating claimable rewards
    uint256 public startingTimestamp = 1653235200;
    // map token id to last claimed timestamp
    mapping(uint256 => uint256) public tokenLastUpdated;
    uint256 public presaleMaxSupply = 10000000 ether;
    uint256 public presaleSold;
    uint256 public presalePerLotPrice = 0.025 ether;
    uint256 public presalePerLotAmount = 1000 ether;
    uint256 public rewardPerDay = 50 ether;
    //owners addresses
    address public owner1 = 0x5E2448CE7bfAebE840e6E6dd2600c0aa9D88f4F7;
    address public owner2 = 0xAE175b64cE7C4Df5cf3e07bb28Bcbaea847F3683;
    address public owner3 = 0x3E68D784d04ED054Be8d8c21482D40d741177B5A;

    address public verifyAddress = 0xD8f94d447c5f7dfB5a6278be1e927bd00cf1c851;

    //list of operators, for future utilities
    mapping(address => bool) public isOperator;

    constructor() ERC20("Gradie Origin", "$GO") ERC20Capped(100000000 ether) {
        //premine
        _mint(msg.sender, 30000000 ether);
        _approve(msg.sender, address(this), 10000000 ether);
    }

    function publicMint(uint256 _amount) public payable {
        require(
            presaleSold + (_amount * presalePerLotAmount) <= presaleMaxSupply,
            "max supply exceeded"
        );
        require(_amount > 0, "mint amount cannot be 0");
        require(
            msg.value >= _amount * presalePerLotPrice,
            "insufficient funds"
        );

        presaleSold += (_amount * presalePerLotAmount);
        _transfer(owner(), msg.sender, _amount * presalePerLotAmount);
    }

    function claim(
        uint256[] calldata _tokenIds,
        uint256[] calldata _bonuses,
        bytes[] calldata _signatures
    ) public nonReentrant {
        require(
            block.timestamp > startingTimestamp,
            "claim has not started yet"
        );
        require(
            _tokenIds.length > 0,
            "need to input atleast one token id to claim"
        );
        require(
            _tokenIds.length == _bonuses.length &&
                _bonuses.length == _signatures.length,
            "invalid input"
        );

        uint256 totalRewards = getTotalClaimableAmount(
            _tokenIds,
            _bonuses,
            _signatures
        );
        require(totalRewards > 0, "there's no reward available");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                parentNFT.ownerOf(_tokenIds[i]) == msg.sender,
                "you're not the NFT(s) holder"
            );

            if (tokenLastUpdated[_tokenIds[i]] == 0)
                tokenLastUpdated[_tokenIds[i]] = startingTimestamp;
            uint256 dayPassed = (block.timestamp -
                tokenLastUpdated[_tokenIds[i]]) / 1 days;
            tokenLastUpdated[_tokenIds[i]] += dayPassed * 1 days;
        }
        _mint(msg.sender, totalRewards);
    }

    function getTotalClaimableAmount(
        uint256[] calldata _tokenIds,
        uint256[] calldata _bonuses,
        bytes[] calldata _signatures
    ) public view returns (uint256) {
        if (block.timestamp < startingTimestamp) return 0;
        if (_tokenIds.length == 0) return 0;
        require(
            _tokenIds.length == _bonuses.length &&
                _bonuses.length == _signatures.length,
            "invalid input"
        );

        uint256 totalRewards = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _id = _tokenIds[i];

            uint256 _verifiedBonus = 0;
            if (
                (tokenLastUpdated[_id] == 0 ||
                    tokenLastUpdated[_id] == startingTimestamp) &&
                _bonuses[i] != 0 &&
                verifyOwnerSignature(
                    keccak256(abi.encode(_id, _bonuses[i])),
                    _signatures[i]
                )
            ) {
                _verifiedBonus = _bonuses[i];
            }

            uint256 lastUpdatedTime = tokenLastUpdated[_id];
            if (lastUpdatedTime == 0) lastUpdatedTime = startingTimestamp;
            uint256 dayPassed = (block.timestamp - lastUpdatedTime) / 1 days;

            totalRewards +=
                dayPassed *
                (rewardPerDay /
                    (100000000 ether / (100000000 ether - totalSupply()))) +
                (_verifiedBonus * 1 ether);
        }
        return totalRewards;
    }

    function getCurrentDailyYield() public returns (uint256) {
        return
            rewardPerDay /
            (100000000 ether / (100000000 ether - totalSupply()));
    }

    function getOwner(uint256 _id) public view returns (address) {
        return parentNFT.ownerOf(_id);
    }

    function setNFTContract(address _set) external onlyOwner {
        parentNFT = IERC721(_set);
    }

    function setVerifyAddress(address _set) external onlyOwner {
        verifyAddress = _set;
    }

    function setStartingTimestamp(uint256 _set) external onlyOwner {
        startingTimestamp = _set;
    }

    function setPerDayReward(uint256 _set) external onlyOwner {
        rewardPerDay = _set;
    }

    function setPresalePerLotPrice(uint256 _set) external onlyOwner {
        presalePerLotPrice = _set;
    }

    function setPresalePerLotAmount(uint256 _set) external onlyOwner {
        presalePerLotAmount = _set;
    }

    function setMaxSupply(uint256 _set) external onlyOwner {
        presaleMaxSupply = _set;
    }

    //Operator - used for future utilities
    modifier onlyOperator() {
        require(
            isOperator[_msgSender()],
            "caller is not allowed to call this function"
        );
        _;
    }

    function setOperator(address _address, bool _set) external onlyOwner {
        isOperator[_address] = _set;
    }

    function mint(address to, uint256 amount) public onlyOperator {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) public onlyOperator {
        _burn(to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }

    function verifyOwnerSignature(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            hash.toEthSignedMessageHash().recover(signature) == verifyAddress;
    }

    function withdrawAll() external onlyOwner {
        uint256 amount = address(this).balance / 3;
        require(amount > 0, "withdraw balance must be larger than 0");
        _widthdraw(owner1, amount);
        _widthdraw(owner2, amount);
        _widthdraw(owner3, amount);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
