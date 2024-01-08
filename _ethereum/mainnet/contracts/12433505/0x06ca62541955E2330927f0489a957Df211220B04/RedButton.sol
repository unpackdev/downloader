// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/*
    Naturally Red Button functionality.
    Creates special role - admin. He's allowed to perform the list of any
    external calls.
*/
contract RedButton {
    address public admin;

    /*
        Internal function for transferring admin ownership
    */
    function _setAdmin(address _admin) internal {
        admin = _admin;
    }

    /*
        Transfer admin ownership
        @dev Only called by
        @param _newAdmin New admin address
    */
    function transferAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), 'Cant set admin to zero address');
        _setAdmin(_newAdmin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Sender not admin');
        _;
    }

    /*
        Execute list of calls. Any calls allowed - transfer ETH, call any contract any function.
        @param _to List of addresses to which make a calls
        @param _data List of call data, may be empty for ETH transfer
        @param weiAmount List of ETH amounts to send on each call
        @dev All params should be same length
    */
    function externalCallEth(
        address payable[] memory  _to,
        bytes[] memory _data,
        uint256[] memory weiAmount
    ) onlyAdmin public payable {
        require(
            _to.length == _data.length && _data.length == weiAmount.length,
            "Parameters should be equal length"
        );

        for (uint16 i = 0; i < _to.length; i++) {
            _cast(_to[i], _data[i], weiAmount[i]);
        }
    }

    function _cast(
        address payable _to,
        bytes memory _data,
        uint256 weiAmount
    ) internal {
        bytes32 response;

        assembly {
            let succeeded := call(sub(gas(), 5000), _to, weiAmount, add(_data, 0x20), mload(_data), 0, 32)
            response := mload(0)
            switch iszero(succeeded)
            case 1 {
                revert(0, 0)
            }
        }
    }
}
