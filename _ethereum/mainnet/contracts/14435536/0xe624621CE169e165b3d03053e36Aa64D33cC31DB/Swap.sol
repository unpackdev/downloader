// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccessControlEnumerable.sol";

import "./ICollectibles.sol";
import "./IERC721.sol";

contract Swap is AccessControlEnumerable {
    error OnlyAdminError();
    error PairNotFoundError();
    error InvalidToTokenIdError();
    error NoCollateralError();

    address public collateralAddress;
    address public swappableAddress;

    IERC721 public collateral;
    ICollectibles public swappable;

    mapping(uint256 => uint256[]) public pairs;

    event SwapEvent(address indexed sender, uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 amount);

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert OnlyAdminError();
        }
        _;
    }

    /// @notice Constructor
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function updateCollateralAddress(address _collateralAddress) external onlyAdmin {
        collateralAddress = _collateralAddress;

        collateral = IERC721(collateralAddress);
    }

    function updateSwappableAddress(address _swappableAddress) external onlyAdmin {
        swappableAddress = _swappableAddress;

        swappable = ICollectibles(swappableAddress);
    }

    /// @dev set pair in pairs
    /// @param _fromTokenId tokenId which is burned
    /// @param _toTokenIds tokenIds which is minted
    function setPair(uint256 _fromTokenId, uint256[] calldata _toTokenIds) external onlyAdmin {
        pairs[_fromTokenId] = _toTokenIds;
    }

    /// @dev remove pair from pairs
    /// @param _fromTokenId tokenId which is swapped
    function removePair(uint256 _fromTokenId) external onlyAdmin {
        delete pairs[_fromTokenId];
    }

    /// @dev swap a pair defined in `pairs`
    /// @param _fromTokenId tokenId which is swapped
    /// @param _toTokenId tokenId which is consumed
    /// @param _amount amount of fromTokenId to swap
    function swap(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _amount
    ) external {
        address sender = _msgSender();
        uint256[] memory toTokenIds = pairs[_fromTokenId];

        if (toTokenIds.length == 0) {
            revert PairNotFoundError();
        }

        if (!_contains(toTokenIds, _toTokenId)) {
            revert InvalidToTokenIdError();
        }

        if (collateral.balanceOf(sender) < 1) {
            revert NoCollateralError();
        }

        swappable.burn(sender, _fromTokenId, _amount);
        swappable.mint(sender, _toTokenId, _amount);

        emit SwapEvent(sender, _fromTokenId, _toTokenId, _amount);
    }

    function _contains(uint256[] memory _array, uint256 _needle) internal pure returns (bool) {
        for (uint256 i = 0; i < _array.length; i++) {
            if (_needle == _array[i]) {
                return true;
            }
        }

        return false;
    }
}
