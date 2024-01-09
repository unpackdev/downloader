// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./Ownable.sol";

abstract contract CROWDValidator is Ownable {
    mapping(address => address) private _validators;

    mapping(uint256 => bool) private _processed;

    function setValidator(address _addr, address _validator) public onlyOwner {
        _validators[_addr] = _validator;
    }

    function getValidator(address _addr) public view returns (address) {
        return _validators[_addr];
    }

    function checkValidator(address _addr) internal view returns (address) {
        address _validator = getValidator(_addr);
        require(_validator != address(0), "validator is not set.");
        return _validator;
    }

    function isContract(address _addr) internal view returns (bool _correct) {
        uint256 _size;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            _size := extcodesize(_addr)
        }
        return _size > 0;
    }

    function isProcessed(uint256 id) internal view returns (bool) {
        return _processed[id];
    }

    function setProcessed(uint256 id) internal {
        _processed[id] = true;
    }

    function verify(
        string memory message,
        uint256 id,
        address addr,
        uint256 amount,
        address addr2,
        uint256 expired_at,
        address signer,
        bytes memory signature
    ) internal {
        require(isProcessed(id) == false, "already processed id");
        ECDSA.verify(message, id, addr, amount, addr2, expired_at, signer, signature);
        setProcessed(id);
    }
}
