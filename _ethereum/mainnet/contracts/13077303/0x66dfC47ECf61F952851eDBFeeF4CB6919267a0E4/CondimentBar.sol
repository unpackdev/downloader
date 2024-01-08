// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract CondimentBar is ERC1155, Ownable {
    using Strings for uint256;
    address private hotDogContract;
    string private baseURI;
    mapping(uint256 => bool) public validCondimentTypes;

    event SetBaseURI(string indexed _baseURI);

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        validCondimentTypes[0] = true;
        validCondimentTypes[1] = true;
        validCondimentTypes[69] = true;
        emit SetBaseURI(baseURI);
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts)
        external
        onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
    }

    function setHotDogContractAddress(address hotDogContractAddress)
        external
        onlyOwner
    {
        hotDogContract = hotDogContractAddress;
    }

    function burnCondimentForAddress(uint256 typeId, address burnTokenAddress)
        external
    {
        require(msg.sender == hotDogContract, "Invalid burner address");
        _burn(burnTokenAddress, typeId, 1);
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            validCondimentTypes[typeId],
            "URI requested for invalid condiment type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}
