//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";

import "./IWineBottleClubGenesis.sol";

/// @title Wine Bottle Club, Referral Program
/// @author Consultec FZCO, <info@consultec.ae>
contract WineBottleClubReferral is Ownable, Pausable, ReentrancyGuard {
    IWineBottleClubGenesis public immutable _genesis;
    uint256 public _kickback;
    uint256 public _mintPrice;

    mapping(address => uint256) public _referredCount;
    mapping(address => int256) public _referralLimit;

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
        _referralMint(to, uint16(count), referrer);
    }

    function _referralMint(
        address to,
        uint16 count,
        address referrer
    ) private {
        _referredCount[referrer] += count;
        int256 remaingingAllowance = getRemainingAllowance(referrer);
        require(remaingingAllowance >= 0, "!allowance");
        require(
            address(this).balance >= (_kickback + _mintPrice) * count,
            "!reserve"
        );
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(referrer).call{value: _kickback * count}("");
        require(success, "!transfer");
        uint256 prevTokenId = _genesis.totalSupply();
        _genesis.publicMint{value: msg.value}(to, count);
        unchecked {
            emit ReferralMinted(referrer, to, prevTokenId + 1, count);
        }
    }

    function addReferralLimits(
        address[] calldata addrs,
        int256[] calldata limits
    ) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _referralLimit[addrs[i]] = limits[i];
        }
    }

    function deleteReferralLimits(address[] calldata addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            delete _referralLimit[addrs[i]];
        }
    }

    function getRemainingAllowance(address referrer)
        public
        view
        returns (int256)
    {
        int256 refCount = int256(_referredCount[referrer]);
        if (_referralLimit[referrer] > 0) {
            return _referralLimit[referrer] - refCount;
        }
        return int256(_genesis.balanceOf(referrer)) - refCount;
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
