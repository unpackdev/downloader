pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./IERC721.sol";
import "./Operations.sol";

interface IZKSeaNFT {
    function onDeposit(IERC721 c, uint256 tokenId, address addr) external returns (Operations.DepositNFT memory);
    function addWithdraw(Operations.WithdrawNFTData calldata wd) external;
    function genWithdrawItems(uint32 n) external returns (WithdrawItem[] memory);
    function onWithdraw(address target, uint64 globalId) external returns (address, uint256);
    function withdrawBalanceUpdate(address addr, uint64 globalId) external;
    function numOfPendingWithdrawals() external view returns (uint32);

    struct WithdrawItem {
        address tokenContract;
        uint256 tokenId;
        uint64 globalId;
        address to;
    }
}
