// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBadbeatContract {

    /**
     * @dev Emitted when new tokens are minted by IMX.
    */

    event AssetMinted(address to, uint256 id, bytes blueprint);
 
    /**
     * @dev Emitted when Ethers are transfer to Payout Address.
    */

    event TransferEth(address from, address payoutAddress1, uint256 amount1, 
    address payoutAddress2, uint256 amount2, uint256 tokens , uint256 catId , uint256 totalAmountRecieved);

}
