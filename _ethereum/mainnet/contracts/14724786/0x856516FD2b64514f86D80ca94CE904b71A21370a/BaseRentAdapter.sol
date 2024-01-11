// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Address.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./IBaseRentAdapter.sol";

contract BaseRentAdapter is ERC721Holder, ReentrancyGuard {
    using Address for address;

    address public immutable TRIBE_ONE_ADDRESS;

    address public devWallet;

    constructor(address _TRIBE_ONE_ADDRESS, address _devWallet) {
        require(_TRIBE_ONE_ADDRESS.isContract(), "BRA: Only contract address is available");
        TRIBE_ONE_ADDRESS = _TRIBE_ONE_ADDRESS;
        devWallet = _devWallet;
    }

    modifier onlyTribeOne() {
        require(msg.sender == TRIBE_ONE_ADDRESS, "BRA: Only TribeOne is allowed");
        _;
    }

    function setDevWallet(address _devWallet) external {
        require(msg.sender == _devWallet, "Only dev can change dev wallet");
        devWallet = _devWallet;
    }

    // function listNFTForRent(uint256 loandId) external virtual {}

    // function withdrawNFTFromRent(uint256 loanId) external virtual override {}

    // function claimRentFee(uint256 loanId) external virtual {}

    // function adjustRentFee(uint256 loanId) external virtual {}
}
