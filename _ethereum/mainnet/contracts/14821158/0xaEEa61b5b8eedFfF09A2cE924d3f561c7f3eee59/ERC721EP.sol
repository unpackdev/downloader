// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Base.sol";

contract ERC721EP is ERC721EBase {
    using Strings for uint256;

    address private constant _supporter_addr = 0xCF9542a8522E685a46007319Af9C39F4Fde9d88a;

    bool private _final = false;
    mapping(uint256 => bool) private _freez;
    uint256 private _mintFee = 0.03 ether;
    bool private _autoFreeze = true;

    event ContractFinalize(address indexed sender);
    
    constructor(string memory name_, string memory symbol_, uint256 royalty, uint256 mintFee_)
    ERC721EBase(name_, symbol_, _supporter_addr, royalty)
    {
        _mintFee = mintFee_;
    }

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

    function setMintFee(uint256 fee)
        public
        onlySupporter
    {
        _mintFee = fee;
    }

    function getMintFee()
        external
        view
        returns(uint256)
    {
        return _mintFee;
    }

    function mint(string memory uri)
        public
        payable
        onlyOwner
        emergencyMode
    {
        require(msg.value >= _mintFee, "Need to send ETH");
        require(!_final, "Already Finalized");
        uint256 currentNumber = totalSupply() + 1;

        _safeMint(_msgSender(), currentNumber);
        _setTokenURI(currentNumber, uri);

        Address.sendValue(payable(supporter()), msg.value);

        if(_autoFreeze){
            freezing(currentNumber);
        }
    }

    function finalize()
        public
        virtual
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
