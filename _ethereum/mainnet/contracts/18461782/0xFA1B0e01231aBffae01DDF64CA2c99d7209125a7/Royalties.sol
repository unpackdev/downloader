// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC165.sol";
import "./IERC2981.sol";

import "./IRoyalties.sol";

error IERC2981AlreadySupported();
error IncorrectRoyalty();
error NotOwnerOrPlatform();

interface IOwnable {
    function owner() external view returns (address);
}

contract Royalties is Ownable, IRoyalties {
    uint96 constant FEE_DENOMINATOR = 10000;
    address platform;

    struct RoyaltyInfo {
        address receiver;
        uint96 royalty;
    }

    mapping(address => RoyaltyInfo) royalties;

    modifier onlyOwnerOrPlatform(address token) {
        address tokenOwner;
        try IOwnable(token).owner() {
            tokenOwner = IOwnable(token).owner();
        } catch {}

        if (
            msg.sender != tokenOwner &&
            msg.sender != platform &&
            msg.sender != owner()
        ) revert NotOwnerOrPlatform();
        _;
    }

    event RoyaltyUpdated(
        address indexed token,
        address receiver,
        uint96 royaltyRate
    );

    function setRoyalty(
        address token,
        address receiver,
        uint96 royaltyRate
    ) external onlyOwnerOrPlatform(token) {
        if (IERC165(token).supportsInterface(type(IERC2981).interfaceId))
            revert IERC2981AlreadySupported();
        if (
            receiver == address(0) ||
            royaltyRate == 0 ||
            royaltyRate > FEE_DENOMINATOR
        ) revert IncorrectRoyalty();

        emit RoyaltyUpdated(token, receiver, royaltyRate);

        royalties[token] = RoyaltyInfo(receiver, royaltyRate);
    }

    function royaltyInfo(
        address token,
        uint256 salePrice
    ) public view override returns (address, uint256) {
        RoyaltyInfo memory royalty = royalties[token];

        uint256 royaltyAmount = (salePrice * royalty.royalty) / FEE_DENOMINATOR;

        return (royalty.receiver, royaltyAmount);
    }

    /// @notice Set the platform address
    /// @param _platform New address of the platform
    function setPlatform(address _platform) external onlyOwner {
        platform = _platform;
    }
}
