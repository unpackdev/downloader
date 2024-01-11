// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

abstract contract GhostMarketRoyalties {

    struct Royalty {
		address payable recipient;
		uint256 value;
	}

    /**
	 * @dev bytes4(keccak256(_GHOSTMARKET_NFT_ROYALTIES)) == 0xe42093a6
	 */
	bytes4 constant _GHOSTMARKET_NFT_ROYALTIES = bytes4(keccak256("_GHOSTMARKET_NFT_ROYALTIES"));

    /*
     * https://eips.ethereum.org/EIPS/eip-2981: bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0x2a55205a;
    // to calculate the percentage amount from token with royalty
    uint96 constant _WEIGHT_VALUE = 1000000;



    /*Method for converting amount to percent and forming Royalty*/
    function calculateRoyalties(address to, uint256 amount) internal pure returns (Royalty[] memory) {
        Royalty[] memory result;
        if (amount == 0) {
            return result;
        }
        uint256 percent = (amount * 100 / _WEIGHT_VALUE) * 100;
        require(percent < 10000, "Royalties 2981 greater than 100%");
        result = new Royalty[](1);
        result[0].recipient = payable(to);
        result[0].value = uint96(percent);
        return result;
    }

    /**
     * @dev get NFT royalties Royalty array
     */
    function getRoyalties(uint256 tokenId)
        external
        view
        returns (Royalty[] memory)
    {}
}
