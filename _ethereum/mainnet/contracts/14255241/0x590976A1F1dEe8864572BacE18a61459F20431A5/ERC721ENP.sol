// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Base.sol";

contract ERC721ENP is ERC721EBase {
    using Strings for uint256;

    bool private _final = false;
    mapping(uint256 => bool) private _freez;

    bool private _autoFreeze = false;

    event URIfreezing(address indexed sender, uint256 tokenId);
    event ContractFinalize(address indexed sender);
    
    constructor(string memory name_, string memory symbol_, address ownerAddress)
    ERC721EBase(name_, symbol_, ownerAddress)
    {}

    function getOwnerFee()
        public
        view
        returns(uint256)
    {
        return address(this).balance;
    }

    function withdrawETH()
        external
        virtual
        onlyAdmin
        emergencyMode
        override
    {
        uint256 royalty = address(this).balance;

        Address.sendValue(payable(owner()), royalty);
    }

    function putTokenURI(uint256 tokenId, string memory uri)
        external
        onlySupporter
    {
       require(!_final, "Already Finalized");
        require(tokenOwnerIsCreator(tokenId), "Can not write");
        _setTokenURI(tokenId, uri);
    }

    function enableAutoFreez()
        public
        virtual
        onlySupporter
    {
        _autoFreeze = true;
    }

    function disableAutoFreez()
        public
        virtual
        onlySupporter
    {
        _autoFreeze = false;
    }

    function mint(string memory uri)
        public
        onlyOwner
        emergencyMode
    {
        require(!_final, "Already Finalized");
        uint256 currentNumber = totalSupply() + 1;

        _safeMint(_msgSender(), currentNumber);
        _setTokenURI(currentNumber, uri);

        if(_autoFreeze){
            freezing(currentNumber);
        }
    }

    function finalize()
        external
        onlySupporter
    {
        _final = true;
        emit ContractFinalize(_msgSender());
    }

    function freezing(uint256 tokenId)
        public
        onlyAdmin
        emergencyMode
    {
        _freez[tokenId] = true;
        emit URIfreezing(_msgSender(), tokenId);
    }

    function isFinalize()
        external
        view
        returns( bool )
    {
        return _final;
    }

    function isFreezing(uint256 tokenId)
        external
        view
        returns( bool )
    {
        return _freez[tokenId];
    }

}
