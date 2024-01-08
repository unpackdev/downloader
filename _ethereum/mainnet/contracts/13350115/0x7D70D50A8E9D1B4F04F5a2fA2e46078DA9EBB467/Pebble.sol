// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract Pebble is ERC721Enumerable, Ownable {

    using Strings for uint256;

    struct holder {
        address account;
        uint num;
    }

    mapping(address => uint) skullAndCrystalHolderClaimsAvailable; // whitelist for oily skulls and time crystals
    mapping(address => bool) oilysV2Claimers; // whitelist for oilyV2 holders

    /// @notice wallet addresses of the owners
    address constant LOGAN = 0x8b5B9497e096ee6FfD6041D1Db37a2ac2b41AB0d;
    address constant DD0SXX = 0xd491e93c6b05e3cdA3073482a5651BCFe3DC1cc7;
    address constant LCLMACHINE = 0x741BFDB9bea6Fa505fF9dFe9E8947B29863373fA;

    string _baseTokenURI;
    uint256 public constant PRICE = 0.1 ether;
    uint256 private reserve = 462;  // total of the three collections + 12 for founders
    bool public active;

    address constant OILYSV2 = 0x49623cAEc21B1fF5D04d7Bf7B71531369a69bCe4;

    modifier onlyActive {
        require( active, "contract is not active" );
        _;
    }

    constructor(string memory baseURI) ERC721("Pebbles", "PEBBLES") {
        setBaseURI(baseURI);
        // team gets the first 12 pebbles
        for (uint i = 1; i <= 10; i++) {
            _safeMint( LOGAN, i );
        }
        for (uint i = 11; i <= 15; i++) {
            _safeMint( DD0SXX, i );
        }
        for (uint i = 16; i <= 20; i++) {
            _safeMint( LCLMACHINE, i );
        }
        reserve -= 20;
    }

    function printer (uint num) private {
        uint256 supply = totalSupply();
        require( supply + num <= 2000 - reserve,  "Exceeds maximum Pebbles supply" );
        for(uint256 i = 1; i <= num; i++) {
            _safeMint( msg.sender, supply + i );
        }
    }

    function setSkullAndCrystalHoldersClaimsAvailable (holder[] memory array) external onlyOwner {
        for (uint i; i < array.length; i++) {
        skullAndCrystalHolderClaimsAvailable[array[i].account] = array[i].num;
        }
    }

    /// @dev function for oily v2 holders to mint for free
    function mintForOilysV2Holders (uint256 num) external onlyActive {
        uint max = IERC721(OILYSV2).balanceOf(msg.sender);
        require( oilysV2Claimers[msg.sender] == false,                                            'already minted');
        require( num <= max && num != 0,                         'cannot mint more than you are eligible for or 0');
        require( num <= reserve,                                                'not enough reserved pebbles left');

        oilysV2Claimers[msg.sender] = true;

        reserve -= num;
        printer(num);
    }

    /// @dev for skull and crystal hodlers to mint reserve tokens for free + gas
    function mintForSkullAndCrystalHolders (uint256 num) external onlyActive {
        require( num <= skullAndCrystalHolderClaimsAvailable[msg.sender] && num != 0,   'cannot mint more than you are eligible for or 0');
        require( num <= reserve,                                                                       'not enough reserved pebbles left');

        skullAndCrystalHolderClaimsAvailable[msg.sender] = 0; // users can only call this function once

        reserve -= num;
    
        printer(num);
    }

    /// @dev this is the regular mint function, which is open to the public when the contract is active
    function mint(uint256 num) external payable onlyActive {
        uint256 supply = totalSupply();
        require( num <= 20 && num != 0,          "You can mint a maximum of 20 Pebbles" );
        require( msg.value == PRICE * num,                  "Ether sent is not correct" );

        printer(num);
    }

    /// @dev returns the tokens that _walletOwner owns
    function walletOfOwner(address _walletOwner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_walletOwner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_walletOwner, i);
        }
        return tokensId;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev allows owner to update URI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @dev new token uri function
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory json = ".json";
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), json)) : "";
    }


    /// @dev Activates sale
    function toggleActivate(bool state) external onlyOwner {
        active = state;
    }

    /// @dev erases reserve allowing unclaimed reserved tokens to enter public sale
    function setReserve (uint num) external onlyOwner {
        reserve = num;
    }

    /// @dev allows owner to withdraw eth from the contract
    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0);
        uint256 _each = address(this).balance / 3;
        (bool status1, ) = payable(LOGAN).call{value: _each}("");
        (bool status2, ) = payable(DD0SXX).call{value: _each}("");
        (bool status3, ) = payable(LCLMACHINE).call{value: _each}("");
        require(status1 == true && status2 == true && status3 == true, 'withdraw failed');
    }
    
    fallback() external payable {
        revert('You sent ether to this contract without specifying a function');
    }
}