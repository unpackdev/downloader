// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./ERC165.sol";
import "./FlashLoanReceiverBase.sol";
import "./IWETH.sol";

contract Buyer is FlashLoanReceiverBase, Ownable, ERC721Holder, ERC165 {
    address public constant SEAPORT =
        0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public constant OPENSEA_CONDUIT =
        0x1E0049783F008A0085193E00003D00cd54003c71;
    IWETH weth;
    address seller;
    bytes openseaTransactionData;

    event FlashloanGranted(address seller, address provider, uint256 amount);

    constructor(ILendingPoolAddressesProvider provider, IWETH weth_)
        FlashLoanReceiverBase(provider)
    {
        weth = weth_;
        weth.approve(OPENSEA_CONDUIT, 10e10 ether);
    }

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        emit FlashloanGranted(seller, initiator, amounts[0]);

        // purchase nft from opensea
        (bool success, ) = SEAPORT.call(openseaTransactionData);
        require(success, "opensea transaction failed");

        uint256 openseaFees = (amounts[0] * 250) / 10000;

        // after buying the nft from opensea get the amount from the seller using pre approved manner
        weth.transferFrom(seller, address(this), amounts[0] - openseaFees);

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i] + premiums[i];
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }

    function myFlashLoanCall(
        address seller_,
        bytes calldata openseaTransactionData_,
        uint256 amount
    ) public onlyOwner {
        seller = seller_;
        openseaTransactionData = openseaTransactionData_;
        address receiverAddress = address(this);

        address[] memory assets = new address[](1);
        assets[0] = address(weth);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function withdraw() public onlyOwner {
        uint256 balance = weth.balanceOf(address(this));
        weth.transfer(msg.sender, balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }
}
