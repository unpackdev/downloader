// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library JamInteraction {
    /// @dev Data representing an interaction on the chain
    struct Data {
        /// 
        bool result;
        address to;
        uint256 value;
        bytes data;
    }

    /// @dev Execute the interaciton and return the result
    /// 
    /// @param interaction The interaction to execute
    /// @return result Whether the interaction succeeded
    function execute(Data calldata interaction) internal returns (bool result) {
        (bool _result,) = payable(interaction.to).call{ value: interaction.value }(interaction.data);
        return _result;
    }
}