// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract ClaimFashion is Ownable, Pausable {

    using SafeERC20 for IERC20;
    IERC20 public immutable fashionToken;

    ERC721Enumerable public immutable fashionApe;

    uint256 public immutable DISTRIBUTION_AMOUNT;

    uint256 public totalClaimed;

    mapping (uint256 => bool) public fashionClaimed;

    event FashionClaimed(
        uint256 indexed tokenId,
        address indexed account,
        uint256 timestamp
    );

    event AirDrop(
        address indexed account,
        uint256 indexed amount,
        uint256 timestamp
    );

    constructor(
        address _fashionTokenAddress,
        address _fashionApeContractAddress,
        uint256 _DISTRIBUTION_AMOUNT
    ) {
        require(_fashionTokenAddress != address(0), "The Fashion token address can't be 0");
        require(_fashionApeContractAddress != address(0), "The Fashion Ape contract address can't be 0");

        fashionToken = IERC20(_fashionTokenAddress);
        fashionApe = ERC721Enumerable(_fashionApeContractAddress);

        DISTRIBUTION_AMOUNT = _DISTRIBUTION_AMOUNT;
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function claimTokens() external whenNotPaused {
        require(fashionApe.balanceOf(msg.sender) > 0, "Nothing to claim no fashion ape in wallet");
        require(getClaimableTokenAmount(msg.sender) > 0, "Nothing to claim");

        uint256 tokensToClaim;

        tokensToClaim = _getClaimableTokenAmount(msg.sender);

        for(uint256 i; i < fashionApe.balanceOf(msg.sender); ++i) {
            uint256 tokenId = fashionApe.tokenOfOwnerByIndex(msg.sender, i);
            if(!fashionClaimed[tokenId]) {
                fashionClaimed[tokenId] = true;
                emit FashionClaimed(tokenId, msg.sender, block.timestamp);
            }
        }

        fashionToken.safeTransfer(msg.sender, tokensToClaim);

        totalClaimed += tokensToClaim;
        emit AirDrop(msg.sender, tokensToClaim, block.timestamp);
    }

    function getClaimableTokenAmount(address _account) public view returns (uint256) {
        uint256 tokensAmount;
        (tokensAmount) = _getClaimableTokenAmount(_account);
        return tokensAmount;
    }

    function _getClaimableTokenAmount(address _account) private view returns (uint256)
    {
        uint256 unclaimedBalance;
        for(uint256 i; i < fashionApe.balanceOf(_account); ++i) {
            uint256 tokenId = fashionApe.tokenOfOwnerByIndex(_account, i);
            if(!fashionClaimed[tokenId]) {
                ++unclaimedBalance;
            }
        }
        uint256 tokensAmount = (unclaimedBalance * DISTRIBUTION_AMOUNT);

        return tokensAmount;
    }

    function claimUnclaimedTokens() external onlyOwner {
        fashionToken.safeTransfer(owner(), fashionToken.balanceOf(address(this)));

        uint256 balance = address(this).balance;
        if (balance > 0) {
            Address.sendValue(payable(owner()), balance);
        }
    }
}