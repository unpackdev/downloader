// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ISubjectTunnel.sol";
import "./DAOControlled.sol";
import "./ValidAddress.sol";

abstract contract SubjectTunnel is DAOControlled, ISubjectTunnel, ValidAddress {
    event DaoAddressChanged(address newDaoAddress);

    constructor(address payable _daoAddress) DAOControlled(_daoAddress) {}

    function _decodeMessage(bytes memory data)
        internal
        pure
        returns (
            uint256 tokenId,
            address ownerAddress,
            uint256 gene,
            bool isNotVirgin,
            bool isBoss,
            uint256 genomeChanges
        )
    {
        return abi.decode(data, (uint256, address, uint256, bool, bool, uint256));
    }

    function setDaoAddress(address payable _daoAddress)
        public
        virtual
        override
        onlyDAO
        isValidAddress(_daoAddress)
    {
        daoAddress = _daoAddress;

        DAOControlled(_daoAddress);

        emit DaoAddressChanged(_daoAddress);
    }
}
