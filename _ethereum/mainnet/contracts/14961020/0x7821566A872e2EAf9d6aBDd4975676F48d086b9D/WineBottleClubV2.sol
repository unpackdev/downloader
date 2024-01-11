//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";

import "./IWineBottleClubGenesis.sol";

/// @title Wine Bottle Club, Referral Program V2
/// @author Consultec FZCO, <info@consultec.ae>
contract WineBottleClubReferralV2 is Ownable, Pausable, ReentrancyGuard {
    IWineBottleClubGenesis public immutable _genesis;
    uint256 public _kickback;
    uint256 public _mintPrice;

    event ReferralMinted(
        address indexed referrer,
        address indexed owner,
        uint256 indexed tokenId,
        uint256 count
    );

    constructor(
        address genesis,
        uint256 price,
        uint256 kickback
    ) {
        _genesis = IWineBottleClubGenesis(genesis);
        _mintPrice = price;
        _kickback = kickback;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMintPrice(uint256 mintPrice) external onlyOwner {
        _mintPrice = mintPrice;
    }

    function setKickback(uint256 kickback) external onlyOwner {
        _kickback = kickback;
    }

    function referralMint(
        address to,
        uint256 count,
        address referrer
    ) external payable nonReentrant whenNotPaused {
        uint256 prevTokenId = _genesis.totalSupply();
        uint16 count_ = uint16(count);
        require(
            address(this).balance >= (_kickback + _mintPrice) * count_,
            "!reserve"
        );
        _genesis.publicMint{value: msg.value}(to, count_);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(referrer).call{value: _kickback * count_}(
            ""
        );
        require(success, "!transfer");
        unchecked {
            emit ReferralMinted(referrer, to, prevTokenId + 1, count_);
        }
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "!transfer");
    }

    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }
}
