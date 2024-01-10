// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Base.sol";

contract ERC721E is ERC721EBase {
    using Strings for uint256;

    bool private _final = false;
    mapping(uint256 => bool) private _freez;

    uint256 private _supporterFee = 0;

    event URIfreezing(address indexed sender, uint256 tokenId);
    event ContractFinalize(address indexed sender);
    
    constructor(string memory name_, string memory symbol_)
    ERC721EBase(name_, symbol_) {}

    function getSupporterFee()
        public
        view
        returns(uint256)
    {
        return _supporterFee;
    }

    function getOwnerFee()
        public
        view
        returns(uint256)
    {
        return address(this).balance - _supporterFee;
    }

    function withdrawETH()
        external
        virtual
        onlyAdmin
        emergencyMode
        override
    {
        uint256 royalty = address(this).balance - _supporterFee;

        Address.sendValue(payable(owner()), royalty);
        Address.sendValue(payable(supporter()), _supporterFee);
        _supporterFee = 0;
    }

    function putTokenURI(uint256 tokenId, string memory uri)
        external
        onlyAdmin
    {
        require(!_final, "Already Finalized");
        require(!_freez[tokenId], "Already Freezed");
        require(tokenOwnerIsCreator(tokenId), "Can not write");
        _setTokenURI(tokenId, uri);
    }

    function mint(string memory uri)
        public
        payable
        onlyAdmin
        emergencyMode
    {
        require(msg.value >= 0.03 ether, "Need to send 0.03 ETH");
        require(!_final, "Already Finalized");
        uint256 currentNumber = totalSupply() + 1;

        _safeMint(_msgSender(), currentNumber);
        _setTokenURI(currentNumber, uri);

        _supporterFee = _supporterFee + msg.value;
    }

    function finalize()
        external
        onlyAdmin
    {
        _final = true;
        emit ContractFinalize(_msgSender());
    }

    function freezing(uint256 tokenId)
        external
        onlyAdmin
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
