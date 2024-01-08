pragma solidity ^0.6.2;

import "./IOpenseaMetadata.sol";
import "./ERC165.sol";

abstract contract OpenseaMetdata is IOpenSeaMetadata, ERC165 {
    string public override contractURI;
    bytes4 private constant _INTERFACE_ID_CONTRACT_METADATA_URI = 0x7a62b340;

    constructor (string memory uri_) public {
        _setContractURI(uri_);
        _registerInterface(_INTERFACE_ID_CONTRACT_METADATA_URI);
    }

    function _setContractURI(string memory newUri) internal virtual {
        contractURI = newUri;
    }
}
