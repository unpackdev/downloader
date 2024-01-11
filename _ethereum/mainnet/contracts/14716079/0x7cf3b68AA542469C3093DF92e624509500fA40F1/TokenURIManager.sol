// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "./ChonkyChkns.sol";

interface ITokenURIManager {
    function setBaseUri(string calldata _baseUri) external;

    function baseURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ChonkyChknsTokenURIManager {
    using Strings for uint256;

    ChonkyChkns public chonkyContract;
    string private _baseURI;

    constructor(address _chonkyChkns) {
        chonkyContract = ChonkyChkns(_chonkyChkns);
    }

    modifier onlyContract() {
        require(
            msg.sender == address(chonkyContract),
            "Only callable by ChonkyChkns contract"
        );
        _;
    }

    function setBaseUri(string calldata _newBaseURI) external onlyContract {
        _baseURI = _newBaseURI;
    }

    function baseURI() external view onlyContract returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        onlyContract
        returns (string memory)
    {
        // TokenURI branches off depending on token type of tokenId
        string memory tokenType = chonkyContract.isGenesis(tokenId)
            ? "genesis"
            : "standard";

        return
            bytes(_baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        _baseURI,
                        tokenType,
                        "/",
                        tokenId.toString()
                    )
                )
                : "";
    }
}
