// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.18;

/**
 * @title A helper smart to see how event are handled when 1 transaction is split in several transfers to some ERC-20 contract.
 */
contract Erc20TransactionSplitter {

    function splitTransfer(address erc20_contract_address, uint num_transfers, address to, uint tokens) public payable {
        require(num_transfers > 0, "number of transfers must be positive");
        for (uint i=0; i < num_transfers; i++) 
        {
            (bool success, ) = erc20_contract_address.call(abi.encodeWithSignature("transfer(address,uint256)", to, tokens/num_transfers));
            require(success);
        }
    }

}