// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Pausable.sol";
import "./EnumerableSet.sol";

contract Staking is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;
    uint256 public constant SECONDS_IN_DAY = 24 * 60 * 60;

    uint256 internal _rate;
    uint256[] internal _tiers;
    uint256[] internal _accelerators;

    address public erc20Address;
    address public erc721Address;

    mapping(address => EnumerableSet.UintSet) internal _depositedIds;
    mapping(address => mapping(uint256 => uint256)) internal _depositedAt;

    constructor(address _erc721Address, address _erc20Address) {
        _pause();
        erc20Address = _erc20Address;
        erc721Address = _erc721Address;

        _rate = 1 * 10**18;
        _tiers = [0, 10, 20, 50, 77];
        _accelerators = [0, 5, 12, 28, 45];
    }

    function deposit(uint256[] calldata tokenIds) external whenNotPaused {
        for (uint256 i; i < tokenIds.length; i++) {
            _depositedIds[msg.sender].add(tokenIds[i]);
            _depositedAt[msg.sender][tokenIds[i]] = block.timestamp;
            IERC721(erc721Address).transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    function withdraw(uint256[] calldata tokenIds) external whenNotPaused {
        uint256 totalRewards;
        uint256 accelerator = _accelerator(_depositedIds[msg.sender].length());

        for (uint256 i; i < tokenIds.length; i++) {
            require(_depositedIds[msg.sender].contains(tokenIds[i]), "not owner");

            totalRewards += _earned(_depositedAt[msg.sender][tokenIds[i]], accelerator);

            _depositedIds[msg.sender].remove(tokenIds[i]);
            delete _depositedAt[msg.sender][tokenIds[i]];
            IERC721(erc721Address).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }
        IERC20(erc20Address).mint(msg.sender, totalRewards);
    }

    function claim() external whenNotPaused {
        uint256 totalRewards;
        uint256 length = _depositedIds[msg.sender].length();
        uint256 accelerator = _accelerator(length);

        for (uint256 i; i < length; i++) {
            uint256 tokenId = _depositedIds[msg.sender].at(i);
            totalRewards += _earned(_depositedAt[msg.sender][tokenId], accelerator);
            _depositedAt[msg.sender][tokenId] = block.timestamp;
        }

        IERC20(erc20Address).mint(msg.sender, totalRewards);
    }

    function _accelerator(uint256 tokens) internal view returns (uint256) {
        uint256 tierIndex;
        for (uint256 i; i < _tiers.length; i++) if (tokens >= _tiers[i]) tierIndex = i;
        return _accelerators[tierIndex];
    }

    function _earned(uint256 timestamp, uint256 accelerator) internal view returns (uint256) {
        if (timestamp == 0) return 0;
        return ((block.timestamp - timestamp) * (_rate + ((_rate / 100) * accelerator))) / SECONDS_IN_DAY;
    }

    function depositsOf(address wallet) external view returns (uint256[] memory) {
        uint256 length = _depositedIds[wallet].length();
        uint256[] memory ids = new uint256[](length);
        for (uint256 i; i < length; i++) ids[i] = _depositedIds[wallet].at(i);
        return ids;
    }

    function depositedAt(address wallet, uint256 tokenId) external view returns (uint256) {
        return _depositedAt[wallet][tokenId];
    }

    function tier(uint256 tokensAmount) external view returns (uint256) {
        uint256 tierIndex;
        for (uint256 i; i < _tiers.length; i++) if (tokensAmount >= _tiers[i]) tierIndex = i;
        return tierIndex;
    }

    function rewardsOf(address wallet) external view returns (uint256[] memory) {
        uint256 length = _depositedIds[wallet].length();
        uint256 accelerator = _accelerator(length);

        uint256[] memory rewards = new uint256[](length);
        for (uint256 i; i < length; i++) {
            uint256 tokenId = _depositedIds[wallet].at(i);
            rewards[i] = _earned(_depositedAt[wallet][tokenId], accelerator);
        }
        return rewards;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function rate() external view returns (uint256) {
        return _rate;
    }

    function setRate(uint256 newRate) external onlyOwner {
        _rate = newRate * 10**18;
    }

    function tiers() external view returns (uint256[] memory) {
        return _tiers;
    }

    function accelerators() external view returns (uint256[] memory) {
        return _accelerators;
    }

    function setERC20Contract(address _erc20Address) external onlyOwner {
        erc20Address = _erc20Address;
    }

    function setERC721Contract(address _erc721Address) external onlyOwner {
        erc721Address = _erc721Address;
    }

    function setTiers(uint256[] memory newTiers, uint256[] memory newAccelerators) external onlyOwner {
        require(newTiers.length == newAccelerators.length, "different length");

        _tiers = newTiers;
        _accelerators = newAccelerators;
    }

    function emergencyWithdrawERC721Tokens(uint256[] calldata tokens, address receiver) external onlyOwner {
        for (uint256 i; i < tokens.length; i++) {
            if (IERC721(erc721Address).ownerOf(tokens[i]) == address(this)) {
                IERC721(erc721Address).transferFrom(address(this), receiver, tokens[i]);
            }
        }
    }
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC20 {
    function mint(address to, uint256 amount) external;
}
