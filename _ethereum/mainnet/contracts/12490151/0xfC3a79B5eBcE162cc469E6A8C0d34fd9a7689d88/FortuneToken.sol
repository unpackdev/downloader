// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./IMao.sol";

contract FortuneToken is ERC20Burnable, ERC20Capped {
    uint256 public immutable tokenStart;
    uint256 public constant INITIAL_ALLOCATION = 888 ether;
    uint256 public constant SECONDS_PER_DAY = 86_400;

    mapping (uint256 => uint256) private _lastClaimed;
    address private immutable _maoAddress;

    constructor(uint256 _tokenStart, address maoAddress)
    ERC20("FortuneToken", "FORTUNE") 
    ERC20Capped(888_888_888 ether) {
        tokenStart = _tokenStart;
        _maoAddress = maoAddress;
    }

    function claim(uint256[] memory tokenIds) external {
        uint256 tokenIdsLength = tokenIds.length;
        require(tokenIdsLength < 8889, "Too many tokens");

        uint256 totalClaimAmount = 0;
        uint256 claimAmount;
        uint256 currentTokenId;

        for (uint i = 0; i < tokenIdsLength; i++) {

            currentTokenId = tokenIds[i];

            // Validate tokenId
            address tokenOwner = IMao(_maoAddress).ownerOf(currentTokenId);
            require(tokenOwner != address(0), "NFT not minted yet");
            require(tokenOwner == _msgSender(), "Sender is not owner");

            for (uint j = i + 1; j < tokenIdsLength; j++) {
                require(tokenIds[j] != currentTokenId, "Duplicate tokenId");
            }

            claimAmount = accumulated(currentTokenId);
            if (claimAmount > 0) {
                _lastClaimed[currentTokenId] = block.timestamp;
                totalClaimAmount += claimAmount;
            }
        }

        require(totalClaimAmount > 0, "Nothing to claim");
        _mint(_msgSender(), totalClaimAmount);
    }

    function getLastClaimedTimestamp(uint256 tokenId) private view returns (uint256) {
        return _lastClaimed[tokenId] != 0 ? _lastClaimed[tokenId] : tokenStart;
    }

    function accumulated(uint256 tokenId) public view returns (uint256) {
        uint256 tokenEarnAmount = IMao(_maoAddress).getTokenEarnAmount(tokenId);

        // Accumulation period
        uint256 lastClaimedTimestamp = getLastClaimedTimestamp(tokenId);
        uint256 timeElapsed = block.timestamp - lastClaimedTimestamp;
        uint256 accumulatedAmount = timeElapsed * tokenEarnAmount / SECONDS_PER_DAY;

        if (lastClaimedTimestamp == tokenStart) {
            accumulatedAmount += INITIAL_ALLOCATION;
        }

        return accumulatedAmount;
    }


    /**
     * Custom functions
     */

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        if (msg.sender != _maoAddress) {
            decreaseAllowance(msg.sender, amount);
        }

        return true;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual override {
        _burn(msg.sender, amount);
    }
}