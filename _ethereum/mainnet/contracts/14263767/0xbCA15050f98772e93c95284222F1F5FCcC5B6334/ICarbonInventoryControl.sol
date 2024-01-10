//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface ICarbonInventoryControl {

     /**
     * @dev function to offset carbon foot print on token and inventory.
     * @param _to Wallet from whom will be burned tokens.
     * @param _broker Broker who will burn tokens.
     * @param _carbonTon Amount to burn on carbon tons.
     * @param _receiptId Transaction identifier that represent the offset.
     * @param _onBehalfOf Broker is burning on behalf of someone.
     * @param _token Commmercial carbon credit token which will be burned.
     */
    function offsetTransaction(address _to, address _broker, uint256 _carbonTon, string memory _receiptId, string memory _onBehalfOf, address _token )
        external;

}