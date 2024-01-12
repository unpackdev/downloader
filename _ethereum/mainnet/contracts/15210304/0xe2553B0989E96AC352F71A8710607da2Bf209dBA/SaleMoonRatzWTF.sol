// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./AccessLock.sol";
import "./IMoonRatzWTF.sol";

/// @title MoonRatzWTF Mint
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice NFT Sale contract for minting MoonRatzWTF NFTs
contract SaleMoonRatzWTF is AccessLock, Pausable, ReentrancyGuard {
    IMoonRatzWTF public NFT;
    uint256 public limit;
    uint256 public userLimit;
    uint256 public count;
    mapping(address => uint256) public userCount;

    event Minted(address indexed user, uint256 quantity);
    event LimitUpdated(address indexed owner, uint256 limit);
    event UserLimitUpdated(address indexed owner, uint256 userLimit);

    constructor(
        IMoonRatzWTF _NFT,
        uint256 _limit,
        uint256 _userLimit
    ) {
        NFT = _NFT;
        _pause();
        setLimit(_limit);
        setUserLimit(_userLimit);
    }

    function setLimit(uint256 _limit) public onlyOwner {
        limit = _limit;
        emit LimitUpdated(owner(), limit);
    }

    function setUserLimit(uint256 _userLimit) public onlyOwner {
        userLimit = _userLimit;
        emit UserLimitUpdated(owner(), userLimit);
    }

    function _mint(uint256 quantity) private {
        NFT.mint(msg.sender, quantity);
        count = count + quantity;
        userCount[msg.sender] = userCount[msg.sender] + quantity;
        emit Minted(msg.sender, quantity);
    }

    function mint(uint256 quantity)
        external
        whenNotPaused
        nonReentrant
    {
        require((count + quantity) <= limit, "Sold out");
        require(
            ((userCount[msg.sender] + quantity) <= userLimit) ||
                msg.sender == owner(),
            "Wallet limit reached"
        );
        _mint(quantity);
    }

    function withdraw(address payable wallet, uint256 amount)
        external
        onlyOwner
    {
        wallet.transfer(amount);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }
}
