/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/
// SPDX-License-Identifier: GPL-3.0-or-later
// solium-disable linebreak-style

pragma solidity 0.8.6;

import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @title PrimeDAO Reputation contract
 * @dev   Reputation is a non-transferable ERC20 token used for PrimeDAO Governance.
 */
contract Reputation is ERC20, Ownable {
    modifier validInput(
        address[] memory _repRecipients,
        uint256[] memory _repAmounts
    ) {
        require(
            _repRecipients.length == _repAmounts.length,
            "Reputation: number of reputation holders doesn't match number of reputation amounts"
        );
        require(
            _repRecipients.length <= 200,
            "Reputation: maximum number of reputation holders and amounts of 200 was exceeded"
        );
        _;
    }

    /**
     * @dev                  Reputation constructor function.
     */
    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC20(_tokenName, _tokenSymbol)
    {}

    /**
     * @dev  Overrides standard ERC20 transfer function, to make tokens non-trasferable.
     * @param recipient     unused parameter.
     * @param amount        unused parameter.
     */
    function transfer(address recipient, uint256 amount)
        public
        pure
        override
        returns (bool)
    {
        return false;
    }

    /**
     * @dev                 Overrides standard ERC20 transferFrom function, to make tokens non-trasferable.
     * @param sender        unused parameter.
     * @param recipient     unused parameter.
     * @param amount        unused parameter.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public pure override returns (bool) {
        return false;
    }

    /**
     * @dev                  Mints reputation to a given address.
     * @param _repRecipient  adress that rep is being minted to.
     * @param _repAmount     amount of reputation to be minted.
     */
    function mint(address _repRecipient, uint256 _repAmount) public onlyOwner {
        ERC20._mint(_repRecipient, _repAmount);
    }

    /**
     * @dev                   Mints reputation for multiple adresses.
     * @param _repRecipients  an array of adresses that rep is being minted to.
     * @param _repAmounts     an array of amounts of reputation to be minted.
     */
    function batchMint(
        address[] memory _repRecipients,
        uint256[] memory _repAmounts
    ) public onlyOwner {
        _batchMint(_repRecipients, _repAmounts);
    }

    /**
     * @dev                  Burns reputation of a given address.
     * @param _repRecipient  adress that's rep is being burned.
     * @param _repAmount     amount of reputation to be burned.
     */
    function burn(address _repRecipient, uint256 _repAmount) public onlyOwner {
        ERC20._burn(_repRecipient, _repAmount);
    }

    /**
     * @dev                   Burns reputation of multiple adresses.
     * @param _repRecipients  an array of adresses that's rep is being burned.
     * @param _repAmounts     an array of amounts of reputation to be burned.
     */
    function batchBurn(
        address[] memory _repRecipients,
        uint256[] memory _repAmounts
    ) public onlyOwner {
        _batchBurn(_repRecipients, _repAmounts);
    }

    // HELPER FUNCTIONS

    function _batchMint(
        address[] memory _repRecipients,
        uint256[] memory _repAmounts
    ) internal validInput(_repRecipients, _repAmounts) {
        for (uint64 j = 0; j < _repAmounts.length; j++) {
            ERC20._mint(_repRecipients[j], _repAmounts[j]);
        }
    }

    function _batchBurn(
        address[] memory _repRecipients,
        uint256[] memory _repAmounts
    ) internal validInput(_repRecipients, _repAmounts) {
        for (uint64 j = 0; j < _repAmounts.length; j++) {
            ERC20._burn(_repRecipients[j], _repAmounts[j]);
        }
    }
}
