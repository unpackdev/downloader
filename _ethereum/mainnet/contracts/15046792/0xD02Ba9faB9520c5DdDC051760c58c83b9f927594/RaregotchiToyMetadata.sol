// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./RaregotchiToyInterface.sol";

contract RaregotchiToyMetadata is Ownable {
    bool private isFrozen = false;
    bool private unveiled = false;

    string private veiledBaseUri = "";
    string private unveiledBaseUri = "";
    string private openBaseUri = "";

    address private toyContractAddress;

    uint16 maxSupply = 3000;

    modifier contractIsNotFrozen() {
        require(isFrozen == false, "This function can not be called anymore");
        _;
    }

    function setToyContractAddress(address _toyContractAddress)
        external
        onlyOwner
    {
        toyContractAddress = _toyContractAddress;
    }

    function unveil() external {
        require(
            msg.sender == toyContractAddress,
            "The caller is not the toy contract"
        );
        unveiled = true;
    }

    /**
     * @dev Set the default baseUri
     */
    function setVeiledBaseUri(string calldata _uri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        veiledBaseUri = _uri;
    }

    /**
     * @dev Set the unveiled baseUri
     */
    function setUnveiledBaseUri(string calldata _baseUri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        unveiledBaseUri = _baseUri;
    }

    /**
     * @dev Set the open baseUri
     */
    function setOpenBaseUri(string calldata _baseUri)
        external
        onlyOwner
        contractIsNotFrozen
    {
        openBaseUri = _baseUri;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        bool isOpen = RaregotchiToyInterface(toyContractAddress).isOpen(
            _tokenId
        );

        string memory baseUri = veiledBaseUri;

        if (unveiled) {
            baseUri = isOpen ? openBaseUri : unveiledBaseUri;
        }

        return string(abi.encodePacked(baseUri, Strings.toString(_tokenId)));
    }
}
