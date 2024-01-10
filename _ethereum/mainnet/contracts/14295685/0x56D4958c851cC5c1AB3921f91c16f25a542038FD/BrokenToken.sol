//  _______  ______    _______  ___   _  _______  __    _    _______  ___      __   __  _______ 
// |  _    ||    _ |  |       ||   | | ||       ||  |  | |  |       ||   |    |  | |  ||  _    |
// | |_|   ||   | ||  |   _   ||   |_| ||    ___||   |_| |  |       ||   |    |  | |  || |_|   |
// |       ||   |_||_ |  | |  ||      _||   |___ |       |  |       ||   |    |  |_|  ||       |
// |  _   | |    __  ||  |_|  ||     |_ |    ___||  _    |  |      _||   |___ |       ||  _   | 
// | |_|   ||   |  | ||       ||    _  ||   |___ | | |   |  |     |_ |       ||       || |_|   |
// |_______||___|  |_||_______||___| |_||_______||_|  |__|  |_______||_______||_______||_______|
// 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ReentrancyGuard.sol";

interface IBrokenClub {
    function balanceOf(address owner) external view returns (uint256);
}

contract BrokenToken is ERC20, Ownable, ReentrancyGuard {
    IBrokenClub public BrokenClub;

    uint256 public BASE_RATE = 5 ether;
    uint256 public START;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastClaimDatetime;
    mapping(address => bool) public allowed;

    constructor(address brokenClub) ERC20("BrokenToken", "BRKN") {
        BrokenClub = IBrokenClub(brokenClub);
        allowed[brokenClub] = true;
    }

    modifier onlyAllowed() {
        require(allowed[msg.sender], "Unautorized access!");
        _;
    }

    function start() public onlyOwner {
        require(START == 0, "Already started");
        START = block.timestamp;
    }

    function setAllowed(address account, bool isAllowed) public onlyOwner {
        allowed[account] = isAllowed;
    }

    function getClaimableBalance(address account)
        external
        view
        returns (uint256)
    {
        return rewards[account] + getPending(account);
    }

    function getPending(address account) internal view returns (uint256) {
        if (START == 0) {
            return 0;
        } else {
            return (BrokenClub.balanceOf(account) *
                    BASE_RATE * (
                        block.timestamp - (lastClaimDatetime[account] > START ? lastClaimDatetime[account] : START)
                    )) / 1 days;
        }
    }

    // ( 4 * 5 * (86400000) ) / 1 days;
    function update(address from, address to) external onlyAllowed {
        if (from != address(0)) {
            rewards[from] += getPending(from);
            lastClaimDatetime[from] = block.timestamp;
        }
        if (to != address(0)) {
            rewards[to] += getPending(to);
            lastClaimDatetime[to] = block.timestamp;
        }
    }

    function redeem(uint256 amount) external onlyAllowed {
        transfer(address(this), amount);
    }

    function withdrawBrokenTokens(address _tokenContract, uint256 _amount) external onlyOwner nonReentrant {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function claim(address account) external nonReentrant {
        require(
            msg.sender == account || allowed[msg.sender],
            "Caller not allowed"
        );
        uint256 amount = rewards[account] + getPending(account);
        _mint(account, amount);
        rewards[account] = 0;
        lastClaimDatetime[account] = block.timestamp;
        allowed[msg.sender] = true;
    }
}
