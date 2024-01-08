// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.4;

import "./ERC721.sol";
import "./IEqzYieldNft.sol";
import "./Ownable.sol";

contract EqzYieldNft is ERC721, IEqzYieldNft, Ownable {
    address immutable public eqzYieldFarm;
    string public baseURI;

    constructor(
        address _eqzYieldFarm,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        eqzYieldFarm = _eqzYieldFarm;
    }

    function mint(address _to, uint256 _tokenId) external override {
        require(msg.sender == eqzYieldFarm, 'MINT_SENDER_NOT_EQZ_YIELD_FARM');
        _mint(_to, _tokenId);
    }

    function burn(uint256 _tokenId) external override {
        require(msg.sender == eqzYieldFarm, 'BURN_SENDER_NOT_EQZ_YIELD_FARM');
        _burn(_tokenId);
    }

    /*
    * @dev _baseURI overwrite _baseURI for computing tokenURI
    */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*
    * @dev setBaseURI Setter for baseURI
    */
    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
        emit BaseURIEvent(_uri);
    }
}
