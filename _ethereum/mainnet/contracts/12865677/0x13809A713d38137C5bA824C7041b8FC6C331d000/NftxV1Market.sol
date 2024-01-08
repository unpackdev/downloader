// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IERC721.sol";

interface INFTX {
    function mint(
        uint256 vaultId, 
        uint256[] memory nftIds, 
        uint256 d2Amount
    ) external payable;

    // function redeem(
    //     uint256 vaultId,
    //     uint256 amount
    // ) external payable;
}

interface IWrappedPunk {
    /**
     * @dev Mints a wrapped punk
     */
    function mint(uint256 punkIndex) external;
    
    /**
     * @dev Registers proxy
     */
    function registerProxy() external;

    /**
     * @dev Gets proxy address
     */
    function proxyInfo(address user) external view returns (address);
}

interface ICryptoPunks {
    // Transfer ownership of a punk to another user without requiring payment
    function transferPunk(address to, uint punkIndex) external;
}

interface IMoonCatsWrapped {
    function wrap(bytes5 catId) external;
    function _catIDToTokenID(bytes5 catId) external view returns(uint256);
}

interface IMoonCatsRescue {
    /* puts a cat up for a specific address to adopt */
    function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) external;

    function rescueOrder(uint256 rescueIndex) external view returns(bytes5);
}

interface IMoonCatAcclimator {
    /**
     * @dev Take a list of MoonCats wrapped in this contract and unwrap them.
     * @param _rescueOrders an array of MoonCats, identified by rescue order, to unwrap
     */
    function batchUnwrap(uint256[] memory _rescueOrders) external;
}

library NftxV1Market {
    address public constant NFTX = 0xAf93fCce0548D3124A5fC3045adAf1ddE4e8Bf7e;

    function _approve(
        address _operator, 
        address _token, 
        uint256[] memory _tokenIds
    ) internal {
        // in case of kitties
        if (_token == 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                IERC721(_token).approve(_operator, _tokenIds[i]);
            }
        }
        // default
        else if (!IERC721(_token).isApprovedForAll(address(this), _operator)) {
            IERC721(_token).setApprovalForAll(_operator, true);
        }
    }

    function sellERC721ForERC20Equivalent(
        uint256 vaultId,
        uint256[] memory tokenIds,
        address token
    ) external {
        _approve(NFTX, token, tokenIds);
        INFTX(NFTX).mint(vaultId, tokenIds, 0);
    }
}